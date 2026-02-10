//
//  FriendsScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Auth

struct FriendsScreen: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var discoveryLocation = DiscoveryLocationProvider.shared

    @State private var isLoading = true
    @State private var lastDataFetch: Date = .distantPast
    @State private var swipedIds: [UUID] = []
    @State private var showMessageSheet = false
    @State private var selectedProfileForMessage: UserProfile? = nil
    @State private var friendRequestMessage = ""
    @State private var selectedProfile: UserProfile? = nil
    @State private var showFilterSheet = false
    @State private var filterPreferences = NearbyFriendsFilterPreferences.fromStorage()

    private var profiles: [UserProfile] {
        let raw = profileManager.discoverProfiles
        // Prefer device location for distance filter; fall back to profile's stored coords
        let lat = DiscoveryLocationProvider.shared.latitudeForFilter ?? profileManager.currentProfile?.latitude
        let lon = DiscoveryLocationProvider.shared.longitudeForFilter ?? profileManager.currentProfile?.longitude
        return raw.filter { filterPreferences.matches($0, currentUserLat: lat, currentUserLon: lon, routeCoordinates: []) }
    }

    private var currentUserInterests: [String] {
        supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
    }

    private func loadProfiles(force: Bool = false) {
        guard let currentUserId = supabaseManager.currentUser?.id else {
            isLoading = false
            return
        }
        guard force || Date().timeIntervalSince(lastDataFetch) > 30 else { return }
        isLoading = true
        Task {
            do {
                // Run independent fetches in parallel
                async let swipedTask = friendsManager.fetchSwipedUserIds()
                async let sentTask: () = friendsManager.fetchSentRequests()
                async let friendsTask: () = friendsManager.fetchFriends()
                async let blockedTask = (try? friendsManager.fetchBlockedExclusionUserIds()) ?? []

                swipedIds = try await swipedTask
                _ = try await sentTask
                _ = try await friendsTask
                let blockedIds = await blockedTask

                let friendIds = friendsManager.friends.map { friend in
                    friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId
                }
                let excludeIds = swipedIds + friendIds + blockedIds
                try await profileManager.fetchDiscoverProfiles(
                    lookingFor: .friends,
                    excludeIds: excludeIds
                )
                lastDataFetch = Date()
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

    private func handleConnectWithMessage(profile: UserProfile) {
        selectedProfileForMessage = profile
        friendRequestMessage = ""
        showMessageSheet = true
    }

    private func sendFriendRequestWithMessage() {
        guard let profile = selectedProfileForMessage else { return }
        Task {
            do {
                try await friendsManager.sendFriendRequest(to: profile.id, message: friendRequestMessage)
            } catch {
                print("Failed to send friend request: \(error)")
            }
        }
        showMessageSheet = false
        selectedProfileForMessage = nil
        friendRequestMessage = ""
    }
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    
    var body: some View {
        let main = NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
//                    HStack(alignment: .top) {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Nearby Friends")
//                                .font(.campfire(.regular, size: 24))
//                                .foregroundColor(charcoalColor)
//
////                            Text("Connect instantly - no matching required!")
////                                .font(.system(size: 14))
////                                .foregroundColor(charcoalColor.opacity(0.6))
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 24))
                            .foregroundColor(charcoalColor)
                            .symbolVariant(filterPreferences.hasActiveFilters ? .fill : .none)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Loading state
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Finding friends nearby...")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }

                    // Friends Cards
                    if !isLoading {
                        VStack(spacing: 16) {
                            ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                                NavigationLink(value: profile) {
                                    FriendCard(
                                        profile: profile,
                                        index: index,
                                        opacity: 1,
                                        offset: 0,
                                        mutualInterests: getMutualInterests(for: profile),
                                        requestSent: friendsManager.hasSentRequest(to: profile.id),
                                        onConnect: { profileId in
                                            handleConnect(profileId: profileId)
                                        },
                                        onConnectWithMessage: { _ in
                                            handleConnectWithMessage(profile: profile)
                                        },
                                        onTap: nil
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .animation(.easeOut(duration: 0.3), value: profiles.count)
                    }

                    // Empty state — Nobody_Nearby asset, campfire font, centered (like Messages empty state)
                    if profiles.isEmpty && !isLoading {
                        VStack(spacing: 0) {
                            Spacer()

                            VStack(spacing: 24) {
                                Image("Nobody_Nearby")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 280, maxHeight: 280)

                                VStack(spacing: 10) {
                                    Text(filterPreferences.hasActiveFilters ? "No one matches your filters" : "No friends nearby")
                                        .font(.campfire(.regular, size: 24))
                                        .foregroundColor(charcoalColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)

                                    Text(filterPreferences.hasActiveFilters ? "Try adjusting your filters" : "Check back later or expand your search radius")
                                        .font(.campfire(.regular, size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
                                        .padding(.horizontal, 32)
                                }
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Load More Button
                    if !profiles.isEmpty {
                        Button(action: {
                            loadProfiles(force: true)
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
                        if let profile = profiles.first(where: { $0.id == profileId }) {
                            handleConnectWithMessage(profile: profile)
                        }
                    }
                )
            }
            .onAppear {
                DiscoveryLocationProvider.shared.requestLocation()
                loadProfiles()
            }
        }
        return main
            .sheet(isPresented: $showFilterSheet) {
                NearbyFriendsFilterSheet(
                    isPresented: $showFilterSheet,
                    preferences: $filterPreferences
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: filterPreferences) { _, newPrefs in
                newPrefs.saveToStorage()
                loadProfiles(force: true)
            }
            .sheet(isPresented: $showMessageSheet) {
                FriendRequestMessageSheet(
                    profileName: selectedProfileForMessage?.displayName ?? "",
                    message: $friendRequestMessage,
                    onSend: sendFriendRequestWithMessage,
                    onSkip: {
                        if let profile = selectedProfileForMessage {
                            handleConnect(profileId: profile.id)
                        }
                        showMessageSheet = false
                        selectedProfileForMessage = nil
                        friendRequestMessage = ""
                    }
                )
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
    }
}

// MARK: - Friend Request Message Sheet

struct FriendRequestMessageSheet: View {
    let profileName: String
    @Binding var message: String
    let onSend: () -> Void
    let onSkip: () -> Void

    @FocusState private var isFocused: Bool

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Send a message with your request?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(charcoalColor)

                Text("Stand out by saying something to \(profileName)")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Message input
            TextField("Write a message (optional)", text: $message, axis: .vertical)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .lineLimit(3...5)
                .focused($isFocused)

            // Buttons
            HStack(spacing: 12) {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button(action: onSend) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
                        Text(message.isEmpty ? "Connect" : "Send")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [skyBlue, forestGreen]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    FriendsScreen()
}
