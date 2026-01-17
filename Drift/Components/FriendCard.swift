//
//  FriendCard.swift
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
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                        Image(systemName: "message")
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

#Preview {
    FriendCard(
        profile: FriendsProfile(
            id: 1,
            name: "Sarah",
            age: 28,
            distance: "2 mi",
            imageURL: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55",
            bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
            tags: ["Van Life", "Photography", "Surf", "Early Riser"],
            verified: true,
            lifestyle: "Van Life",
            nextDestination: "Portland, OR",
            travelDates: "Jan 20-25",
            mutualInterests: ["Photography", "Surf"]
        )
    )
    .padding()
    .background(Color("SoftGray"))
}
