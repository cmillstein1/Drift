//
//  DiscoverFullScreenProfileView.swift
//  Drift
//
//  Full-screen profile view with photo carousel and draggable bottom drawer.
//  Used in Discover screen for both dating and friends modes.
//

import SwiftUI
import DriftBackend

struct DiscoverFullScreenProfileView: View {
    let profile: UserProfile
    let mode: DiscoverMode
    var distanceMiles: Int?
    var lastActiveAt: Date?

    // Callbacks
    var onLike: (() -> Void)?
    var onPass: (() -> Void)?
    var onConnect: (() -> Void)?
    var onBlockComplete: (() -> Void)?

    @State private var currentPhotoIndex: Int = 0
    @State private var zoomedPhotoIndex: Int? = nil
    @State private var drawerExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var hasAppeared = false
    @StateObject private var scrollState = DiscoverScrollState()
    @State private var scrollOffsetY: CGFloat = 0
    @State private var travelStops: [DriftBackend.TravelStop] = []
    @State private var connectPressed: Bool = false
    @State private var likePressed: Bool = false
    @State private var passPressed: Bool = false
    @State private var showReportSheet: Bool = false

    // Colors
    private let softGray = Color("SoftGray")
    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let forestGreen = Color("ForestGreen")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)

    /// Collapsed drawer height (handle + name/buttons + padding)
    private let collapsedDrawerHeight: CGFloat = 140
    /// Expanded drawer stops below mode switcher (top ~120pt reserved)
    private let expandedDrawerTopInset: CGFloat = 120

    /// Friends gradient for connect button
    private static let friendsGradient = LinearGradient(
        colors: [
            Color(red: 0.66, green: 0.77, blue: 0.84),  // Sky Blue
            Color(red: 0.33, green: 0.47, blue: 0.34)   // Forest Green
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Dating gradient for interested button
    private var datingGradient: LinearGradient {
        LinearGradient(
            colors: [burntOrange, sunsetRose],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// All photos (deduplicated)
    private var photos: [String] {
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
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let expandedDrawerHeight = screenHeight - expandedDrawerTopInset
            let tabBarPadding = LayoutConstants.tabBarBottomPadding
            let totalCollapsed = collapsedDrawerHeight + tabBarPadding
            let totalExpanded = expandedDrawerHeight + safeAreaBottom

            ZStack(alignment: .bottom) {
                photoCarousel(geometry: geometry)
                bottomDrawer(
                    screenHeight: screenHeight,
                    totalCollapsedHeight: totalCollapsed,
                    totalExpandedHeight: totalExpanded,
                    safeAreaBottom: safeAreaBottom,
                    tabBarPadding: tabBarPadding,
                    scrollOffsetY: $scrollOffsetY
                )
            }
            .task {
                do {
                    travelStops = try await ProfileManager.shared.fetchTravelSchedule(for: profile.id)
                } catch {
                    print("Failed to load travel stops: \(error)")
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: scrollOffsetY) { _, y in
            scrollState.isAtTop = y >= -10
        }
    }

    // MARK: - Photo Carousel

    @ViewBuilder
    private func photoCarousel(geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        // Photo area fills the entire screen
        let photoAreaHeight = screenHeight

        ZStack(alignment: .top) {
            // Photo TabView - fills entire screen, extend into top safe area
            TabView(selection: $currentPhotoIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photoUrl in
                    Group {
                        if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                            CachedAsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: screenWidth, height: photoAreaHeight)
                                        .clipped()
                                } else if phase.error != nil {
                                    placeholderGradient
                                        .frame(width: screenWidth, height: photoAreaHeight)
                                } else {
                                    placeholderGradient
                                        .frame(width: screenWidth, height: photoAreaHeight)
                                        .overlay(ProgressView().tint(.white))
                                }
                            }
                        } else {
                            placeholderGradient
                                .frame(width: screenWidth, height: photoAreaHeight)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: screenWidth, height: photoAreaHeight)
            .ignoresSafeArea(edges: .top)
            .onTapGesture {
                zoomedPhotoIndex = currentPhotoIndex
            }

            // Overlay: pagination on top (bottom middle), travel + next destination underneath, left-aligned
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Pagination — on top, centered at bottom middle of photo area
                if photos.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<photos.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.45))
                                .frame(width: index == currentPhotoIndex ? 20 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPhotoIndex)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.35))
                            .background(Capsule().fill(.ultraThinMaterial.opacity(0.25)))
                    )
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 14)
                }

                // Travel pace + next destination — underneath pagination, left-aligned (soft shadow, no box)
                if profile.travelPace != nil || (profile.nextDestination.map { !$0.isEmpty } ?? false) {
                    HStack(spacing: 12) {
                        if let pace = profile.travelPace {
                            HStack(spacing: 5) {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 11))
                                Text(pace.displayName)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        }
                        if let next = profile.nextDestination, !next.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                                Text("Next: \(next)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 12)
                }

                // Space for drawer + tab bar
                Spacer().frame(height: collapsedDrawerHeight + LayoutConstants.tabBarBottomPadding + 20)
            }
            .frame(height: photoAreaHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fullScreenCover(isPresented: Binding(
            get: { zoomedPhotoIndex != nil },
            set: { if !$0 { zoomedPhotoIndex = nil } }
        )) {
            if let idx = zoomedPhotoIndex, idx < photos.count, let url = URL(string: photos[idx]) {
                DiscoverZoomablePhotoView(imageURL: url, onDismiss: { zoomedPhotoIndex = nil })
            } else {
                Color.clear
            }
        }
        .frame(height: photoAreaHeight)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Bottom Drawer (SnapChef-style: 1:1 height = baseHeight - dragOffset, UIKit pan)

    @ViewBuilder
    private func bottomDrawer(
        screenHeight: CGFloat,
        totalCollapsedHeight: CGFloat,
        totalExpandedHeight: CGFloat,
        safeAreaBottom: CGFloat,
        tabBarPadding: CGFloat,
        scrollOffsetY: Binding<CGFloat>
    ) -> some View {
        let baseHeight = drawerExpanded ? totalExpandedHeight : totalCollapsedHeight
        // 1:1 finger tracking: drag down (positive) = shorter, drag up (negative) = taller
        let currentHeight = max(totalCollapsedHeight, min(totalExpandedHeight, baseHeight - dragOffset))

        VStack(spacing: 0) {
            // Drag handle with UIKit pan overlay for smooth tracking (extended hit area)
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                Color.clear.frame(height: 12)
            }
            .frame(height: 36)
            .contentShape(Rectangle())
            .overlay {
                DiscoverPanGestureView(
                    scrollState: scrollState,
                    onChanged: { translation in
                        dragOffset = translation
                    },
                    onEnded: { translation in
                        handleDrawerDragEnd(translation, totalCollapsedHeight: totalCollapsedHeight, totalExpandedHeight: totalExpandedHeight)
                    }
                )
            }

            collapsedDrawerContent
                .padding(.horizontal, 20)

            if drawerExpanded {
                expandedDrawerContent(
                    safeAreaBottom: safeAreaBottom + tabBarPadding,
                    scrollOffsetY: scrollOffsetY,
                    scrollState: scrollState
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: currentHeight)
        .background(Color.white)
        .clipShape(DiscoverRoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
        .animation(hasAppeared ? .spring(response: 0.28, dampingFraction: 0.82) : nil, value: currentHeight)
        .animation(hasAppeared ? .spring(response: 0.28, dampingFraction: 0.82) : nil, value: drawerExpanded)
        .onAppear {
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
    }

    private func handleDrawerDragEnd(_ dragDistance: CGFloat, totalCollapsedHeight: CGFloat, totalExpandedHeight: CGFloat) {
        let threshold: CGFloat = 44
        let expand: Bool
        if abs(dragDistance) > threshold {
            expand = dragDistance < 0
        } else {
            expand = drawerExpanded
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            drawerExpanded = expand
            dragOffset = 0
        }
    }

    // MARK: - Collapsed Drawer Content (horizontal ellipsis above buttons; name not truncated)

    @ViewBuilder
    private var collapsedDrawerContent: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: Name, age + badge (one line) + location; right column is fixedSize so buttons never truncate
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(profile.displayName), \(profile.displayAge)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(inkMain)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if profile.verified {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(forestGreen)
                    }
                }
                if let location = profile.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(inkSub)
                        Text(location)
                            .font(.system(size: 14))
                            .foregroundColor(inkSub)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            // Right: Connect/heart/X; fixed size so never truncated when name is long
            VStack(alignment: .trailing, spacing: 8) {
                if mode == .dating {
                    HStack(spacing: 8) {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                likePressed = true
                            }
                            onLike?()
                        } label: {
                            if likePressed {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(datingGradient)
                                    .clipShape(Circle())
                                    .scaleEffect(1.15)
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(datingGradient)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(likePressed || passPressed)
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                passPressed = true
                            }
                            onPass?()
                        } label: {
                            if passPressed {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                                    .scaleEffect(1.1)
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(inkMain.opacity(0.6))
                                    .frame(width: 36, height: 36)
                                    .background(gray100)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(likePressed || passPressed)
                    }
                } else {
                    // Fixed frame so Connect → checkmark transition doesn't shift layout
                    HStack(spacing: 8) {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                connectPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                onConnect?()
                            }
                        } label: {
                            if connectPressed {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Self.friendsGradient)
                                    .clipShape(Circle())
                                    .scaleEffect(1.1)
                            } else {
                                Text("Connect")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(forestGreen)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(Capsule().stroke(forestGreen, lineWidth: 1.5))
                            }
                        }
                        .disabled(connectPressed || passPressed)

                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                passPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                onPass?()
                            }
                        } label: {
                            if passPressed {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                                    .scaleEffect(1.1)
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(inkMain.opacity(0.6))
                                    .frame(width: 36, height: 36)
                                    .background(gray100)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(connectPressed || passPressed)
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    // MARK: - Expanded Drawer Content

    @ViewBuilder
    private func expandedDrawerContent(
        safeAreaBottom: CGFloat,
        scrollOffsetY: Binding<CGFloat>,
        scrollState: DiscoverScrollState
    ) -> some View {
        ScrollViewWithOffset(contentOffsetY: scrollOffsetY, showsIndicators: false, scrollViewBackgroundColor: .white) {
            VStack(spacing: 0) {
                // 1. Photo grid FIRST (above lifestyle); tap = zoom + carousel index (sheet stays open)
                if photos.count > 1 {
                    photoGridSection()
                }

                // 2. Lifestyle section
                if profile.lifestyle != nil || profile.travelPace != nil || profile.workStyle != nil || profile.homeBase != nil || profile.morningPerson != nil {
                    lifestyleSection
                }

                // 3. About me
                if let bio = profile.bio, !bio.isEmpty {
                    sectionView(title: "About me") {
                        Text(bio)
                            .font(.system(size: 16))
                            .foregroundColor(inkMain)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Friends: rig, travel pace, next destination (no prompts)
                if mode == .friends {
                    if profile.rigInfo != nil && !profile.rigInfo!.isEmpty
                        || profile.travelPace != nil
                        || (profile.nextDestination != nil && !profile.nextDestination!.isEmpty) {
                        friendsTravelInfoSection
                    }
                }

                // 4. First prompt (dating only)
                if mode == .dating, let answers = profile.promptAnswers, !answers.isEmpty {
                    let firstPrompt = answers[0]
                    sectionView(title: firstPrompt.prompt) {
                        Text(firstPrompt.answer)
                            .font(.system(size: 16))
                            .foregroundColor(inkMain)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // 5. Travel plans (with matching header style)
                if !travelStops.isEmpty {
                    travelPlansSection
                }

                // 6. Second prompt (dating only)
                if mode == .dating, let answers = profile.promptAnswers, answers.count > 1 {
                    let secondPrompt = answers[1]
                    sectionView(title: secondPrompt.prompt) {
                        Text(secondPrompt.answer)
                            .font(.system(size: 16))
                            .foregroundColor(inkMain)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // 7. Interests (under photo / prominent for both modes)
                if !profile.interests.isEmpty {
                    interestsSection
                }

                // 8. Additional prompts (dating only)
                if mode == .dating, let answers = profile.promptAnswers, answers.count > 2 {
                    ForEach(Array(answers.dropFirst(2).enumerated()), id: \.offset) { _, promptAnswer in
                        sectionView(title: promptAnswer.prompt) {
                            Text(promptAnswer.answer)
                                .font(.system(size: 16))
                                .foregroundColor(inkMain)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // 9. Looking for
                lookingForSection

                // Report button at bottom of sheet
                Button {
                    showReportSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 14))
                        Text("Report")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(inkSub)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)

                // Bottom padding for safe area
                Color.clear.frame(height: safeAreaBottom + 20)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(
                targetName: profile.displayName,
                targetUserId: profile.id,
                profile: profile,
                onComplete: { didBlock in
                    if didBlock {
                        onBlockComplete?()
                    }
                }
            )
        }
    }

    // MARK: - Photo Grid Section (fixed-size cells; tap opens zoom)

    private static func photoGridCellSize(containerWidth: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 20
        let spacing: CGFloat = 8
        let totalSpacing = spacing * 2
        let availableWidth = containerWidth - (horizontalPadding * 2) - totalSpacing
        return availableWidth / 3
    }

    private static func photoGridHeight(photoCount: Int, containerWidth: CGFloat) -> CGFloat {
        let cellSize = photoGridCellSize(containerWidth: containerWidth)
        let spacing: CGFloat = 8
        let rows = (photoCount + 2) / 3
        return CGFloat(rows) * cellSize + CGFloat(max(0, rows - 1)) * spacing
    }

    @ViewBuilder
    private func photoGridSection(onPhotoTapped: (() -> Void)? = nil) -> some View {
        let containerWidth = UIScreen.main.bounds.width
        let cellSize = Self.photoGridCellSize(containerWidth: containerWidth)
        let gridHeight = Self.photoGridHeight(photoCount: photos.count, containerWidth: containerWidth)

        VStack(alignment: .leading, spacing: 12) {
            Text("PHOTOS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))
                .padding(.horizontal, 20)

            let columns = [
                GridItem(.fixed(cellSize), spacing: 8),
                GridItem(.fixed(cellSize), spacing: 8),
                GridItem(.fixed(cellSize), spacing: 8)
            ]

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photoUrl in
                    if let url = URL(string: photoUrl) {
                        CachedAsyncImage(url: url) { phase in
                            Group {
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    placeholderGradient
                                }
                            }
                            .frame(width: cellSize, height: cellSize)
                            .clipped()
                        }
                        .frame(width: cellSize, height: cellSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            currentPhotoIndex = index
                            zoomedPhotoIndex = index
                        }
                    }
                }
            }
            .frame(height: gridHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(softGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Section View

    @ViewBuilder
    private func sectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(softGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Friends Travel Info (rig, pace, next destination — no prompts)

    @ViewBuilder
    private var friendsTravelInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RIG & TRAVEL")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))

            VStack(alignment: .leading, spacing: 8) {
                if let rig = profile.rigInfo, !rig.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 14))
                            .foregroundColor(burntOrange)
                        Text(rig)
                            .font(.system(size: 16))
                            .foregroundColor(inkMain)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let pace = profile.travelPace {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 14))
                            .foregroundColor(burntOrange)
                        Text(pace.displayName)
                            .font(.system(size: 16))
                            .foregroundColor(inkMain)
                    }
                }
                if let next = profile.nextDestination, !next.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(burntOrange)
                        Text("Next: \(next)")
                            .font(.system(size: 16))
                            .foregroundColor(inkMain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(softGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Lifestyle Section

    @ViewBuilder
    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFESTYLE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))

            VStack(spacing: 0) {
                if let lifestyle = profile.lifestyle {
                    lifestyleRow(icon: "sparkles", iconColor: burntOrange, label: "LIFESTYLE", value: lifestyle.displayName)
                }
                if let pace = profile.travelPace {
                    lifestyleRow(icon: "car.fill", iconColor: forestGreen, label: "TRAVEL PACE", value: pace.displayName)
                }
                if let work = profile.workStyle {
                    lifestyleRow(icon: "briefcase", iconColor: inkMain, label: "WORK STYLE", value: work.displayName)
                }
                if let home = profile.homeBase, !home.isEmpty {
                    lifestyleRow(icon: "house", iconColor: inkMain, label: "HOME BASE", value: home)
                }
                if let morning = profile.morningPerson {
                    lifestyleRow(icon: morning ? "sun.max" : "moon.stars", iconColor: inkMain, label: "MORNING PERSON", value: morning ? "Yes" : "No")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(softGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Travel Plans Section (matching header style)

    @ViewBuilder
    private var travelPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRAVEL PLANS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))

            VStack(spacing: 8) {
                ForEach(travelStops) { stop in
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(burntOrange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.location)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(inkMain)
                            Text(stop.dateRange)
                                .font(.system(size: 12))
                                .foregroundColor(inkSub)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(softGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private func lifestyleRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.3)
                    .foregroundColor(inkMain.opacity(0.5))
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(inkMain)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Interests Section

    @ViewBuilder
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INTERESTS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))

            WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(profile.interests, id: \.self) { interest in
                    HStack(spacing: 4) {
                        if let emoji = DriftUI.emoji(for: interest) {
                            Text(emoji)
                                .font(.system(size: 12))
                        }
                        Text(interest)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(charcoal)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(desertSand)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(softGray)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Looking For Section

    @ViewBuilder
    private var lookingForSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LOOKING FOR")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(inkMain.opacity(0.6))
            Text(profile.lookingFor.displayName)
                .font(.system(size: 16))
                .foregroundColor(inkMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    // MARK: - Helpers

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Wrapping HStack

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
}

// MARK: - Discover Scale Button Style

private struct DiscoverScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Discover Rounded Corner Shape

private struct DiscoverRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview("Dating Mode") {
    DiscoverFullScreenProfileView(
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
            travelPace: .moderate,
            nextDestination: "Portland, OR",
            interests: ["Van Life", "Photography", "Surf", "Early Riser"],
            lookingFor: .dating
        ),
        mode: .dating,
        distanceMiles: 5,
        onLike: {},
        onPass: {},
        onBlockComplete: {}
    )
}

#Preview("Friends Mode") {
    DiscoverFullScreenProfileView(
        profile: UserProfile(
            id: UUID(),
            name: "Marcus",
            age: 31,
            bio: "Digital nomad exploring national parks. Remote work + outdoor adventures.",
            avatarUrl: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800",
            photos: [
                "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800"
            ],
            location: "Austin, TX",
            verified: true,
            lifestyle: .digitalNomad,
            travelPace: .fast,
            interests: ["Rock Climbing", "Remote Work", "Adventure"],
            lookingFor: .friends
        ),
        mode: .friends,
        distanceMiles: 12,
        onPass: {},
        onConnect: {},
        onBlockComplete: {}
    )
}
