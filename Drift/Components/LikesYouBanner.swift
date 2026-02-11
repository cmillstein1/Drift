//
//  LikesYouBanner.swift
//  Drift
//

import SwiftUI
import DriftBackend

struct LikesYouBanner: View {
    let count: Int
    let profiles: [UserProfile]
    let hasProAccess: Bool
    let onTap: () -> Void

    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoalColor = Color("Charcoal")

    /// Single avatar: profile photo (blurred when !hasProAccess) or neutral gray placeholder so we never show "glowing rings".
    @ViewBuilder
    private func avatarView(urlString: String, profile: UserProfile, hasProAccess: Bool) -> some View {
        let url = URL(string: urlString)
        let showBlur = !hasProAccess

        Group {
            if let url = url, !urlString.isEmpty {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipped()
                            .blur(radius: showBlur ? 12 : 0)
                    case .failure, .empty:
                        neutralPlaceholder(profile: profile)
                            .blur(radius: showBlur ? 12 : 0)
                    @unknown default:
                        neutralPlaceholder(profile: profile)
                            .blur(radius: showBlur ? 12 : 0)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                neutralPlaceholder(profile: profile)
                    .frame(width: 44, height: 44)
                    .blur(radius: showBlur ? 12 : 0)
                    .clipShape(Circle())
            }
        }
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private func neutralPlaceholder(profile: UserProfile) -> some View {
        Color(white: 0.75)
            .overlay(
                Text(profile.initials)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Stacked avatars: show actual profile photo, blurred when user doesn't have Drift Pro
                HStack(spacing: -12) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        let photoURL = profile.primaryDisplayPhotoUrl ?? ""
                        avatarView(urlString: photoURL, profile: profile, hasProAccess: hasProAccess)
                            .zIndex(Double(profiles.count - index))
                    }

                    if count > 3 {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [burntOrange, pink500],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text("+\(count - 3)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 1 ? "1 person likes you" : "\(count) people like you")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(charcoalColor)

                    Text(hasProAccess ? "Tap to see who" : "Upgrade to Drift Pro to see who")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(burntOrange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [burntOrange.opacity(0.5), pink500.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 6)
    }
}
