//
//  FriendCard.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct FriendCardInterest: Identifiable {
    let id: String
    let label: String
    let emoji: String?
    let isExtra: Bool
    let isMutual: Bool

    init(_ label: String, isExtra: Bool = false, isMutual: Bool = false) {
        self.id = label
        self.label = label
        self.emoji = DriftUI.emoji(for: label)
        self.isExtra = isExtra
        self.isMutual = isMutual
    }
}

struct FriendCard: View {
    let profile: UserProfile
    let index: Int
    let opacity: Double
    let offset: CGFloat
    var mutualInterests: [String]
    var requestSent: Bool
    var onConnect: ((UUID) -> Void)?
    var onConnectWithMessage: ((UUID) -> Void)?

    init(profile: UserProfile, index: Int = 0, opacity: Double = 1.0, offset: CGFloat = 0, mutualInterests: [String] = [], requestSent: Bool = false, onConnect: ((UUID) -> Void)? = nil, onConnectWithMessage: ((UUID) -> Void)? = nil) {
        self.profile = profile
        self.index = index
        self.opacity = opacity
        self.offset = offset
        self.mutualInterests = mutualInterests
        self.requestSent = requestSent
        self.onConnect = onConnect
        self.onConnectWithMessage = onConnectWithMessage
    }

    // Use DriftUI design system colors
    private var charcoalColor: Color { DriftUI.charcoal }
    private var burntOrange: Color { DriftUI.burntOrange }
    private var forestGreen: Color { DriftUI.forestGreen }
    private var skyBlue: Color { DriftUI.skyBlue }
    private var desertSand: Color { DriftUI.desertSand }

    private var interestTags: [FriendCardInterest] {
        let maxVisible = 4
        let mutualSet = Set(mutualInterests)

        // Sort interests: mutual first, then others
        let sortedInterests = profile.interests.sorted { a, b in
            let aIsMutual = mutualSet.contains(a)
            let bIsMutual = mutualSet.contains(b)
            if aIsMutual != bIsMutual {
                return aIsMutual // mutual interests come first
            }
            return false // keep original order otherwise
        }

        var tags = sortedInterests.prefix(maxVisible).map { interest in
            FriendCardInterest(interest, isMutual: mutualSet.contains(interest))
        }
        let remaining = profile.interests.count - maxVisible
        if remaining > 0 {
            tags.append(FriendCardInterest("+\(remaining) more", isExtra: true))
        }
        return tags
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(alignment: .top, spacing: 16) {
                // Profile Image
                FriendCardImage(
                    imageUrl: profile.photos.first ?? profile.avatarUrl ?? "",
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

            // Tags (interests) - FlowLayout with max 4 visible + overflow indicator
            FlowLayout(data: interestTags, spacing: 6) { tag in
                InterestTag(
                    tag.label,
                    emoji: tag.isExtra ? nil : tag.emoji,
                    variant: tag.isExtra ? .extra : (tag.isMutual ? .highlighted : .default)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

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
                    if requestSent {
                        // Request Sent state
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .medium))

                            Text("Request Sent")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(forestGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .overlay(
                            Capsule()
                                .stroke(forestGreen, lineWidth: 2)
                        )
                        .clipShape(Capsule())
                    } else {
                        // Connect button (no message)
                        Button(action: {
                            if let onConnect = onConnect {
                                onConnect(profile.id)
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

                        // Connect with message button
                        Button(action: {
                            if let onConnectWithMessage = onConnectWithMessage {
                                onConnectWithMessage(profile.id)
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
    VStack(spacing: 16) {
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
            mutualInterests: ["Photography", "Surf"],
            requestSent: false
        )

        FriendCard(
            profile: UserProfile(
                id: UUID(),
                name: "Mike",
                age: 32,
                bio: "RV enthusiast",
                avatarUrl: nil,
                location: "Denver, CO",
                verified: false,
                lifestyle: .rvLife,
                nextDestination: nil,
                interests: ["Hiking", "Camping"],
                lookingFor: .friends
            ),
            mutualInterests: [],
            requestSent: true
        )
    }
    .padding()
    .background(Color("SoftGray"))
}
