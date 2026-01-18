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
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            // Check if user is friendsOnly - if so, show FriendsScreen directly
            if supabaseManager.isFriendsOnly() {
                FriendsScreen()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                    // Card Stack for Dating
                    GeometryReader { geometry in
                        HStack {
                            Spacer()
                            
                            if let card = currentCard {
                                ZStack {
                                    // Show up to 2 cards
                                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                                        if index >= currentIndex && index < currentIndex + 2 {
                                            let offset = index - currentIndex
                                            let isTop = offset == 0
                                            
                                            ProfileCard(
                                                profile: profile,
                                                isTop: isTop,
                                                mode: mode,
                                                scale: 1.0 - Double(offset) * 0.05,
                                                offset: Double(offset) * -10,
                                                onSwipe: handleSwipe,
                                                onTap: {
                                                    selectedProfile = profile
                                                }
                                            )
                                            .zIndex(Double(profiles.count - index))
                                        }
                                    }
                                }
                                .frame(width: min(448, geometry.size.width - 16))
                                .frame(height: geometry.size.height)
                            } else {
                                VStack {
                                    Spacer()
                                    Text("No more profiles")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .offset(y: -8)
                }
                }
            }
        }
        .onAppear {
            loadProfiles()
        }
        .onChange(of: mode) { _ in
            loadProfiles()
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
