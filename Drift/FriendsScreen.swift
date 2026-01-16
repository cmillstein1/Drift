//
//  FriendsScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct FriendsProfile: Identifiable {
    let id: Int
    let name: String
    let age: Int
    let distance: String
    let imageURL: String
    let bio: String
    let tags: [String]
    let verified: Bool
    let lifestyle: String
    let nextDestination: String
    let travelDates: String
    let mutualInterests: [String]
}

struct FriendsScreen: View {
    @State private var friendsProfiles: [FriendsProfile] = [
        FriendsProfile(
            id: 1,
            name: "Sarah",
            age: 28,
            distance: "2 mi",
            imageURL: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaWdpdGFsJTIwbm9tYWQlMjBiZWFjaHxlbnwxfHx8fDE3Njg1MDYwNTJ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
            bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
            tags: ["Van Life", "Photography", "Surf", "Early Riser"],
            verified: true,
            lifestyle: "Van Life",
            nextDestination: "Portland, OR",
            travelDates: "Jan 20-25",
            mutualInterests: ["Photography", "Surf"]
        ),
        FriendsProfile(
            id: 2,
            name: "Marcus",
            age: 31,
            distance: "5 mi",
            imageURL: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3VudGFpbiUyMGhpa2luZyUyMGFkdmVudHVyZXxlbnwxfHx8fDE3NjgzODg4MDN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
            bio: "Software engineer working remotely from my Sprinter van. Building startups and climbing rocks.",
            tags: ["Remote Dev", "Van Life", "Rock Climbing", "Tech"],
            verified: true,
            lifestyle: "Digital Nomad",
            nextDestination: "Boulder, CO",
            travelDates: "Feb 1-15",
            mutualInterests: ["Van Life", "Tech"]
        ),
        FriendsProfile(
            id: 4,
            name: "Jake",
            age: 29,
            distance: "12 mi",
            imageURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
            bio: "Outdoor enthusiast and coffee roaster. Always down for a weekend adventure or a chill camping trip.",
            tags: ["Camping", "Coffee", "Mountain Biking", "Chill Vibes"],
            verified: true,
            lifestyle: "Van Life",
            nextDestination: "Seattle, WA",
            travelDates: "Jan 25-30",
            mutualInterests: ["Coffee", "Camping"]
        ),
        FriendsProfile(
            id: 5,
            name: "Emma",
            age: 27,
            distance: "15 mi",
            imageURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
            bio: "Full-time traveler and content creator. Love meeting new people and finding hidden gems.",
            tags: ["Travel", "Content Creation", "Food", "Music"],
            verified: true,
            lifestyle: "Digital Nomad",
            nextDestination: "San Francisco, CA",
            travelDates: "Now - Feb 5",
            mutualInterests: ["Travel", "Music"]
        ),
        FriendsProfile(
            id: 6,
            name: "Chris",
            age: 30,
            distance: "18 mi",
            imageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
            bio: "Trail runner and nature photographer. Looking for hiking buddies and coworking partners.",
            tags: ["Trail Running", "Photography", "Coworking", "Nature"],
            verified: true,
            lifestyle: "Van Life",
            nextDestination: "Yosemite, CA",
            travelDates: "Jan 22-28",
            mutualInterests: ["Photography", "Nature"]
        ),
        FriendsProfile(
            id: 7,
            name: "Olivia",
            age: 25,
            distance: "22 mi",
            imageURL: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800",
            bio: "Freelance designer exploring the West Coast. Looking for coffee dates and coworking buddies.",
            tags: ["Design", "Coffee", "Art", "Coworking"],
            verified: true,
            lifestyle: "Digital Nomad",
            nextDestination: "Los Angeles, CA",
            travelDates: "Feb 10-20",
            mutualInterests: ["Coffee", "Art"]
        ),
        FriendsProfile(
            id: 8,
            name: "Liam",
            age: 32,
            distance: "25 mi",
            imageURL: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800",
            bio: "Adventure filmmaker capturing life on the road. Always looking for the next great story.",
            tags: ["Filmmaking", "Adventure", "Storytelling", "Camping"],
            verified: false,
            lifestyle: "Van Life",
            nextDestination: "Lake Tahoe, NV",
            travelDates: "Jan 28 - Feb 3",
            mutualInterests: ["Adventure", "Camping"]
        )
    ]
    
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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(charcoalColor)
                    
                    Text("Connect instantly - no matching required!")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 24)
                
                // Friends Cards
                VStack(spacing: 16) {
                    ForEach(Array(friendsProfiles.enumerated()), id: \.element.id) { index, profile in
                        FriendCard(
                            profile: profile,
                            index: index,
                            opacity: index < cardOpacities.count ? cardOpacities[index] : 0,
                            offset: index < cardOffsets.count ? cardOffsets[index] : 30
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
                // Load More Button
                Button(action: {
                    // TODO: Load more friends
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
                .padding(.bottom, 100)
            }
        }
        .background(softGray)
        .onAppear {
            // Initialize animation arrays
            cardOpacities = Array(repeating: 0, count: friendsProfiles.count)
            cardOffsets = Array(repeating: 30, count: friendsProfiles.count)
            
            // Animate cards with staggered delays (same as onboarding)
            for index in 0..<friendsProfiles.count {
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

struct FriendCard: View {
    let profile: FriendsProfile
    let index: Int
    let opacity: Double
    let offset: CGFloat
    var onConnect: ((Int) -> Void)?
    var onMessage: ((Int) -> Void)?
    
    init(profile: FriendsProfile, index: Int = 0, opacity: Double = 1.0, offset: CGFloat = 0, onConnect: ((Int) -> Void)? = nil, onMessage: ((Int) -> Void)? = nil) {
        self.profile = profile
        self.index = index
        self.opacity = opacity
        self.offset = offset
        self.onConnect = onConnect
        self.onMessage = onMessage
    }
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(alignment: .top, spacing: 16) {
                // Profile Image
                FriendCardImage(
                    imageUrl: profile.imageURL,
                    verified: profile.verified
                )
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(profile.name), \(profile.age)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "paperplane")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.6))
                            
                            Text("\(profile.distance) away")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                    }
                    
                    Text(profile.bio)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .lineLimit(2)
                    
                    // Mutual Interests
                    if !profile.mutualInterests.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(burntOrange)
                            
                            Text("\(profile.mutualInterests.count) shared interest\(profile.mutualInterests.count > 1 ? "s" : "")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(burntOrange)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            
            // Tags
            HStack(spacing: 8) {
                ForEach(Array(profile.tags.prefix(3).enumerated()), id: \.offset) { _, tag in
                    Text(tag)
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(desertSand)
                        .clipShape(Capsule())
                        .fixedSize()
                        .lineLimit(1)
                }
                
                if profile.tags.count > 3 {
                    Text("+\(profile.tags.count - 3) more")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                        .fixedSize()
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .fixedSize(horizontal: false, vertical: true)
            
            // Travel Info & Actions
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        HStack(spacing: 0) {
                            Text("Next: ")
                            Text(profile.nextDestination)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text(profile.travelDates)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(charcoalColor)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        if let onConnect = onConnect {
                            onConnect(profile.id)
                        } else {
                            print("Connected with: \(profile.name)")
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image("person_plus")
                                .resizable()
                                .frame(width: 16, height: 16)
                            
                            Text("Connect")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [skyBlue, forestGreen]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        if let onMessage = onMessage {
                            onMessage(profile.id)
                        } else {
                            print("Message: \(profile.name)")
                        }
                    }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .opacity(opacity)
        .offset(y: offset)
    }
}

// Profile image with verified badge for friend cards
struct FriendCardImage: View {
    let imageUrl: String
    let verified: Bool
    
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Profile Image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(softGray)
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Verified Badge
            if verified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(forestGreen)
                    .padding(2)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .offset(x: 4, y: -4)
            }
        }
        .frame(width: 96, height: 96)
    }
}

#Preview {
    FriendsScreen()
}
