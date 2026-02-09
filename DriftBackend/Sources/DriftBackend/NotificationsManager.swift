import Foundation
import Supabase

// MARK: - Notification Types

/// Type of notification for display styling and filtering.
public enum NotificationType: String, Codable, CaseIterable, Sendable {
    case match          // Dating match (coral)
    case friendRequest  // Friend request (teal)
    case communityReply // Reply to your community post (orange for help, purple for events)
    case eventJoin      // Someone joined your event (purple)
    case eventMessage   // Message in an event you're in (purple)
    case system         // System announcement (gray)
}

/// Filter options for the notifications screen.
public enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case social = "Social"
    case events = "Events"
}

// MARK: - Notification Item

/// A unified notification item for display in the Activity screen.
public struct NotificationItem: Identifiable, Sendable {
    public let id: UUID
    public let type: NotificationType
    public let title: String
    public let subtitle: String?
    public let preview: String?
    public let createdAt: Date
    public var isRead: Bool

    // Associated data for navigation
    public let actorProfile: UserProfile?
    public let relatedPostId: UUID?
    public let relatedConversationId: UUID?
    public let relatedMatchId: UUID?
    public let relatedFriendRequestId: UUID?
    public let communityPostType: CommunityPostType?
    public let helpCategory: HelpCategory?

    public init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        subtitle: String? = nil,
        preview: String? = nil,
        createdAt: Date,
        isRead: Bool = false,
        actorProfile: UserProfile? = nil,
        relatedPostId: UUID? = nil,
        relatedConversationId: UUID? = nil,
        relatedMatchId: UUID? = nil,
        relatedFriendRequestId: UUID? = nil,
        communityPostType: CommunityPostType? = nil,
        helpCategory: HelpCategory? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.preview = preview
        self.createdAt = createdAt
        self.isRead = isRead
        self.actorProfile = actorProfile
        self.relatedPostId = relatedPostId
        self.relatedConversationId = relatedConversationId
        self.relatedMatchId = relatedMatchId
        self.relatedFriendRequestId = relatedFriendRequestId
        self.communityPostType = communityPostType
        self.helpCategory = helpCategory
    }

    /// Formatted time ago string.
    public var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if interval < 172800 {
            return "Yesterday"
        } else {
            let days = Int(interval / 86400)
            return "\(days) days ago"
        }
    }
}

// MARK: - Notifications Manager

/// Manager for aggregating and displaying notifications from various sources.
@MainActor
public class NotificationsManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = NotificationsManager()

    /// All notifications sorted by date (newest first).
    @Published public var notifications: [NotificationItem] = []
    /// Total count of unread notifications.
    @Published public var unreadCount: Int = 0
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    /// Last time the user viewed notifications (for "new" section).
    private var lastViewedAt: Date {
        get {
            guard let userId = SupabaseManager.shared.currentUser?.id else { return Date.distantPast }
            let key = "notifications_last_viewed_\(userId.uuidString)"
            return UserDefaults.standard.object(forKey: key) as? Date ?? Date.distantPast
        }
        set {
            guard let userId = SupabaseManager.shared.currentUser?.id else { return }
            let key = "notifications_last_viewed_\(userId.uuidString)"
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Public Methods

    /// Fetches and aggregates all notifications from various sources.
    public func fetchNotifications() async {
        guard SupabaseManager.shared.currentUser != nil else { return }

        // Prevent concurrent fetches which cause request cancellations
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        var allNotifications: [NotificationItem] = []

        // Fetch all notification sources in parallel
        async let matchNotifications = fetchMatchNotifications()
        async let friendRequestNotifications = fetchFriendRequestNotifications()
        async let communityReplyNotifications = fetchCommunityReplyNotifications()
        async let eventJoinNotifications = fetchEventJoinNotifications()
        async let eventMessageNotifications = fetchEventMessageNotifications()

        // Await all results (they run in parallel)
        let matches = await matchNotifications
        let friendRequests = await friendRequestNotifications
        let communityReplies = await communityReplyNotifications
        let eventJoins = await eventJoinNotifications
        let eventMessages = await eventMessageNotifications

        // Combine all notifications
        allNotifications.append(contentsOf: matches)
        allNotifications.append(contentsOf: friendRequests)
        allNotifications.append(contentsOf: communityReplies)
        allNotifications.append(contentsOf: eventJoins)
        allNotifications.append(contentsOf: eventMessages)

        // If task was cancelled or all fetches failed, keep existing notifications
        if Task.isCancelled || (allNotifications.isEmpty && !self.notifications.isEmpty) {
            isLoading = false
            return
        }

        // Sort by date (newest first)
        allNotifications.sort { $0.createdAt > $1.createdAt }

        self.notifications = allNotifications
        self.unreadCount = allNotifications.filter { !$0.isRead }.count
        isLoading = false
    }

    /// Marks all notifications as read.
    public func markAllAsRead() {
        lastViewedAt = Date()
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        unreadCount = 0
    }

    /// Marks a single notification as read.
    public func markAsRead(id: UUID) {
        if let i = notifications.firstIndex(where: { $0.id == id }), !notifications[i].isRead {
            notifications[i].isRead = true
            unreadCount = max(0, unreadCount - 1)
        }
    }

    /// Removes a notification from the list (e.g. after swipe to delete).
    public func removeNotification(id: UUID) {
        if let i = notifications.firstIndex(where: { $0.id == id }) {
            let wasUnread = !notifications[i].isRead
            notifications.remove(at: i)
            if wasUnread { unreadCount = max(0, unreadCount - 1) }
        }
    }

    /// Returns notifications that are "new" (after last viewed).
    public var newNotifications: [NotificationItem] {
        notifications.filter { $0.createdAt > lastViewedAt }
    }

    /// Returns notifications that are "earlier" (before last viewed).
    public var earlierNotifications: [NotificationItem] {
        notifications.filter { $0.createdAt <= lastViewedAt }
    }

    /// Filters notifications by type.
    public func filtered(by filter: NotificationFilter) -> [NotificationItem] {
        switch filter {
        case .all:
            return notifications
        case .social:
            // Matches and friend requests
            return notifications.filter { $0.type == .match || $0.type == .friendRequest }
        case .events:
            // Event joins, event messages, and community replies
            return notifications.filter { $0.type == .eventJoin || $0.type == .eventMessage || $0.type == .communityReply }
        }
    }

    // MARK: - Private Fetch Methods

    private func fetchMatchNotifications() async -> [NotificationItem] {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return [] }

        do {
            let matches: [Match] = try await client
                .from("matches")
                .select()
                .or("user1_id.eq.\(userId),user2_id.eq.\(userId)")
                .eq("is_match", value: true)
                .order("matched_at", ascending: false)
                .limit(20)
                .execute()
                .value

            // Batch-fetch all other user profiles in a single query
            let otherUserIds = matches.map { $0.user1Id == userId ? $0.user2Id : $0.user1Id }
            let profileMap = (try? await ProfileManager.shared.fetchProfiles(by: otherUserIds)) ?? [:]

            var notifications: [NotificationItem] = []

            for match in matches {
                let otherUserId = match.user1Id == userId ? match.user2Id : match.user1Id
                let profile = profileMap[otherUserId]

                let matchedAt = match.matchedAt ?? Date()
                let isRead = matchedAt <= lastViewedAt

                let subtitle: String? = profile?.bio.flatMap { bio in
                    bio.isEmpty ? nil : String(bio.prefix(50))
                }

                let notification = NotificationItem(
                    id: match.id,
                    type: .match,
                    title: "You matched with \(profile?.displayName ?? "someone")!",
                    subtitle: subtitle,
                    createdAt: matchedAt,
                    isRead: isRead,
                    actorProfile: profile,
                    relatedMatchId: match.id
                )
                notifications.append(notification)
            }

            return notifications
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                #if DEBUG
                print("[Notifications] Failed to fetch matches: \(error)")
                #endif
            }
            return []
        }
    }

    private func fetchFriendRequestNotifications() async -> [NotificationItem] {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return [] }

        do {
            let requests: [Friend] = try await client
                .from("friends")
                .select("*, requester:profiles!requester_id(*)")
                .eq("addressee_id", value: userId)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value

            var notifications: [NotificationItem] = []

            for request in requests {
                let createdAt = request.createdAt ?? Date()
                let isRead = createdAt <= lastViewedAt

                let notification = NotificationItem(
                    id: request.id,
                    type: .friendRequest,
                    title: "\(request.requesterProfile?.displayName ?? "Someone") sent you a friend request.",
                    createdAt: createdAt,
                    isRead: isRead,
                    actorProfile: request.requesterProfile,
                    relatedFriendRequestId: request.id
                )
                notifications.append(notification)
            }

            return notifications
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                #if DEBUG
                print("[Notifications] Failed to fetch friend requests: \(error)")
                #endif
            }
            return []
        }
    }

    private func fetchCommunityReplyNotifications() async -> [NotificationItem] {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return [] }

        do {
            // Get user's post IDs
            struct PostIdRow: Decodable {
                let id: UUID
                let type: String
                let title: String
                let helpCategory: String?

                enum CodingKeys: String, CodingKey {
                    case id
                    case type
                    case title
                    case helpCategory = "help_category"
                }
            }

            let myPosts: [PostIdRow] = try await client
                .from("community_posts")
                .select("id, type, title, help_category")
                .eq("author_id", value: userId)
                .is("deleted_at", value: nil)
                .execute()
                .value

            guard !myPosts.isEmpty else { return [] }

            let postIds = myPosts.map { $0.id.uuidString }
            let postMap = Dictionary(uniqueKeysWithValues: myPosts.map { ($0.id, $0) })

            // Get recent replies to user's posts (not by the user)
            let replies: [PostReply] = try await client
                .from("post_replies")
                .select("*, author:profiles!author_id(*)")
                .in("post_id", values: postIds)
                .neq("author_id", value: userId)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .limit(30)
                .execute()
                .value

            var notifications: [NotificationItem] = []

            for reply in replies {
                let createdAt = reply.createdAt ?? Date()
                let isRead = createdAt <= lastViewedAt

                let post = postMap[reply.postId]
                let postType = CommunityPostType(rawValue: post?.type ?? "help") ?? .help
                let helpCategory = post?.helpCategory.flatMap { HelpCategory(rawValue: $0) }

                let contextName: String
                if postType == .event {
                    contextName = post?.title ?? "your event"
                } else {
                    contextName = helpCategory?.displayName ?? "your post"
                }

                let notification = NotificationItem(
                    id: reply.id,
                    type: .communityReply,
                    title: "\(reply.author?.displayName ?? "Someone") replied to your question in \(contextName)",
                    preview: reply.content.count > 60 ? "\"\(String(reply.content.prefix(60)))...\"" : "\"\(reply.content)\"",
                    createdAt: createdAt,
                    isRead: isRead,
                    actorProfile: reply.author,
                    relatedPostId: reply.postId,
                    communityPostType: postType,
                    helpCategory: helpCategory
                )
                notifications.append(notification)
            }

            return notifications
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                #if DEBUG
                print("[Notifications] Failed to fetch community replies: \(error)")
                #endif
            }
            return []
        }
    }

    private func fetchEventJoinNotifications() async -> [NotificationItem] {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return [] }

        do {
            // Get events the user created
            struct MyEventRow: Decodable {
                let id: UUID
                let title: String
            }

            let myEvents: [MyEventRow] = try await client
                .from("community_posts")
                .select("id, title")
                .eq("author_id", value: userId)
                .eq("type", value: "event")
                .is("deleted_at", value: nil)
                .execute()
                .value

            guard !myEvents.isEmpty else { return [] }

            let eventIds = myEvents.map { $0.id.uuidString }
            let eventTitleMap = Dictionary(uniqueKeysWithValues: myEvents.map { ($0.id, $0.title) })

            // Get attendees who joined these events (not the creator)
            struct AttendeeRow: Decodable {
                let id: UUID
                let postId: UUID
                let userId: UUID
                let status: String
                let createdAt: Date?

                enum CodingKeys: String, CodingKey {
                    case id
                    case postId = "post_id"
                    case userId = "user_id"
                    case status
                    case createdAt = "created_at"
                }
            }

            let attendees: [AttendeeRow] = try await client
                .from("event_attendees")
                .select("id, post_id, user_id, status, created_at")
                .in("post_id", values: eventIds)
                .neq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(30)
                .execute()
                .value

            // Batch-fetch all attendee profiles in a single query
            let attendeeUserIds = attendees.map { $0.userId }
            let profileMap = (try? await ProfileManager.shared.fetchProfiles(by: attendeeUserIds)) ?? [:]

            var notifications: [NotificationItem] = []

            for attendee in attendees {
                let createdAt = attendee.createdAt ?? Date()
                let isRead = createdAt <= lastViewedAt

                let profile = profileMap[attendee.userId]
                let eventTitle = eventTitleMap[attendee.postId] ?? "your event"

                let statusText = attendee.status == "pending" ? "requested to join" : "joined"

                let notification = NotificationItem(
                    id: attendee.id,
                    type: .eventJoin,
                    title: "\(profile?.displayName ?? "Someone") \(statusText) \(eventTitle)",
                    createdAt: createdAt,
                    isRead: isRead,
                    actorProfile: profile,
                    relatedPostId: attendee.postId,
                    communityPostType: .event
                )
                notifications.append(notification)
            }

            return notifications
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                #if DEBUG
                print("[Notifications] Failed to fetch event joins: \(error)")
                #endif
            }
            return []
        }
    }

    private func fetchEventMessageNotifications() async -> [NotificationItem] {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return [] }

        do {
            // Get events the user is attending
            struct AttendeeRow: Decodable {
                let postId: UUID

                enum CodingKeys: String, CodingKey {
                    case postId = "post_id"
                }
            }

            let attendances: [AttendeeRow] = try await client
                .from("event_attendees")
                .select("post_id")
                .eq("user_id", value: userId)
                .eq("status", value: "confirmed")
                .execute()
                .value

            // Get events the user created
            struct MyEventRow: Decodable {
                let id: UUID
            }

            let myEvents: [MyEventRow] = try await client
                .from("community_posts")
                .select("id")
                .eq("author_id", value: userId)
                .eq("type", value: "event")
                .is("deleted_at", value: nil)
                .execute()
                .value

            // Combine event IDs (attending + created)
            var allEventIds = Set(attendances.map { $0.postId })
            for event in myEvents {
                allEventIds.insert(event.id)
            }

            guard !allEventIds.isEmpty else { return [] }

            let eventIdStrings = allEventIds.map { $0.uuidString }

            // Get post titles
            struct PostRow: Decodable {
                let id: UUID
                let title: String
            }

            let posts: [PostRow] = try await client
                .from("community_posts")
                .select("id, title")
                .in("id", values: eventIdStrings)
                .execute()
                .value

            let postTitleMap = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0.title) })

            // Get recent messages in those events (not by the user)
            struct MessageRow: Decodable {
                let id: UUID
                let eventId: UUID
                let userId: UUID
                let content: String
                let createdAt: Date?

                enum CodingKeys: String, CodingKey {
                    case id
                    case eventId = "event_id"
                    case userId = "user_id"
                    case content
                    case createdAt = "created_at"
                }
            }

            let messages: [MessageRow] = try await client
                .from("event_messages")
                .select("id, event_id, user_id, content, created_at")
                .in("event_id", values: eventIdStrings)
                .neq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            // Batch-fetch all sender profiles in a single query
            let senderUserIds = Array(Set(messages.map { $0.userId }))
            let profileMap = (try? await ProfileManager.shared.fetchProfiles(by: senderUserIds)) ?? [:]

            var notifications: [NotificationItem] = []

            for message in messages {
                let createdAt = message.createdAt ?? Date()
                let isRead = createdAt <= lastViewedAt

                let profile = profileMap[message.userId]
                let eventTitle = postTitleMap[message.eventId] ?? "event"

                let notification = NotificationItem(
                    id: message.id,
                    type: .eventMessage,
                    title: "\(profile?.displayName ?? "Someone") posted in \(eventTitle)",
                    preview: message.content.count > 60 ? "\"\(String(message.content.prefix(60)))...\"" : "\"\(message.content)\"",
                    createdAt: createdAt,
                    isRead: isRead,
                    actorProfile: profile,
                    relatedPostId: message.eventId,
                    communityPostType: .event
                )
                notifications.append(notification)
            }

            return notifications
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                #if DEBUG
                print("[Notifications] Failed to fetch event messages: \(error)")
                #endif
            }
            return []
        }
    }
}
