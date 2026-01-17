//
//  FriendsScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

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

#Preview {
    FriendsScreen()
}
