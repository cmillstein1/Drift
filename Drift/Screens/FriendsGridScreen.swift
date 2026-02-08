//
//  FriendsGridScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Supabase
import Auth

struct FriendsGridScreen: View {
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    
    @State private var isLoading = true
    @State private var friends: [UserProfile] = []
    @State private var searchText = ""
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    
    private var filteredFriends: [UserProfile] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { friend in
            friend.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var currentUserInterests: [String] {
        supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
    }
    
    private func getMutualInterests(for profile: UserProfile) -> [String] {
        Set(currentUserInterests).intersection(Set(profile.interests)).map { $0 }
    }
    
    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(inkSub)
                        .font(.system(size: 16))
                    
                    TextField("Search friends...", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(inkMain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredFriends.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(inkSub)
                        Text(searchText.isEmpty ? "No friends yet" : "No friends found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(inkSub)
                    }
                    Spacer()
                } else {
                    // Friends Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                NavigationLink(value: friend) {
                                    FriendGridCard(profile: friend, mutualInterests: getMutualInterests(for: friend))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .clipped()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("My Friends")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(inkMain)
                    if !friends.isEmpty {
                        Text("\(friends.count) friend\(friends.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(inkSub)
                    }
                }
            }
        }
        .navigationDestination(for: UserProfile.self) { profile in
            FriendDetailView(
                profile: profile,
                mutualInterests: getMutualInterests(for: profile),
                requestSent: false,
                showConnectButton: false,
                isFromFriendsGrid: true,
                onConnect: nil,
                onMessage: { profileId in
                    // Handle message action
                }
            )
        }
        .onAppear {
            loadFriends()
        }
    }
    
    private func loadFriends() {
        isLoading = true
        Task {
            do {
                guard let currentUserId = supabaseManager.currentUser?.id else {
                    await MainActor.run {
                        self.friends = []
                        self.isLoading = false
                    }
                    return
                }

                try await friendsManager.fetchFriends()

                let friendProfiles = friendsManager.friends.compactMap { friend -> UserProfile? in
                    friend.otherProfile(currentUserId: currentUserId)
                }

                await MainActor.run {
                    self.friends = friendProfiles
                    self.isLoading = false
                }
            } catch {
                print("Failed to load friends: \(error)")
                await MainActor.run {
                    self.friends = []
                    self.isLoading = false
                }
            }
        }
    }
}

struct FriendGridCard: View {
    let profile: UserProfile
    let mutualInterests: [String]
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let desertSand = Color("DesertSand")
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Container - Fixed height to ensure even cards
            ZStack(alignment: .bottomLeading) {
                // Background placeholder to ensure consistent height
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                
                // Image container with proper clipping
                CachedAsyncImage(url: URL(string: profile.primaryDisplayPhotoUrl ?? "")) { phase in
                    Group {
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .contentShape(Rectangle())
                
                // Verified badge
                if profile.verified {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(forestGreen)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 20)
                                )
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                
                // Name and distance overlay
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(profile.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if profile.displayAge > 0 {
                            Text(", \(profile.displayAge)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    
                    if let location = profile.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 11))
                            Text(location)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.clear, lineWidth: 0)
            )
            
            // Shared interests badge
            if !mutualInterests.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(burntOrange)
                    Text("\(mutualInterests.count) shared")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(charcoalColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(burntOrange.opacity(0.1))
                .clipShape(Capsule())
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            
            // Interests tags
            if !profile.interests.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    let displayInterests = Array(profile.interests.prefix(2))
                    HStack(spacing: 6) {
                        ForEach(displayInterests, id: \.self) { interest in
                            HStack(spacing: 4) {
                                if let emoji = DriftUI.emoji(for: interest) {
                                    Text(emoji)
                                        .font(.system(size: 10))
                                }
                                Text(interest)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(charcoalColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(desertSand)
                            .clipShape(Capsule())
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if profile.interests.count > 2 {
                            Text("+\(profile.interests.count - 2)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.clear, lineWidth: 0)
        )
    }
}

#Preview {
    FriendsGridScreen()
}
