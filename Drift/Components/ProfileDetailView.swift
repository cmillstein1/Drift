//
//  ProfileDetailView.swift
//  Drift
//
//  Full profile view matching Discover page design (dating & friends parity).
//

import SwiftUI
import DriftBackend

/// Mode for the detail view: dating shows Like, friends shows Connect (same layout).
enum ProfileDetailMode {
    case dating
    case friends
}

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
    /// When .friends, show Connect button instead of Like (same layout as dating for parity).
    var detailMode: ProfileDetailMode = .dating
    /// Called when Connect is tapped (friends mode). When nil, Connect is hidden.
    var onConnect: (() -> Void)? = nil

    @State private var imageIndex: Int = 0
    @State private var showFullScreenPhoto = false
    @State private var fullScreenPhotoIndex: Int = 0
    /// UIScrollView contentOffset.y: 0 at top, positive when scrolled down. Used to fade header.
    @State private var scrollContentOffsetY: CGFloat = 0
    @State private var travelStops: [DriftBackend.TravelStop] = []
    /// When true, Like was tapped — play animation then dismiss.
    @State private var likeTriggered = false
    @Environment(\.dismiss) var dismiss

    private let profileHeaderCollapseThreshold: CGFloat = 72

    // Colors from Discover
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)
    private let gray700 = Color(red: 0.37, green: 0.37, blue: 0.42)
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let skyBlue = Color(red: 0.66, green: 0.77, blue: 0.84)
    private let forestGreen = Color("ForestGreen")
    private let desertSand = Color("DesertSand")

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

    /// Single section divider height for even spacing (dating, friends, messages).
    private let sectionDividerHeight: CGFloat = 12
    /// Vertical padding inside each section for even spacing.
    private let sectionVerticalPadding: CGFloat = 20

    /// When false (e.g. opened from message), layout is identical to discover; only the bottom bar is hidden.
    private var showsBottomBar: Bool { !showBackButton || showLikeAndPassButtons }

    /// Bottom padding total so "Looking for" scrolls fully into view; same scroll content height in all contexts.
    private let scrollBottomPaddingTotal: CGFloat = 96

    /// Max top inset for spacer; avoids huge gap when presented from map (nav stack reports inflated safe area).
    private let maxTopInsetForSpacer: CGFloat = 56

    var body: some View {
        GeometryReader { geometry in
            let rawTop = geometry.safeAreaInsets.top
            let topInset = min(rawTop, maxTopInsetForSpacer)
            // More space above photo so it isn’t cut off by status bar/Dynamic Island.
            // When opened from message (showBackButton), pull content up so top matches profile detail view.
            let extraAbovePhoto: CGFloat = showBackButton ? -28 : 28
            let topSpacerHeight = max(0, topInset + extraAbovePhoto)

            ZStack {
                // When no bottom bar (message), use white so no softgray strip at bottom; otherwise softGray
                (showsBottomBar ? softGray : Color.white)
                    .ignoresSafeArea()

                // Main scrollable content; ScrollViewWithOffset reports contentOffset.y so header fade works
                ScrollViewWithOffset(contentOffsetY: $scrollContentOffsetY, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top spacer so back button and carousel sit below status bar (safe-area aware)
                        Color.clear.frame(height: topSpacerHeight)
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
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("\(profile.displayName), \(profile.displayAge)")
                                            .font(.system(size: 36, weight: .heavy))
                                            .tracking(-0.5)
                                            .foregroundColor(.white)
                                        if profile.verified {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(forestGreen)
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        }
                                    }

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

                            // Top bar on photo: back/close left + photo page dots (when multiple photos)
                            VStack {
                                HStack(spacing: 12) {
                                    // Back / close (left) — same circular style in all contexts
                                    Button {
                                        if showBackButton {
                                            isOpen = false
                                        }
                                        dismiss()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.black.opacity(0.4))
                                            .clipShape(Circle())
                                    }
                                    Spacer()
                                    // Photo page indicators — subtle dots (tappable)
                                    if images.count > 1 {
                                        HStack(spacing: 5) {
                                            ForEach(Array(images.enumerated()), id: \.offset) { index, _ in
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        imageIndex = index
                                                    }
                                                } label: {
                                                    Circle()
                                                        .fill(index == imageIndex ? Color.white : Color.white.opacity(0.5))
                                                        .frame(width: 6, height: 6)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.black.opacity(0.18)))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 500)

                    // ==========================================
                    // PROFILE CONTENT (white block) — same layout for dating, friends, and messages (no redundant header)
                    // ==========================================
                    if profile.bio != nil && !profile.bio!.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About me")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(inkMain.opacity(0.6))
                                .tracking(0.3)
                            Text(profile.bio!)
                                .font(.system(size: 16))
                                .foregroundColor(inkMain)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, sectionVerticalPadding)
                        .padding(.bottom, sectionVerticalPadding)
                        .background(Color.white)
                        if !travelStops.isEmpty || profile.lifestyle != nil || profile.nextDestination != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil || !profile.interests.isEmpty {
                            softGray.frame(height: sectionDividerHeight)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // ==========================================
                    // TRAVEL PLANS CARD
                    // ==========================================
                    if !travelStops.isEmpty {
                        TravelPlansCard(travelStops: travelStops, cornerRadius: 0)
                        if profile.lifestyle != nil || profile.nextDestination != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil || !profile.interests.isEmpty {
                            softGray.frame(height: sectionDividerHeight)
                                .frame(maxWidth: .infinity)
                        }
                    } else if profile.lifestyle != nil || profile.nextDestination != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil || !profile.interests.isEmpty {
                        softGray.frame(height: sectionDividerHeight)
                            .frame(maxWidth: .infinity)
                    }

                    // ==========================================
                    // LIFESTYLE / NEXT STOP / WORK / HOME / MORNING (onboarding data)
                    // ==========================================
                    if profile.lifestyle != nil || profile.nextDestination != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil {

                        VStack(spacing: 0) {
                            if let lifestyle = profile.lifestyle {
                                lifestyleNextStopRow(
                                    iconBg: burntOrange.opacity(0.1),
                                    iconName: "sparkles",
                                    iconColor: burntOrange,
                                    label: "LIFESTYLE",
                                    value: lifestyle.displayName
                                )
                            }
                            if let next = profile.nextDestination, !next.isEmpty {
                                lifestyleNextStopRow(
                                    iconBg: skyBlue.opacity(0.2),
                                    iconName: "paperplane",
                                    iconColor: forestGreen,
                                    label: "NEXT STOP",
                                    value: next
                                )
                            }
                            if let work = profile.workStyle {
                                lifestyleNextStopRow(
                                    iconBg: inkMain.opacity(0.08),
                                    iconName: "briefcase",
                                    iconColor: inkMain,
                                    label: "WORK STYLE",
                                    value: work.displayName
                                )
                            }
                            if let home = profile.homeBase, !home.isEmpty {
                                lifestyleNextStopRow(
                                    iconBg: inkMain.opacity(0.08),
                                    iconName: "house",
                                    iconColor: inkMain,
                                    label: "HOME BASE",
                                    value: home
                                )
                            }
                            if let morning = profile.morningPerson {
                                lifestyleNextStopRow(
                                    iconBg: inkMain.opacity(0.08),
                                    iconName: morning ? "sun.max" : "moon.stars",
                                    iconColor: inkMain,
                                    label: "MORNING PERSON",
                                    value: morning ? "Yes" : "No"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, sectionVerticalPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)

                        if !profile.interests.isEmpty {
                            softGray.frame(height: sectionDividerHeight)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // ==========================================
                    // INTERESTS (onboarding tags)
                    // ==========================================
                    if !profile.interests.isEmpty {
                        let hasLifestyleBlock = profile.lifestyle != nil || profile.nextDestination != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil
                        if !hasLifestyleBlock {
                            softGray.frame(height: sectionDividerHeight)
                                .frame(maxWidth: .infinity)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("INTERESTS")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(inkMain.opacity(0.6))

                            WrappingHStack(horizontalSpacing: 10, verticalSpacing: 10) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(burntOrange)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(burntOrange.opacity(0.12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(burntOrange.opacity(0.28), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, sectionVerticalPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)

                        if profile.promptAnswers != nil && !profile.promptAnswers!.isEmpty {
                            softGray.frame(height: sectionDividerHeight)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // ==========================================
                    // PROMPTS (onboarding prompt answers)
                    // ==========================================
                    if let answers = profile.promptAnswers, !answers.isEmpty {
                        softGray.frame(height: sectionDividerHeight)
                            .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(answers.enumerated()), id: \.offset) { index, promptAnswer in
                                promptSection(question: promptAnswer.prompt, answer: promptAnswer.answer)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        softGray.frame(height: sectionDividerHeight)
                            .frame(maxWidth: .infinity)
                    }

                    // ==========================================
                    // LOOKING FOR (onboarding)
                    // ==========================================
                    if profile.promptAnswers == nil || profile.promptAnswers!.isEmpty {
                        softGray.frame(height: sectionDividerHeight)
                            .frame(maxWidth: .infinity)
                    }
                    lookingForSection
                    
                    // Bottom: with bar = padding above bar; without bar = minimal white footer (no softgray strip)
                    if showsBottomBar {
                        Color.clear.frame(height: scrollBottomPaddingTotal - 26)
                        Color.white.frame(height: 2)
                        Spacer().frame(height: 24)
                    } else {
                        // Enough white to avoid softgray strip; not so much it feels like "longer Looking for"
                        Color.white
                            .frame(height: 48)
                            .ignoresSafeArea(edges: .bottom)
                    }

                    // ==========================================
                    // Legacy simple pleasure (hidden; prompts use promptAnswers)
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

                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsBottomBar {
                    VStack(spacing: 0) {
                        if detailMode == .friends, let onConnect = onConnect {
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                onConnect()
                                withAnimation(.easeOut(duration: 0.25)) {
                                    isOpen = false
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Connect")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(forestGreen)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(LikeButtonStyle())
                        } else {
                            Button {
                                guard !likeTriggered else { return }
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                likeTriggered = true
                                withAnimation(.easeInOut(duration: 0.25)) { }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    onLike()
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isOpen = false
                                    }
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 18))
                                        .scaleEffect(likeTriggered ? 1.3 : 1.0)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: likeTriggered)
                                    Text("Like")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [burntOrange, sunsetRose],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .scaleEffect(likeTriggered ? 0.98 : 1.0)
                            }
                            .buttonStyle(LikeButtonStyle())
                            .disabled(likeTriggered)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
//                    .background(
//                        Color.white
//                            .frame(minHeight: 200)
//                            .offset(y: -2)
//                            .ignoresSafeArea(edges: .bottom)
//                    )
                }
            }

            }
            .opacity(likeTriggered ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: likeTriggered)
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
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Header section: avatar, name, age, location, distance, travel pace badge (match reference).
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    if let urlString = profile.avatarUrl ?? profile.photos.first, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Color.gray
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    if profile.verified {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(forestGreen)
                            .background(Circle().fill(Color.white).frame(width: 22, height: 22))
                            .offset(x: 4, y: 4)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(profile.displayName), \(profile.displayAge)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(inkMain)
                    if let location = profile.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 14))
                            Text(location)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(inkMain.opacity(0.6))
                    }
                    if distanceMiles != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 12))
                            Text("\(distanceMiles ?? 0) miles away")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(inkMain.opacity(0.6))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 12)
            if let pace = profile.travelPace {
                Text(pace.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(inkMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(desertSand))
            }
        }
        .padding(24)
    }

    /// Prompt Q&A block (onboarding prompt answers); no background (parent wraps in white).
    @ViewBuilder
    private func promptSection(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(inkMain)
            Text(answer)
                .font(.system(size: 16))
                .foregroundColor(inkMain)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, sectionVerticalPadding)
    }

    /// Looking For section (onboarding).
    @ViewBuilder
    private var lookingForSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LOOKING FOR")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(inkMain.opacity(0.6))
                .tracking(0.5)
            Text(profile.lookingFor.displayName)
                .font(.system(size: 16))
                .foregroundColor(inkMain)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, sectionVerticalPadding)
        .background(Color.white)
    }

    /// One row for Lifestyle or Next Stop (with even vertical spacing). icon in circle + label + value (match reference image).
    @ViewBuilder
    private func lifestyleNextStopRow(iconBg: Color, iconName: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconBg)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(inkMain.opacity(0.6))
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(inkMain)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
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

// MARK: - Message profile (same layout as ProfileDetailView; no bottom bar)

/// Profile detail when opened from a message. Hides tab bar, uses minimal top space, no bottom Like/Connect bar.
struct MessageProfileDetailView: View {
    let profile: UserProfile
    @Binding var isOpen: Bool
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    var body: some View {
        ProfileDetailView(
            profile: profile,
            isOpen: $isOpen,
            onLike: {},
            onPass: {},
            showBackButton: true,
            showLikeAndPassButtons: false
        )
        .onAppear {
            tabBarVisibility.isVisible = false
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
        }
    }
}

// MARK: - Like button press animation
private struct LikeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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
