//
//  DiscoverScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import CoreLocation
import DriftBackend
import Auth


struct DiscoverScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var messagingManager = MessagingManager.shared
    @StateObject private var communityManager = CommunityManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @StateObject private var notificationsManager = NotificationsManager.shared

    @State private var showNotificationsSheet: Bool = false
    @State private var swipedIds: Set<UUID> = []
    @State private var likedFadingId: UUID? = nil
    @State private var currentIndex: Int = 0
    @State private var mode: DiscoverMode = .dating
    @State private var selectedProfile: UserProfile? = nil
    @State private var matchedProfile: UserProfile? = nil
    @State private var showLikePrompt: Bool = false
    @State private var likeMessage: String = ""
    @State private var swipeProgress: CGFloat = 0
    @State private var showFilters: Bool = false
    @State private var friendsFilterPreferences = NearbyFriendsFilterPreferences.fromStorage()
    @State private var routeCoordinates: [ReferenceCoordinate] = []
    @State private var showDatingSettings: Bool = false
    @State private var datingFilterPreferences = DatingFilterPreferences.fromStorage()
    @State private var showCreateEventSheet: Bool = false
    @State private var zoomedPhotoURL: String? = nil
    @State private var selectedFriendProfile: UserProfile? = nil
    @State private var selectedEvent: CommunityPost? = nil
    @State private var showSwipeLimitPaywall: Bool = false
    /// Current dating profile index for full-screen carousel view
    @State private var currentDatingProfileIndex: Int = 0
    /// Fade animation for profile transitions
    @State private var profileTransitionOpacity: Double = 1.0
    /// Scroll offset for tab bar hide/show (dating and unified .both).
    @State private var discoverScrollOffsetY: CGFloat = 0
    /// Previous scroll offset to detect scroll direction.
    @State private var lastDiscoverScrollOffsetY: CGFloat = 0
    /// Scroll offset for friends feed when discoveryMode == .friends only.
    @State private var friendsScrollOffsetY: CGFloat = 0
    /// Previous scroll offset for friends feed to detect scroll direction.
    @State private var lastFriendsScrollOffsetY: CGFloat = 0
    /// When true, unified ScrollViewWithOffset scrolls to top (when switching segments in .both).
    @State private var scrollToTopTrigger: Bool = false
    /// Cached blocked user IDs to avoid duplicate fetches across loadProfiles/preloadFriendsProfiles
    @State private var cachedBlockedIds: [UUID] = []
    @State private var lastExclusionFetch: Date = .distantPast
    /// True until the first profile fetch completes (prevents empty-state flash on launch)
    @State private var isInitialLoading: Bool = true
    /// Stamp overlay shown during swipe animation ("LIKE" or "NOPE")
    @State private var showLikeStamp: Bool = false
    @State private var showNopeStamp: Bool = false
    /// Last profile that was passed (X'd) in dating mode — enables undo/reverse
    @State private var lastPassedProfile: UserProfile? = nil
    /// Stamp overlay for undo animation
    @State private var showUndoStamp: Bool = false
    /// Paywall for undo (Drift Pro only)
    @State private var showUndoPaywall: Bool = false
    /// Task references for cancellation on disappear
    @State private var loadProfilesTask: Task<Void, Never>?
    @State private var preloadFriendsTask: Task<Void, Never>?
    @State private var recycleProfilesTask: Task<Void, Never>?
    /// Geocoded coordinates for profiles that have a location string but no lat/lon.
    @State private var geocodedProfileCoords: [UUID: CLLocationCoordinate2D] = [:]
    /// Cache by location string to avoid re-geocoding the same city.
    @State private var locationGeocodeCache: [String: CLLocationCoordinate2D] = [:]

    /// Top spacer so first card clears the overlay (safe area + mode switcher + subtitle + padding).
    private let topNavBarHeight: CGFloat = 120
    /// Scroll offset past which expanded header is fully gone and compact (name) header is shown
    private let headerCollapseThreshold: CGFloat = 72
    /// Height of compact header (safe area + title row)
    private let compactHeaderHeight: CGFloat = 44

    // Colors from HTML
    private let softGray = Color("SoftGray")
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37) // #FF5E5E
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50) // #6B7280
    private let tealPrimary = Color(red: 0.18, green: 0.83, blue: 0.75) // #2DD4BF
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96) // bg-gray-100
    private let gray700 = Color(red: 0.37, green: 0.37, blue: 0.42) // text-gray-700
    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoal = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let desertSand = Color("DesertSand")

    /// Dating feed: only profiles looking for dating or both (client-side safeguard).
    private var profiles: [UserProfile] {
        profileManager.discoverProfiles.filter { $0.lookingFor == .dating || $0.lookingFor == .both }
    }

    private var currentCard: UserProfile? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }

    /// Profiles still visible in the feed (not yet swiped), filtered by dating distance preference.
    private var visibleDatingProfiles: [UserProfile] {
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let userLat = coord?.latitude ?? profileManager.currentProfile?.latitude
        let userLon = coord?.longitude ?? profileManager.currentProfile?.longitude
        let unswiped = profiles.filter { !swipedIds.contains($0.id) }
        return unswiped.filter { datingFilterPreferences.matches($0, currentUserLat: userLat, currentUserLon: userLon, routeCoordinates: routeCoordinates) }
    }

    /// Current profile for full-screen dating view
    private var currentFullScreenProfile: UserProfile? {
        let visible = visibleDatingProfiles
        guard currentDatingProfileIndex < visible.count else { return nil }
        return visible[currentDatingProfileIndex]
    }

    /// Friends feed: only profiles looking for friends or both (client-side safeguard).
    /// Exclude current user so we never show our own profile in the grid (e.g. from cache).
    private var friendsProfiles: [UserProfile] {
        let currentId = profileManager.currentProfile?.id
        return profileManager.discoverProfilesFriends.filter {
            ($0.lookingFor == .friends || $0.lookingFor == .both) && $0.id != currentId
        }
    }

    /// Profiles still visible in the friends feed (not yet swiped/connected), filtered by distance preference.
    private var visibleFriendsProfiles: [UserProfile] {
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let userLat = coord?.latitude ?? profileManager.currentProfile?.latitude
        let userLon = coord?.longitude ?? profileManager.currentProfile?.longitude
        let unswiped = friendsProfiles.filter { !swipedIds.contains($0.id) }
        let result = unswiped.filter { friendsFilterPreferences.matches($0, currentUserLat: userLat, currentUserLon: userLon, routeCoordinates: routeCoordinates, geocodedCoords: geocodedProfileCoords) }
        if unswiped.count != result.count || result.isEmpty {
            print("[Friends Debug] visibleFriendsProfiles: friendsProfiles=\(friendsProfiles.count), unswiped=\(unswiped.count), afterFilter=\(result.count), routeCoords=\(routeCoordinates.count)")
        }
        return result
    }

    /// Events filtered by the same distance preferences as friends.
    private var visibleEvents: [CommunityPost] {
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let userLat = coord?.latitude ?? profileManager.currentProfile?.latitude
        let userLon = coord?.longitude ?? profileManager.currentProfile?.longitude
        return communityManager.posts
            .filter { $0.type == .event }
            .filter { friendsFilterPreferences.matchesEvent($0, currentUserLat: userLat, currentUserLon: userLon, routeCoordinates: routeCoordinates) }
    }

    /// Current profile for full-screen friends view
    private var currentFullScreenFriendsProfile: UserProfile? {
        let visible = visibleFriendsProfiles
        guard visible.count > 0 else { return nil }
        return visible[0]  // Always show first available
    }

    /// Distance in miles from current user to profile; nil if unknown.
    private func distanceMiles(for profile: UserProfile) -> Int? {
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let userLat = coord?.latitude ?? profileManager.currentProfile?.latitude
        let userLon = coord?.longitude ?? profileManager.currentProfile?.longitude
        return DistanceHelper.miles(from: userLat, userLon, to: profile.latitude, profile.longitude)
    }

    /// Loads coordinates from the user's travel stops for along-my-route filtering.
    private func loadRouteCoordinates() {
        Task {
            do {
                let stops = try await profileManager.fetchTravelSchedule()
                routeCoordinates = stops.compactMap { stop in
                    guard let lat = stop.latitude, let lon = stop.longitude else { return nil }
                    return ReferenceCoordinate(latitude: lat, longitude: lon)
                }
            } catch {
                #if DEBUG
                print("[DiscoverScreen] Failed to load route coordinates: \(error)")
                #endif
                routeCoordinates = []
            }
        }
    }

    private func loadProfiles() {
        loadProfiles(forMode: mode)
    }

    /// Fetches swiped and blocked IDs, using cache if fresh (< 30s).
    private func fetchExclusionIds() async throws -> (swiped: [UUID], blocked: [UUID]) {
        let swiped = try await friendsManager.fetchSwipedUserIds()
        let blocked: [UUID]
        if Date().timeIntervalSince(lastExclusionFetch) < 30 {
            blocked = cachedBlockedIds
        } else {
            blocked = try await friendsManager.fetchBlockedExclusionUserIds()
            cachedBlockedIds = blocked
            lastExclusionFetch = Date()
        }
        return (swiped, blocked)
    }

    /// Load profiles for a specific mode. Data is stored separately in ProfileManager so no race condition issues.
    private func loadProfiles(forMode targetMode: DiscoverMode) {
        // Use device location for distance filter when available (dating & friends)
        DiscoveryLocationProvider.shared.requestLocation()
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let lookingFor: LookingFor = targetMode == .dating ? .dating : .friends

        loadProfilesTask = Task {
            do {
                let (swiped, blocked) = try await fetchExclusionIds()
                // Always set swipedIds - it's shared across modes
                swipedIds = Set(swiped)
                let isAlongMyRoute = lookingFor == .friends ? friendsFilterPreferences.alongMyRoute : datingFilterPreferences.alongMyRoute
                let isUnlimited = lookingFor == .friends ? friendsFilterPreferences.isUnlimitedDistance : datingFilterPreferences.isUnlimitedDistance
                let maxDist = lookingFor == .friends ? friendsFilterPreferences.maxDistanceMiles : datingFilterPreferences.maxDistanceMiles
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: lookingFor,
                    excludeIds: Array(swipedIds) + blocked,
                    currentUserLat: coord?.latitude,
                    currentUserLon: coord?.longitude,
                    alongMyRoute: isAlongMyRoute,
                    unlimitedDistance: isUnlimited,
                    friendsMaxDistanceMiles: maxDist
                )
                // Reset index only if still on this mode
                if mode == targetMode {
                    currentIndex = 0
                }
                if lookingFor == .friends || lookingFor == .both {
                    await geocodeProfilesWithoutCoordinates()
                }
            } catch {
                print("Failed to load profiles: \(error)")
            }
            isInitialLoading = false
        }
    }

    private func recycleProfiles() {
        // Reset the current index to recycle through profiles again
        // Clear local swipedIds so we can see all profiles again
        swipedIds = Set()
        currentIndex = 0

        // Reload profiles without excluding any (use device location for distance when available)
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let targetMode = mode
        let lookingFor: LookingFor = targetMode == .dating ? .dating : .friends
        recycleProfilesTask = Task {
            do {
                guard mode == targetMode else { return }
                let isAlongMyRoute = lookingFor == .friends ? friendsFilterPreferences.alongMyRoute : datingFilterPreferences.alongMyRoute
                let isUnlimited = lookingFor == .friends ? friendsFilterPreferences.isUnlimitedDistance : datingFilterPreferences.isUnlimitedDistance
                let maxDist = lookingFor == .friends ? friendsFilterPreferences.maxDistanceMiles : datingFilterPreferences.maxDistanceMiles
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: lookingFor,
                    excludeIds: [],
                    currentUserLat: coord?.latitude,
                    currentUserLon: coord?.longitude,
                    alongMyRoute: isAlongMyRoute,
                    unlimitedDistance: isUnlimited,
                    friendsMaxDistanceMiles: maxDist
                )
            } catch {
                print("Failed to recycle profiles: \(error)")
            }
        }
    }

    /// Preload friends profiles in background for instant tab switching.
    private func preloadFriendsProfiles() {
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        preloadFriendsTask = Task {
            do {
                let (swiped, blocked) = try await fetchExclusionIds()
                guard let currentUserId = supabaseManager.currentUser?.id else { return }
                try await friendsManager.fetchSentRequests()
                try await friendsManager.fetchFriends()
                let friendIds = friendsManager.friends.map { friend in
                    friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId
                }
                let excludeIds = swiped + friendIds + blocked
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: .friends,
                    excludeIds: excludeIds,
                    currentUserLat: coord?.latitude,
                    currentUserLon: coord?.longitude,
                    alongMyRoute: friendsFilterPreferences.alongMyRoute,
                    unlimitedDistance: friendsFilterPreferences.isUnlimitedDistance,
                    friendsMaxDistanceMiles: friendsFilterPreferences.maxDistanceMiles
                )
            } catch {
                print("Failed to preload friends profiles: \(error)")
            }
            isInitialLoading = false
            await geocodeProfilesWithoutCoordinates()
        }
    }

    /// Geocode profiles that have a location string but no lat/lon so distance filtering works.
    private func geocodeProfilesWithoutCoordinates() async {
        let needGeocode = friendsProfiles.filter { p in
            p.latitude == nil && p.longitude == nil &&
            p.location != nil && !p.location!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !needGeocode.isEmpty else { return }
        let geocoder = CLGeocoder()
        for p in needGeocode {
            let locationString = p.location!.trimmingCharacters(in: .whitespacesAndNewlines)
            if let cached = locationGeocodeCache[locationString] {
                geocodedProfileCoords[p.id] = cached
                continue
            }
            guard let placemarks = try? await geocoder.geocodeAddressString(locationString),
                  let coord = placemarks.first?.location?.coordinate else { continue }
            locationGeocodeCache[locationString] = coord
            geocodedProfileCoords[p.id] = coord
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }

    /// Relative time string for last active (e.g. "2h ago", "1d ago").
    private func lastActiveString(for date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Mutual interests between current user and profile (for dating card).
    private func datingMutualInterests(for profile: UserProfile) -> [String] {
        let current = profileManager.currentProfile?.interests ?? []
        return Array(Set(current).intersection(Set(profile.interests)))
    }

    @ViewBuilder
    private func datingPromptSection(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(burntOrange)
            Text(answer)
                .font(.system(size: 16))
                .foregroundColor(charcoal)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(gray100),
            alignment: .bottom
        )
    }

    private func handleSwipe(direction: SwipeDirection) {
        guard let profile = currentCard else { return }
        handleSwipe(profile: profile, direction: direction)
    }

    /// Record swipe for a specific profile (used by card feed). Removes profile from feed and optionally shows match.
    private func handleSwipe(profile: UserProfile, direction: SwipeDirection) {
        let isLike = (direction == .right || direction == .up)

        // Check daily like limit for free users
        if isLike && !revenueCatManager.hasProAccess {
            friendsManager.resetDailyLikesIfNeeded()
            if friendsManager.hasReachedDailyLikeLimit {
                showSwipeLimitPaywall = true
                return
            }
        }

        if isLike {
            withAnimation(.easeOut(duration: 0.35)) {
                likedFadingId = profile.id
            }
        } else {
            swipedIds.insert(profile.id)
        }

        Task {
            do {
                let swipeDirection: DriftBackend.SwipeDirection
                switch direction {
                case .left: swipeDirection = .left
                case .right: swipeDirection = .right
                case .up: swipeDirection = .up
                }
                let match = try await friendsManager.swipe(on: profile.id, direction: swipeDirection)

                if isLike {
                    try await Task.sleep(nanoseconds: 350_000_000)
                    await MainActor.run {
                        swipedIds.insert(profile.id)
                        likedFadingId = nil
                        if let match = match {
                            matchedProfile = match.otherUserProfile
                        }
                        if visibleDatingProfiles.isEmpty {
                            loadProfiles()
                        }
                    }
                } else if let match = match {
                    await MainActor.run {
                        matchedProfile = match.otherUserProfile
                    }
                }
            } catch {
                if isLike {
                    await MainActor.run {
                        swipedIds.insert(profile.id)
                        likedFadingId = nil
                    }
                }
                print("❌ [DISCOVER] Failed to record swipe: \(error)")
            }
        }

        if !isLike && visibleDatingProfiles.isEmpty {
            loadProfiles()
        }
    }

    // Scale factor for X button
    private var xButtonScale: CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.1
        let progress = max(-swipeProgress, 0)
        return baseScale + (maxScale - baseScale) * progress
    }

    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            let discoveryMode = supabaseManager.getDiscoveryMode()

            if discoveryMode == .friends {
                friendsView.id("friends")
            } else if discoveryMode == .dating {
                datingView.id("dating")
            } else {
                unifiedDiscoverView
            }
        }
        .onAppear {
            print("[Friends Debug] DiscoverScreen.onAppear — filterPrefs: maxDist=\(friendsFilterPreferences.maxDistanceMiles), alongMyRoute=\(friendsFilterPreferences.alongMyRoute), unlimited=\(friendsFilterPreferences.isUnlimitedDistance)")
            // Load cached profiles from disk immediately to prevent empty-state flash
            profileManager.loadCachedDiscoverProfiles()

            #if DEBUG
            // Inject mock dating profiles for testing
            if profileManager.discoverProfiles.isEmpty {
                profileManager.discoverProfiles = Self.mockDatingProfiles
                isInitialLoading = false
            }
            #endif

            // Request device location for distance filtering (dating & friends)
            DiscoveryLocationProvider.shared.requestLocation()

            // When Messages "Find friends" requested Discover in friends mode, switch to it
            if tabBarVisibility.discoverStartInFriendsMode {
                mode = .friends
                tabBarVisibility.discoverStartInFriendsMode = false
            }
            let discoveryMode = supabaseManager.getDiscoveryMode()
            if discoveryMode == .both {
                // Default to Friends (travel community first) for App Store positioning
                mode = .friends
                // Preload both datasets for instant tab switching
                if profileManager.discoverProfiles.isEmpty {
                    loadProfiles(forMode: .dating)
                }
                if profileManager.discoverProfilesFriends.isEmpty {
                    preloadFriendsProfiles()
                }
            } else if discoveryMode == .dating {
                if profileManager.discoverProfiles.isEmpty {
                    loadProfiles(forMode: .dating)
                }
            } else if discoveryMode == .friends {
                // Friends-only mode - load friends profiles for community grid
                mode = .friends
                if profileManager.discoverProfilesFriends.isEmpty {
                    preloadFriendsProfiles()
                }
            }
            tabBarVisibility.isVisible = true

            // Load route coordinates if along-my-route is already enabled
            if friendsFilterPreferences.alongMyRoute {
                loadRouteCoordinates()
            }

            // Subscribe to real-time updates
            Task {
                await FriendsManager.shared.subscribeToMatches()
                await FriendsManager.shared.subscribeToFriendRequests()
            }

            // Load events for community grid
            Task { try? await communityManager.fetchPosts(type: .event) }
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
            loadProfilesTask?.cancel()
            preloadFriendsTask?.cancel()
            recycleProfilesTask?.cancel()
            Task {
                await FriendsManager.shared.unsubscribe()
            }
        }
        .onChange(of: mode) { _, newMode in
            // Reset profile transition opacity
            profileTransitionOpacity = 1.0
            // Clear reverse state when switching modes
            lastPassedProfile = nil

            // Keep tab bar visible in both modes
            tabBarVisibility.isVisible = true

            // Only reload if profiles for this mode are empty (preserve cached data when switching)
            if newMode == .dating && profileManager.discoverProfiles.isEmpty {
                loadProfiles(forMode: .dating)
            } else if newMode == .friends && profileManager.discoverProfilesFriends.isEmpty {
                loadProfiles(forMode: .friends)
            }
            DispatchQueue.main.async {
                discoverScrollOffsetY = 0
                scrollToTopTrigger = true
            }
        }
        .onChange(of: friendsFilterPreferences) { _, newPrefs in
            newPrefs.saveToStorage()
            if newPrefs.alongMyRoute {
                loadRouteCoordinates()
            } else {
                routeCoordinates = []
            }
            // Re-fetch friends profiles with updated along-my-route setting
            preloadFriendsProfiles()
        }
        .fullScreenCover(item: $matchedProfile) { profile in
            MatchAnimationView(
                matchedProfile: profile,
                currentUserAvatarUrl: profileManager.currentProfile?.primaryDisplayPhotoUrl,
                onSendMessage: { messageText in
                    matchedProfile = nil
                    // Send the message if not empty
                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Task {
                            do {
                                let conversation = try await MessagingManager.shared.fetchOrCreateConversation(
                                    with: profile.id,
                                    type: .dating
                                )
                                try await MessagingManager.shared.sendMessage(
                                    to: conversation.id,
                                    content: messageText
                                )
                            } catch {
                                print("Failed to send match message: \(error)")
                            }
                        }
                    }
                },
                onKeepSwiping: {
                    matchedProfile = nil
                }
            )
        }
        .fullScreenCover(item: $selectedProfile) { profile in
            DatingProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedProfile != nil },
                    set: { if !$0 { selectedProfile = nil } }
                ),
                onLike: {
                    handleSwipe(profile: profile, direction: .right)
                },
                onPass: {
                    handleSwipe(profile: profile, direction: .left)
                },
                showLikeAndPassButtons: true,
                distanceMiles: distanceMiles(for: profile)
            )
            .id(profile.id)
        }
        .fullScreenCover(item: $selectedFriendProfile) { profile in
            FriendsProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedFriendProfile != nil },
                    set: { if !$0 { selectedFriendProfile = nil } }
                ),
                distanceMiles: distanceMiles(for: profile),
                onConnect: {
                    handleConnect(profileId: profile.id)
                }
            )
            .id(profile.id)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(initialPost: event)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showDatingSettings) {
            DatingSettingsSheet(isPresented: $showDatingSettings)
        }
        .onChange(of: profileManager.datingPrefsVersion) { _, _ in
            // Dating preferences were saved — reload filter prefs and re-fetch profiles
            datingFilterPreferences = DatingFilterPreferences.fromStorage()
            loadProfilesTask?.cancel()
            profileManager.resetFetchGuard(for: .dating)
            currentDatingProfileIndex = 0
            currentIndex = 0
            profileManager.discoverProfiles = []
            loadProfiles(forMode: .dating)
        }
        .sheet(isPresented: $showFilters) {
            NearbyFriendsFilterSheet(
                isPresented: $showFilters,
                preferences: $friendsFilterPreferences
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreateEventSheet) {
            CreateCommunityPostSheet(restrictToPostType: .event)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSwipeLimitPaywall) {
            PaywallScreen(isOpen: $showSwipeLimitPaywall, source: .swipeLimit)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showUndoPaywall) {
            PaywallScreen(isOpen: $showUndoPaywall, source: .undo)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showNotificationsSheet, onDismiss: {
            Task {
                await notificationsManager.fetchNotifications()
            }
        }) {
            NotificationsScreen()
        }
    }

    /// Current user's location: profile city/state (lat/lon) first, then device location as fallback.
    /// Ensures the map can show people even when profile coords aren't saved yet (e.g. location text only).
    private var currentUserMapCoordinate: CLLocationCoordinate2D? {
        if let lat = profileManager.currentProfile?.latitude,
           let lon = profileManager.currentProfile?.longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return DiscoveryLocationProvider.shared.lastCoordinate
    }

    // MARK: - Unified Discover (when discoveryMode == .both)
    @ViewBuilder
    private var unifiedDiscoverView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Show the appropriate pane based on mode (smooth crossfade)
            ZStack {
                if mode == .friends {
                    unifiedFriendsPane
                        .transition(.opacity)
                } else {
                    unifiedDatingPane
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.28), value: mode)

            // Single overlay: mode switcher + top-right button (Community: create event +; Dating: compass map)
            // Match Messages tab: ~10pt below safe area (safe area top ~59 + 10) and light segment design
            VStack {
                HStack {
                    modeSwitcher(style: .light)
                    Spacer()
                    if mode == .friends {
                        discoverNotificationsButton
                        discoverCreateEventButton
                    } else {
                        if lastPassedProfile != nil {
                            Button {
                                reverseLastPass()
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                        unifiedDiscoverMapButton
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lastPassedProfile != nil)
                .animation(.easeInOut(duration: 0.25), value: mode)
                .padding(.horizontal, 24)
                .padding(.top, 70)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [softGray, softGray.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )
                Spacer()
            }
            .opacity(unifiedOverlayVisible ? 1 : 0)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var unifiedOverlayVisible: Bool {
        // Always show overlay in friends mode so filter/notifications/create-event stay accessible on empty state
        return mode == .friends || (mode == .dating && !visibleDatingProfiles.isEmpty)
    }

    /// Bell button for notifications. Same style as CommunityScreen.
    private var discoverNotificationsButton: some View {
        Button {
            showNotificationsSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(charcoal)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)

                if notificationsManager.unreadCount > 0 {
                    Circle()
                        .fill(burntOrange)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// "+" button for creating a new event (Community tab only). Same style as CommunityScreen; no Help option.
    private var discoverCreateEventButton: some View {
        Button {
            showCreateEventSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(charcoal)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var unifiedDiscoverMapButton: some View {
        if mode == .dating {
            NavigationLink {
                DiscoverMapSheet(
                    profiles: profiles,
                    currentUserCoordinate: currentUserMapCoordinate,
                    hideCurrentUserLocation: profileManager.currentProfile?.hideLocationOnMap ?? false,
                    isPushed: true,
                    onSelectProfile: { selectedProfile = $0 },
                    distanceMiles: distanceMiles(for:)
                )
            } label: { discoverMapButtonLabel }
        } else {
            NavigationLink {
                DiscoverMapSheet(
                    profiles: profileManager.discoverProfilesFriends,
                    currentUserCoordinate: currentUserMapCoordinate,
                    hideCurrentUserLocation: profileManager.currentProfile?.hideLocationOnMap ?? false,
                    isPushed: true,
                    onSelectProfile: { selectedFriendProfile = $0 },
                    distanceMiles: distanceMiles(for:)
                )
            } label: { discoverMapButtonLabel }
        }
    }

    private var discoverMapButtonLabel: some View {
        Image(systemName: "safari")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.gray)
            .frame(width: 40, height: 40)
            .glassEffect()
            .clipShape(Circle())
    }

    @ViewBuilder
    private var unifiedDatingPane: some View {
        if isInitialLoading && visibleDatingProfiles.isEmpty {
            ZStack {
                softGray.ignoresSafeArea()
                VanProgressView(size: 50)
            }
        } else if visibleDatingProfiles.isEmpty {
            ZStack {
                emptyState
                swipeStampOverlay
            }
        } else if let profile = currentFullScreenProfile {
            ZStack {
                DiscoverFullScreenProfileView(
                    profile: profile,
                    mode: .dating,
                    distanceMiles: distanceMiles(for: profile),
                    lastActiveAt: profile.lastActiveAt,
                    onLike: { handleFullScreenSwipe(profile: profile, direction: .right) },
                    onPass: { handleFullScreenSwipe(profile: profile, direction: .left) },
                    onBlockComplete: { loadProfiles() }
                )
                .id(profile.id)
                .opacity(profileTransitionOpacity)

                // Swipe stamp overlays
                swipeStampOverlay
            }
        }
    }

    @ViewBuilder
    private var unifiedFriendsPane: some View {
        CommunityGridView(
            profiles: visibleFriendsProfiles,
            events: visibleEvents,
            distanceMiles: distanceMiles(for:),
            sharedInterests: sharedInterestsForGrid,
            isLoading: isInitialLoading,
            spinnerTopOffset: 100,
            onRefresh: {
                try? await communityManager.fetchPosts(type: .event)
                preloadFriendsProfiles()
            },
            onSelectProfile: { selectedFriendProfile = $0 },
            onSelectEvent: { selectedEvent = $0 },
            onConnect: { handleConnect(profileId: $0) }
        )
    }

    private var unifiedDatingFeedContent: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topNavBarHeight)
            VStack(spacing: 22) {
                ForEach(visibleDatingProfiles) { profile in
                    DiscoverCard(
                        profile: profile,
                        mode: .dating,
                        lastActiveAt: profile.lastActiveAt,
                        distanceMiles: distanceMiles(for: profile),
                        onPrimaryAction: { handleSwipe(profile: profile, direction: .right) },
                        onPass: { handleSwipe(profile: profile, direction: .left) },
                        onViewProfile: { selectedProfile = profile },
                        onBlockComplete: { loadProfiles() }
                    )
                    .opacity(likedFadingId == profile.id ? 0 : 1)
                    .animation(.easeOut(duration: 0.35), value: likedFadingId)
                }
                DiscoverEndOfFeedView()
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Dating View (Full-screen carousel) — used when discoveryMode == .dating only
    @ViewBuilder
    private var datingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isInitialLoading && visibleDatingProfiles.isEmpty {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VanProgressView(size: 50)
                }
            } else if visibleDatingProfiles.isEmpty {
                ZStack {
                    emptyState
                    swipeStampOverlay
                }
            } else if let profile = currentFullScreenProfile {
                ZStack {
                    DiscoverFullScreenProfileView(
                        profile: profile,
                        mode: .dating,
                        distanceMiles: distanceMiles(for: profile),
                        lastActiveAt: profile.lastActiveAt,
                        onLike: { handleFullScreenSwipe(profile: profile, direction: .right) },
                        onPass: { handleFullScreenSwipe(profile: profile, direction: .left) },
                        onBlockComplete: { loadProfiles() }
                    )
                    .id(profile.id)
                    .opacity(profileTransitionOpacity)

                    // Swipe stamp overlays
                    swipeStampOverlay
                }
            }

            // Top overlay: reverse button + map button
            VStack {
                HStack {
                    Spacer()
                    if lastPassedProfile != nil {
                        Button {
                            reverseLastPass()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    NavigationLink {
                        DiscoverMapSheet(
                            profiles: profiles,
                            currentUserCoordinate: currentUserMapCoordinate,
                            hideCurrentUserLocation: profileManager.currentProfile?.hideLocationOnMap ?? false,
                            isPushed: true,
                            onSelectProfile: { selectedProfile = $0 },
                            distanceMiles: distanceMiles(for:)
                        )
                    } label: {
                        Image(systemName: "safari")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lastPassedProfile != nil)
                .padding(.horizontal, 16)
                .padding(.top, 60)
                Spacer()
            }
            .opacity(visibleDatingProfiles.isEmpty ? 0 : 1)
        }
        .ignoresSafeArea(edges: .top)
    }

    /// Handle swipe for full-screen profile view and advance to next profile
    private func handleFullScreenSwipe(profile: UserProfile, direction: SwipeDirection) {
        let isLike = (direction == .right || direction == .up)

        // Check daily like limit for free users
        if isLike && !revenueCatManager.hasProAccess {
            friendsManager.resetDailyLikesIfNeeded()
            if friendsManager.hasReachedDailyLikeLimit {
                showSwipeLimitPaywall = true
                return
            }
        }

        // 1. Show stamp overlay
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if isLike {
                showLikeStamp = true
            } else {
                showNopeStamp = true
            }
        }

        // 2. Fade out current profile
        withAnimation(.easeOut(duration: 0.25).delay(0.15)) {
            profileTransitionOpacity = 0
        }

        // 3. After fade out, swap to next profile and fade in
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            showLikeStamp = false
            showNopeStamp = false
            // Track last passed profile for undo (only for passes, not likes)
            if !isLike {
                lastPassedProfile = profile
            } else {
                lastPassedProfile = nil
            }
            swipedIds.insert(profile.id)
            profileTransitionOpacity = 0

            // Fade in next profile
            withAnimation(.easeIn(duration: 0.3)) {
                profileTransitionOpacity = 1
            }

            if visibleDatingProfiles.count <= 1 {
                loadProfiles()
            }
        }

        // 4. Record swipe on backend (fire-and-forget)
        Task {
            do {
                let swipeDirection: DriftBackend.SwipeDirection
                switch direction {
                case .left: swipeDirection = .left
                case .right: swipeDirection = .right
                case .up: swipeDirection = .up
                }
                let match = try await friendsManager.swipe(on: profile.id, direction: swipeDirection)

                await MainActor.run {
                    if let match = match {
                        matchedProfile = match.otherUserProfile
                    }
                    if visibleDatingProfiles.isEmpty {
                        loadProfiles()
                    }
                }
            } catch {
                print("[DISCOVER] Failed to record swipe: \(error)")
            }
        }
    }

    /// Reverse the last pass (undo the X) — Drift Pro only. Removes from local swipedIds and deletes backend swipe record.
    private func reverseLastPass() {
        guard let profile = lastPassedProfile else { return }

        // Gate behind Drift Pro
        if !revenueCatManager.hasProAccess {
            showUndoPaywall = true
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 1. Show undo stamp
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            showUndoStamp = true
        }

        // 2. Fade out current profile
        withAnimation(.easeOut(duration: 0.25).delay(0.15)) {
            profileTransitionOpacity = 0
        }

        // 3. After animation, swap back to the reversed profile
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            showUndoStamp = false
            // Remove the passed profile from swipedIds so it reappears
            swipedIds.remove(profile.id)
            lastPassedProfile = nil
            profileTransitionOpacity = 0

            // Fade in the restored profile
            withAnimation(.easeIn(duration: 0.3)) {
                profileTransitionOpacity = 1
            }
        }

        // Delete the swipe record from backend
        Task {
            do {
                try await friendsManager.deleteSwipe(on: profile.id)
            } catch {
                print("[DISCOVER] Failed to delete swipe for reverse: \(error)")
            }
        }
    }

    /// Handle connect for full-screen friends view
    private func handleFullScreenFriendsConnect(profile: UserProfile) {
        // Advance to next profile immediately (no black screen)
        swipedIds.insert(profile.id)
        profileTransitionOpacity = 1

        Task {
            do {
                try await friendsManager.sendFriendRequest(to: profile.id)
                await MainActor.run {
                    if visibleFriendsProfiles.isEmpty {
                        loadProfiles(forMode: .friends)
                    }
                }
            } catch {
                print("[DISCOVER] Failed to send friend request: \(error)")
            }
        }

        if visibleFriendsProfiles.count <= 1 {
            loadProfiles(forMode: .friends)
        }
    }

    /// Handle pass for full-screen friends view
    private func handleFullScreenFriendsPass(profile: UserProfile) {
        // Advance to next profile immediately (no black screen)
        swipedIds.insert(profile.id)
        profileTransitionOpacity = 1

        if visibleFriendsProfiles.isEmpty {
            loadProfiles(forMode: .friends)
        }
        if visibleFriendsProfiles.count <= 1 {
            loadProfiles(forMode: .friends)
        }
    }

    // Placeholder gradient for missing images
    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Simple wrapping HStack for tags
    struct WrappingHStack: Layout {
        var alignment: HorizontalAlignment = .leading
        var horizontalSpacing: CGFloat = 8
        var verticalSpacing: CGFloat = 8

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let containerWidth = proposal.width ?? .infinity
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > containerWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }

            return CGSize(width: containerWidth, height: currentY + lineHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var currentX: CGFloat = bounds.minX
            var currentY: CGFloat = bounds.minY
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                    currentX = bounds.minX
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }
        }
    }

    // MARK: - Unified Mode Switcher with Sliding Animation
    @ViewBuilder
    private func modeSwitcher(style: ModeSwitcherStyle) -> some View {
        DiscoverModeSwitcher(mode: $mode, style: style)
    }
    
    enum ModeSwitcherStyle {
        case dark   // For use on dark/image backgrounds
        case light  // For use on light backgrounds
    }

    // MARK: - Dating Filter Button
    @ViewBuilder
    private var datingFilterButton: some View {
        Button {
            showFilters = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial.opacity(0.5))
                .background(Color.black.opacity(0.2))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Swipe Stamp Overlay

    @ViewBuilder
    private var swipeStampOverlay: some View {
        ZStack {
            if showLikeStamp {
                Text("LIKE")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [burntOrange, sunsetRose],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [burntOrange, sunsetRose],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .rotationEffect(.degrees(-15))
                    .opacity(showLikeStamp ? 1 : 0)
                    .scaleEffect(showLikeStamp ? 1 : 0.5)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
            if showNopeStamp {
                Text("KEEP DRIFTIN'")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(charcoal.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(charcoal.opacity(0.85), lineWidth: 4)
                    )
                    .rotationEffect(.degrees(15))
                    .opacity(showNopeStamp ? 1 : 0)
                    .scaleEffect(showNopeStamp ? 1 : 0.5)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
            if showUndoStamp {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 32, weight: .heavy))
                    Text("UNDO")
                        .font(.system(size: 44, weight: .heavy))
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                .rotationEffect(.degrees(-10))
                .opacity(showUndoStamp ? 1 : 0)
                .scaleEffect(showUndoStamp ? 1 : 0.5)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Empty State (End of feed: compass + "You're all caught up!")
    @ViewBuilder
    private var emptyState: some View {
        let discoveryMode = supabaseManager.getDiscoveryMode()

        ZStack {
            VStack(spacing: 0) {
                // Mode switcher at top — match Messages tab (safe area + 10pt)
                if discoveryMode == .both {
                    HStack {
                        modeSwitcher(style: .light)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 70)
                    .padding(.bottom, 20)

                    // Subtitle under segment (dating)
                    Text("Stories from travelers looking to date")
                        .font(.system(size: 12))
                        .foregroundColor(inkSub)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }

                Spacer()

                DiscoverEndOfFeedView()

                // Reverse button below the end-of-feed view
                if lastPassedProfile != nil {
                    Button {
                        reverseLastPass()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Go back")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(charcoal)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, 20)
                }

                Spacer()
            }
            .padding(.bottom, tabBarVisibility.isVisible ? LayoutConstants.tabBarBottomPadding : 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(softGray)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lastPassedProfile != nil)
    }

    // MARK: - Friends View (Community grid) — used when discoveryMode == .friends only
    @ViewBuilder
    private var friendsView: some View {
        ZStack {
            softGray.ignoresSafeArea()

            // Community grid view (same as unifiedFriendsPane but without mode switcher)
            CommunityGridView(
                profiles: visibleFriendsProfiles,
                events: visibleEvents,
                distanceMiles: distanceMiles(for:),
                sharedInterests: sharedInterestsForGrid,
                topSpacing: 60, // Smaller top spacing since no mode switcher in friends-only mode
                isLoading: isInitialLoading,
                onRefresh: {
                    try? await communityManager.fetchPosts(type: .event)
                    preloadFriendsProfiles()
                },
                onSelectProfile: { selectedFriendProfile = $0 },
                onSelectEvent: { selectedEvent = $0 },
                onConnect: { handleConnect(profileId: $0) }
            )

            // Top overlay: notifications + create event buttons (no mode switcher for friends-only mode)
            VStack {
                HStack {
                    Spacer()
                    discoverNotificationsButton
                    discoverCreateEventButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [softGray, softGray.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )
                Spacer()
            }
        }
        .fullScreenCover(item: $selectedFriendProfile) { profile in
            FriendsProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedFriendProfile != nil },
                    set: { if !$0 { selectedFriendProfile = nil } }
                ),
                distanceMiles: distanceMiles(for: profile),
                onConnect: {
                    Task {
                        try? await friendsManager.sendFriendRequest(to: profile.id)
                    }
                }
            )
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(initialPost: event)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    private func getMutualInterests(for profile: UserProfile) -> [String] {
        let currentUserInterests = supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
        return Set(currentUserInterests).intersection(Set(profile.interests)).map { $0 }
    }

    /// When current user has interests loaded, returns shared interest names for each profile so cards show 1–2 shared interest segments. When nil, cards show profile.interests.
    private var sharedInterestsForGrid: ((UserProfile) -> [String])? {
        let current = profileManager.currentProfile?.interests ?? []
        guard !current.isEmpty else { return nil }
        return { self.getMutualInterests(for: $0) }
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


    // MARK: - Dating Settings Button
    @ViewBuilder
    private var datingSettingsButton: some View {
        Button {
            showDatingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundColor(charcoal)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Friends Filter Button
    @ViewBuilder
    private var friendsFilterButton: some View {
        Button {
            showFilters = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundColor(charcoal)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mock Dating Profiles (DEBUG only)
    #if DEBUG
    private static let mockDatingProfiles: [UserProfile] = [
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Sarah",
            age: 27,
            bio: "Full-time van lifer chasing sunsets along the Pacific Coast. Photographer by trade, adventurer by heart.",
            photos: [
                "https://picsum.photos/seed/sarah1/600/900",
                "https://picsum.photos/seed/sarah2/600/900",
                "https://picsum.photos/seed/sarah3/600/900"
            ],
            location: "Big Sur, CA",
            verified: true,
            lifestyle: .vanLife,
            travelPace: .moderate,
            nextDestination: "Portland, OR",
            interests: ["Photography", "Hiking", "Surf", "Coffee"],
            lookingFor: .dating,
            promptAnswers: [
                DriftBackend.PromptAnswer(prompt: "A simple pleasure I enjoy", answer: "Morning coffee with a mountain view from the van door."),
                DriftBackend.PromptAnswer(prompt: "Dating on the road looks like", answer: "Sharing a campfire, cooking dinner together, and stargazing.")
            ]
        ),
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Maya",
            age: 30,
            bio: "Digital nomad and yoga teacher. Currently parked near Joshua Tree. Always looking for new trails and good conversation.",
            photos: [
                "https://picsum.photos/seed/maya1/600/900",
                "https://picsum.photos/seed/maya2/600/900"
            ],
            location: "Joshua Tree, CA",
            lifestyle: .digitalNomad,
            travelPace: .slow,
            nextDestination: "Sedona, AZ",
            interests: ["Yoga", "Rock Climbing", "Reading", "Van Life"],
            lookingFor: .dating,
            promptAnswers: [
                DriftBackend.PromptAnswer(prompt: "My ideal weekend", answer: "A sunrise hike followed by a lazy afternoon reading in the hammock.")
            ],
            workStyle: .remote
        ),
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Jordan",
            age: 25,
            bio: "RV life with my golden retriever. I build websites by day and build campfires by night.",
            photos: [
                "https://picsum.photos/seed/jordan1/600/900",
                "https://picsum.photos/seed/jordan2/600/900",
                "https://picsum.photos/seed/jordan3/600/900",
                "https://picsum.photos/seed/jordan4/600/900"
            ],
            location: "Moab, UT",
            verified: true,
            lifestyle: .rvLife,
            travelPace: .fast,
            interests: ["Mountain Biking", "Photography", "Dogs", "Remote Work"],
            lookingFor: .both,
            rigInfo: "2022 Airstream Basecamp",
            promptAnswers: [
                DriftBackend.PromptAnswer(prompt: "A simple pleasure I enjoy", answer: "My dog's excitement every time we pull into a new campground."),
                DriftBackend.PromptAnswer(prompt: "The way to my heart is", answer: "Good trail beta and homemade guacamole.")
            ],
            workStyle: .remote,
            morningPerson: true
        ),
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Elena",
            age: 29,
            bio: "Former city girl turned full-time traveler. Trading my apartment for an Airstream was the best decision I ever made.",
            photos: [
                "https://picsum.photos/seed/elena1/600/900",
                "https://picsum.photos/seed/elena2/600/900"
            ],
            location: "Bend, OR",
            lifestyle: .vanLife,
            travelPace: .moderate,
            nextDestination: "Glacier National Park",
            interests: ["Skiing", "Cooking", "Stargazing", "Hiking"],
            lookingFor: .dating,
            promptAnswers: [
                DriftBackend.PromptAnswer(prompt: "Dating on the road looks like", answer: "Exploring farmers markets and cooking a meal together with whatever we find.")
            ],
            homeBase: "Denver, CO"
        ),
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Alex",
            age: 32,
            bio: "Slow-traveling through the Southwest in a converted Sprinter. Writer, climber, desert lover.",
            photos: [
                "https://picsum.photos/seed/alex1/600/900"
            ],
            location: "Flagstaff, AZ",
            lifestyle: .vanLife,
            travelPace: .slow,
            interests: ["Writing", "Rock Climbing", "Desert", "Minimalism"],
            lookingFor: .dating,
            promptAnswers: [
                DriftBackend.PromptAnswer(prompt: "A simple pleasure I enjoy", answer: "Watching thunderstorms roll across the desert from the comfort of my van.")
            ],
            workStyle: .remote,
            morningPerson: false
        ),
    ]
    #endif
}

// MARK: - Interest Item
private struct DiscoverInterestItem: Identifiable {
    let id: String
    let name: String

    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

#Preview {
    DiscoverScreen()
}
