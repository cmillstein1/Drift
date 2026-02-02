//
//  FriendsListContent.swift
//  Drift
//

import SwiftUI
import DriftBackend
import Auth

struct FriendsListContent: View {
    var filterPreferences: NearbyFriendsFilterPreferences = .default
    /// Called when user taps "View Profile" on a card; use to push the profile (e.g. path.append(profile)).
    var onViewProfile: ((UserProfile) -> Void)? = nil

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

    private func distanceMiles(for profile: UserProfile) -> Int? {
        let lat = DiscoveryLocationProvider.shared.latitudeForFilter ?? profileManager.currentProfile?.latitude
        let lon = DiscoveryLocationProvider.shared.longitudeForFilter ?? profileManager.currentProfile?.longitude
        return DistanceHelper.miles(from: lat, lon, to: profile.latitude, profile.longitude)
    }

    private var scrollContent: some View {
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
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    DiscoverEndOfFeedView()
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 420)
            } else {
                ForEach(profiles) { profile in
                    DiscoverCard(
                        profile: profile,
                        mode: .friends,
                        lastActiveAt: profile.lastActiveAt,
                        distanceMiles: distanceMiles(for: profile),
                        onPrimaryAction: { handleConnect(profileId: profile.id) },
                        onViewProfile: { onViewProfile?(profile) },
                        onBlockComplete: { loadProfiles() }
                    )
                }
                DiscoverEndOfFeedView()
                    .padding(.top, 24)
                    .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, LayoutConstants.tabBarBottomPadding)
    }

    var body: some View {
        ScrollView {
            scrollContent
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
