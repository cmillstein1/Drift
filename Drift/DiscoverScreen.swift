//
//  DiscoverScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

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
            nextDestination: "Portland, OR"
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
            nextDestination: "Boulder, CO"
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
            nextDestination: "Moab, UT"
        )
    ]
    
    @State private var currentIndex: Int = 0
    @State private var originalProfiles: [Profile] = []
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                if currentIndex < profiles.count {
                    ZStack {
                        ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                            if index >= currentIndex && index < currentIndex + 2 {
                                let offset = index - currentIndex
                                let isTop = offset == 0
                                
                                ProfileCard(
                                    profile: profile,
                                    isTop: isTop,
                                    scale: 1.0 - Double(offset) * 0.05,
                                    offset: Double(offset) * -10
                                )
                                .zIndex(Double(profiles.count - index))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 100 - 16)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                } else {
                    VStack {
                        Spacer()
                        Text("No more profiles")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            originalProfiles = profiles
        }
    }
    
}

struct ProfileCard: View {
    let profile: Profile
    let isTop: Bool
    let scale: Double
    let offset: Double
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: profile.imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    ProgressView()
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                    .clipped()
                            case .failure:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                        .clipShape(
                            UnevenRoundedRectangle(
                                cornerRadii: RectangleCornerRadii(
                                    topLeading: 24,
                                    bottomLeading: 0,
                                    bottomTrailing: 0,
                                    topTrailing: 24
                                )
                            )
                        )
                        
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.black.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                        .clipShape(
                            UnevenRoundedRectangle(
                                cornerRadii: RectangleCornerRadii(
                                    topLeading: 24,
                                    bottomLeading: 0,
                                    bottomTrailing: 0,
                                    topTrailing: 24
                                )
                            )
                        )
                        
                        if profile.verified {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(forestGreen)
                                
                                Text("Verified")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.9))
                                    .background(.ultraThinMaterial)
                            )
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(profile.name), \(profile.age)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                
                                Text(profile.location)
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                        
                        Text(profile.bio)
                            .font(.system(size: 15))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .lineSpacing(4)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(profile.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(desertSand)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Text("Next:")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                            
                            Text(profile.nextDestination)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(burntOrange)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scaleEffect(scale)
            .offset(y: offset)
            .opacity(isTop ? 1.0 : 0.95)
        }
    }
}

#Preview {
    DiscoverScreen()
}
