//
//  ScrollViewWithOffset.swift
//  Drift
//
//  Wraps scroll content in a UIScrollView and reports contentOffset.y so header fade/parallax works reliably.
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

    init(
        contentOffsetY: Binding<CGFloat>,
        showsIndicators: Bool = false,
        ignoresSafeAreaContentInset: Bool = false,
        scrollViewBackgroundColor: UIColor = .clear,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self._contentOffsetY = contentOffsetY
        self.showsIndicators = showsIndicators
        self.ignoresSafeAreaContentInset = ignoresSafeAreaContentInset
        self.scrollViewBackgroundColor = scrollViewBackgroundColor
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

        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hosting.view)
        context.coordinator.hostingController = hosting

        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        context.coordinator.offsetBinding = $contentOffsetY
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var offsetBinding: Binding<CGFloat>
        weak var scrollView: UIScrollView?
        var hostingController: UIHostingController<Content>?

        init(offset: Binding<CGFloat>) {
            self.offsetBinding = offset
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let y = scrollView.contentOffset.y
            DispatchQueue.main.async { [weak self] in
                self?.offsetBinding.wrappedValue = y
            }
        }
    }
}
