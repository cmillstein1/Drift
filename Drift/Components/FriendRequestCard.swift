//
//  FriendRequestCard.swift
//  Drift
//
//  Created by Claude on 1/19/26.
//

import SwiftUI
import DriftBackend

struct FriendRequestCard: View {
    let friendRequest: Friend
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onViewProfile: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let burntOrange = Color("BurntOrange")

    private var profile: UserProfile? {
        friendRequest.requesterProfile
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Profile Image
                Button(action: onViewProfile) {
                    AsyncImage(url: URL(string: profile?.photos.first ?? profile?.avatarUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [skyBlue, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(profile?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [skyBlue, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(profile?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 56, height: 56)
                        }
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(profile?.displayName ?? "Unknown")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)

                        if profile?.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(forestGreen)
                        }
                    }

                    if let location = profile?.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(location)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(charcoalColor.opacity(0.6))
                    }

                    Text("Wants to connect")
                        .font(.system(size: 12))
                        .foregroundColor(burntOrange)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 8) {
                    // Decline
                    Button(action: onDecline) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // Accept
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        FriendRequestCard(
            friendRequest: Friend(
                id: UUID(),
                requesterId: UUID(),
                addresseeId: UUID(),
                status: .pending,
                requesterProfile: UserProfile(
                    id: UUID(),
                    name: "Sarah",
                    age: 28,
                    bio: "Van-lifer",
                    avatarUrl: nil,
                    location: "Big Sur, CA",
                    verified: true,
                    lifestyle: .vanLife,
                    nextDestination: nil,
                    interests: [],
                    lookingFor: .friends
                )
            ),
            onAccept: {},
            onDecline: {},
            onViewProfile: {}
        )
    }
    .padding()
    .background(Color("SoftGray"))
}
