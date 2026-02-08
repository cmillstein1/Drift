//
//  FriendRow.swift
//  Drift
//

import SwiftUI
import DriftBackend

struct FriendRow: View {
    let friend: Friend
    let currentUserId: UUID?
    let onTap: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    private var friendProfile: UserProfile? {
        guard let currentUserId = currentUserId else { return nil }
        if friend.requesterId == currentUserId {
            return friend.addresseeProfile
        } else {
            return friend.requesterProfile
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    CachedAsyncImage(url: URL(string: friendProfile?.primaryDisplayPhotoUrl ?? ""), targetSize: CGSize(width: 56, height: 56)) { phase in
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
                                    Text(friendProfile?.initials ?? "?")
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
                                    Text(friendProfile?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 56, height: 56)
                        }
                    }

                    // Friend Badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 20, height: 20)

                        Image(systemName: "person.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: -2, y: -2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(friendProfile?.displayName ?? "Friend")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoalColor)

                    Text("Tap to start chatting")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(forestGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
