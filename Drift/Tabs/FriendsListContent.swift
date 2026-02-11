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
    /// When false, only the feed content is rendered (no ScrollView); parent embeds this in its own scroll (e.g. Discover single-scroll).
    var embedInScrollView: Bool = true
    /// When set and embedInScrollView true, scroll offset is reported so tab bar can hide/show.
    var contentOffsetY: Binding<CGFloat>? = nil

    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var discoveryLocation = DiscoveryLocationProvider.shared
    @State private var isLoading = true
    @State private var swipedIds: [UUID] = []

    /// Friends feed: only profiles looking for friends or both (client-side safeguard).
    private var profiles: [UserProfile] {
        let raw = profileManager.discoverProfilesFriends
            .filter { $0.lookingFor == .friends || $0.lookingFor == .both }
        let lat = DiscoveryLocationProvider.shared.latitudeForFilter ?? profileManager.currentProfile?.latitude
        let lon = DiscoveryLocationProvider.shared.longitudeForFilter ?? profileManager.currentProfile?.longitude
        return raw.filter { filterPreferences.matches($0, currentUserLat: lat, currentUserLon: lon, routeCoordinates: []) }
    }

    private var currentUserInterests: [String] {
        supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
    }

    private func loadProfiles(forceRefresh: Bool = false) {
        // Skip loading if data already cached (preloaded by DiscoverScreen)
        if !forceRefresh && !profileManager.discoverProfilesFriends.isEmpty {
            isLoading = false
            return
        }

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

    /// Use VStack when content is inside a UIScrollView (ScrollViewWithOffset) so the scroll view gets correct content height; use LazyVStack only inside SwiftUI ScrollView.
    private var useVStackForScroll: Bool {
        !embedInScrollView || contentOffsetY != nil
    }

    private var scrollContent: some View {
        Group {
            if useVStackForScroll {
                VStack(spacing: 22) {
                    scrollContentBody
                }
            } else {
                LazyVStack(spacing: 22) {
                    scrollContentBody
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, LayoutConstants.tabBarBottomPadding)
    }

    @ViewBuilder
    private var scrollContentBody: some View {
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

    var body: some View {
        Group {
            if !embedInScrollView {
                scrollContent
            } else if let binding = contentOffsetY {
                ScrollViewWithOffset(
                    contentOffsetY: binding,
                    showsIndicators: false,
                    ignoresSafeAreaContentInset: false,
                    scrollViewBackgroundColor: UIColor(named: "SoftGray") ?? UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
                ) {
                    scrollContent
                }
                .ignoresSafeArea(edges: [])
            } else {
                ScrollView(showsIndicators: false) {
                    scrollContent
                }
            }
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
