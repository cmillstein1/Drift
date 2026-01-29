//
//  DiscoverScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Auth

enum DiscoverMode {
    case dating
    case friends
}

struct DiscoverScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var messagingManager = MessagingManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var swipedIds: [UUID] = []
    @State private var currentIndex: Int = 0
    @State private var mode: DiscoverMode = .dating
    @State private var selectedProfile: UserProfile? = nil
    @State private var matchedProfile: UserProfile? = nil
    @State private var showLikePrompt: Bool = false
    @State private var likeMessage: String = ""
    @State private var swipeProgress: CGFloat = 0
    @State private var showFilters: Bool = false
    @State private var showDatingSettings: Bool = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 1.0
    @State private var scrollPosition: CGFloat = 0
    @State private var currentScrollOffset: CGFloat = 0
    @State private var isScrolledDown: Bool = false // Track if user has scrolled down
    @State private var maxScrollOffset: CGFloat = 0 // Track the maximum scroll offset reached
    @State private var lastScrollDirection: CGFloat = 0 // Track last scroll direction (negative = down, positive = up)
    @State private var zoomedPhotoURL: String? = nil

    /// Height of top nav bar (status padding + content) for scroll‑away offset
    private let topNavBarHeight: CGFloat = 132
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

    private func loadProfiles() {
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
                    excludeIds: swipedIds + blocked
                )
                currentIndex = 0
            } catch {
                print("Failed to load profiles: \(error)")
            }
        }
    }
    
    private func handleScrollOffset(_ offset: CGFloat) {
        // Calculate header opacity based on scroll position
        let fadeThreshold: CGFloat = 100
        if offset > -fadeThreshold {
            // Near top - show header
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                headerOpacity = 1.0
            }
        } else {
            // Scrolled down - hide header
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                headerOpacity = 0.0
            }
        }
        
        // Handle tab bar visibility based on scroll position and direction
        let scrollDelta = offset - lastScrollOffset
        
        // Track maximum scroll offset reached (most negative value)
        if offset < maxScrollOffset {
            maxScrollOffset = offset
        }
        
        // Always show tab bar when near top (within first 50px of scroll)
        if offset > -50 {
            if !tabBarVisibility.isVisible {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    tabBarVisibility.isVisible = true
                }
            }
            isScrolledDown = false
            maxScrollOffset = 0 // Reset when back at top
            lastScrollOffset = offset
            lastScrollDirection = 0
            return
        }
        
        // Track if user has scrolled down past threshold
        if offset < -50 {
            isScrolledDown = true
        }
        
        // Hide/show based on scroll direction when scrolled down
        // Only update if there's meaningful scroll movement (at least 2px)
        // Only show tab bar if user is actually scrolling up (not just bouncing at bottom)
        if abs(scrollDelta) > 2 {
            // Determine if this is a sustained upward scroll (not a bounce)
            // A bounce would be: scrolling up briefly then immediately back down
            // A real scroll up would be: consistent upward movement
            
            let isConsistentScrollUp = scrollDelta > 0 && (lastScrollDirection >= 0 || scrollDelta > 5)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if scrollDelta < 0 {
                    // Scrolling down - hide tab bar
                    tabBarVisibility.isVisible = false
                    lastScrollDirection = scrollDelta
                } else if scrollDelta > 0 && isScrolledDown && isConsistentScrollUp {
                    // Scrolling up AND we were scrolled down AND it's a consistent upward scroll
                    // Only show if we're actually making progress toward the top
                    // Don't show if we're still very far from top (likely a bounce)
                    if offset > -200 {
                        // We're within 200px of top - safe to show tab bar
                        tabBarVisibility.isVisible = true
                    } else if offset > maxScrollOffset + 100 {
                        // We've scrolled up more than 100px from the bottom - likely intentional
                        tabBarVisibility.isVisible = true
                    }
                }
            }
            
            // Update last scroll direction
            if abs(scrollDelta) > 2 {
                lastScrollDirection = scrollDelta
            }
        }
        lastScrollOffset = offset
    }
    
    private func recycleProfiles() {
        // Reset the current index to recycle through profiles again
        // Clear local swipedIds so we can see all profiles again
        swipedIds = []
        currentIndex = 0

        // Reload profiles without excluding any
        Task {
            do {
                let lookingFor: LookingFor = mode == .dating ? .dating : .friends
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: lookingFor,
                    excludeIds: []
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

        print("🃏 [DISCOVER] handleSwipe called")
        print("🃏 [DISCOVER] Profile: \(profile.displayName) (\(profile.id))")
        print("🃏 [DISCOVER] Direction: \(direction)")

        Task {
            do {
                let swipeDirection: DriftBackend.SwipeDirection
                switch direction {
                case .left:
                    swipeDirection = .left
                case .right:
                    swipeDirection = .right
                case .up:
                    swipeDirection = .up
                }

                print("🃏 [DISCOVER] Calling friendsManager.swipe...")
                let match = try await friendsManager.swipe(on: profile.id, direction: swipeDirection)

                print("🃏 [DISCOVER] Swipe returned, match: \(match != nil ? "YES" : "NO")")

                if let match = match {
                    print("🎊 [DISCOVER] MATCH DETECTED!")
                    print("🎊 [DISCOVER] Match ID: \(match.id)")
                    print("🎊 [DISCOVER] Other user profile: \(match.otherUserProfile?.displayName ?? "nil")")

                    await MainActor.run {
                        print("🎊 [DISCOVER] Setting matchedProfile to trigger fullScreenCover...")
                        matchedProfile = match.otherUserProfile
                        print("🎊 [DISCOVER] matchedProfile is now: \(matchedProfile?.displayName ?? "nil")")
                    }
                } else {
                    print("🃏 [DISCOVER] No match returned")
                }
            } catch {
                print("❌ [DISCOVER] Failed to record swipe: \(error)")
            }
        }

        if currentIndex < profiles.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex += 1
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                loadProfiles()
            }
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
            // When Messages "Find friends" requested Discover in friends mode, switch to it
            if tabBarVisibility.discoverStartInFriendsMode {
                mode = .friends
                tabBarVisibility.discoverStartInFriendsMode = false
            }
            let discoveryMode = supabaseManager.getDiscoveryMode()
            if discoveryMode == .dating || (discoveryMode == .both && mode == .dating) {
                loadProfiles()
            }
            // Initialize tab bar as visible and reset scroll offset tracking
            tabBarVisibility.isVisible = true
            lastScrollOffset = 0

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
                    handleSwipe(direction: .right)
                },
                onPass: {
                    handleSwipe(direction: .left)
                }
            )
        }
        .sheet(isPresented: $showDatingSettings) {
            DatingSettingsSheet(isPresented: $showDatingSettings)
        }
    }

    // MARK: - Dating View (Connected to Real Data)
    @ViewBuilder
    private var datingView: some View {
        ZStack {
            softGray.ignoresSafeArea()

            if let profile = currentCard {
                // ScrollView full size so content can scroll into header zone; header overlaid and slides up with scroll
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 1)
                            .background(
                                GeometryReader { geo in
                                    let namedOffset = geo.frame(in: .named("discoverScroll")).minY
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: namedOffset)
                                        .onAppear { handleScrollOffset(namedOffset) }
                                        .onChange(of: namedOffset) { _, newValue in
                                            currentScrollOffset = newValue
                                            handleScrollOffset(newValue)
                                        }
                                }
                            )

                        // Top spacer so card starts below header when at rest; content scrolls into header area
                        Color.clear.frame(height: topNavBarHeight - 1)

                        // White card
                            VStack(spacing: 0) {
                            // ----- Header: name, age, verified, location, distance, tags -----
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text("\(profile.displayName), \(profile.displayAge)")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(charcoal)
                                            if profile.verified {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(forestGreen)
                                            }
                                        }
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin")
                                                .font(.system(size: 14))
                                            if let loc = profile.location {
                                                Text(loc)
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            Text("•")
                                            Image(systemName: "location")
                                                .font(.system(size: 14))
                                            Text("Nearby")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        .foregroundColor(charcoal.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 12)

                                // Quick info tags
                                HStack(spacing: 8) {
                                    if let lifestyle = profile.lifestyle {
                                        Text(lifestyle.displayName)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(charcoal)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(desertSand)
                                            .clipShape(Capsule())
                                    }
                                    if let pace = profile.travelPace {
                                        HStack(spacing: 4) {
                                            Image(systemName: "van.side")
                                                .font(.system(size: 10))
                                            Text(pace.displayName)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(charcoal)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(desertSand)
                                        .clipShape(Capsule())
                                    }
                                    if let lastActive = lastActiveString(for: profile.lastActiveAt) {
                                        Text(lastActive)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(burntOrange)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(burntOrange.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(gray100),
                                alignment: .bottom
                            )

                            // ----- First image 3:4 (fixed frame so photo fills container, no gaps) -----
                            ZStack(alignment: .bottomTrailing) {
                                GeometryReader { geo in
                                    let w = geo.size.width
                                    let h = w * 4 / 3
                                    if let firstUrl = profile.photos.first ?? profile.avatarUrl, let url = URL(string: firstUrl) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: w, height: h)
                                                    .clipped()
                                            } else {
                                                placeholderGradient
                                                    .frame(width: w, height: h)
                                            }
                                        }
                                        .frame(width: w, height: h)
                                        .clipped()
                                        .contentShape(Rectangle())
                                        .onTapGesture { zoomedPhotoURL = firstUrl }
                                    } else {
                                        placeholderGradient
                                            .frame(width: w, height: h)
                                    }
                                }
                                .aspectRatio(3/4, contentMode: .fit)
                                Button {
                                    handleSwipe(direction: .right)
                                } label: {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                }
                                .padding(20)
                            }
                            .aspectRatio(3/4, contentMode: .fit)

                            // ----- Bio -----
                            if let bio = profile.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoal)
                                    .lineSpacing(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .background(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(gray100),
                                        alignment: .bottom
                                    )
                            }

                            // ----- Prompt 1 -----
                            if let answers = profile.promptAnswers, !answers.isEmpty {
                                datingPromptSection(question: answers[0].prompt, answer: answers[0].answer)
                            } else if let simple = profile.simplePleasure, !simple.isEmpty {
                                datingPromptSection(question: "My simple pleasure", answer: simple)
                            }

                            // ----- Second image 4:3 -----
                            if profile.photos.count > 1 {
                                let photo2URL = profile.photos[1]
                                ZStack(alignment: .bottomTrailing) {
                                    GeometryReader { geo in
                                        let w = geo.size.width
                                        let h = w * 3 / 4
                                        if let url = URL(string: photo2URL) {
                                            AsyncImage(url: url) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: w, height: h)
                                                        .clipped()
                                                } else {
                                                    placeholderGradient.frame(width: w, height: h)
                                                }
                                            }
                                            .frame(width: w, height: h)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture { zoomedPhotoURL = photo2URL }
                                        }
                                    }
                                    .aspectRatio(4/3, contentMode: .fit)
                                    Button {
                                        handleSwipe(direction: .right)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                    }
                                    .padding(16)
                                }
                            }

                            // ----- Mutual interests -----
                            let mutuals = datingMutualInterests(for: profile)
                            if !mutuals.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 18))
                                            .foregroundColor(burntOrange)
                                        Text("\(mutuals.count) Shared Interest\(mutuals.count == 1 ? "" : "s")")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(charcoal)
                                    }
                                    WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                                        ForEach(mutuals, id: \.self) { interest in
                                            Text(interest)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(burntOrange)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(burntOrange.opacity(0.1))
                                                .overlay(Capsule().stroke(burntOrange, lineWidth: 2))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white)
                                .overlay(
                                    Rectangle().frame(height: 1).foregroundColor(gray100),
                                    alignment: .bottom
                                )
                            }

                            // ----- Prompt 2 -----
                            if let answers = profile.promptAnswers, answers.count > 1 {
                                datingPromptSection(question: answers[1].prompt, answer: answers[1].answer)
                            } else if let datingLooks = profile.datingLooksLike, !datingLooks.isEmpty {
                                datingPromptSection(question: "Dating me looks like", answer: datingLooks)
                            }

                            // ----- Third image square -----
                            if profile.photos.count > 2 {
                                let photo3URL = profile.photos[2]
                                ZStack(alignment: .bottomTrailing) {
                                    GeometryReader { geo in
                                        let s = geo.size.width
                                        if let url = URL(string: photo3URL) {
                                            AsyncImage(url: url) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: s, height: s)
                                                        .clipped()
                                                } else {
                                                    placeholderGradient.frame(width: s, height: s)
                                                }
                                            }
                                            .frame(width: s, height: s)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture { zoomedPhotoURL = photo3URL }
                                        }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                    Button {
                                        handleSwipe(direction: .right)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                    }
                                    .padding(16)
                                }
                            }

                            // ----- Interests -----
                            if !profile.interests.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Interests")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(charcoal.opacity(0.6))
                                    WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                                        ForEach(profile.interests, id: \.self) { tag in
                                            Text(tag)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(charcoal)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(desertSand)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white)
                                .overlay(
                                    Rectangle().frame(height: 1).foregroundColor(gray100),
                                    alignment: .bottom
                                )
                            }

                            // ----- Travel plans -----
                            if profile.nextDestination != nil || profile.travelDates != nil {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Travel Plans")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(charcoal.opacity(0.6))
                                    VStack(alignment: .leading, spacing: 12) {
                                        if let dest = profile.nextDestination {
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(burntOrange)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Next Destination")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(charcoal.opacity(0.6))
                                                    Text(dest)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(charcoal)
                                                }
                                                Spacer()
                                            }
                                        }
                                        if let dates = profile.travelDates {
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "calendar")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(burntOrange)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Travel Dates")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(charcoal.opacity(0.6))
                                                    Text(dates)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(charcoal)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white)
                                .overlay(
                                    Rectangle().frame(height: 1).foregroundColor(gray100),
                                    alignment: .bottom
                                )
                            }

                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 16)

                        Spacer().frame(height: LayoutConstants.tabBarBottomPadding)
                        }
                        .background(softGray)
                    }
                    .coordinateSpace(name: "discoverScroll")
                    .overlay(alignment: .top) {
                        ZStack(alignment: .top) {
                            // 1) Expanded bar: slides up and fades as user scrolls
                            let expandedOffset = max(-topNavBarHeight, min(0, currentScrollOffset))
                            let expandedOpacity = currentScrollOffset > 0 ? 1.0 : max(0, 1.0 + currentScrollOffset / headerCollapseThreshold)
                            HStack {
                                if supabaseManager.getDiscoveryMode() == .both {
                                    modeSwitcher(style: .light)
                                }
                                Spacer()
                                ReportBlockMenuButton(
                                    userId: currentCard?.id,
                                    displayName: currentCard?.displayName,
                                    onBlockComplete: { loadProfiles() }
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                            .frame(maxWidth: .infinity)
                            .background(softGray.ignoresSafeArea(edges: .top))
                            .padding(.top, 60)
                            .offset(y: expandedOffset)
                            .opacity(expandedOpacity)

                            // 2) Compact bar: person's name centered + more button; fades in when expanded has scrolled away
                            let compactOpacity = currentScrollOffset >= -headerCollapseThreshold ? 0.0 : min(1.0, (-currentScrollOffset - headerCollapseThreshold) / 40.0)
                            let compactButtonOpacity: Double = currentScrollOffset >= -headerCollapseThreshold ? 1.0 : max(0, 1.0 + Double(currentScrollOffset + headerCollapseThreshold) / 50.0)
                            ZStack {
                                Text(profile.displayName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(charcoal)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                HStack {
                                    Spacer()
                                    ReportBlockMenuButton(
                                        userId: currentCard?.id,
                                        displayName: currentCard?.displayName,
                                        onBlockComplete: { loadProfiles() }
                                    )
                                    .opacity(compactButtonOpacity)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: compactHeaderHeight)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.ignoresSafeArea(edges: .top))
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(gray100),
                                alignment: .bottom
                            )
                            .padding(.top, 60)
                            .opacity(compactOpacity)
                        }
                    }
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newOffset in
                    // Update scroll position
                    scrollPosition = newOffset
                    
                    // Calculate header opacity based on scroll position
                    // Fade out when scrolling down, fade in when at top
                    let fadeThreshold: CGFloat = 100
                    if newOffset > -fadeThreshold {
                        // Near top - show header
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            headerOpacity = 1.0
                        }
                    } else {
                        // Scrolled down - hide header
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            headerOpacity = 0.0
                        }
                    }
                    
                    // Handle tab bar visibility based on scroll position and direction
                    let scrollDelta = newOffset - lastScrollOffset
                    
                    // Track maximum scroll offset reached (most negative value)
                    if newOffset < maxScrollOffset {
                        maxScrollOffset = newOffset
                    }
                    
                    // Always show tab bar when near top (within first 50px of scroll)
                    if newOffset > -50 {
                        if !tabBarVisibility.isVisible {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                tabBarVisibility.isVisible = true
                            }
                        }
                        isScrolledDown = false
                        maxScrollOffset = 0 // Reset when back at top
                        lastScrollOffset = newOffset
                        lastScrollDirection = 0
                        return
                    }
                    
                    // Track if user has scrolled down past threshold
                    if newOffset < -50 {
                        isScrolledDown = true
                    }
                    
                    // Hide/show based on scroll direction when scrolled down
                    // Only update if there's meaningful scroll movement (at least 2px)
                    // Only show tab bar if user is actually scrolling up (not just bouncing at bottom)
                    if abs(scrollDelta) > 2 {
                        // Determine if this is a sustained upward scroll (not a bounce)
                        // A bounce would be: scrolling up briefly then immediately back down
                        // A real scroll up would be: consistent upward movement
                        
                        let isConsistentScrollUp = scrollDelta > 0 && (lastScrollDirection >= 0 || scrollDelta > 5)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if scrollDelta < 0 {
                                // Scrolling down - hide tab bar
                                tabBarVisibility.isVisible = false
                                lastScrollDirection = scrollDelta
                            } else if scrollDelta > 0 && isScrolledDown && isConsistentScrollUp {
                                // Scrolling up AND we were scrolled down AND it's a consistent upward scroll
                                // Only show if we're actually making progress toward the top
                                // Don't show if we're still very far from top (likely a bounce)
                                if newOffset > -200 {
                                    // We're within 200px of top - safe to show tab bar
                                    tabBarVisibility.isVisible = true
                                } else if newOffset > maxScrollOffset + 100 {
                                    // We've scrolled up more than 100px from the bottom - likely intentional
                                    tabBarVisibility.isVisible = true
                                }
                            }
                        }
                        
                        // Update last scroll direction
                        if abs(scrollDelta) > 2 {
                            lastScrollDirection = scrollDelta
                        }
                    }
                    lastScrollOffset = newOffset
                }

                // Persistent Pass (X) button - bottom left, more pronounced
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            handleSwipe(direction: .left)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(charcoal)
                                .frame(width: 58, height: 58)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(charcoal.opacity(0.25), lineWidth: 1.5))
                                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 5)
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, LayoutConstants.tabBarHeight + 12)
                        .offset(y: tabBarVisibility.isVisible ? 0 : LayoutConstants.tabBarHeight + 16)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarVisibility.isVisible)
                        Spacer()
                    }
                }
                .allowsHitTesting(true)
            } else {
                // Empty state when no profiles - always show tab bar
                emptyState
                    .onAppear {
                        tabBarVisibility.isVisible = true
                    }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { zoomedPhotoURL != nil },
            set: { if !$0 { zoomedPhotoURL = nil } }
        )) {
            if let urlString = zoomedPhotoURL, let url = URL(string: urlString) {
                DiscoverZoomablePhotoView(imageURL: url, onDismiss: { zoomedPhotoURL = nil })
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

    // MARK: - Empty State
    @ViewBuilder
    private var emptyState: some View {
        let forestGreen = Color("ForestGreen")
        let discoveryMode = supabaseManager.getDiscoveryMode()

        VStack(spacing: 0) {
            // Mode switcher at top - same vertical position as when cards are showing (padding.top 60 for status bar)
            if discoveryMode == .both {
                HStack {
                    modeSwitcher(style: .light)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 72) // 60 status bar + 12, matches datingView header
                .padding(.bottom, 20)
            }

            Spacer()

            VStack(spacing: 24) {
                // Illustration
                Image("Dating_Empty_State")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 280)

                // Main title
                Text("You've seen everyone for now")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(inkMain)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Subtitle
                Text("Try changing your filters so more people match your criteria—or check back later!")
                    .font(.system(size: 16))
                    .foregroundColor(inkSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                // Buttons
                VStack(spacing: 12) {
                    // Change filters button (primary)
                    Button {
                        showDatingSettings = true
                    } label: {
                        Text("Change filters")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(forestGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)

                    // Review skipped profiles button (secondary)
                    Button {
                        recycleProfiles()
                    } label: {
                        Text("Review skipped profiles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(forestGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(forestGreen.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.top, 8)
            }

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
        
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    // Mode switcher row - same position as dating view
                    HStack {
                        if discoveryMode == .both {
                            modeSwitcher(style: .light)
                        }
                        Spacer()
                        friendsFilterButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    // Title section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nearby Friends")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(inkMain)

                        Text("Connect instantly - no matching required!")
                            .font(.system(size: 14))
                            .foregroundColor(inkSub)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .background(softGray)

                FriendsListContent()
            }
            .background(softGray)
            .navigationDestination(for: UserProfile.self) { profile in
                FriendDetailView(
                    profile: profile,
                    mutualInterests: getMutualInterests(for: profile),
                    requestSent: friendsManager.hasSentRequest(to: profile.id),
                    showConnectButton: true,
                    isFromFriendsGrid: false,
                    onConnect: { profileId in
                        handleConnect(profileId: profileId)
                    },
                    onMessage: { profileId in
                        // Handle message action if needed
                    }
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

// MARK: - Friends List Content

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

enum SwipeDirection {
    case left
    case right
    case up
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // Take the minimum value (most negative = scrolled down most)
        // This ensures we always get the actual scroll position
        let next = nextValue()
        if abs(next) > abs(value) {
            value = next
        } else {
            value = next
        }
    }
}

// MARK: - Discover Mode Switcher with Sliding Animation
struct DiscoverModeSwitcher: View {
    @Binding var mode: DiscoverMode
    var style: DiscoverScreen.ModeSwitcherStyle
    @Namespace private var animation
    
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private let friendsGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.66, green: 0.77, blue: 0.84),  // #A8C5D6 Sky Blue
            Color(red: 0.33, green: 0.47, blue: 0.34)   // #547756 Forest Green
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        HStack(spacing: 0) {
            // Dating button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    mode = .dating
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                    Text("Dating")
                        .font(.system(size: 12, weight: mode == .dating ? .bold : .medium))
                        .tracking(0.5)
                }
                .foregroundColor(datingTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if mode == .dating {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [burntOrange, pink500],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "discoverSegmentBg", in: animation)
                    }
                }
            }
            .buttonStyle(.plain)

            // Friends button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    mode = .friends
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("Friends")
                        .font(.system(size: 12, weight: mode == .friends ? .bold : .medium))
                        .tracking(0.5)
                }
                .foregroundColor(friendsTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if mode == .friends {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(friendsGradient)
                            .matchedGeometryEffect(id: "discoverSegmentBg", in: animation)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(containerOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    // MARK: - Style-dependent colors
    
    private var datingTextColor: Color {
        switch style {
        case .dark:
            return mode == .dating ? .white : .white.opacity(0.9)
        case .light:
            return mode == .dating ? .white : .gray.opacity(0.6)
        }
    }
    
    private var friendsTextColor: Color {
        switch style {
        case .dark:
            return mode == .friends ? .white : .white.opacity(0.9)
        case .light:
            return mode == .friends ? .white : .gray.opacity(0.6)
        }
    }
    
    @ViewBuilder
    private var containerBackground: some View {
        switch style {
        case .dark:
            ZStack {
                Color.black.opacity(0.2)
                Rectangle().fill(.ultraThinMaterial.opacity(0.5))
            }
        case .light:
            Color.white
        }
    }
    
    @ViewBuilder
    private var containerOverlay: some View {
        switch style {
        case .dark:
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        case .light:
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .dark:
            return .black.opacity(0.2)
        case .light:
            return .black.opacity(0.05)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .dark: return 8
        case .light: return 4
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .dark: return 4
        case .light: return 2
        }
    }
}

// MARK: - Discover Zoomable Photo (full-screen pinch-to-zoom)
struct DiscoverZoomablePhotoView: View {
    let imageURL: URL
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture { onDismiss() }

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(lastScale * value, minScale), maxScale)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                default:
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.4), radius: 4)
                    }
                    .padding(24)
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3)) {
                if scale > 1 {
                    scale = 1
                    offset = .zero
                    lastOffset = .zero
                    lastScale = 1
                } else {
                    scale = 2
                    lastScale = 1
                }
            }
        }
    }
}

#Preview {
    DiscoverScreen()
}
