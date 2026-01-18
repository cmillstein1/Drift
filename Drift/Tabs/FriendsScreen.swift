//
//  FriendsScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct FriendsScreen: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared

    private var profiles: [UserProfile] {
        profileManager.discoverProfiles
    }

    private var currentUserInterests: [String] {
        supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
    }

    private func loadProfiles() {
        Task {
            do {
                try await profileManager.fetchDiscoverProfiles(lookingFor: .friends)
            } catch {
                print("Failed to load friends profiles: \(error)")
            }
        }
    }

    private func getMutualInterests(for profile: UserProfile) -> [String] {
        Set(currentUserInterests).intersection(Set(profile.interests)).map { $0 }
    }

    private func handleConnect(profileId: UUID) {
        Task {
            do {
                _ = try await friendsManager.swipe(on: profileId, direction: .right)
            } catch {
                print("Failed to connect: \(error)")
            }
        }
    }
    
    @State private var cardOpacities: [Double] = []
    @State private var cardOffsets: [CGFloat] = []
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby Friends")
                        .font(.campfire(.regular, size: 24))
                        .foregroundColor(charcoalColor)

                    Text("Connect instantly - no matching required!")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Friends Cards
                VStack(spacing: 16) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        FriendCard(
                            profile: profile,
                            index: index,
                            opacity: index < cardOpacities.count ? cardOpacities[index] : 0,
                            offset: index < cardOffsets.count ? cardOffsets[index] : 30,
                            mutualInterests: getMutualInterests(for: profile),
                            onConnect: handleConnect
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                // Empty state
                if profiles.isEmpty && !profileManager.isLoading {
                    VStack(spacing: 8) {
                        Text("No friends nearby")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)

                        Text("Check back later or expand your search radius")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .padding(.horizontal, 16)
                }

                // Load More Button
                if !profiles.isEmpty {
                    Button(action: {
                        loadProfiles()
                    }) {
                        Text("Load More Friends")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }

                Spacer().frame(height: 100)
            }
        }
        .background(softGray)
        .onAppear {
            loadProfiles()
        }
        .onChange(of: profiles.count) { count in
            // Initialize animation arrays
            cardOpacities = Array(repeating: 0, count: count)
            cardOffsets = Array(repeating: 30, count: count)

            // Animate cards with staggered delays
            for index in 0..<count {
                withAnimation(.easeOut(duration: 0.4).delay(0.2 + Double(index) * 0.1)) {
                    if index < cardOpacities.count {
                        cardOpacities[index] = 1
                    }
                    if index < cardOffsets.count {
                        cardOffsets[index] = 0
                    }
                }
            }
        }
    }
}

#Preview {
    FriendsScreen()
}
