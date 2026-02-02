//
//  DiscoverCard.swift
//  Drift
//
//  Reusable discover card: header (photo, name, age, last online, location, distance),
//  main photo, about me, 3 interests, next stop, travel pace, and Connect/Like + View Profile.
//

import SwiftUI
import UIKit
import DriftBackend

struct DiscoverCard: View {
    let profile: UserProfile
    var mode: DiscoverMode
    /// Last active time for "2h ago" style text; nil hides.
    var lastActiveAt: Date? = nil
    /// Distance in miles from current user; nil hides.
    var distanceMiles: Int? = nil
    var onPrimaryAction: (() -> Void)? = nil
    var onViewProfile: (() -> Void)? = nil
    /// When set, the card shows a report/block menu in the header; callback after block.
    var onBlockComplete: (() -> Void)? = nil

    private let softGray = Color("SoftGray")
    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let forestGreen = Color("ForestGreen")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)

    /// Same green gradient as the Friends segment in the mode switcher.
    private static let friendsGradient = LinearGradient(
        colors: [
            Color(red: 0.66, green: 0.77, blue: 0.84),  // Sky Blue
            Color(red: 0.33, green: 0.47, blue: 0.34)   // Forest Green
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private var primaryAccentGradient: LinearGradient {
        if mode == .dating {
            return LinearGradient(
                colors: [burntOrange, sunsetRose],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return Self.friendsGradient
    }

    private var primaryButtonTitle: String {
        mode == .dating ? "Like" : "Connect"
    }

    private var primaryButtonIcon: String {
        mode == .dating ? "heart.fill" : "person.badge.plus"
    }

    private var mainPhotoURL: String? {
        profile.photos.first ?? profile.avatarUrl
    }

    private var displayInterests: [String] {
        Array(profile.interests.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: profile photo, name, age, last online, location, distance, more
            HStack(alignment: .center, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    if let urlString = profile.avatarUrl ?? profile.photos.first, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                placeholderCircle
                            }
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } else {
                        placeholderCircle
                            .frame(width: 48, height: 48)
                    }
                    if profile.verified {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(forestGreen)
                            .background(Circle().fill(Color.white))
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(profile.displayName), \(profile.displayAge)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)
                        if lastActiveString != nil {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(charcoal.opacity(0.5))
                            Text(lastActiveString ?? "")
                                .font(.system(size: 12))
                                .foregroundColor(charcoal.opacity(0.6))
                        }
                    }
                    HStack(spacing: 4) {
                        Image("map_pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                        if let loc = profile.location {
                            Text(loc)
                                .font(.system(size: 12))
                        }
                        if distanceMiles != nil {
                            Text("•")
                                .font(.system(size: 12))
                            Text(distanceString)
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundColor(charcoal.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let onBlockComplete = onBlockComplete {
                    ReportBlockMenuButton(
                        userId: profile.id,
                        displayName: profile.displayName,
                        profile: profile,
                        onBlockComplete: onBlockComplete,
                        plainStyle: true
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)

            // Main photo (contained in card width)
            if let urlString = mainPhotoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderGradient
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 380)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture { onViewProfile?() }
            } else {
                placeholderGradient
                    .frame(height: 380)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                    )
                    .onTapGesture { onViewProfile?() }
            }

            // About me (bio)
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(charcoal)
                    .lineSpacing(8)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
            }

            // 3 interests
            if !displayInterests.isEmpty {
                HStack(spacing: 8) {
                    ForEach(displayInterests, id: \.self) { tag in
                        HStack(spacing: 4) {
                            if let emoji = DriftUI.emoji(for: tag) {
                                Text(emoji)
                                    .font(.system(size: 12))
                            }
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(charcoal)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(desertSand)
                        .overlay(
                            Capsule()
                                .strokeBorder(charcoal.opacity(0.1), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            // Next stop + travel pace
            HStack(spacing: 8) {
                if let next = profile.nextDestination, !next.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 10))
                        Text("Next: \(next)")
                            .font(.system(size: 12))
                    }
                }
                if profile.nextDestination != nil && profile.travelPace != nil {
                    Text("•")
                        .font(.system(size: 12))
                }
                if let pace = profile.travelPace {
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 10))
                        Text(pace.displayName)
                            .font(.system(size: 12))
                    }
                }
            }
            .foregroundColor(charcoal.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Primary button: full-width Like (dating) or Connect (friends)
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onPrimaryAction?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: primaryButtonIcon)
                        .font(.system(size: 16))
                    Text(primaryButtonTitle)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(primaryAccentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 999))
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var lastActiveString: String? {
        guard let date = lastActiveAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var distanceString: String {
        guard let mi = distanceMiles else { return "" }
        if mi == 1 { return "1 mi" }
        return "\(mi) mi"
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.gray.opacity(0.5))
            )
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.5, blue: 0.6),
                Color(red: 0.3, green: 0.4, blue: 0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Primary action button style (scale + animation)
private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview("Dating") {
    DiscoverCard(
        profile: UserProfile(
            id: UUID(),
            name: "Sarah",
            age: 28,
            bio: "Woke up to this view in Big Sur. Sometimes the best office has no walls 🌊",
            avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
            location: "Big Sur, CA",
            verified: true,
            lifestyle: .vanLife,
            travelPace: .moderate,
            nextDestination: "Portland, OR",
            interests: ["Photography", "Ocean Views", "Early Riser"],
            lookingFor: .dating
        ),
        mode: .dating,
        lastActiveAt: Date().addingTimeInterval(-7200),
        distanceMiles: 2
    )
    .padding()
    .background(Color("SoftGray"))
}

#Preview("Friends") {
    DiscoverCard(
        profile: UserProfile(
            id: UUID(),
            name: "Marcus",
            age: 31,
            bio: "Finished a client call then climbed this. Remote work hits different.",
            avatarUrl: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800",
            location: "Austin, TX",
            verified: true,
            travelPace: .fast,
            nextDestination: "Boulder, CO",
            interests: ["Rock Climbing", "Remote Work", "Adventure"],
            lookingFor: .friends
        ),
        mode: .friends,
        lastActiveAt: Date().addingTimeInterval(-3600 * 5),
        distanceMiles: 5
    )
    .padding()
    .background(Color("SoftGray"))
}
