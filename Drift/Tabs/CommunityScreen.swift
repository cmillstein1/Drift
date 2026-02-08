//
//  CommunityScreen.swift
//  Drift
//
//  Builder Help: categories, help topics, Ask Question
//

import SwiftUI
import DriftBackend

// MARK: - Main Screen (Builder Help)

struct CommunityScreen: View {
    @State private var showCreateSheet: Bool = false
    @State private var showNotificationsSheet: Bool = false
    @State private var selectedPost: CommunityPost? = nil
    @State private var selectedBuilderHelpCategory: HelpCategory? = nil
    @State private var searchQuery: String = ""
    @StateObject private var communityManager = CommunityManager.shared
    @StateObject private var notificationsManager = NotificationsManager.shared
    @State private var lastDataFetch: Date = .distantPast

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private func loadData() {
        // Skip re-fetch if data is less than 30 seconds old
        guard Date().timeIntervalSince(lastDataFetch) > 30 else { return }
        Task {
            do {
                try await communityManager.fetchPosts(type: .help)
                await communityManager.subscribeToPosts()
                lastDataFetch = Date()
            } catch {
                print("Failed to load Builder Help data: \(error)")
            }
        }
    }

    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: Builder Help title, notifications, filter by category
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Builder Help")
                            .font(.campfire(.regular, size: 24))
                            .foregroundColor(charcoal)

                        Spacer()

                        Button {
                            showNotificationsSheet = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(charcoal)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)

                                if notificationsManager.unreadCount > 0 {
                                    Circle()
                                        .fill(burntOrange)
                                        .frame(width: 10, height: 10)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }

                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                }
                .background(softGray)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(charcoal.opacity(0.4))
                    TextField("Search help topics...", text: $searchQuery)
                        .font(.system(size: 16))
                        .foregroundColor(charcoal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(searchQuery.isEmpty ? Color.gray.opacity(0.2) : burntOrange, lineWidth: 2)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Builder Help content only
                builderHelpContent
            }
        }
        .onAppear {
            loadData()
        }
        .onDisappear {
            Task {
                await communityManager.unsubscribeFromAttendees()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCommunityPostSheet(restrictToPostType: .help)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showNotificationsSheet, onDismiss: {
            Task {
                await notificationsManager.fetchNotifications()
            }
        }) {
            NotificationsScreen()
        }
        .sheet(item: $selectedPost) { post in
            CommunityPostDetailSheet(initialPost: post)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Help posts for Builder Help section, optionally filtered by category and search
    private var helpPosts: [CommunityPost] {
        var result = communityManager.posts.filter { $0.type == .help }
        if let cat = selectedBuilderHelpCategory {
            result = result.filter { $0.helpCategory == cat }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.content.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    private var builderHelpContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Filter by category
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filter by category")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(charcoal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BuilderHelpCategoryButton(
                            name: "Electrical",
                            icon: "bolt.fill",
                            assetImageName: "electrical",
                            color: burntOrange,
                            isSelected: selectedBuilderHelpCategory == .electrical
                        ) { selectedBuilderHelpCategory = selectedBuilderHelpCategory == .electrical ? nil : .electrical }
                        BuilderHelpCategoryButton(
                            name: "Plumbing",
                            icon: "drop.fill",
                            assetImageName: "plumbing",
                            color: Color("SkyBlue"),
                            isSelected: selectedBuilderHelpCategory == .plumbing
                        ) { selectedBuilderHelpCategory = selectedBuilderHelpCategory == .plumbing ? nil : .plumbing }
                        BuilderHelpCategoryButton(
                            name: "General",
                            icon: "wrench.and.screwdriver.fill",
                            assetImageName: "general",
                            color: Color("ForestGreen"),
                            isSelected: selectedBuilderHelpCategory == .other
                        ) { selectedBuilderHelpCategory = selectedBuilderHelpCategory == .other ? nil : .other }
                    }
                }

                // Recent Help Topics + Ask Question
                HStack {
                    Text("Recent Help Topics")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(charcoal)
                    Spacer()
                    Button {
                        showCreateSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Ask Question")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(burntOrange)
                        .clipShape(Capsule())
                    }
                }

                if helpPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 40))
                            .foregroundColor(charcoal.opacity(0.3))
                        Text("No help topics yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(charcoal)
                        Text("Tap Ask Question to get help from the community.")
                            .font(.system(size: 14))
                            .foregroundColor(charcoal.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    VStack(spacing: 12) {
                        ForEach(helpPosts) { post in
                            BuilderHelpTopicCard(post: post)
                                .onTapGesture { selectedPost = post }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 120)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable {
            do {
                try await communityManager.fetchPosts(type: .help)
            } catch {
                print("[CommunityScreen] Builder Help refresh failed: \(error)")
            }
        }
    }
}

// MARK: - Builder Help Category Button

private struct BuilderHelpCategoryButton: View {
    let name: String
    let icon: String
    var assetImageName: String? = nil
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let asset = assetImageName {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("Charcoal"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Builder Help Topic Card

private struct BuilderHelpTopicCard: View {
    let post: CommunityPost
    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let burntOrange = Color("BurntOrange")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    private var categoryColor: Color {
        guard let cat = post.helpCategory else { return charcoal }
        return Color(cat.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: avatar, author, time, Solved badge
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    if let avatarUrl = post.author?.avatarUrl, let url = URL(string: avatarUrl) {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [desertSand, warmWhite],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(charcoal.opacity(0.5))
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [desertSand, warmWhite],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(charcoal.opacity(0.5))
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author?.name ?? "Anonymous")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(charcoal)
                        Text(post.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(charcoal.opacity(0.5))
                    }
                }
                Spacer()
                if post.isSolved == true {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Solved")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(forestGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(forestGreen.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 12)

            // Category tag
            if let category = post.helpCategory {
                Text(category == .other ? "General" : category.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor.opacity(0.15))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
            }

            // Title
            Text(post.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(charcoal)
                .lineSpacing(2)
                .padding(.bottom, 6)

            // Preview
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(charcoal.opacity(0.7))
                .lineLimit(2)
                .lineSpacing(2)
                .padding(.bottom, 16)

            // Footer
            Rectangle()
                .fill(softGray)
                .frame(height: 1)
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                    Text("\(post.replyCount)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.6))
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 14))
                    Text("\(post.likeCount)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.6))
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Community Post Card

struct CommunityPostCard: View {
    let post: CommunityPost
    @StateObject private var communityManager = CommunityManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    private var avatarBackgroundColor: Color {
        switch post.type {
        case .event: return Color.purple.opacity(0.15)
        case .help: return burntOrange.opacity(0.15)
        }
    }

    private var avatarIconColor: Color {
        switch post.type {
        case .event: return Color.purple
        case .help: return burntOrange
        }
    }

    private var badgeBackgroundColor: Color {
        switch post.type {
        case .event: return Color.purple.opacity(0.1)
        case .help: return burntOrange.opacity(0.1)
        }
    }

    private var typeIcon: String {
        switch post.type {
        case .event: return "calendar"
        case .help: return "wrench.and.screwdriver"
        }
    }

    private var typeLabel: String {
        switch post.type {
        case .event: return "EVENT"
        case .help: return "HELP"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post Header
            HStack(spacing: 12) {
                // Avatar with type-specific color
                if let avatarUrl = post.author?.avatarUrl, let url = URL(string: avatarUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(avatarIconColor)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(avatarBackgroundColor)
                            .frame(width: 44, height: 44)

                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(avatarIconColor)
                    }
                }

                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author?.name ?? "Anonymous")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(charcoal)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(post.timeAgo)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(charcoal.opacity(0.5))
                }

                Spacer()

                // Type Badge
                HStack(spacing: 6) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 12))
                    Text(typeLabel)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(avatarIconColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(badgeBackgroundColor)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoal)
                    .lineSpacing(2)

                Text(post.content)
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.7))
                    .lineSpacing(4)
                    .lineLimit(2)

                // Metadata Tags
                if post.eventLocation != nil || post.helpCategory != nil {
                    HStack(spacing: 8) {
                        if let location = post.eventLocation {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text(location)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(charcoal.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(softGray)
                            .clipShape(Capsule())
                        }

                        if let category = post.helpCategory {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 10))
                                Text(category.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(category.color))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(category.color).opacity(0.1))
                            .clipShape(Capsule())
                        }

                        // Event date badge
                        if let formattedDate = post.formattedEventDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(formattedDate)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Post Footer
            Rectangle()
                .fill(softGray)
                .frame(height: 1)

            HStack {
                // Engagement Stats
                HStack(spacing: 20) {
                    if post.replyCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 14))
                            Text("\(post.replyCount)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(charcoal.opacity(0.4))
                    }

                    Button {
                        Task {
                            try? await communityManager.togglePostLike(post.id)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: post.isLikedByCurrentUser == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 14))
                            Text("\(post.likeCount)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(post.isLikedByCurrentUser == true ? burntOrange : charcoal.opacity(0.4))
                    }
                }

                Spacer()

                // Action Button
                switch post.type {
                case .event:
                    Button {
                        Task {
                            if post.isAttendingEvent == true {
                                try? await communityManager.leaveEvent(post.id)
                            } else {
                                try? await communityManager.joinEvent(post.id)
                            }
                        }
                    } label: {
                        Text(post.isAttendingEvent == true ? "Joined" : "Join Event")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(post.isAttendingEvent == true ? charcoal : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(post.isAttendingEvent == true ? Color.clear : charcoal)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(charcoal, lineWidth: post.isAttendingEvent == true ? 2 : 0)
                            )
                    }

                case .help:
                    if post.isSolved == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Solved")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(forestGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(forestGreen.opacity(0.1))
                        .clipShape(Capsule())
                    } else {
                        Text("View")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                Capsule()
                                    .stroke(burntOrange, lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    CommunityScreen()
}
