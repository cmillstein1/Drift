//
//  NotificationsScreen.swift
//  Drift
//
//  Activity/Notifications hub showing matches, friend requests, community replies, etc.
//

import SwiftUI
import DriftBackend

struct NotificationsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notificationsManager = NotificationsManager.shared
    @ObservedObject private var friendsManager = FriendsManager.shared
    @State private var selectedFilter: NotificationFilter = .all
    @State private var selectedConversation: Conversation? = nil
    @State private var selectedPost: CommunityPost? = nil

    private var filteredNotifications: [NotificationItem] {
        notificationsManager.filtered(by: selectedFilter)
    }

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")

    // Notification type colors
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let tealPrimary = Color(red: 0.18, green: 0.83, blue: 0.75)
    private let purpleEvent = Color(red: 0.55, green: 0.36, blue: 0.96)
    private let orangeBuild = Color(red: 0.96, green: 0.62, blue: 0.04)

    var body: some View {
        NavigationStack {
            ZStack {
                softGray.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Content
                    if notificationsManager.isLoading && notificationsManager.notifications.isEmpty {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredNotifications.isEmpty {
                        emptyStateView
                    } else {
                        notificationsList
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await notificationsManager.fetchNotifications()
            }
            .onDisappear {
                // Mark all as read when leaving the screen
                notificationsManager.markAllAsRead()
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
            .fullScreenCover(item: $selectedConversation) { conversation in
                NavigationStack {
                    MessageDetailScreen(
                        conversation: conversation,
                        onClose: { selectedConversation = nil }
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            // Title row
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(charcoal)
                }

                Spacer()

                Text("Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoal)

                Spacer()

                // Mark all as read button
                Button {
                    notificationsManager.markAllAsRead()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor(charcoal)
                        .frame(width: 32, height: 32)
                        .background(softGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Filter tabs
            HStack(spacing: 8) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(selectedFilter == filter ? .white : charcoal.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedFilter == filter ? charcoal : Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color.white)
    }

    // MARK: - Notifications List (swipe left = delete, swipe right = mark as read)

    private var notificationsList: some View {
        List {
            ForEach(filteredNotifications) { notification in
                notificationCard(notification)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            notificationsManager.removeNotification(id: notification.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if !notification.isRead {
                            Button {
                                notificationsManager.markAsRead(id: notification.id)
                            } label: {
                                Label("Read", systemImage: "checkmark.circle")
                            }
                            .tint(tealPrimary)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(softGray)
        .refreshable {
            await notificationsManager.fetchNotifications()
        }
    }

    // MARK: - Notification Card

    @ViewBuilder
    private func notificationCard(_ notification: NotificationItem) -> some View {
        Button {
            handleNotificationTap(notification)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Avatar with badge
                avatarView(for: notification)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    notificationTitle(notification)

                    // Preview text
                    if let preview = notification.preview {
                        Text(preview)
                            .font(.system(size: 13))
                            .foregroundColor(charcoal.opacity(0.6))
                            .lineLimit(1)
                    }

                    // Time ago
                    Text(notification.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.top, 4)
                }

                Spacer()

                // Action button for certain types
                actionButton(for: notification)
            }
            .padding(16)
            .background(
                HStack(spacing: 0) {
                    // Left accent bar
                    Rectangle()
                        .fill(accentColor(for: notification.type))
                        .frame(width: 4)

                    // White background
                    Color.white
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(NotificationCardButtonStyle())
    }

    @ViewBuilder
    private func avatarView(for notification: NotificationItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // Main avatar
            if let profile = notification.actorProfile,
               let avatarUrl = profile.primaryDisplayPhotoUrl,
               let url = URL(string: avatarUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(accentColor(for: notification.type).opacity(0.15))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                // Icon-based avatar for system or unknown
                Circle()
                    .fill(accentColor(for: notification.type).opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: iconForType(notification.type, communityType: notification.communityPostType))
                            .font(.system(size: 18))
                            .foregroundColor(accentColor(for: notification.type))
                    )
            }

            // Badge icon
            Circle()
                .fill(accentColor(for: notification.type))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: badgeIcon(for: notification.type))
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                )
                .offset(x: 4, y: 4)
        }
    }

    @ViewBuilder
    private func notificationTitle(_ notification: NotificationItem) -> some View {
        let titleText = notification.title

        // Parse and style the title (bold names, colored context)
        Text(attributedTitle(for: notification))
            .font(.system(size: 14))
            .foregroundColor(charcoal)
            .multilineTextAlignment(.leading)
    }

    private func attributedTitle(for notification: NotificationItem) -> AttributedString {
        var result = AttributedString(notification.title)
        result.foregroundColor = Color(charcoal)

        // Bold the actor name if present
        if let profile = notification.actorProfile {
            let name = profile.displayName
            if let range = result.range(of: name) {
                result[range].font = .system(size: 14, weight: .bold)
            }
        }

        // Color the context (category name, event name)
        if notification.type == .communityReply {
            if let category = notification.helpCategory {
                if let range = result.range(of: category.displayName) {
                    result[range].foregroundColor = Color(orangeBuild)
                    result[range].font = .system(size: 14, weight: .semibold)
                }
            } else if notification.communityPostType == .event {
                // Event context in purple
                // Find the last quoted part after "in"
            }
        }

        return result
    }

    @ViewBuilder
    private func actionButton(for notification: NotificationItem) -> some View {
        switch notification.type {
        case .match:
            Button {
                openMatchConversation(notification)
            } label: {
                Text("Chat")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(coralPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

        case .friendRequest:
            HStack(spacing: 10) {
                Button {
                    handleAcceptFriendRequest(notification)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(tealPrimary)
                        .clipShape(Circle())
                }
                Button {
                    handleDeclineFriendRequest(notification)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(charcoal.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }

        default:
            // Unread indicator for other types
            if !notification.isRead {
                Circle()
                    .fill(accentColor(for: notification.type))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.gray.opacity(0.4))
            }

            Text("No activity yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(charcoal)

            Text("When you get matches, friend requests, or replies, they'll show up here.")
                .font(.system(size: 14))
                .foregroundColor(charcoal.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func accentColor(for type: NotificationType) -> Color {
        switch type {
        case .match: return coralPrimary
        case .friendRequest: return tealPrimary
        case .communityReply: return orangeBuild
        case .eventJoin: return purpleEvent
        case .eventMessage: return purpleEvent
        case .system: return Color.gray.opacity(0.5)
        }
    }

    private func iconForType(_ type: NotificationType, communityType: CommunityPostType?) -> String {
        switch type {
        case .match: return "heart.fill"
        case .friendRequest: return "person.fill"
        case .communityReply:
            return communityType == .event ? "tent" : "wrench.and.screwdriver"
        case .eventJoin: return "tent"
        case .eventMessage: return "tent"
        case .system: return "info"
        }
    }

    private func badgeIcon(for type: NotificationType) -> String {
        switch type {
        case .match: return "heart.fill"
        case .friendRequest: return "person.badge.plus"
        case .communityReply: return "bubble.left.fill"
        case .eventJoin: return "person.badge.plus"
        case .eventMessage: return "bubble.left.fill"
        case .system: return "info"
        }
    }

    // MARK: - Actions

    private func handleNotificationTap(_ notification: NotificationItem) {
        switch notification.type {
        case .match:
            openMatchConversation(notification)
        case .friendRequest:
            // Could open profile view
            break
        case .communityReply, .eventJoin, .eventMessage:
            if let postId = notification.relatedPostId {
                openCommunityPost(postId: postId)
            }
        case .system:
            break
        }
    }

    private func openMatchConversation(_ notification: NotificationItem) {
        guard let profile = notification.actorProfile else { return }

        Task {
            do {
                let conversation = try await MessagingManager.shared.fetchOrCreateConversation(
                    with: profile.id,
                    type: .dating
                )
                await MainActor.run {
                    selectedConversation = conversation
                }
            } catch {
            }
        }
    }

    private func openCommunityPost(postId: UUID) {
        Task {
            do {
                let post = try await CommunityManager.shared.fetchPost(by: postId)
                await MainActor.run {
                    selectedPost = post
                }
            } catch {
            }
        }
    }

    private func handleAcceptFriendRequest(_ notification: NotificationItem) {
        guard let requestId = notification.relatedFriendRequestId else { return }

        Task {
            do {
                _ = try await friendsManager.respondToFriendRequest(requestId, accept: true)
                await notificationsManager.fetchNotifications()
            } catch {
            }
        }
    }

    private func handleDeclineFriendRequest(_ notification: NotificationItem) {
        guard let requestId = notification.relatedFriendRequestId else { return }

        Task {
            do {
                _ = try await friendsManager.respondToFriendRequest(requestId, accept: false)
                await notificationsManager.fetchNotifications()
            } catch {
            }
        }
    }
}

// MARK: - Button Style

struct NotificationCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NotificationsScreen()
}
