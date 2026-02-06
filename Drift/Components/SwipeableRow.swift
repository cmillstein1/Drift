//
//  SwipeableRow.swift
//  Drift
//

import SwiftUI

/// A container that adds swipe-to-reveal action buttons to any content.
/// Use this instead of `.swipeActions` when the content lives inside a
/// `LazyVStack` / `ScrollView` rather than a `List`.
struct SwipeableRow<Content: View>: View {
    let content: Content
    let actions: [SwipeAction]

    @State private var offset: CGFloat = 0

    private let buttonWidth: CGFloat = 72
    private var totalReveal: CGFloat { CGFloat(actions.count) * buttonWidth }
    private var isOpen: Bool { offset < -1 }

    init(actions: [SwipeAction], @ViewBuilder content: () -> Content) {
        self.actions = actions
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons revealed behind the content
            HStack(spacing: 0) {
                ForEach(actions.indices, id: \.self) { idx in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
                        actions[idx].action()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: actions[idx].icon)
                                .font(.system(size: 16, weight: .semibold))
                            Text(actions[idx].label)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: buttonWidth)
                        .frame(maxHeight: .infinity)
                    }
                    .background(actions[idx].tint)
                }
            }
            .frame(width: totalReveal)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Main content, draggable
            content
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let proposed = value.translation.width
                            if proposed < 0 {
                                offset = max(proposed, -totalReveal * 1.2)
                            } else if isOpen {
                                offset = min(0, -totalReveal + proposed)
                            }
                        }
                        .onEnded { value in
                            let threshold = totalReveal * 0.4
                            withAnimation(.easeOut(duration: 0.2)) {
                                if -value.translation.width > threshold || -value.predictedEndTranslation.width > threshold {
                                    offset = -totalReveal
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
                // When swiped open, overlay an invisible tap catcher to close
                .overlay {
                    if isOpen {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = 0
                                }
                            }
                    }
                }
        }
    }
}

struct SwipeAction {
    let label: String
    let icon: String
    let tint: Color
    let action: () -> Void
}
