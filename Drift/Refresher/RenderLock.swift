import SwiftUI

// Inline RenderLock (from gh123man/SwiftUI-RenderLock)
// Prevents unnecessary view re-evaluation during refresh

struct RenderLocked<Content: View>: View, Equatable {
    @Binding var isLocked: Bool
    let content: Content

    static func == (lhs: RenderLocked, rhs: RenderLocked) -> Bool {
        // When locked, report equal to prevent re-render
        return lhs.isLocked && rhs.isLocked
    }

    var body: some View {
        content
    }
}

extension View {
    func renderLocked(with binding: Binding<Bool>) -> some View {
        RenderLocked(isLocked: binding, content: self).equatable()
    }
}
