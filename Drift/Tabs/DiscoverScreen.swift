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

    @State private var swipedIds: [UUID] = []
    @State private var currentIndex: Int = 0
    @State private var mode: DiscoverMode = .dating
    @State private var selectedProfile: UserProfile? = nil
    @State private var segmentIndex: Int = 0
    @State private var showMatchAlert: Bool = false
    @State private var matchedProfile: UserProfile? = nil
    @State private var showLikePrompt: Bool = false
    @State private var likeMessage: String = ""
    @State private var swipeProgress: CGFloat = 0

    private var profiles: [UserProfile] {
        profileManager.discoverProfiles
    }
    
    private var segmentOptions: [SegmentOption] {
        [
            SegmentOption(
                id: 0,
                title: "Dating",
                icon: "heart.fill",
                activeGradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, pink500]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ),
            SegmentOption(
                id: 1,
                title: "Friends",
                icon: "person.2.fill",
                activeGradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        ]
    }
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)

    private var currentCard: UserProfile? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }

    private func updateSegmentIndex() {
        segmentIndex = mode == .dating ? 0 : 1
    }

    private func loadProfiles() {
        Task {
            do {
                // Fetch already swiped IDs
                swipedIds = try await friendsManager.fetchSwipedUserIds()

                // Fetch profiles based on mode
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

    private func handleSwipe(direction: SwipeDirection) {
        guard let profile = currentCard else { return }

        // Record the swipe in backend
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

                // Check if it's a match
                if let match = match {
                    await MainActor.run {
                        matchedProfile = match.otherUserProfile
                        showMatchAlert = true
                    }
                }
            } catch {
                print("Failed to record swipe: \(error)")
            }
        }

        // Move to next card
        if currentIndex < profiles.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex += 1
            }
        } else {
            // Reload profiles when deck is empty
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                loadProfiles()
            }
        }
    }

    @ViewBuilder
    private var datingCardStack: some View {
        ZStack {
            GeometryReader { geometry in
                if let profile = currentCard {
                    // Single card view - Hinge style (no stack peek)
                    ProfileCard(
                        profile: profile,
                        isTop: true,
                        mode: mode,
                        scale: 1.0,
                        offset: 0,
                        onSwipe: handleSwipe,
                        onTap: {
                            selectedProfile = profile
                        },
                        onSwipeProgress: { progress in
                            swipeProgress = progress
                        }
                    )
                    .padding(.horizontal, 8)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundColor(charcoalColor.opacity(0.3))

                        Text("No more profiles")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(charcoalColor)

                        Text("Check back later for new matches")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))

                        Button {
                            loadProfiles()
                        } label: {
                            Text("Refresh")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(DriftUI.burntOrange)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Fixed action buttons at bottom
            if currentCard != nil {
                VStack {
                    Spacer()
                    fixedActionButtons
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showLikePrompt) {
            LikeMessageSheet(
                profileName: currentCard?.displayName ?? "",
                message: $likeMessage,
                onSend: {
                    showLikePrompt = false
                    handleSwipe(direction: .right)
                    likeMessage = ""
                },
                onSkip: {
                    showLikePrompt = false
                    handleSwipe(direction: .right)
                    likeMessage = ""
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    // Scale factor for X button (scales up when swiping left)
    private var xButtonScale: CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.3
        // Negative swipe progress means swiping left
        let progress = max(-swipeProgress, 0)
        return baseScale + (maxScale - baseScale) * progress
    }

    // Scale factor for heart button (scales up when swiping right)
    private var heartButtonScale: CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.3
        // Positive swipe progress means swiping right
        let progress = max(swipeProgress, 0)
        return baseScale + (maxScale - baseScale) * progress
    }

    @ViewBuilder
    private var fixedActionButtons: some View {
        HStack {
            // Pass button (left)
            Button {
                handleSwipe(direction: .left)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(charcoalColor)
                    .frame(width: 56, height: 56)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(xButtonScale)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: swipeProgress)

            Spacer()

            // Like button (right)
            Button {
                showLikePrompt = true
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, pink500]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: burntOrange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(heartButtonScale)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: swipeProgress)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 100) // Space for tab bar
    }

    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()

            // Check discovery mode
            let discoveryMode = supabaseManager.getDiscoveryMode()

            if discoveryMode == .friends {
                // Friends only - show FriendsScreen directly
                FriendsScreen()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if discoveryMode == .dating {
                // Dating only - show dating cards directly without toggle
                VStack(spacing: 0) {
                    datingCardStack
                }
            } else {
                // Both - show segment toggle
                VStack(spacing: 0) {
                    // Mode Toggle
                    SegmentToggle(
                        options: segmentOptions,
                        selectedIndex: Binding(
                            get: { segmentIndex },
                            set: { newIndex in
                                segmentIndex = newIndex
                                mode = newIndex == 0 ? .dating : .friends
                            }
                        )
                    )
                    .frame(maxWidth: 448) // max-w-md equivalent
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                    // Content based on mode
                    .onChange(of: mode) { _ in
                        updateSegmentIndex()
                    }
                    .onAppear {
                        updateSegmentIndex()
                    }

                    if mode == .friends {
                        FriendsScreen()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        datingCardStack
                    }
                }
            }
        }
        .onAppear {
            // Load dating profiles on appear for dating modes
            // FriendsScreen handles its own loading when in "both" mode
            let discoveryMode = supabaseManager.getDiscoveryMode()
            if discoveryMode == .dating || (discoveryMode == .both && mode == .dating) {
                loadProfiles()
            }
        }
        .onChange(of: mode) { newMode in
            // Only load when switching to dating - FriendsScreen handles friends loading
            if newMode == .dating {
                loadProfiles()
            }
        }
        .alert("It's a Match!", isPresented: $showMatchAlert) {
            Button("Send Message") {
                // TODO: Navigate to messaging
            }
            Button("Keep Swiping", role: .cancel) {}
        } message: {
            if let profile = matchedProfile {
                Text("You and \(profile.displayName) liked each other!")
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
}

enum SwipeDirection {
    case left
    case right
    case up
}

#Preview {
    DiscoverScreen()
}
