//
//  DiscoverScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

enum DiscoverMode {
    case dating
    case friends
}

struct DiscoverScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var swipedIds: [UUID] = []
    @State private var currentIndex: Int = 0
    @State private var mode: DiscoverMode = .dating
    @State private var selectedProfile: UserProfile? = nil
    @State private var showMatchAlert: Bool = false
    @State private var matchedProfile: UserProfile? = nil
    @State private var showLikePrompt: Bool = false
    @State private var likeMessage: String = ""
    @State private var swipeProgress: CGFloat = 0
    @State private var showFilters: Bool = false
    @State private var lastScrollOffset: CGFloat = 0

    // Colors from HTML
    private let softGray = Color("SoftGray")
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37) // #FF5E5E
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50) // #6B7280
    private let tealPrimary = Color(red: 0.18, green: 0.83, blue: 0.75) // #2DD4BF
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96) // bg-gray-100
    private let gray700 = Color(red: 0.37, green: 0.37, blue: 0.42) // text-gray-700

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
                swipedIds = try await friendsManager.fetchSwipedUserIds()
                let lookingFor: LookingFor = mode == .dating ? .dating : .friends
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: lookingFor,
                    excludeIds: swipedIds
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

    private func handleSwipe(direction: SwipeDirection) {
        guard let profile = currentCard else { return }

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

                let match = try await friendsManager.swipe(on: profile.id, direction: swipeDirection)

                if let match = match {
                    await MainActor.run {
                        matchedProfile = match.otherUserProfile
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMatchAlert = true
                        }
                    }
                }
            } catch {
                print("Failed to record swipe: \(error)")
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
            Color.white.ignoresSafeArea()

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
            let discoveryMode = supabaseManager.getDiscoveryMode()
            if discoveryMode == .dating || (discoveryMode == .both && mode == .dating) {
                loadProfiles()
            }
            tabBarVisibility.isVisible = true
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
        }
        .onChange(of: mode) { newMode in
            if newMode == .dating {
                loadProfiles()
            }
        }
        .overlay {
            if showMatchAlert, let profile = matchedProfile {
                MatchAnimationView(
                    matchedProfile: profile,
                    currentUserAvatarUrl: profileManager.currentProfile?.avatarUrl,
                    onSendMessage: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showMatchAlert = false
                        }
                        // TODO: Navigate to conversation with match
                    },
                    onKeepSwiping: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showMatchAlert = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1000)
            }
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
    }

    // MARK: - Dating View (Connected to Real Data)
    @ViewBuilder
    private var datingView: some View {
        ZStack {
            Color.white

            if let profile = currentCard {
                // Main scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ==========================================
                        // HERO SECTION - h-[500px]
                        // ==========================================
                        GeometryReader { geo in
                            ZStack(alignment: .bottom) {
                                // Hero image (first photo or avatar)
                                if let heroUrl = profile.photos.first ?? profile.avatarUrl,
                                   let url = URL(string: heroUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: geo.size.width, height: 500)
                                        } else if phase.error != nil {
                                            placeholderGradient
                                        } else {
                                            placeholderGradient
                                                .overlay(ProgressView().tint(.white))
                                        }
                                    }
                                    .frame(width: geo.size.width, height: 500)
                                    .clipped()
                                } else {
                                    placeholderGradient
                                        .frame(width: geo.size.width, height: 500)
                                }

                                // Gradient overlay
                                LinearGradient(
                                    stops: [
                                        .init(color: .black.opacity(0.8), location: 0.0),
                                        .init(color: .clear, location: 0.4)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(width: geo.size.width, height: 500)

                                // Hero overlay content
                                HStack(alignment: .bottom, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(profile.displayName), \(profile.age ?? 0)")
                                            .font(.system(size: 36, weight: .heavy))
                                            .tracking(-0.5)
                                            .foregroundColor(.white)

                                        if let location = profile.location {
                                            HStack(spacing: 8) {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 14))
                                                Text(location)
                                            }
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        }
                                    }

                                    Spacer()

                                    // Like button
                                    Button {
                                        handleSwipe(direction: .right)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 56, height: 56)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                                .padding(24)
                            }
                        }
                        .frame(height: 500)

                        // ==========================================
                        // BIO SECTION - p-6 space-y-6
                        // ==========================================
                        VStack(alignment: .leading, spacing: 24) {
                            if let bio = profile.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 18))
                                    .foregroundColor(inkMain)
                                    .lineSpacing(6)
                            }

                            // Tags row (interests)
                            if !profile.interests.isEmpty {
                                WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                                    ForEach(profile.interests, id: \.self) { interest in
                                        Text(interest)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(gray700)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(gray100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)

                        // ==========================================
                        // PROMPT SECTION 1 - "My simple pleasure"
                        // ==========================================
                        if let simplePleasure = profile.simplePleasure, !simplePleasure.isEmpty {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(coralPrimary)
                                    .frame(width: 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MY SIMPLE PLEASURE")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(coralPrimary)

                                    Text(simplePleasure)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(inkMain)
                                }
                                .padding(.leading, 16)
                                .padding(.vertical, 4)

                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.white)
                        }

                        // ==========================================
                        // RIG PHOTO SECTION - mt-6 h-[400px]
                        // ==========================================
                        if profile.photos.count > 1 {
                            GeometryReader { geo in
                                ZStack {
                                    AsyncImage(url: URL(string: profile.photos[1])) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: geo.size.width, height: 400)
                                        } else {
                                            placeholderGradient
                                        }
                                    }
                                    .frame(width: geo.size.width, height: 400)
                                    .clipped()

                                    // Like button top-right
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Button {
                                                handleSwipe(direction: .right)
                                            } label: {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                                    .frame(width: 48, height: 48)
                                                    .background(Color.white.opacity(0.2))
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            }
                                            .padding(.trailing, 24)
                                            .padding(.top, 16)
                                        }
                                        Spacer()
                                    }

                                    // Rig info card bottom-left (only if rigInfo exists)
                                    if let rigInfo = profile.rigInfo, !rigInfo.isEmpty {
                                        VStack {
                                            Spacer()
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: "box.truck.fill")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(coralPrimary)
                                                        Text("The Rig")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(inkMain)
                                                    }
                                                    Text(rigInfo)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(inkSub)
                                                }
                                                .padding(12)
                                                .frame(maxWidth: 200, alignment: .leading)
                                                .background(Color.white.opacity(0.95))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                                                Spacer()
                                            }
                                            .padding(.leading, 24)
                                            .padding(.bottom, 24)
                                        }
                                    }
                                }
                            }
                            .frame(height: 400)
                            .padding(.top, 24)
                        }

                        // ==========================================
                        // PROMPT SECTION 2 - "Dating me looks like"
                        // ==========================================
                        if let datingLooksLike = profile.datingLooksLike, !datingLooksLike.isEmpty {
                            VStack(spacing: 16) {
                                Text("DATING ME LOOKS LIKE")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(Color.gray)

                                Text(datingLooksLike)
                                    .font(.system(size: 18))
                                    .foregroundColor(inkMain)
                                    .multilineTextAlignment(.center)
                                    .padding(20)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.05))
                        }

                        // ==========================================
                        // ADDITIONAL PHOTOS
                        // ==========================================
                        ForEach(Array(profile.photos.dropFirst(2).enumerated()), id: \.offset) { index, photoUrl in
                            GeometryReader { geo in
                                ZStack {
                                    AsyncImage(url: URL(string: photoUrl)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: geo.size.width, height: 400)
                                        } else {
                                            placeholderGradient
                                        }
                                    }
                                    .frame(width: geo.size.width, height: 400)
                                    .clipped()

                                    // Like button top-right
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Button {
                                                handleSwipe(direction: .right)
                                            } label: {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                                    .frame(width: 48, height: 48)
                                                    .background(Color.white.opacity(0.2))
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            }
                                            .padding(.trailing, 24)
                                            .padding(.top, 16)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .frame(height: 400)
                        }

                        // Bottom padding for tab bar
                        Spacer().frame(height: LayoutConstants.tabBarBottomPadding)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("discoverScroll")).minY
                                )
                        }
                    )
                }
                .coordinateSpace(name: "discoverScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    // Near top of content - always show tab bar
                    if offset > -100 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            tabBarVisibility.isVisible = true
                        }
                        lastScrollOffset = offset
                        return
                    }

                    let scrollDelta = offset - lastScrollOffset
                    if abs(scrollDelta) > 8 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if scrollDelta < 0 {
                                // Scrolling down
                                tabBarVisibility.isVisible = false
                            } else if scrollDelta > 0 {
                                // Scrolling up
                                tabBarVisibility.isVisible = true
                            }
                        }
                        lastScrollOffset = offset
                    }
                }

                // ==========================================
                // FLOATING HEADER - mode switcher + more button
                // ==========================================
                VStack {
                    HStack {
                        // Show mode switcher only in "both" mode
                        if supabaseManager.getDiscoveryMode() == .both {
                            modeSwitcher(style: .dark)
                        }
                        Spacer()
                        Button { } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60) // Account for status bar / safe area

                    Spacer()
                }

                // ==========================================
                // PASS BUTTON - bottom above tab bar
                // ==========================================
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            handleSwipe(direction: .left)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(Color.gray)
                                .frame(width: 64, height: 64)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
                        }

                        Spacer()
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, LayoutConstants.tabBarBottomPadding)
                    .offset(y: tabBarVisibility.isVisible ? 0 : 120)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: tabBarVisibility.isVisible)
                }
            } else {
                // Empty state when no profiles - always show tab bar
                emptyState
                    .onAppear {
                        tabBarVisibility.isVisible = true
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

    // MARK: - Empty State
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundColor(inkMain.opacity(0.3))

            Text("No more profiles")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(inkMain)

            Text("Check back later for new matches")
                .font(.system(size: 14))
                .foregroundColor(inkSub)

            Button {
                recycleProfiles()
            } label: {
                Text("Refresh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(coralPrimary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(softGray)
    }

    // MARK: - Friends View
    @ViewBuilder
    private var friendsView: some View {
        let discoveryMode = supabaseManager.getDiscoveryMode()
        
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
        isLoading = true
        Task {
            do {
                swipedIds = try await friendsManager.fetchSwipedUserIds()
                try await friendsManager.fetchSentRequests()
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: .friends,
                    excludeIds: swipedIds
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
                        FriendCard(
                            profile: profile,
                            mutualInterests: getMutualInterests(for: profile),
                            requestSent: friendsManager.hasSentRequest(to: profile.id),
                            onConnect: { profileId in
                                handleConnect(profileId: profileId)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarBottomPadding)
        }
        .onAppear {
            loadProfiles()
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
        value = nextValue()
    }
}

// MARK: - Discover Mode Switcher with Sliding Animation
struct DiscoverModeSwitcher: View {
    @Binding var mode: DiscoverMode
    var style: DiscoverScreen.ModeSwitcherStyle
    @Namespace private var animation
    
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(friendsGradient)
                            .matchedGeometryEffect(id: "discoverSegmentBg", in: animation)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(containerOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    // MARK: - Style-dependent colors
    
    private var datingTextColor: Color {
        switch style {
        case .dark:
            return mode == .dating ? coralPrimary : .white.opacity(0.9)
        case .light:
            return mode == .dating ? coralPrimary : .gray.opacity(0.6)
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
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        case .light:
            RoundedRectangle(cornerRadius: 20)
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

#Preview {
    DiscoverScreen()
}
