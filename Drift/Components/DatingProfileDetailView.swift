//
//  DatingProfileDetailView.swift
//  Drift
//
//  Profile detail when opened from Dating: Discover card, Likes You, or Activity host.
//  Uses the shared ProfileDetailView layout with dating-specific options (Like/Pass or back-only).
//

import SwiftUI
import DriftBackend

/// Profile detail for Dating context: Discover, Likes You, Activity host.
/// Same layout as Friends and Message profile; only bottom bar and back button vary.
struct DatingProfileDetailView: View {
    let profile: UserProfile
    @Binding var isOpen: Bool
    let onLike: () -> Void
    let onPass: () -> Void
    /// Show back button (e.g. from Likes You, Activity, Messages list).
    var showBackButton: Bool = false
    /// Show Like and Pass buttons in bottom bar (e.g. Discover card, Likes You, pending friend request).
    var showLikeAndPassButtons: Bool = false
    /// Shown next to location as "X miles away" when set.
    var distanceMiles: Int? = nil

    var body: some View {
        ProfileDetailView(
            profile: profile,
            isOpen: $isOpen,
            onLike: onLike,
            onPass: onPass,
            showBackButton: showBackButton,
            showLikeAndPassButtons: showLikeAndPassButtons,
            distanceMiles: distanceMiles,
            detailMode: .dating
        )
    }
}
