//
//  DiscoverScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

enum LookingFor: String {
    case dating
    case friends
    case both
}

struct Profile: Identifiable {
    let id: Int
    let name: String
    let age: Int
    let location: String
    let imageURL: String
    let bio: String
    let tags: [String]
    let verified: Bool
    let lifestyle: String
    let nextDestination: String
    let lookingFor: LookingFor
}

enum DiscoverMode {
    case dating
    case friends
}

struct DiscoverScreen: View {
    @State private var profiles: [Profile] = [
        Profile(
            id: 1,
            name: "Sarah",
            age: 28,
            location: "Big Sur, CA",
            imageURL: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaWdpdGFsJTIwbm9tYWQlMjBiZWFjaHxlbnwxfHx8fDE3Njg1MDYwNTJ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
            bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
            tags: ["Van Life", "Photography", "Surf", "Early Riser"],
            verified: true,
            lifestyle: "Van Life",
            nextDestination: "Portland, OR",
            lookingFor: .both
        ),
        Profile(
            id: 2,
            name: "Marcus",
            age: 31,
            location: "Austin, TX",
            imageURL: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3VudGFpbiUyMGhpa2luZyUyMGFkdmVudHVyZXxlbnwxfHx8fDE3NjgzODg4MDN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
            bio: "Software engineer working remotely from my Sprinter van. Building startups and climbing rocks.",
            tags: ["Remote Dev", "Van Life", "Rock Climbing", "Tech"],
            verified: true,
            lifestyle: "Digital Nomad",
            nextDestination: "Boulder, CO",
            lookingFor: .both
        ),
        Profile(
            id: 3,
            name: "Luna",
            age: 26,
            location: "Sedona, AZ",
            imageURL: "https://images.unsplash.com/photo-1638732984003-d2a05a69ebd6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkZXNlcnQlMjBsYW5kc2NhcGUlMjB0cmF2ZWxlcnxlbnwxfHx8fDE3Njg1MDYwNTN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
            bio: "Yoga instructor and writer. Desert lover seeking authentic connections and shared sunsets.",
            tags: ["Yoga", "Writing", "Meditation", "Desert Life"],
            verified: false,
            lifestyle: "Van Life",
            nextDestination: "Moab, UT",
            lookingFor: .dating
        ),
        Profile(
            id: 4,
            name: "Jake",
            age: 29,
            location: "Portland, OR",
            imageURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
            bio: "Outdoor enthusiast and coffee roaster. Always down for a weekend adventure or a chill camping trip.",
            tags: ["Camping", "Coffee", "Mountain Biking", "Chill Vibes"],
            verified: true,
            lifestyle: "Van Life",
            nextDestination: "Seattle, WA",
            lookingFor: .friends
        )
    ]
    
    @State private var currentIndex: Int = 0
    @State private var mode: DiscoverMode = .dating
    @State private var originalProfiles: [Profile] = []
    @State private var selectedProfile: Profile? = nil
    @State private var segmentIndex: Int = 0
    
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
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51) // Keep pink500 as is since it's not in assets
    
    private var currentCard: Profile? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }
    
    private func updateSegmentIndex() {
        segmentIndex = mode == .dating ? 0 : 1
    }
    
    private func handleSwipe(direction: SwipeDirection) {
        if currentIndex < profiles.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex += 1
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = 0
                profiles = originalProfiles
            }
        }
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
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
        .onAppear {
            originalProfiles = profiles
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
