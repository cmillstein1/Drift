//
//  FriendsListContent.swift
//  Drift
//

import SwiftUI
import DriftBackend
import Auth

struct FriendsListContent: View {
    var filterPreferences: NearbyFriendsFilterPreferences = .default

    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var discoveryLocation = DiscoveryLocationProvider.shared
    @State private var isLoading = true
    @State private var swipedIds: [UUID] = []

    private var profiles: [UserProfile] {
        let raw = profileManager.discoverProfiles
        // Prefer device location for distance filter; fall back to profile's stored coords
        let lat = DiscoveryLocationProvider.shared.latitudeForFilter ?? profileManager.currentProfile?.latitude
        let lon = DiscoveryLocationProvider.shared.longitudeForFilter ?? profileManager.currentProfile?.longitude
        return raw.filter { filterPreferences.matches($0, currentUserInterests: currentUserInterests, currentUserLat: lat, currentUserLon: lon) }
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
                    // Empty state — Nobody_Nearby asset, campfire font, centered (like Messages empty state)
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)

                        VStack(spacing: 24) {
                            Image("Nobody_Nearby")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 280, maxHeight: 280)

                            VStack(spacing: 10) {
                                Text(filterPreferences.hasActiveFilters ? "No one matches your filters" : "No friends nearby")
                                    .font(.campfire(.regular, size: 24))
                                    .foregroundColor(DriftUI.charcoal)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                                Text(filterPreferences.hasActiveFilters ? "Try adjusting your filters" : "Check back later or expand your search radius")
                                    .font(.campfire(.regular, size: 16))
                                    .foregroundColor(DriftUI.charcoal.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 32)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 420)
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
            DiscoveryLocationProvider.shared.requestLocation()
            loadProfiles()
            Task {
                await FriendsManager.shared.subscribeToFriendRequests()
            }
        }
    }
}
