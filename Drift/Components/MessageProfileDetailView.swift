//
//  MessageProfileDetailView.swift
//  Drift
//
//  Profile detail when opened from a message thread (tap profile picture).
//  Same layout as Dating and Friends; back button only, no bottom bar. Hides tab bar.
//

import SwiftUI
import DriftBackend

/// Profile detail when opened from a message. Back button only, no Like/Connect bar; hides tab bar.
struct MessageProfileDetailView: View {
    let profile: UserProfile
    @Binding var isOpen: Bool
    var body: some View {
        ProfileDetailView(
            profile: profile,
            isOpen: $isOpen,
            onLike: {},
            onPass: {},
            showBackButton: true,
            showLikeAndPassButtons: false
        )
    }
}
