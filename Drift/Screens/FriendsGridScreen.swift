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
                    // Add mock friends for preview
                    await MainActor.run {
                        self.friends = createMockFriends()
                        self.isLoading = false
                    }
                    return
                }
                
                try await friendsManager.fetchFriends()
                
                // Extract profiles from friends
                let friendProfiles = friendsManager.friends.compactMap { friend -> UserProfile? in
                    friend.otherProfile(currentUserId: currentUserId)
                }
                
                await MainActor.run {
                    // If no friends, show mock data for preview
                    if friendProfiles.isEmpty {
                        self.friends = createMockFriends()
                    } else {
                        self.friends = friendProfiles
                    }
                    self.isLoading = false
                }
            } catch {
                print("Failed to load friends: \(error)")
                // Show mock friends on error for preview
                await MainActor.run {
                    self.friends = createMockFriends()
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createMockFriends() -> [UserProfile] {
        return [
            UserProfile(
                id: UUID(),
                name: "Sarah",
                age: 28,
                bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
                avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
                photos: [
                    "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
                    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800",
                    "https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800",
                    "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1472214103451-1944b5e71b8b?w=800"
                ],
                location: "Big Sur, CA",
                verified: true,
                lifestyle: .vanLife,
                nextDestination: "Portland, OR",
                travelDates: "March 15 - April 20",
                interests: ["Van Life", "Photography", "Surf", "Early Riser"],
                lookingFor: .friends,
                promptAnswers: [
                    DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "Waking up before sunrise, making pour-over coffee, and watching the fog roll over the ocean."),
                    DriftBackend.PromptAnswer(prompt: "The best trip I ever took was", answer: "Driving the entire Pacific Coast Highway from San Diego to Seattle. Two months of pure magic."),
                    DriftBackend.PromptAnswer(prompt: "I'm really good at", answer: "Finding the most epic sunrise spots and making friends with local surfers."),
                    DriftBackend.PromptAnswer(prompt: "You can find me on weekends", answer: "Chasing waves at sunrise, exploring hidden beaches, and capturing the perfect golden hour shot."),
                    DriftBackend.PromptAnswer(prompt: "I'm looking for someone who", answer: "Loves adventure as much as I do and isn't afraid to wake up early for a good sunrise."),
                    DriftBackend.PromptAnswer(prompt: "My ideal first date is", answer: "A sunrise hike followed by coffee at a local roastery, then exploring a new beach together.")
                ]
            ),
            UserProfile(
                id: UUID(),
                name: "Marcus",
                age: 31,
                bio: "Full-time RV life with my dog Max. Software developer working remotely from national parks.",
                avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                photos: [
                    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800",
                    "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800",
                    "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
                    "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800"
                ],
                location: "Yellowstone, WY",
                verified: true,
                lifestyle: .rvLife,
                nextDestination: "Grand Teton, WY",
                travelDates: "April 1 - May 15",
                interests: ["Coding", "Dogs", "National Parks", "Stargazing", "Hiking"],
                lookingFor: .friends,
                promptAnswers: [
                    DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "Stargazing with Max after a long day of coding. Nothing beats the Milky Way from a dark sky location."),
                    DriftBackend.PromptAnswer(prompt: "I'm really good at", answer: "Finding the perfect balance between work and adventure. My RV office has the best views."),
                    DriftBackend.PromptAnswer(prompt: "A life goal of mine is", answer: "Visiting all 63 US National Parks. Currently at 42 and counting!"),
                    DriftBackend.PromptAnswer(prompt: "You can find me on weekends", answer: "Hiking with Max, working on side projects, or finding the best remote work spots with WiFi and views."),
                    DriftBackend.PromptAnswer(prompt: "I'm looking for someone who", answer: "Appreciates both productivity and adventure, and doesn't mind a dog who thinks he's a person."),
                    DriftBackend.PromptAnswer(prompt: "My ideal first date is", answer: "A sunset hike followed by stargazing. I'll bring the telescope and Max will bring the enthusiasm.")
                ]
            ),
            UserProfile(
                id: UUID(),
                name: "Luna",
                age: 26,
                bio: "Yoga instructor and writer. Living nomadically and documenting my journey.",
                avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
                photos: [
                    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
                    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800",
                    "https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1511497584788-876760111969?w=800",
                    "https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=800"
                ],
                location: "Sedona, AZ",
                verified: false,
                lifestyle: .vanLife,
                nextDestination: "Moab, UT",
                travelDates: "May 1 - June 10",
                interests: ["Yoga", "Writing", "Meditation", "Hiking"],
                lookingFor: .friends,
                promptAnswers: [
                    DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "Morning yoga sessions on my van's rooftop with the desert sunrise as my backdrop."),
                    DriftBackend.PromptAnswer(prompt: "The best trip I ever took was", answer: "A solo journey through the Southwest that taught me the power of solitude and self-discovery."),
                    DriftBackend.PromptAnswer(prompt: "I'm currently reading/watching", answer: "Reading 'Wild' by Cheryl Strayed and watching documentaries about van life conversions."),
                    DriftBackend.PromptAnswer(prompt: "You can find me on weekends", answer: "Practicing yoga in nature, journaling at sunrise, or exploring new desert landscapes."),
                    DriftBackend.PromptAnswer(prompt: "I'm looking for someone who", answer: "Values mindfulness, respects my need for alone time, and loves deep conversations under the stars."),
                    DriftBackend.PromptAnswer(prompt: "My ideal first date is", answer: "A sunrise yoga session followed by a healthy breakfast and a hike to a beautiful viewpoint.")
                ]
            ),
            UserProfile(
                id: UUID(),
                name: "Jake",
                age: 29,
                bio: "Outdoor enthusiast and coffee connoisseur. Always looking for the next adventure.",
                avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
                photos: [
                    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800",
                    "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800"
                ],
                location: "Bend, OR",
                verified: true,
                lifestyle: .vanLife,
                nextDestination: "Crater Lake, OR",
                travelDates: "June 1 - July 15",
                interests: ["Camping", "Coffee", "Rock Climbing", "Photography"],
                lookingFor: .friends,
                promptAnswers: [
                    DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "Finding the perfect local coffee roaster in every new town I visit. I keep a detailed map of my favorites."),
                    DriftBackend.PromptAnswer(prompt: "I'm really good at", answer: "Rock climbing and finding hidden climbing spots. Always down for a climbing partner!"),
                    DriftBackend.PromptAnswer(prompt: "The best part of van life is", answer: "Waking up at a new crag, making coffee, and climbing all day. Pure freedom."),
                    DriftBackend.PromptAnswer(prompt: "You can find me on weekends", answer: "At the climbing gym or on a new route, always with a fresh cup of coffee in hand."),
                    DriftBackend.PromptAnswer(prompt: "I'm looking for someone who", answer: "Loves climbing as much as I do, or is willing to learn. Coffee appreciation is a bonus!"),
                    DriftBackend.PromptAnswer(prompt: "My ideal first date is", answer: "A morning climb followed by coffee at my favorite local roastery, then exploring the area together.")
                ]
            ),
            UserProfile(
                id: UUID(),
                name: "Emma",
                age: 27,
                bio: "Digital nomad and travel blogger. Sharing stories from the road.",
                avatarUrl: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800",
                photos: [
                    "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800",
                    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800",
                    "https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800",
                    "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800"
                ],
                location: "Asheville, NC",
                verified: true,
                lifestyle: .vanLife,
                nextDestination: "Great Smoky Mountains",
                travelDates: "July 1 - August 20",
                interests: ["Writing", "Photography", "Hiking", "Foodie"],
                lookingFor: .friends,
                promptAnswers: [
                    DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "Discovering hole-in-the-wall restaurants and food trucks. I document every amazing meal I find."),
                    DriftBackend.PromptAnswer(prompt: "The best trip I ever took was", answer: "A 6-month journey through the American Southwest, documenting the stories of fellow nomads I met along the way."),
                    DriftBackend.PromptAnswer(prompt: "I'm really good at", answer: "Finding the best local spots - whether it's food, hiking trails, or hidden gems. My blog readers trust my recommendations!"),
                    DriftBackend.PromptAnswer(prompt: "You can find me on weekends", answer: "Exploring farmers markets, trying new restaurants, or hiking to find the perfect spot for my next blog post."),
                    DriftBackend.PromptAnswer(prompt: "I'm looking for someone who", answer: "Loves food as much as I do and is always up for trying new places and sharing stories."),
                    DriftBackend.PromptAnswer(prompt: "My ideal first date is", answer: "A food tour of the area - hitting up the best local spots, food trucks, and maybe a farmers market.")
                ]
            ),
            UserProfile(
                id: UUID(),
                name: "Alex",
                age: 30,
                bio: "Adventure seeker and van builder. Customizing vans and exploring the country.",
                avatarUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800",
                photos: [
                    "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800",
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    "https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800",
                    "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800",
                    "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
                    "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800"
                ],
                location: "Denver, CO",
                verified: false,
                lifestyle: .vanLife,
                nextDestination: "Rocky Mountain NP",
                travelDates: "August 1 - September 15",
                interests: ["Van Building", "Woodworking", "Camping", "Mountain Biking"],
                lookingFor: .friends,
                promptAnswers: [
                    DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "The smell of fresh sawdust and the satisfaction of a perfectly executed woodworking project in my mobile workshop."),
                    DriftBackend.PromptAnswer(prompt: "I'm really good at", answer: "Building custom van conversions. I've helped over 20 people convert their vans into dream homes on wheels."),
                    DriftBackend.PromptAnswer(prompt: "A life goal of mine is", answer: "Starting a van conversion business that helps others achieve their nomadic dreams."),
                    DriftBackend.PromptAnswer(prompt: "You can find me on weekends", answer: "In my mobile workshop building something new, or out testing my latest van build on a mountain bike trail."),
                    DriftBackend.PromptAnswer(prompt: "I'm looking for someone who", answer: "Appreciates craftsmanship, loves adventure, and maybe wants to learn a thing or two about van building."),
                    DriftBackend.PromptAnswer(prompt: "My ideal first date is", answer: "A tour of my current van build project, followed by a mountain bike ride and beers at a local brewery.")
                ]
            )
        ]
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
                AsyncImage(url: URL(string: profile.photos.first ?? profile.avatarUrl ?? "")) { phase in
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
                        
                        if let age = profile.age {
                            Text(", \(age)")
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
