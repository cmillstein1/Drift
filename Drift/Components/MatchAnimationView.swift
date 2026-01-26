//
//  MatchAnimationView.swift
//  Drift
//
//  "It's a Match!" celebration overlay
//

import SwiftUI
import DriftBackend

struct MatchAnimationView: View {
    let matchedProfile: UserProfile
    let currentUserAvatarUrl: String?
    let onSendMessage: (String) -> Void
    let onKeepSwiping: () -> Void

    @State private var message: String = ""

    // Animation states
    @State private var viewOpacity: Double = 0
    @State private var showBadge = false
    @State private var showTitle = false
    @State private var showPhotos = false
    @State private var showCard = false
    @State private var showButtons = false
    @State private var heartScale: CGFloat = 0
    @State private var lineScale: CGFloat = 0
    @State private var leftPhotoOffset: CGFloat = -60
    @State private var rightPhotoOffset: CGFloat = 60
    @State private var closeButtonOpacity: Double = 0

    // Floating hearts animation
    @State private var floatingHearts: [FloatingHeart] = []
    @State private var sparkles: [Sparkle] = []
    @State private var showBackgroundEffects = false

    // Colors
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoal = Color("Charcoal")
    private let skyBlue = Color(red: 0.66, green: 0.77, blue: 0.84)
    private let forestGreen = Color(red: 0.33, green: 0.47, blue: 0.34)
    private let desertSand = Color(red: 0.96, green: 0.91, blue: 0.84)

    var body: some View {
        ZStack {
            // Background gradient (light theme)
            LinearGradient(
                gradient: Gradient(colors: [
                    softGray,
                    Color.white,
                    desertSand.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated background elements
            if showBackgroundEffects {
                ZStack {
                    // Soft gradient orbs
                    GradientOrb(
                        colors: [burntOrange.opacity(0.3), sunsetRose.opacity(0.3)],
                        size: 500,
                        position: CGPoint(x: UIScreen.main.bounds.width + 32, y: -32),
                        animationDuration: 4
                    )

                    GradientOrb(
                        colors: [skyBlue.opacity(0.3), forestGreen.opacity(0.3)],
                        size: 500,
                        position: CGPoint(x: -32, y: UIScreen.main.bounds.height + 32),
                        animationDuration: 5
                    )

                    // Floating hearts
                    ForEach(floatingHearts) { heart in
                        FloatingHeartView(heart: heart, sunsetRose: sunsetRose)
                    }

                    // Sparkles
                    ForEach(sparkles) { sparkle in
                        SparkleView(sparkle: sparkle, burntOrange: burntOrange)
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }

            // Close button - top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: onKeepSwiping) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoal.opacity(0.6))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .opacity(closeButtonOpacity)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                Spacer()
            }

            // Main Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 120)

                    // Match Header
                    VStack(spacing: 16) {
                        // "IT'S A MATCH" badge
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                            Text("IT'S A MATCH")
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(1)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [burntOrange, sunsetRose],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: burntOrange.opacity(0.3), radius: 12, x: 0, y: 6)
                        .scaleEffect(showBadge ? 1 : 0.5)
                        .opacity(showBadge ? 1 : 0)

                        // Title
                        VStack(spacing: 8) {
                            Text("You and \(matchedProfile.displayName) connected!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(charcoal)
                                .multilineTextAlignment(.center)

                            Text("Start a conversation and see where it goes")
                                .font(.system(size: 16))
                                .foregroundColor(charcoal.opacity(0.5))
                        }
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 10)
                    }
                    .padding(.horizontal, 24)

                    // Photo Display
                    ZStack {
                        // Connecting line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [burntOrange, sunsetRose, burntOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 96, height: 4)
                            .clipShape(Capsule())
                            .scaleEffect(x: lineScale, y: 1)

                        HStack(spacing: -20) {
                            // Current user photo
                            ProfileCircle(
                                imageUrl: currentUserAvatarUrl,
                                initials: nil,
                                gradientColors: [burntOrange, sunsetRose],
                                offsetX: 0
                            )
                            .offset(x: leftPhotoOffset)
                            .opacity(showPhotos ? 1 : 0)

                            // Matched user photo
                            ProfileCircle(
                                imageUrl: matchedProfile.photos.first ?? matchedProfile.avatarUrl,
                                initials: matchedProfile.initials,
                                gradientColors: [burntOrange, sunsetRose],
                                offsetX: 0
                            )
                            .offset(x: rightPhotoOffset)
                            .opacity(showPhotos ? 1 : 0)
                        }

                        // Heart in center
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                LinearGradient(
                                    colors: [burntOrange, sunsetRose],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: burntOrange.opacity(0.4), radius: 8, x: 0, y: 4)
                            .scaleEffect(heartScale)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // User Info Card with Message Input
                    VStack(spacing: 16) {
                        // User info card
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                // Small profile image
                                AsyncImage(url: URL(string: matchedProfile.photos.first ?? matchedProfile.avatarUrl ?? "")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        LinearGradient(
                                            colors: [burntOrange, sunsetRose],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .overlay(
                                            Text(matchedProfile.initials)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    }
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(matchedProfile.displayName)
                                            .font(.system(size: 20, weight: .bold))
                                        if let age = matchedProfile.age {
                                            Text(", \(age)")
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(charcoal)

                                    if let location = matchedProfile.location {
                                        HStack(spacing: 4) {
                                            Text("📍")
                                                .font(.system(size: 12))
                                            Text(location)
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(charcoal.opacity(0.5))
                                    }
                                }

                                Spacer()
                            }

                            // Message input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Send a message")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoal.opacity(0.7))

                                TextField("Say hi to \(matchedProfile.displayName)...", text: $message, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding(16)
                                    .background(softGray.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                        .opacity(showCard ? 1 : 0)
                        .offset(y: showCard ? 0 : 30)

                        // Action buttons
                        VStack(spacing: 12) {
                            // Send Message button
                            Button(action: {
                                onSendMessage(message)
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 18))
                                    Text("Send Message")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    LinearGradient(
                                        colors: [burntOrange, sunsetRose],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: burntOrange.opacity(0.25), radius: 12, x: 0, y: 6)
                            }
                            .opacity(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)

                            // Keep exploring button
                            Button(action: onKeepSwiping) {
                                Text("Keep exploring")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoal.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                            }
                        }
                        .opacity(showButtons ? 1 : 0)
                        .offset(y: showButtons ? 0 : 20)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .opacity(viewOpacity)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Fade in the entire view first
        withAnimation(.easeOut(duration: 0.3)) {
            viewOpacity = 1
        }

        // Show background effects
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            showBackgroundEffects = true
        }

        // Generate floating hearts (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            floatingHearts = (0..<8).map { i in
                FloatingHeart(
                    id: i,
                    startX: CGFloat(10 + i * 12),
                    delay: Double(i) * 0.15,
                    duration: 4 + Double.random(in: 0...2)
                )
            }
        }

        // Generate sparkles (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sparkles = (0..<12).map { i in
                Sparkle(
                    id: i,
                    targetX: 50 + (Double.random(in: 0...1) - 0.5) * 80,
                    targetY: 50 + (Double.random(in: 0...1) - 0.5) * 80,
                    delay: Double(i) * 0.08
                )
            }
        }

        // Show badge with spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            showBadge = true
        }

        // Show title
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            showTitle = true
        }

        // Show photos sliding in
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            showPhotos = true
            leftPhotoOffset = 0
            rightPhotoOffset = 0
        }

        // Show connecting line
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            lineScale = 1.0
        }

        // Show heart with bounce
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.7)) {
            heartScale = 1.0
        }

        // Show close button
        withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
            closeButtonOpacity = 1
        }

        // Show card sliding up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.85)) {
            showCard = true
        }

        // Show buttons
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.0)) {
            showButtons = true
        }
    }
}

// MARK: - Supporting Views

struct FloatingHeart: Identifiable {
    let id: Int
    let startX: CGFloat
    let delay: Double
    let duration: Double
}

struct FloatingHeartView: View {
    let heart: FloatingHeart
    let sunsetRose: Color

    @State private var animate = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 24))
            .foregroundColor(sunsetRose)
            .opacity(animate ? 0 : 0.4)
            .scaleEffect(animate ? 0.8 : 0)
            .rotationEffect(.degrees(animate ? 360 : 0))
            .offset(
                x: CGFloat(heart.startX / 100) * UIScreen.main.bounds.width,
                y: animate ? -UIScreen.main.bounds.height * 0.2 : UIScreen.main.bounds.height
            )
            .onAppear {
                withAnimation(
                    .easeOut(duration: heart.duration)
                    .delay(heart.delay)
                ) {
                    animate = true
                }
            }
    }
}

struct Sparkle: Identifiable {
    let id: Int
    let targetX: Double
    let targetY: Double
    let delay: Double
}

struct SparkleView: View {
    let sparkle: Sparkle
    let burntOrange: Color

    @State private var animate = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 16))
            .foregroundColor(burntOrange)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0 : 1)
            .position(
                x: animate ? CGFloat(sparkle.targetX / 100) * UIScreen.main.bounds.width : UIScreen.main.bounds.width / 2,
                y: animate ? CGFloat(sparkle.targetY / 100) * UIScreen.main.bounds.height : UIScreen.main.bounds.height / 2
            )
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5)
                    .delay(sparkle.delay)
                ) {
                    animate = true
                }
            }
    }
}

struct GradientOrb: View {
    let colors: [Color]
    let size: CGFloat
    let position: CGPoint
    let animationDuration: Double

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.2

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 60)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                    opacity = 0.3
                }
            }
    }
}

struct ProfileCircle: View {
    let imageUrl: String?
    let initials: String?
    let gradientColors: [Color]
    let offsetX: CGFloat

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.5

    var body: some View {
        ZStack {
            // Pulse effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 128, height: 128)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)

            // Photo
            Circle()
                .fill(Color.white)
                .frame(width: 128, height: 128)
                .overlay(
                    AsyncImage(url: URL(string: imageUrl ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let initials = initials {
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                Text(initials)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    }
                    .frame(width: 122, height: 122)
                    .clipShape(Circle())
                )
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
        .offset(x: offsetX)
        .onAppear {
            withAnimation(
                .easeOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.15
                pulseOpacity = 0
            }
        }
    }
}

#Preview {
    MatchAnimationView(
        matchedProfile: UserProfile(
            id: UUID(),
            name: "Sarah",
            age: 28
        ),
        currentUserAvatarUrl: nil,
        onSendMessage: { _ in },
        onKeepSwiping: {}
    )
}
