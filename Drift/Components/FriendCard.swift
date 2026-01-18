//
//  FriendCard.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct FriendCard: View {
    let profile: UserProfile
    let index: Int
    let opacity: Double
    let offset: CGFloat
    var mutualInterests: [String]
    var onConnect: ((UUID) -> Void)?
    var onMessage: ((UUID) -> Void)?

    init(profile: UserProfile, index: Int = 0, opacity: Double = 1.0, offset: CGFloat = 0, mutualInterests: [String] = [], onConnect: ((UUID) -> Void)? = nil, onMessage: ((UUID) -> Void)? = nil) {
        self.profile = profile
        self.index = index
        self.opacity = opacity
        self.offset = offset
        self.mutualInterests = mutualInterests
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
                    imageUrl: profile.avatarUrl ?? "",
                    verified: profile.verified
                )

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text(profile.displayName)
                            if let age = profile.age {
                                Text(", \(age)")
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)

                        if let location = profile.location {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                Text(location)
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                    }

                    if let bio = profile.bio {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .lineLimit(2)
                    }

                    // Mutual Interests
                    if !mutualInterests.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(burntOrange)

                            Text("\(mutualInterests.count) shared interest\(mutualInterests.count > 1 ? "s" : "")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(burntOrange)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)

            // Tags (interests)
            HStack(spacing: 8) {
                ForEach(Array(profile.interests.prefix(3).enumerated()), id: \.offset) { _, interest in
                    Text(interest)
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(desertSand)
                        .clipShape(Capsule())
                        .fixedSize()
                        .lineLimit(1)
                }

                if profile.interests.count > 3 {
                    Text("+\(profile.interests.count - 3) more")
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
                    if let nextDestination = profile.nextDestination {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.6))

                            HStack(spacing: 0) {
                                Text("Next: ")
                                Text(nextDestination)
                                    .fontWeight(.medium)
                            }
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Show travel dates if available
                    if let travelDates = profile.travelDates {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.6))

                            Text(travelDates)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(charcoalColor)
                        }
                    }
                }

                // Action Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        if let onConnect = onConnect {
                            onConnect(profile.id)
                        } else {
                            print("Connected with: \(profile.displayName)")
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
                            print("Message: \(profile.displayName)")
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
        profile: UserProfile(
            id: UUID(),
            name: "Sarah",
            age: 28,
            bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
            avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
            location: "Big Sur, CA",
            verified: true,
            lifestyle: .vanLife,
            nextDestination: "Portland, OR",
            interests: ["Van Life", "Photography", "Surf", "Early Riser"],
            lookingFor: .friends
        ),
        mutualInterests: ["Photography", "Surf"]
    )
    .padding()
    .background(Color("SoftGray"))
}
