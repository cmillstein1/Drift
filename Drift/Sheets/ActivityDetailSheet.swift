//
//  ActivityDetailSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import UIKit
import Auth
import DriftBackend

struct ActivityDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let activity: Activity
    @StateObject private var activityManager = ActivityManager.shared
    @State private var isJoined: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var selectedHostProfile: UserProfile? = nil
    var onActivityUpdated: (() -> Void)? = nil

    private var isHost: Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return false }
        return activity.hostId == userId
    }

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color(red: 0.45, green: 0.76, blue: 0.98)
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    /// Share button is visible when activity is public, or when the current user is the host (for private activities).
    private var canShowShareButton: Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }
        if activity.isPrivate {
            return activity.hostId == currentUserId
        }
        return true
    }

    var displayedAttendees: [ActivityAttendee] {
        activity.attendees?.filter { $0.status == .confirmed } ?? []
    }

    private var formattedDuration: String {
        guard let minutes = activity.durationMinutes else { return "TBD" }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) min"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            heroSection
            ScrollView(.vertical, showsIndicators: false) {
                scrollContent
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            bottomActionBar
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // Check if user is already attending
            isJoined = activityManager.isAttending(activity.id)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showEditSheet) {
            CreateActivitySheet(existingActivity: activity) { activityData in
                Task {
                    do {
                        try await handleUpdate(activityData)
                        await MainActor.run {
                            showEditSheet = false
                            onActivityUpdated?()
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $selectedHostProfile) { host in
            DatingProfileDetailView(
                profile: host,
                isOpen: Binding(
                    get: { selectedHostProfile != nil },
                    set: { if !$0 { selectedHostProfile = nil } }
                ),
                onLike: {},
                onPass: {},
                showBackButton: true,
                showLikeAndPassButtons: false
            )
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            heroImage
            heroGradientOverlay
            heroHeaderControls
            heroCategoryBadge
            heroTitleOverlay
        }
        .frame(height: 256)
    }

    private var heroImage: some View {
        CachedAsyncImage(url: URL(string: activity.imageUrl ?? "")) { phase in
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
                        .foregroundColor(.gray)
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: 256)
        .clipped()
    }

    private var heroGradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.2),
                Color.black.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 256)
    }

    private var heroHeaderControls: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoalColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            Spacer()
            if canShowShareButton {
                Button(action: { handleShare() }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoalColor)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var heroCategoryBadge: some View {
        VStack {
            HStack {
                Spacer()
                Text(activity.category.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 64)
            Spacer()
        }
    }

    private var heroTitleOverlay: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Button(action: {
                    if let host = activity.host { selectedHostProfile = host }
                }) {
                    HStack(spacing: 4) {
                        Text("Hosted by")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        Text(activity.host?.displayName ?? "Unknown")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Scroll Content
    private var scrollContent: some View {
        VStack(spacing: 0) {
            keyInfoCards
            locationCard
            descriptionSection
            imageAttributionSection
            attendeesSection
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .padding(.bottom, 120)
    }

    /// Unsplash attribution: show when we have an Unsplash image or stored attribution. Placed after description so it's visible.
    private var imageAttributionSection: some View {
        Group {
            if shouldShowUnsplashAttribution {
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(charcoalColor.opacity(0.12))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    unsplashAttributionView
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private var shouldShowUnsplashAttribution: Bool {
        let hasUnsplashImage = (activity.imageUrl ?? "").lowercased().contains("unsplash")
        let hasStoredAttribution = (activity.imageAttributionName ?? "").isEmpty == false
            || (activity.imageAttributionUrl ?? "").isEmpty == false
        return hasUnsplashImage || hasStoredAttribution
    }

    @ViewBuilder
    private var unsplashAttributionView: some View {
        if let name = activity.imageAttributionName, !name.isEmpty,
           let urlString = activity.imageAttributionUrl, !urlString.isEmpty,
           let url = URL(string: urlString) {
            Link(destination: url) {
                Text("Photo by \(name) on Unsplash")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        } else if let unsplashUrl = URL(string: "https://unsplash.com") {
            Link(destination: unsplashUrl) {
                Text("Photo from Unsplash")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var keyInfoCards: some View {
        HStack(alignment: .top, spacing: 16) {
            dateTimeCard
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            attendeesCard
                .frame(maxWidth: .infinity)
                .frame(height: 180)
        }
        .padding(.horizontal, 0)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    private var dateTimeCard: some View {
        infoCard(
            icon: "calendar",
            iconGradient: [burntOrange.opacity(0.1), sunsetRose.opacity(0.1)],
            iconColor: burntOrange,
            label: "DATE & TIME",
            title: activity.formattedDate,
            subtitle: formattedDuration,
            blurColors: [burntOrange.opacity(0.05), .clear]
        )
    }

    private var attendeesCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [forestGreen.opacity(0.1), skyBlue.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.2")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(forestGreen)
                }
                .padding(.bottom, 12)
                Text("ATTENDEES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .tracking(0.5)
                    .padding(.bottom, 6)
                Text("\(activity.currentAttendees) joined")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(charcoalColor)
                    .padding(.bottom, 8)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(
                                width: geometry.size.width * CGFloat(activity.currentAttendees) / CGFloat(max(activity.maxAttendees, 1)),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [forestGreen.opacity(0.05), .clear]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                ))
                .frame(width: 80, height: 80)
                .blur(radius: 20)
                .offset(x: 20, y: -20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
    }

    private func infoCard(
        icon: String,
        iconGradient: [Color],
        iconColor: Color,
        label: String,
        title: String,
        subtitle: String,
        blurColors: [Color]
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: iconGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .padding(.bottom, 12)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .tracking(0.5)
                    .padding(.bottom, 6)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(charcoalColor)
                    .padding(.bottom, 2)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: blurColors),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                ))
                .frame(width: 80, height: 80)
                .blur(radius: 20)
                .offset(x: 20, y: -20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
    }

    private var locationCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                            .shadow(color: burntOrange.opacity(0.2), radius: 8, x: 0, y: 4)
                        Image(systemName: "mappin")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Location")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoalColor)
                }
                Text(activity.location)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoalColor)
                HStack(spacing: 8) {
                    Circle()
                        .fill(burntOrange.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Text(activity.exactLocation ?? "Exact location shared after joining")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [burntOrange.opacity(0.05), .clear]),
                    startPoint: .bottomTrailing,
                    endPoint: .topLeading
                ))
                .frame(width: 128, height: 128)
                .blur(radius: 30)
                .offset(x: 40, y: 40)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
        .padding(.horizontal, 0)
        .padding(.bottom, 24)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [burntOrange, sunsetRose]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 4, height: 24)
                Text("About This Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)
            }
            Text(activity.description ?? "Join us for an amazing experience! This is a great opportunity to meet fellow travelers and create unforgettable memories. All skill levels welcome. Don't forget to bring water and good vibes!")
                .font(.system(size: 15))
                .foregroundColor(charcoalColor.opacity(0.7))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [forestGreen, skyBlue]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 4, height: 24)
                    Text("Who's Going")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoalColor)
                }
                Spacer()
                Text("\(activity.currentAttendees) \(activity.currentAttendees == 1 ? "person" : "people")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], alignment: .leading, spacing: 12) {
                ForEach(displayedAttendees) { attendee in
                    attendeeRow(attendee)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 0)
        .padding(.bottom, 0)
    }

    private func attendeeRow(_ attendee: ActivityAttendee) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: URL(string: attendee.profile?.avatarUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle().fill(Color.gray.opacity(0.2))
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                if attendee.profile?.verified == true {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(forestGreen)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            Text(attendee.profile?.displayName ?? "Unknown")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoalColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.2))
            HStack(spacing: 12) {
                Button(action: { handleMessage() }) {
                    Image(systemName: "message")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(burntOrange)
                        .frame(width: 48, height: 48)
                        .background(Color.clear)
                        .overlay(Circle().stroke(burntOrange, lineWidth: 2))
                }
                if isHost {
                    Button(action: { showEditSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                            Text("Edit")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, sunsetRose]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                } else {
                    Button(action: { handleJoin() }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        } else {
                            Text(isJoined ? "Leave Activity" : "Join Activity")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                    }
                    .background(
                        isJoined
                            ? LinearGradient(
                                gradient: Gradient(colors: [charcoalColor, charcoalColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .background(
                Color.white.opacity(0.95)
                    .background(.ultraThinMaterial)
            )
        }
    }

    private func handleJoin() {
        isLoading = true

        Task {
            do {
                if isJoined {
                    try await activityManager.leaveActivity(activity.id)
                } else {
                    try await activityManager.joinActivity(activity.id)
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isJoined.toggle()
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }

    private func handleShare() {
        let shareText = "\(activity.title) – \(activity.location) on \(activity.formattedDate)"
        let previewImage = sharePreviewImage()
        var activityItems: [Any] = [shareText]
        if let image = previewImage {
            activityItems.insert(image, at: 0)
        }
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
                  let rootVC = window.rootViewController else { return }
            var top = rootVC
            while let presented = top.presentedViewController { top = presented }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            top.present(activityVC, animated: true)
        }
    }

    /// Builds a preview image for the share sheet: icon and event name.
    private func sharePreviewImage() -> UIImage? {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1).setFill()
            ctx.fill(rect)
            let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
            if let symbol = UIImage(systemName: activity.category.icon, withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let symbolRect = CGRect(
                    x: (size.width - symbol.size.width) / 2,
                    y: (size.height - symbol.size.height) / 2 - 10,
                    width: symbol.size.width,
                    height: symbol.size.height
                )
                symbol.draw(in: symbolRect)
            }
            let maxTitleWidth = size.width - 12
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            let title = activity.title as NSString
            let titleSize = title.boundingRect(with: CGSize(width: maxTitleWidth, height: 24), options: .usesLineFragmentOrigin, attributes: attrs, context: nil).size
            let titleRect = CGRect(
                x: 6,
                y: size.height - titleSize.height - 12,
                width: maxTitleWidth,
                height: min(titleSize.height, 24)
            )
            title.draw(in: titleRect, withAttributes: attrs)
        }
        return image
    }

    private func handleMessage() {
        // TODO: Navigate to messaging with host
        print("Message host: \(activity.host?.displayName ?? "Unknown")")
    }

    private func handleUpdate(_ activityData: ActivityData) async throws {
        guard let activityId = activityData.activityId else { return }
        let category: ActivityCategory = {
            switch activityData.category {
            case "Outdoor": return .outdoor
            case "Work": return .work
            case "Social": return .social
            case "Food & Drink": return .foodDrink
            case "Wellness": return .wellness
            case "Adventure": return .adventure
            default: return activity.category
            }
        }()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateOnly = dateFormatter.date(from: activityData.date)
        let timeOnly = timeFormatter.date(from: activityData.time)
        var startsAt = activity.startsAt
        if let d = dateOnly, let t = timeOnly {
            let cal = Calendar.current
            let dateComps = cal.dateComponents([.year, .month, .day], from: d)
            let timeComps = cal.dateComponents([.hour, .minute], from: t)
            var comps = DateComponents()
            comps.year = dateComps.year
            comps.month = dateComps.month
            comps.day = dateComps.day
            comps.hour = timeComps.hour
            comps.minute = timeComps.minute
            if let combined = cal.date(from: comps) {
                startsAt = combined
            }
        }
        try await activityManager.updateActivity(
            activityId,
            title: activityData.title,
            description: activityData.description.isEmpty ? nil : activityData.description,
            category: category,
            location: activityData.location,
            startsAt: startsAt,
            maxAttendees: activityData.maxAttendees,
            isPrivate: activityData.privacy == .private
        )
    }
}

#Preview {
    ActivityDetailSheet(
        activity: Activity(
            hostId: UUID(),
            title: "Sunrise Hike",
            description: "Join us for an amazing sunrise hike! This is a great opportunity to meet fellow travelers and create unforgettable memories. All skill levels welcome. Don't forget to bring water and good vibes!",
            category: .outdoor,
            location: "Big Sur Trail",
            exactLocation: "Trailhead parking lot",
            imageUrl: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800",
            startsAt: Date().addingTimeInterval(86400),
            durationMinutes: 120,
            maxAttendees: 8,
            currentAttendees: 4
        )
    )
}
