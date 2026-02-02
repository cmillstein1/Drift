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
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var swipedIds: [UUID] = []
    @State private var likedFadingId: UUID? = nil
    @State private var currentIndex: Int = 0
    @State private var mode: DiscoverMode = .dating
    @State private var selectedProfile: UserProfile? = nil
    @State private var matchedProfile: UserProfile? = nil
    @State private var showLikePrompt: Bool = false
    @State private var likeMessage: String = ""
    @State private var swipeProgress: CGFloat = 0
    @State private var showFilters: Bool = false
    @State private var friendsFilterPreferences = NearbyFriendsFilterPreferences.default
    @State private var showDatingSettings: Bool = false
    @State private var zoomedPhotoURL: String? = nil
    @State private var friendsNavigationPath = NavigationPath()
    @State private var selectedFriendProfile: UserProfile? = nil

    /// Top spacer so first card clears the overlay (safe area + mode switcher + subtitle + padding).
    private let topNavBarHeight: CGFloat = 168
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

    private var profiles: [UserProfile] {
        profileManager.discoverProfiles
    }

    private var currentCard: UserProfile? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }

    /// Profiles still visible in the feed (not yet swiped). Used for card feed.
    private var visibleDatingProfiles: [UserProfile] {
        profiles.filter { !swipedIds.contains($0.id) }
    }

    /// Distance in miles from current user to profile; nil if unknown.
    private func distanceMiles(for profile: UserProfile) -> Int? {
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        let userLat = coord?.latitude ?? profileManager.currentProfile?.latitude
        let userLon = coord?.longitude ?? profileManager.currentProfile?.longitude
        return DistanceHelper.miles(from: userLat, userLon, to: profile.latitude, profile.longitude)
    }

    private func loadProfiles() {
        // Use device location for distance filter when available (dating & friends)
        DiscoveryLocationProvider.shared.requestLocation()
        let coord = DiscoveryLocationProvider.shared.lastCoordinate

        Task {
            do {
                let (swiped, blocked) = try await (
                    friendsManager.fetchSwipedUserIds(),
                    friendsManager.fetchBlockedExclusionUserIds()
                )
                swipedIds = swiped
                let lookingFor: LookingFor = mode == .dating ? .dating : .friends
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: lookingFor,
                    excludeIds: swipedIds + blocked,
                    currentUserLat: coord?.latitude,
                    currentUserLon: coord?.longitude
                )
                currentIndex = 0
            } catch {
                print("Failed to load profiles: \(error)")
            }
        }
    }

    private func recycleProfiles() {
        // Reset the current index to recycle through profiles again
        // Clear local swipedIds so we can see all profiles again
        swipedIds = []
        currentIndex = 0

        // Reload profiles without excluding any (use device location for distance when available)
        let coord = DiscoveryLocationProvider.shared.lastCoordinate
        Task {
            do {
                let lookingFor: LookingFor = mode == .dating ? .dating : .friends
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: lookingFor,
                    excludeIds: [],
                    currentUserLat: coord?.latitude,
                    currentUserLon: coord?.longitude
                )
            } catch {
                print("Failed to recycle profiles: \(error)")
            }
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

        if isLike {
            withAnimation(.easeOut(duration: 0.35)) {
                likedFadingId = profile.id
            }
        } else {
            swipedIds.append(profile.id)
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
                        swipedIds.append(profile.id)
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
                        swipedIds.append(profile.id)
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
                friendsView
            } else if discoveryMode == .dating {
                datingView
            } else {
                if mode == .dating {
                    datingView
                } else {
                    friendsView
                }
            }
        }
        .onAppear {
            // Request device location for distance filtering (dating & friends)
            DiscoveryLocationProvider.shared.requestLocation()

            // When Messages "Find friends" requested Discover in friends mode, switch to it
            if tabBarVisibility.discoverStartInFriendsMode {
                mode = .friends
                tabBarVisibility.discoverStartInFriendsMode = false
            }
            let discoveryMode = supabaseManager.getDiscoveryMode()
            if discoveryMode == .dating || (discoveryMode == .both && mode == .dating) {
                loadProfiles()
            }
            tabBarVisibility.isVisible = true

            // Subscribe to real-time updates
            Task {
                await FriendsManager.shared.subscribeToMatches()
                await FriendsManager.shared.subscribeToFriendRequests()
            }
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
            Task {
                await FriendsManager.shared.unsubscribe()
            }
        }
        .onChange(of: mode) { newMode in
            if newMode == .dating {
                loadProfiles()
            }
        }
        .fullScreenCover(item: $matchedProfile) { profile in
            MatchAnimationView(
                matchedProfile: profile,
                currentUserAvatarUrl: profileManager.currentProfile?.avatarUrl,
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
            ProfileDetailView(
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
                distanceMiles: distanceMiles(for: profile),
                detailMode: .dating
            )
        }
        .fullScreenCover(item: $selectedFriendProfile) { profile in
            ProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedFriendProfile != nil },
                    set: { if !$0 { selectedFriendProfile = nil } }
                ),
                onLike: {},
                onPass: {},
                distanceMiles: distanceMiles(for: profile),
                detailMode: .friends,
                onConnect: {
                    handleConnect(profileId: profile.id)
                }
            )
        }
        .sheet(isPresented: $showDatingSettings) {
            DatingSettingsSheet(isPresented: $showDatingSettings)
        }
    }

    // MARK: - Dating View (Feed of DiscoverCards)
    @ViewBuilder
    private var datingView: some View {
        ZStack {
            softGray.ignoresSafeArea()

            if visibleDatingProfiles.isEmpty {
                emptyState
                    .onAppear {
                        tabBarVisibility.isVisible = true
                    }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        Color.clear.frame(height: topNavBarHeight)
                        ForEach(visibleDatingProfiles) { profile in
                            DiscoverCard(
                                profile: profile,
                                mode: .dating,
                                lastActiveAt: profile.lastActiveAt,
                                distanceMiles: distanceMiles(for: profile),
                                onPrimaryAction: { handleSwipe(profile: profile, direction: .right) },
                                onViewProfile: { selectedProfile = profile },
                                onBlockComplete: { loadProfiles() }
                            )
                            .opacity(likedFadingId == profile.id ? 0 : 1)
                            .animation(.easeOut(duration: 0.35), value: likedFadingId)
                        }
                        DiscoverEndOfFeedView()
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                        Spacer().frame(height: LayoutConstants.tabBarBottomPadding)
                    }
                    .padding(.horizontal, 16)
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 0) {
                        HStack {
                            if supabaseManager.getDiscoveryMode() == .both {
                                modeSwitcher(style: .light)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        Text("Stories from travelers looking to date")
                            .font(.system(size: 12))
                            .foregroundColor(inkSub)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .background(softGray.ignoresSafeArea(edges: .top))
                    .padding(.top, 60)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
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

    // MARK: - Empty State (End of feed: compass + "You're all caught up!")
    @ViewBuilder
    private var emptyState: some View {
        let discoveryMode = supabaseManager.getDiscoveryMode()

        VStack(spacing: 0) {
            // Mode switcher at top
            if discoveryMode == .both {
                HStack {
                    modeSwitcher(style: .light)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
                .padding(.bottom, 4)

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

            Spacer()
        }
        .padding(.bottom, LayoutConstants.tabBarBottomPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(softGray)
    }

    // MARK: - Friends View
    @ViewBuilder
    private var friendsView: some View {
        let discoveryMode = supabaseManager.getDiscoveryMode()
        
        NavigationStack(path: $friendsNavigationPath) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    // Mode switcher row
                    HStack {
                        if discoveryMode == .both {
                            modeSwitcher(style: .light)
                        }
                        Spacer()
                        friendsFilterButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    // Subtitle under segment (friends)
                    Text("Stories from travelers looking for friends")
                        .font(.system(size: 12))
                        .foregroundColor(inkSub)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)

//                    // Title section
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Nearby Friends")
//                            .font(.system(size: 24, weight: .heavy))
//                            .foregroundColor(inkMain)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 24)
//                    .padding(.bottom, 16)
                }
                .background(softGray)

                FriendsListContent(
                    filterPreferences: friendsFilterPreferences,
                    onViewProfile: { profile in
                        selectedFriendProfile = profile
                    }
                )
            }
            .background(softGray)
            .sheet(isPresented: $showFilters) {
                NearbyFriendsFilterSheet(
                    isPresented: $showFilters,
                    preferences: $friendsFilterPreferences
                )
            }
        }
    }
    
    private func getMutualInterests(for profile: UserProfile) -> [String] {
        let currentUserInterests = supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
        return Set(currentUserInterests).intersection(Set(profile.interests)).map { $0 }
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


    // MARK: - Friends Filter Button
    @ViewBuilder
    private var friendsFilterButton: some View {
        Button {
            showFilters = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18))
                .foregroundColor(inkMain)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
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
