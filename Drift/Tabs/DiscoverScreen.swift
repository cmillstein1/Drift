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
    @State private var showDatingSettings: Bool = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 1.0
    @State private var scrollPosition: CGFloat = 0
    @State private var currentScrollOffset: CGFloat = 0
    @State private var isScrolledDown: Bool = false // Track if user has scrolled down
    @State private var maxScrollOffset: CGFloat = 0 // Track the maximum scroll offset reached
    @State private var lastScrollDirection: CGFloat = 0 // Track last scroll direction (negative = down, positive = up)

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
            let discoveryMode = supabaseManager.getDiscoveryMode()
            if discoveryMode == .dating || (discoveryMode == .both && mode == .dating) {
                loadProfiles()
            }
            // Initialize tab bar as visible and reset scroll offset tracking
            tabBarVisibility.isVisible = true
            lastScrollOffset = 0
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
                // Main scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ==========================================
                        // HEADER SECTION - Mode switcher, name, location (fades on scroll)
                        // ==========================================
                        VStack(spacing: 0) {
                            // Mode switcher row - matches friends view positioning
                            if supabaseManager.getDiscoveryMode() == .both {
                                HStack {
                                    modeSwitcher(style: .light)
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                                .padding(.bottom, 20)
                            }
                            
                            // Name and location section
                            VStack(alignment: .leading, spacing: 4) {
                                // Name and age
                                Text("\(profile.displayName), \(profile.age ?? 0)")
                                    .font(.system(size: 28, weight: .heavy))
                                    .tracking(-0.5)
                                    .foregroundColor(inkMain)
                                
                                // Location
                                if let location = profile.location {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 14))
                                        Text(location)
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(inkSub)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        .padding(.top, 60) // Account for status bar
                        .background(softGray)
                        .opacity(headerOpacity)
                        .background(
                            GeometryReader { geo in
                                let namedOffset = geo.frame(in: .named("discoverScroll")).minY
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: namedOffset
                                    )
                                    .onAppear {
                                        currentScrollOffset = namedOffset
                                    }
                                    .onChange(of: namedOffset) { oldValue, newValue in
                                        // Directly update state when offset changes
                                        currentScrollOffset = newValue
                                        handleScrollOffset(newValue)
                                    }
                            }
                        )
                        
                        // ==========================================
                        // FIRST PHOTO - Below header
                        // ==========================================
                        if let firstPhotoUrl = profile.photos.first ?? profile.avatarUrl,
                           let url = URL(string: firstPhotoUrl) {
                            GeometryReader { geo in
                                ZStack(alignment: .bottom) {
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
                                    
                                    // Like button - bottom right
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
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
                                            .padding(.trailing, 24)
                                            .padding(.bottom, 24)
                                        }
                                    }
                                }
                            }
                            .frame(height: 500)
                        } else {
                            // Placeholder if no photo
                            placeholderGradient
                                .frame(height: 500)
                        }

                        // ==========================================
                        // ABOUT SECTION - After first photo
                        // ==========================================
                        if let bio = profile.bio, !bio.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                // About heading with accent line
                                HStack(spacing: 12) {
                                    // Accent line with gradient
                                    LinearGradient(
                                        colors: [coralPrimary, coralPrimary.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 4, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    
                                    Text("ABOUT")
                                        .font(.system(size: 13, weight: .semibold))
                                        .tracking(1)
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))
                                }
                                
                                // About text
                                Text(bio)
                                    .font(.system(size: 16))
                                    .foregroundColor(inkMain)
                                    .lineSpacing(6)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(softGray)
                        }

                        // ==========================================
                        // PROMPT SECTION 1 - First prompt answer (after About)
                        // ==========================================
                        if let promptAnswers = profile.promptAnswers, !promptAnswers.isEmpty, promptAnswers.count > 0 {
                            VStack(spacing: 16) {
                                // Prompt title - centered, uppercase
                                Text(promptAnswers[0].prompt.uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(Color.gray)
                                
                                // Answer card - centered, white background
                                Text(promptAnswers[0].answer)
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
                            .background(softGray)
                        } else if let simplePleasure = profile.simplePleasure, !simplePleasure.isEmpty {
                            // Fallback to old prompt for backward compatibility
                            VStack(spacing: 16) {
                                Text("MY SIMPLE PLEASURE")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(Color.gray)
                                
                                Text(simplePleasure)
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
                            .background(softGray)
                        }

                        // ==========================================
                        // SECOND PHOTO SECTION
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

                                    // Like button - bottom right
                                    VStack {
                                        Spacer()
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
                                            .padding(.bottom, 24)
                                        }
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
                        } else if profile.photos.isEmpty && profile.avatarUrl == nil {
                            // If no photos at all, show placeholder
                            placeholderGradient
                                .frame(height: 400)
                        }

                        // ==========================================
                        // INTERESTS SECTION - After second photo (or first if only one photo)
                        // ==========================================
                        if !profile.interests.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                // Interests heading with accent line
                                HStack(spacing: 12) {
                                    // Accent line with gradient
                                    LinearGradient(
                                        colors: [coralPrimary, coralPrimary.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 4, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    
                                    Text("INTERESTS")
                                        .font(.system(size: 13, weight: .semibold))
                                        .tracking(1)
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))
                                }
                                
                                // Interest tags with emojis
                                WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                                    ForEach(profile.interests, id: \.self) { interest in
                                        HStack(spacing: 6) {
                                            if let emoji = DriftUI.emoji(for: interest) {
                                                Text(emoji)
                                                    .font(.system(size: 14))
                                            }
                                            Text(interest)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(gray700)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(burntOrange.opacity(0.15))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(softGray)
                        }

                        // ==========================================
                        // PROMPT SECTION 2 - Second prompt answer (after Interests)
                        // ==========================================
                        if let promptAnswers = profile.promptAnswers, promptAnswers.count > 1 {
                            VStack(spacing: 16) {
                                Text(promptAnswers[1].prompt.uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(Color.gray)

                                Text(promptAnswers[1].answer)
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
                            .background(softGray)
                        } else if let datingLooksLike = profile.datingLooksLike, !datingLooksLike.isEmpty {
                            // Fallback to old prompt for backward compatibility
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
                            .background(softGray)
                        }

                        // ==========================================
                        // ADDITIONAL PHOTOS with prompt answers (photos 3+)
                        // ==========================================
                        // Only show if there are more than 2 photos
                        if profile.photos.count > 2 {
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

                                    // Like button - bottom right
                                    VStack {
                                        Spacer()
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
                                            .padding(.bottom, 24)
                                        }
                                    }
                                }
                            }
                            .frame(height: 400)
                            
                            // Show prompt answer after each additional photo (starting with 3rd prompt)
                            if let promptAnswers = profile.promptAnswers, promptAnswers.count > index + 2 {
                                VStack(spacing: 16) {
                                    Text(promptAnswers[index + 2].prompt.uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(Color.gray)

                                    Text(promptAnswers[index + 2].answer)
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
                                .background(softGray)
                            }
                        }
                        }

                        // Bottom padding for tab bar
                        Spacer().frame(height: LayoutConstants.tabBarBottomPadding)
                    }
                }
                .coordinateSpace(name: "discoverScroll")
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

                // ==========================================
                // FLOATING HEADER - Appears when scrolled (fades in when header fades out)
                // ==========================================
                VStack {
                    HStack {
                        // Show mode switcher only in "both" mode
                        if supabaseManager.getDiscoveryMode() == .both {
                            modeSwitcher(style: .light)
                        }
                        Spacer()
                        Button { } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .foregroundColor(inkMain)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60) // Account for status bar / safe area
                    .padding(.bottom, 16)
                    .background(softGray)

                    Spacer()
                }
                .opacity(1.0 - headerOpacity) // Inverse of header opacity - shows when header is hidden
                .allowsHitTesting(headerOpacity < 0.5) // Only allow interaction when visible

                // ==========================================
                // PASS BUTTON - bottom left, slides with tab bar
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
                        .padding(.leading, 24)
                        .padding(.bottom, LayoutConstants.tabBarHeight + 16) // Position above tab bar
                        .offset(y: tabBarVisibility.isVisible ? 0 : LayoutConstants.tabBarHeight + 20) // Higher when tab bar is hidden
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarVisibility.isVisible)

                        Spacer()
                    }
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
        let forestGreen = Color("ForestGreen")
        
        VStack(spacing: 0) {
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

#Preview {
    DiscoverScreen()
}
