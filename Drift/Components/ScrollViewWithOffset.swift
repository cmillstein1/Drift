//
//  ScrollViewWithOffset.swift
//  Drift
//
//  Wraps scroll content in a UIScrollView and reports contentOffset.y so header fade/parallax works reliably.
//  Content size is set from the hosting view's sizeThatFits (expanded height) to avoid the circular constraint
//  that would otherwise cap content height to the scroll view frame and cause "snap back" scrolling.
//

import SwiftUI
import UIKit

struct ScrollViewWithOffset<Content: View>: UIViewRepresentable {
    let content: Content
    @Binding var contentOffsetY: CGFloat
    var showsIndicators: Bool = false
    /// When true, disables automatic safe area content insets so the caller controls top spacing (avoids double top inset).
    var ignoresSafeAreaContentInset: Bool = false
    /// Background color of the scroll view (e.g. .white to avoid showing softGray through gaps).
    var scrollViewBackgroundColor: UIColor = .clear
    /// When set and true, scroll view scrolls to top and binding is set back to false (e.g. when switching segments).
    var scrollToTop: Binding<Bool>? = nil

    init(
        contentOffsetY: Binding<CGFloat>,
        showsIndicators: Bool = false,
        ignoresSafeAreaContentInset: Bool = false,
        scrollViewBackgroundColor: UIColor = .clear,
        scrollToTop: Binding<Bool>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self._contentOffsetY = contentOffsetY
        self.showsIndicators = showsIndicators
        self.ignoresSafeAreaContentInset = ignoresSafeAreaContentInset
        self.scrollViewBackgroundColor = scrollViewBackgroundColor
        self.scrollToTop = scrollToTop
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $contentOffsetY)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = showsIndicators
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = scrollViewBackgroundColor
        if ignoresSafeAreaContentInset {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.contentOffset = .zero

        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hosting.view)
        context.coordinator.hostingController = hosting

        let heightConstraint = hosting.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 1)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            heightConstraint,
        ])
        context.coordinator.scrollView = scrollView
        context.coordinator.contentHeightConstraint = heightConstraint
        DispatchQueue.main.async {
            context.coordinator.updateContentSize(scrollView: scrollView)
        }
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        context.coordinator.offsetBinding = $contentOffsetY
        let didScrollToTop = scrollToTop?.wrappedValue == true
        if let binding = scrollToTop, binding.wrappedValue {
            scrollView.setContentOffset(.zero, animated: false)
            // Defer state updates to avoid "Modifying state during view update".
            DispatchQueue.main.async {
                binding.wrappedValue = false
                self.contentOffsetY = 0
            }
        }
        DispatchQueue.main.async {
            context.coordinator.updateContentSize(scrollView: scrollView)
        }
        if didScrollToTop {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                context.coordinator.updateContentSize(scrollView: scrollView)
            }
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var offsetBinding: Binding<CGFloat>
        weak var scrollView: UIScrollView?
        var hostingController: UIHostingController<Content>?
        var contentHeightConstraint: NSLayoutConstraint?
        private var lastReportedOffsetY: CGFloat = -.infinity

        init(offset: Binding<CGFloat>) {
            self.offsetBinding = offset
        }

        private let maxContentHeight: CGFloat = 100_000

        func updateContentSize(scrollView: UIScrollView) {
            guard let hostingView = hostingController?.view else { return }
            let width = scrollView.bounds.width
            guard width > 0 else { return }
            let minScrollHeight = scrollView.bounds.height + 1
            contentHeightConstraint?.constant = maxContentHeight
            hostingView.setNeedsLayout()
            hostingView.layoutIfNeeded()
            let size = hostingView.sizeThatFits(CGSize(width: width, height: maxContentHeight))
            var contentHeight = size.height
            if contentHeight <= minScrollHeight || contentHeight.isInfinite || contentHeight.isNaN || contentHeight > maxContentHeight {
                contentHeight = maxContentHeight
            }
            scrollView.contentSize = CGSize(width: width, height: contentHeight)
            contentHeightConstraint?.constant = contentHeight
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let y = scrollView.contentOffset.y
            guard abs(y - lastReportedOffsetY) > 0.5 else { return }
            lastReportedOffsetY = y
            DispatchQueue.main.async { [weak self] in
                self?.offsetBinding.wrappedValue = y
            }
        }
    }
}
