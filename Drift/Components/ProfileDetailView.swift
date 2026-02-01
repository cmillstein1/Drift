//
//  ProfileDetailView.swift
//  Drift
//
//  Full profile view matching Discover page design
//

import SwiftUI
import DriftBackend

struct ProfileDetailView: View {
    let profile: UserProfile
    @Binding var isOpen: Bool
    let onLike: () -> Void
    let onPass: () -> Void
    /// When true, show a back button at top left (e.g. when opened from message thread or Likes You).
    var showBackButton: Bool = false
    /// When true with showBackButton, still show Like and Pass buttons (e.g. when opened from Likes You).
    var showLikeAndPassButtons: Bool = false
    /// When set, shown next to location as "X miles away".
    var distanceMiles: Int? = nil

    @State private var imageIndex: Int = 0
    @State private var showFullScreenPhoto = false
    @State private var fullScreenPhotoIndex: Int = 0
    /// UIScrollView contentOffset.y: 0 at top, positive when scrolled down. Used to fade header.
    @State private var scrollContentOffsetY: CGFloat = 0
    @State private var travelStops: [DriftBackend.TravelStop] = []
    @Environment(\.dismiss) var dismiss

    private let profileHeaderCollapseThreshold: CGFloat = 72

    // Colors from Discover
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)
    private let gray700 = Color(red: 0.37, green: 0.37, blue: 0.42)
    private let softGray = Color("SoftGray")

    /// Profile photos only, deduplicated by URL (no avatar fallback mixed in; no duplicates).
    private var images: [String] {
        if profile.photos.isEmpty {
            return (profile.avatarUrl.map { [$0] } ?? []).filter { !$0.isEmpty }
        }
        var seen = Set<String>()
        return profile.photos.filter { url in
            guard !url.isEmpty else { return false }
            return seen.insert(url).inserted
        }
    }

    var body: some View {
        ZStack {
            (showBackButton ? softGray : Color.white).ignoresSafeArea()

            // Main scrollable content; ScrollViewWithOffset reports contentOffset.y so header fade works
            ScrollViewWithOffset(contentOffsetY: $scrollContentOffsetY, showsIndicators: false) {
                VStack(spacing: 0) {
                    if showBackButton {
                        Color.clear.frame(height: 79)
                    }
                    // Photo carousel at top (all photos, swipeable)
                    GeometryReader { geo in
                        let w = max(geo.size.width, 1)
                        ZStack(alignment: .topTrailing) {
                            ZStack(alignment: .bottom) {
                                TabView(selection: $imageIndex) {
                                    ForEach(Array(images.enumerated()), id: \.offset) { index, photoUrl in
                                        Group {
                                            if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                                                AsyncImage(url: url) { phase in
                                                    if let image = phase.image {
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: w, height: 500)
                                                    } else if phase.error != nil {
                                                        placeholderGradient
                                                    } else {
                                                        placeholderGradient
                                                            .overlay(ProgressView().tint(.white))
                                                    }
                                                }
                                                .frame(width: w, height: 500)
                                                .clipped()
                                            } else {
                                                placeholderGradient
                                                    .frame(width: w, height: 500)
                                            }
                                        }
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(width: w, height: 500)
                                .clipped()
                                .id(images.count)
                                .onTapGesture {
                                    fullScreenPhotoIndex = imageIndex
                                    showFullScreenPhoto = true
                                }

                                // Gradient and name overlay — fade out as user swipes to next photo
                                LinearGradient(
                                    stops: [
                                        .init(color: .black.opacity(0.8), location: 0.0),
                                        .init(color: .clear, location: 0.4)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(width: w, height: 500)
                                .opacity(imageIndex == 0 ? 1 : 0)
                                .animation(.easeInOut(duration: 0.25), value: imageIndex)
                                .allowsHitTesting(false)

                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(profile.displayName), \(profile.displayAge)")
                                        .font(.system(size: 36, weight: .heavy))
                                        .tracking(-0.5)
                                        .foregroundColor(.white)

                                    if let location = profile.location {
                                        HStack(spacing: 6) {
                                            Image("map_pin_white")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 14, height: 14)
                                            Text(location)
                                            if let miles = distanceMiles {
                                                Text("•")
                                                Text("\(miles) miles away")
                                            }
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    }

                                    HStack(spacing: 8) {
                                        ForEach(Array(profile.interests.prefix(2)), id: \.self) { interest in
                                            HStack(spacing: 4) {
                                                if let emoji = DriftUI.emoji(for: interest) {
                                                    Text(emoji).font(.system(size: 12))
                                                }
                                                Text(interest)
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.25))
                                            .clipShape(Capsule())
                                        }
                                        if let lastActive = lastActiveString(for: profile.lastActiveAt) {
                                            Text("Active \(lastActive)")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.white.opacity(0.25))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(24)
                                .opacity(imageIndex == 0 ? 1 : 0)
                                .animation(.easeInOut(duration: 0.25), value: imageIndex)
                                .allowsHitTesting(false)
                            }

                            // Custom pagination at top — capsule segments (active = opaque white, inactive = semi-transparent)
                            if images.count > 1 {
                                VStack {
                                    HStack(spacing: 6) {
                                        ForEach(Array(images.enumerated()), id: \.offset) { index, _ in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(index == imageIndex ? Color.white : Color.white.opacity(0.4))
                                                .frame(height: 4)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                                .allowsHitTesting(false)
                            }

                            HStack(alignment: .top) {
                                Spacer()
                                // Like button (hidden when opened from message; shown when from Likes You)
                                if !showBackButton || showLikeAndPassButtons {
                                    Button {
                                        onLike()
                                        dismiss()
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 56, height: 56)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                            }
                            .padding(.top, 12)
                            .padding(.trailing, 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 500)

                    // ==========================================
                    // ABOUT ME SECTION
                    // ==========================================
                    if let bio = profile.bio, !bio.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About me")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(inkMain)

                            Text(bio)
                                .font(.system(size: 18))
                                .foregroundColor(inkMain)
                                .lineSpacing(6)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: showBackButton ? 20 : 0))
                        .padding(.horizontal, showBackButton ? 16 : 0)
                        .padding(.top, showBackButton ? 16 : 0)
                    }

                    // ==========================================
                    // TRAVEL PLANS CARD
                    // ==========================================
                    if !travelStops.isEmpty {
                        TravelPlansCard(travelStops: travelStops)
                            .padding(.horizontal, showBackButton ? 16 : 0)
                            .padding(.top, showBackButton ? 12 : 0)
                    }

                    // ==========================================
                    // LIFESTYLE CARD
                    // ==========================================
                    if profile.lifestyle != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil {
                        LifestyleCard(
                            lifestyle: profile.lifestyle,
                            workStyle: profile.workStyle,
                            homeBase: profile.homeBase,
                            morningPerson: profile.morningPerson,
                            cornerRadius: 16
                        )
                        .padding(.horizontal, showBackButton ? 16 : 0)
                        .padding(.top, showBackButton ? 12 : 0)
                    }

                    // ==========================================
                    // INTERESTS CARD
                    // ==========================================
                    if !profile.interests.isEmpty {
                        InterestsCard(interests: profile.interests)
                            .padding(.horizontal, showBackButton ? 16 : 0)
                            .padding(.top, showBackButton ? 12 : 0)
                    }

                    // ==========================================
                    // PROMPT SECTION 1 - "My simple pleasure"
                    // ==========================================
//                    if let simplePleasure = profile.simplePleasure, !simplePleasure.isEmpty {
//                        HStack(spacing: 0) {
//                            Rectangle()
//                                .fill(coralPrimary)
//                                .frame(width: 4)
//
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("MY SIMPLE PLEASURE")
//                                    .font(.system(size: 12, weight: .bold))
//                                    .tracking(1)
//                                    .foregroundColor(coralPrimary)
//
//                                Text(simplePleasure)
//                                    .font(.system(size: 20, weight: .medium))
//                                    .foregroundColor(inkMain)
//                            }
//                            .padding(.leading, 16)
//                            .padding(.vertical, 4)
//
//                            Spacer()
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.vertical, 8)
//                        .background(Color.white)
//                    }

                    // Bottom padding for action buttons
                    Spacer().frame(height: 120)
                }
            }

            // ==========================================
            // FLOATING HEADER - close + menu (hidden when showBackButton); fades out when user scrolls up
            // ==========================================
            if !showBackButton {
                let fullscreenHeaderOpacity = scrollContentOffsetY <= 0 ? 1.0 : max(0, 1.0 - Double(scrollContentOffsetY) / Double(profileHeaderCollapseThreshold))
                VStack {
                    HStack {
                        Spacer()
                        ReportBlockMenuButton(
                            userId: profile.id,
                            displayName: profile.displayName,
                            onBlockComplete: { isOpen = false },
                            darkStyle: true
                        )
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .opacity(fullscreenHeaderOpacity)

                    Spacer()
                }
            }

            // ==========================================
            // PASS BUTTON - bottom left (hidden when opened from message; shown when from Likes You)
            // ==========================================
            if !showBackButton || showLikeAndPassButtons {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            onPass()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(Color.gray)
                                .frame(width: 64, height: 64)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
                        }

                        Spacer()
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 40)
                }
            }

        }
        .overlay(alignment: .top) {
            // PARALLAX HEADER (when opened from message or Likes You): back + menu; top padding respects safe area so button isn't hidden
            if showBackButton {
                ZStack(alignment: .top) {
                    // Expanded: back button + ReportBlockMenu — slide up and fade with scroll
                    let headerOffset = max(-80, min(0, -scrollContentOffsetY))
                    let headerOpacity = scrollContentOffsetY <= 0 ? 1.0 : max(0, 1.0 - Double(scrollContentOffsetY) / Double(profileHeaderCollapseThreshold))
                    HStack {
                        Button {
                            isOpen = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.leading, 24)
                        .padding(.vertical, 12)
                        .padding(.trailing, 8)
                        Spacer()
                        ReportBlockMenuButton(
                            userId: profile.id,
                            displayName: profile.displayName,
                            onBlockComplete: { isOpen = false },
                            plainStyle: true
                        )
                        .padding(.trailing, 24)
                    }
                    .padding(.top, 16)
                    .offset(y: headerOffset)
                    .opacity(headerOpacity)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            ProfilePhotoFullScreenView(
                imageUrls: images,
                initialIndex: fullScreenPhotoIndex,
                onDismiss: { showFullScreenPhoto = false }
            )
        }
        .task {
            // Load travel stops for this profile
            do {
                travelStops = try await ProfileManager.shared.fetchTravelSchedule(for: profile.id)
            } catch {
                print("Failed to load travel stops: \(error)")
            }
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Relative time string for last active (e.g. "2h ago", "1d ago").
    private func lastActiveString(for date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func lifestyleIcon(for lifestyle: Lifestyle) -> String {
        switch lifestyle {
        case .vanLife: return "car.side"
        case .rvLife: return "bus"
        case .digitalNomad: return "laptopcomputer"
        case .traveler: return "airplane"
        }
    }

    // Wrapping HStack for tags
    struct WrappingHStack: Layout {
        var alignment: HorizontalAlignment = .leading
        var horizontalSpacing: CGFloat = 8
        var verticalSpacing: CGFloat = 8

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let containerWidth = proposal.width ?? .infinity
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > containerWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }

            return CGSize(width: containerWidth, height: currentY + lineHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var currentX: CGFloat = bounds.minX
            var currentY: CGFloat = bounds.minY
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                    currentX = bounds.minX
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }
        }
    }

    // Lifestyle grid item for profile detail
    struct LifestyleGridItemView: View {
        let icon: String
        let label: String
        let value: String

        private let charcoal = Color("Charcoal")
        private let desertSand = Color("DesertSand")
        private let forestGreen = Color("ForestGreen")

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(forestGreen)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(charcoal.opacity(0.6))

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(desertSand.opacity(0.5))
        }
    }
}

// MARK: - Full-screen photo viewer
private struct ProfilePhotoFullScreenView: View {
    let imageUrls: [String]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int

    init(imageUrls: [String], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.imageUrls = imageUrls
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.2, blue: 0.25), Color(red: 0.15, green: 0.15, blue: 0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, photoUrl in
                    Group {
                        if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    placeholderGradient
                                } else {
                                    placeholderGradient
                                        .overlay(ProgressView().tint(.white))
                                }
                            }
                        } else {
                            placeholderGradient
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: imageUrls.count > 1 ? .automatic : .never))
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ProfileDetailView(
        profile: UserProfile(
            id: UUID(),
            name: "Sarah",
            age: 28,
            bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
            avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
            photos: [
                "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
                "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800",
                "https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800"
            ],
            location: "Big Sur, CA",
            verified: true,
            lifestyle: .vanLife,
            nextDestination: "Portland, OR",
            interests: ["Van Life", "Photography", "Surf", "Early Riser"],
            lookingFor: .dating,
            promptAnswers: [
                DriftBackend.PromptAnswer(prompt: "My simple pleasure is", answer: "Waking up before sunrise, making pour-over coffee, and watching the fog roll over the ocean."),
                DriftBackend.PromptAnswer(prompt: "The best trip I ever took was", answer: "Driving the entire Pacific Coast Highway from San Diego to Seattle. Two months of pure magic."),
                DriftBackend.PromptAnswer(prompt: "I'm really good at", answer: "Finding the most epic sunrise spots and making friends with local surfers.")
            ] as [DriftBackend.PromptAnswer]
        ),
        isOpen: .constant(true),
        onLike: {},
        onPass: {}
    )
}
