//
//  FriendsProfileDetailView.swift
//  Drift
//
//  Profile detail when opened from Friends: Discover friend card (Connect) or My Friends sheet (Accept/Decline).
//  Uses the shared ProfileDetailView layout with friends-specific options.
//

import SwiftUI
import DriftBackend

/// Profile detail for Friends context: Discover friend card with Connect, or My Friends with Accept/Decline.
/// Same layout as Dating and Message profile; bottom bar shows Connect or Like/Pass for pending requests.
struct FriendsProfileDetailView: View {
    let profile: UserProfile
    @Binding var isOpen: Bool
    /// Shown next to location as "X miles away" when set.
    var distanceMiles: Int? = nil
    /// When set, show Connect button (Discover friend card). When nil, show Like/Pass for pending request.
    var onConnect: (() -> Void)? = nil
    /// Accept callback when viewing a pending friend request (My Friends sheet). Used with onDecline.
    var onAccept: (() -> Void)? = nil
    /// Decline callback when viewing a pending friend request (My Friends sheet). Used with onAccept.
    var onDecline: (() -> Void)? = nil

    private var isPendingRequest: Bool {
        onAccept != nil || onDecline != nil
    }

    var body: some View {
        ProfileDetailView(
            profile: profile,
            isOpen: $isOpen,
            onLike: onAccept ?? {},
            onPass: onDecline ?? {},
            showBackButton: isPendingRequest,
            showLikeAndPassButtons: isPendingRequest,
            distanceMiles: distanceMiles,
            detailMode: onConnect != nil ? .friends : .dating,
            onConnect: onConnect
        )
    }
}
