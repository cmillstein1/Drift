//
//  ProfileCard.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

private struct InterestItem: Identifiable {
    let id: String
    let name: String

    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

// Custom shape for rounding only top corners
private struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ProfileCard: View {
    let profile: UserProfile
    let isTop: Bool
    let mode: DiscoverMode
    let scale: Double
    let offset: Double
    let onSwipe: (SwipeDirection) -> Void
    let onTap: () -> Void
    var onSwipeProgress: ((CGFloat) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    // Swipe threshold
    private let swipeThreshold: CGFloat = 120

    // Calculate swipe progress (-1 to 1, clamped)
    private var swipeProgress: CGFloat {
        min(max(dragOffset.width / swipeThreshold, -1), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            // Main scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Primary photo with name overlay
                    primaryPhotoSection(geometry: geometry)

                    // Bio section
                    if let bio = profile.bio {
                        bioSection(bio: bio)
                    }

                    // Additional photos with interests
                    additionalPhotosSection(geometry: geometry)

                    // Travel info section
                    travelSection

                    // Bottom padding for action buttons and tab bar
                    Spacer()
                        .frame(height: 180)
                }
            }
            .scrollDisabled(isDragging)
            .background(Color.white)
            .clipShape(TopRoundedRectangle(radius: 24))
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
            .offset(x: isTop ? dragOffset.width : 0)
            .rotationEffect(.degrees(isTop ? Double(dragOffset.width / 25) : 0))
            .simultaneousGesture(
                isTop ? DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only track horizontal movement if it's more horizontal than vertical
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)

                        if horizontalAmount > verticalAmount || isDragging {
                            isDragging = true
                            dragOffset.width = value.translation.width
                            // Report swipe progress
                            let progress = min(max(value.translation.width / swipeThreshold, -1), 1)
                            onSwipeProgress?(progress)
                        }
                    }
                    .onEnded { value in
                        if isDragging {
                            isDragging = false
                            if abs(value.translation.width) > swipeThreshold {
                                // Animate off screen
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset.width = value.translation.width > 0 ? 500 : -500
                                }
                                // Report full swipe progress
                                onSwipeProgress?(value.translation.width > 0 ? 1 : -1)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSwipe(value.translation.width > 0 ? .right : .left)
                                    dragOffset = .zero
                                    onSwipeProgress?(0)
                                }
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                }
                                onSwipeProgress?(0)
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                            onSwipeProgress?(0)
                        }
                    }
                : nil
            )
        }
    }

    // MARK: - Primary Photo Section

    @ViewBuilder
    private func primaryPhotoSection(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            // Photo
            AsyncImage(url: URL(string: profile.photos.first ?? profile.avatarUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
            .clipped()

            // Gradient overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .clear,
                    .black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Name, age, location overlay with verified badge
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(profile.displayName)
                        .font(.system(size: 28, weight: .bold))
                    if let age = profile.age {
                        Text("\(age)")
                            .font(.system(size: 28, weight: .regular))
                    }
                    if profile.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundColor(DriftUI.forestGreen)
                    }
                }
                .foregroundColor(.white)

                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                    Text(profile.location ?? "Unknown")
                        .font(.system(size: 16))
                }
                .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
    }

    // MARK: - Bio Section

    @ViewBuilder
    private func bioSection(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bio)
                .font(.system(size: 16))
                .foregroundColor(DriftUI.charcoal)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
    }

    // MARK: - Additional Photos Section

    @ViewBuilder
    private func additionalPhotosSection(geometry: GeometryProxy) -> some View {
        // Interest tags section
        if !profile.interests.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Interests")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DriftUI.charcoal.opacity(0.6))

                FlowLayout(data: profile.interests.prefix(6).map { InterestItem($0) }, spacing: 8) { item in
                    HStack(spacing: 6) {
                        if let emoji = DriftUI.emoji(for: item.name) {
                            Text(emoji)
                                .font(.system(size: 14))
                        }
                        Text(item.name)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DriftUI.charcoal.opacity(0.85))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white)
        }

        // Additional photos
        ForEach(Array(profile.photos.dropFirst().prefix(3).enumerated()), id: \.offset) { index, photoUrl in
            AsyncImage(url: URL(string: photoUrl)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width * 1.2)
            .clipped()
        }
    }

    // MARK: - Travel Section

    @ViewBuilder
    private var travelSection: some View {
        if profile.nextDestination != nil || profile.travelDates != nil || profile.travelPace != nil {
            VStack(alignment: .leading, spacing: 16) {
                Text("Travel Details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DriftUI.charcoal.opacity(0.6))

                if let nextDestination = profile.nextDestination {
                    HStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .font(.system(size: 16))
                            .foregroundColor(DriftUI.burntOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next destination")
                                .font(.system(size: 12))
                                .foregroundColor(DriftUI.charcoal.opacity(0.6))
                            Text(nextDestination)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DriftUI.charcoal)
                        }
                    }
                }

                if let travelDates = profile.travelDates {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(DriftUI.burntOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Travel dates")
                                .font(.system(size: 12))
                                .foregroundColor(DriftUI.charcoal.opacity(0.6))
                            Text(travelDates)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DriftUI.charcoal)
                        }
                    }
                }

                if let travelPace = profile.travelPace {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 16))
                            .foregroundColor(DriftUI.burntOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Travel pace")
                                .font(.system(size: 12))
                                .foregroundColor(DriftUI.charcoal.opacity(0.6))
                            Text(travelPace.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DriftUI.charcoal)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white)
        }
    }

}

// MARK: - Like Message Sheet

struct LikeMessageSheet: View {
    let profileName: String
    @Binding var message: String
    let onSend: () -> Void
    let onSkip: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Send a message with your like?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DriftUI.charcoal)

                Text("Stand out by saying something to \(profileName)")
                    .font(.system(size: 14))
                    .foregroundColor(DriftUI.charcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Message input
            TextField("Write a message (optional)", text: $message, axis: .vertical)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .lineLimit(3...5)
                .focused($isFocused)

            // Buttons
            HStack(spacing: 12) {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DriftUI.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button(action: onSend) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                        Text(message.isEmpty ? "Like" : "Send")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [DriftUI.burntOrange, Color(red: 0.93, green: 0.36, blue: 0.51)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    ProfileCard(
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
            interests: ["Photography", "Hiking", "Coffee", "Surfing", "Yoga", "Travel"],
            lookingFor: .both
        ),
        isTop: true,
        mode: .dating,
        scale: 1.0,
        offset: 0,
        onSwipe: { _ in },
        onTap: { }
    )
    .padding(.horizontal, 8)
    .background(Color("SoftGray"))
}
