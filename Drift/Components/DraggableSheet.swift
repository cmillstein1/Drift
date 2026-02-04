//
//  DraggableSheet.swift
//  Drift
//
//  UIKit pan gesture and scroll state for native-like draggable sheet behavior.
//  Pattern from SnapChef: 1:1 finger tracking via currentHeight = baseHeight - dragOffset.
//

import SwiftUI
import UIKit
import Combine

// MARK: - UIKit Pan Gesture Handler

struct DiscoverPanGestureView: UIViewRepresentable {
    let scrollState: DiscoverScrollState
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.scrollState = scrollState
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scrollState: scrollState, onChanged: onChanged, onEnded: onEnded)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var scrollState: DiscoverScrollState
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat) -> Void

        init(scrollState: DiscoverScrollState, onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat) -> Void) {
            self.scrollState = scrollState
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view).y

            switch gesture.state {
            case .began, .changed:
                onChanged(translation)

            case .ended, .cancelled:
                onEnded(translation)

            default:
                break
            }
        }

        /// Only begin gesture if dragging down AND at top, OR dragging up (to expand)
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }

            let velocity = panGesture.velocity(in: panGesture.view)
            let isDraggingDown = velocity.y > 0
            let isDraggingUp = velocity.y < 0
            let isAtTop = scrollState.isAtTop

            if isDraggingUp {
                return true
            } else if isDraggingDown {
                return isAtTop
            }

            return false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
    }
}

// MARK: - Scroll State (for sheet vs scroll coordination)

final class DiscoverScrollState: ObservableObject {
    @Published var isAtTop: Bool = true
}
