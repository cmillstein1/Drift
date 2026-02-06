//
//  CommunityProfileGridCard.swift
//  Drift
//
//  Created by Casey Millstein on 2/4/26.
//

import SwiftUI
import DriftBackend

struct CommunityProfileGridCard: View {
    let profile: UserProfile
    let distanceMiles: Int?
    /// Interest names to show as segments (e.g. shared interests or profile.interests). When nil, uses profile.interests.
    var displayInterests: [String]? = nil
    var onTap: (() -> Void)? = nil

    private let forestGreen = Color("ForestGreen")

    // Fixed height for consistent card sizing
    private let imageHeight: CGFloat = 220

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Profile image
            CachedAsyncImage(url: URL(string: profile.photos.first ?? profile.avatarUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 32))
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: imageHeight, maxHeight: imageHeight)
            .clipped()
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Verified badge (top-right)
            if profile.verified {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(forestGreen)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                            )
                            .padding(8)
                    }
                    Spacer()
                }
            }

            // Name, age, location overlay (bottom-left) — bottom white section removed
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(profile.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if profile.displayAge > 0 {
                        Text(", \(profile.displayAge)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }

                if let location = profile.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 11))
                        if let miles = distanceMiles {
                            Text("\(miles) mi")
                                .font(.system(size: 11))
                        } else {
                            Text(location)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        CommunityProfileGridCard(
            profile: UserProfile(
                id: UUID(),
                name: "Sarah",
                age: 28,
                bio: "Van-lifer and photographer",
                avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
                photos: ["https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800"],
                location: "Big Sur, CA",
                verified: true,
                lifestyle: .vanLife,
                interests: ["Van Life", "Photography", "Surf"],
                lookingFor: .friends,
                promptAnswers: []
            ),
            distanceMiles: 12
        )

        CommunityProfileGridCard(
            profile: UserProfile(
                id: UUID(),
                name: "Marcus",
                age: 31,
                bio: "RV Life",
                avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                photos: ["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800"],
                location: "Yellowstone, WY",
                verified: false,
                lifestyle: .rvLife,
                interests: [],
                lookingFor: .friends,
                promptAnswers: []
            ),
            distanceMiles: nil
        )
    }
    .padding()
}
