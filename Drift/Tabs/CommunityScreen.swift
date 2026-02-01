//
//  CommunityScreen.swift
//  Drift
//
//  Community feed combining activities, builder help, and marketplace
//

import SwiftUI
import DriftBackend

// MARK: - Filter Enum

enum CommunityFilter: String, CaseIterable {
    case all = "All"
    case events = "Events"
    case buildHelp = "Help"

    var icon: String {
        switch self {
        case .all: return ""
        case .events: return "tent"
        case .buildHelp: return "wrench.and.screwdriver"
        }
    }

    var postType: CommunityPostType? {
        switch self {
        case .all: return nil
        case .events: return .event
        case .buildHelp: return .help
        }
    }
}

// MARK: - Main Screen

struct CommunityScreen: View {
    @State private var selectedFilter: CommunityFilter = .all
    @State private var showCreateSheet: Bool = false
    @State private var showNotificationsSheet: Bool = false
    @State private var selectedPost: CommunityPost? = nil
    @StateObject private var communityManager = CommunityManager.shared
    @StateObject private var notificationsManager = NotificationsManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private func loadData() {
        Task {
            do {
                try await communityManager.fetchPosts(type: selectedFilter.postType)
                await communityManager.subscribeToPosts()
            } catch {
                print("Failed to load community data: \(error)")
            }
        }
    }

    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 20) {
                    // Title row with notifications and + buttons
                    HStack {
                        Text("Community")
                            //.font(.system(size: 32, weight: .bold))
                            .font(.campfire(.regular, size: 24))
                            .foregroundColor(charcoal)

                        Spacer()

                        // Notifications Button
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

                                // Unread badge
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

                        // Create Post Button
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: burntOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Tab Navigation - Pill style with sliding indicator
                    CommunitySegmentedControl(
                        selectedFilter: $selectedFilter
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(softGray)

                // Posts Feed
                List {
                    if filteredPosts.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray.opacity(0.4))
                            }

                            Text("No posts yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoal)

                            Text("Be the first to share something with the community!")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 400)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredPosts) { post in
                            Group {
                                if post.type == .event {
                                    EventCard(post: post)
                                } else {
                                    CommunityPostCard(post: post)
                                }
                            }
                            .onTapGesture {
                                selectedPost = post
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable {
                    do {
                        try await communityManager.fetchPosts(type: selectedFilter.postType)
                        print("[CommunityScreen] Refresh completed, posts count: \(communityManager.posts.count)")
                    } catch {
                        print("[CommunityScreen] Refresh failed: \(error)")
                    }
                }
            }

        }
        .onAppear {
            loadData()
            setupAttendeeRealtime()
            // Notifications are loaded by AppDataManager on init
        }
        .onDisappear {
            Task {
                await communityManager.unsubscribeFromAttendees()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCommunityPostSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showNotificationsSheet, onDismiss: {
            // Refresh notifications count after viewing
            Task {
                await notificationsManager.fetchNotifications()
            }
        }) {
            NotificationsScreen()
        }
        .sheet(item: $selectedPost) { post in
            if post.type == .event {
                EventDetailSheet(initialPost: post)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            } else {
                CommunityPostDetailSheet(initialPost: post)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            loadData()
        }
    }

    private func setupAttendeeRealtime() {
        Task {
            await communityManager.subscribeToMyAttendeeChanges()
        }
    }

    // Filtered posts based on selected filter
    private var filteredPosts: [CommunityPost] {
        // Filter is applied at fetch time, so just return all posts
        communityManager.posts
    }
}

// MARK: - Community Segmented Control

struct CommunitySegmentedControl: View {
    @Binding var selectedFilter: CommunityFilter
    @Namespace private var animation
    
    private let charcoal = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(CommunityFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        if !filter.icon.isEmpty {
                            Image(systemName: filter.icon)
                                .font(.system(size: 14))
                        }
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedFilter == filter ? .white : charcoal.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedFilter == filter {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(charcoal)
                                .matchedGeometryEffect(id: "communitySegment", in: animation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
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
                    AsyncImage(url: url) { image in
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
