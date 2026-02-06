//
//  DiscoverCard.swift
//  Drift
//
//  Reusable discover card: main photo (full-bleed to top) with name/location overlay on bottom-left,
//  about me, 3 interests, next stop, travel pace, and Connect/interested + Pass + View Profile.
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
    /// Pass action (dating only); when set, card shows Pass button to the right of interested.
    var onPass: (() -> Void)? = nil
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
    private let actionButtonCornerRadius: CGFloat = 12

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
        mode == .dating ? "interested" : "Connect"
    }

    private var primaryButtonIcon: String {
        mode == .dating ? "leaf.fill" : "person.badge.plus"
    }

    private var mainPhotoURL: String? {
        profile.photos.first ?? profile.avatarUrl
    }

    private var displayInterests: [String] {
        Array(profile.interests.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main photo extends to top with name/location overlay on bottom-left
            let mainPhotoHeight: CGFloat = 420
            ZStack(alignment: .bottomLeading) {
                if let urlString = mainPhotoURL, let url = URL(string: urlString) {
                    GeometryReader { geo in
                        CachedAsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: mainPhotoHeight)
                                    .clipped()
                            } else {
                                placeholderGradient
                                    .frame(width: geo.size.width, height: mainPhotoHeight)
                            }
                        }
                    }
                    .frame(height: mainPhotoHeight)
                    .clipped()
                } else {
                    placeholderGradient
                        .frame(height: mainPhotoHeight)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }

                // Bottom gradient for text readability
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.7), location: 0.0),
                        .init(color: .clear, location: 0.5)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: mainPhotoHeight)
                .allowsHitTesting(false)

                // Name, age, last online, location, miles away on bottom-left
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 6) {
                        Text("\(profile.displayName), \(profile.displayAge)")
                            .font(.system(size: 28, weight: .heavy))
                            .tracking(-0.5)
                            .foregroundColor(.white)
                        if let lastActive = lastActiveString {
                            Text("•")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Text(lastActive)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        if profile.verified {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(forestGreen)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    HStack(spacing: 6) {
                        Image("map_pin_white")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                        if let loc = profile.location {
                            Text(loc)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                        }
                        if let miles = distanceMiles {
                            if profile.location != nil {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Text(miles == 1 ? "1 mi away" : "\(miles) mi away")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)

                // Report/block menu at top-right over photo
                if let onBlockComplete = onBlockComplete {
                    VStack {
                        HStack {
                            Spacer()
                            ReportBlockMenuButton(
                                userId: profile.id,
                                displayName: profile.displayName,
                                profile: profile,
                                onBlockComplete: onBlockComplete,
                                plainStyle: true
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        Spacer(minLength: 0)
                    }
                    .frame(height: mainPhotoHeight)
                }
            }
            .frame(height: mainPhotoHeight)
            .contentShape(Rectangle())
            .onTapGesture { onViewProfile?() }

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

            // Primary button: interested (dating) with leaf icon + Pass, or Connect (friends) full-width
            HStack(spacing: 12) {
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
                    .clipShape(RoundedRectangle(cornerRadius: actionButtonCornerRadius))
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: .infinity)

                if mode == .dating, onPass != nil {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onPass?()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(charcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(gray100)
                            .clipShape(RoundedRectangle(cornerRadius: actionButtonCornerRadius))
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
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
