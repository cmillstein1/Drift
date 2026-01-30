//
//  FriendsListContent.swift
//  Drift
//

import SwiftUI
import DriftBackend
import Auth

struct FriendsListContent: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var isLoading = true
    @State private var swipedIds: [UUID] = []

    private var profiles: [UserProfile] {
        profileManager.discoverProfiles
    }

    private var currentUserInterests: [String] {
        supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
    }

    private func loadProfiles() {
        guard let currentUserId = supabaseManager.currentUser?.id else {
            isLoading = false
            return
        }
        isLoading = true
        Task {
            do {
                swipedIds = try await friendsManager.fetchSwipedUserIds()
                try await friendsManager.fetchSentRequests()
                try await friendsManager.fetchFriends()
                let friendIds = friendsManager.friends.map { friend in
                    friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId
                }
                let blockedIds = (try? await friendsManager.fetchBlockedExclusionUserIds()) ?? []
                let excludeIds = swipedIds + friendIds + blockedIds
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: .friends,
                    excludeIds: excludeIds
                )
            } catch {
                print("Failed to load friends profiles: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func getMutualInterests(for profile: UserProfile) -> [String] {
        Set(currentUserInterests).intersection(Set(profile.interests)).map { $0 }
    }

    private func handleConnect(profileId: UUID) {
        Task {
            do {
                try await friendsManager.sendFriendRequest(to: profileId)
            } catch {
                print("Failed to send friend request: \(error)")
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Finding friends nearby...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if profiles.isEmpty {
                    VStack(spacing: 8) {
                        Text("No friends nearby")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DriftUI.charcoal)

                        Text("Check back later or expand your search radius")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                } else {
                    ForEach(profiles) { profile in
                        NavigationLink(value: profile) {
                            FriendCard(
                                profile: profile,
                                mutualInterests: getMutualInterests(for: profile),
                                requestSent: friendsManager.hasSentRequest(to: profile.id),
                                onConnect: { profileId in
                                    handleConnect(profileId: profileId)
                                },
                                onTap: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarBottomPadding)
        }
        .onAppear {
            loadProfiles()
            Task {
                await FriendsManager.shared.subscribeToFriendRequests()
            }
        }
    }
}
