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

    // Colors matching HTML design
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50) // #6B7280
    private let tealPrimary = Color(red: 0.18, green: 0.83, blue: 0.75) // #2DD4BF

    private var interestTags: [FriendCardInterest] {
        let maxVisible = 3
        let mutualSet = Set(mutualInterests)

        let sortedInterests = profile.interests.sorted { a, b in
            let aIsMutual = mutualSet.contains(a)
            let bIsMutual = mutualSet.contains(b)
            if aIsMutual != bIsMutual {
                return aIsMutual
            }
            return false
        }

        var tags = sortedInterests.prefix(maxVisible).map { interest in
            FriendCardInterest(interest, isMutual: mutualSet.contains(interest))
        }
        return tags
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Content - Profile info row
            HStack(alignment: .top, spacing: 16) {
                // Profile Image (larger, 80x80 with rounded corners)
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: profile.photos.first ?? profile.avatarUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Online indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 4, y: 4)
                }

                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    // Name, age, verified badge
                    HStack(spacing: 6) {
                        Text(profile.displayName)
                            .font(.system(size: 18, weight: .bold))
                        if let age = profile.age {
                            Text(", \(age)")
                                .font(.system(size: 18, weight: .bold))
                        }
                        if profile.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .foregroundColor(inkMain)

                    // Location with teal icon
                    if let location = profile.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12))
                                .foregroundColor(tealPrimary)

                            Text(location)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(inkSub)
                        }
                    }

                    // Bio (2 lines max)
                    if let bio = profile.bio {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray.opacity(0.8))
                            .lineSpacing(4)
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                }

                Spacer()
            }
            .padding(16)

            // Interest tags row
            if !interestTags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(interestTags) { tag in
                        HStack(spacing: 4) {
                            if let emoji = tag.emoji {
                                Text(emoji)
                                    .font(.system(size: 12))
                            }
                            Text(tag.label)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color.gray.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            // Action button
            if requestSent {
                // Request Sent state - outlined teal
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Request Sent")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(tealPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(tealPrimary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tealPrimary, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else {
                // Connect button - gradient style
                Button(action: {
                    if let onConnect = onConnect {
                        onConnect(profile.id)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Connect")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.66, green: 0.77, blue: 0.84),  // #A8C5D6 Sky Blue
                                Color(red: 0.33, green: 0.47, blue: 0.34)   // #547756 Forest Green
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
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
