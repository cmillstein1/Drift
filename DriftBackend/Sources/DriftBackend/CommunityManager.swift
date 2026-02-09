import Foundation
import Supabase
import Realtime

/// Manager for community posts (Events and Help requests).
///
/// Handles fetching, creating, and managing community posts, replies, likes, and event attendance.
@MainActor
public class CommunityManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = CommunityManager()

    /// All community posts (combined feed).
    @Published public var posts: [CommunityPost] = []
    /// Current post's replies.
    @Published public var currentReplies: [PostReply] = []
    /// User's own posts.
    @Published public var myPosts: [CommunityPost] = []
    /// Count of new interactions on user's posts since last viewed.
    @Published public var newInteractionCount: Int = 0
    /// Events the current user has joined as an attendee.
    @Published public var joinedEvents: [CommunityPost] = []
    /// Number of joined events with unread chat messages.
    @Published public var unreadEventChatCount: Int = 0
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var postsChannel: RealtimeChannelV2?
    private var repliesChannel: RealtimeChannelV2?
    private var eventMessagesChannel: RealtimeChannelV2?
    private var attendeesChannel: RealtimeChannelV2?
    private var myAttendeeChangesChannel: RealtimeChannelV2?

    /// Callback for new event messages (used by UI to append messages)
    public var onNewEventMessage: ((EventMessage) -> Void)?

    /// Callback for attendee status changes (used by UI to refresh attendees/requests)
    public var onAttendeeChange: ((UUID) -> Void)?

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    private static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch Posts

    /// Fetches community posts with optional filtering.
    ///
    /// - Parameters:
    ///   - type: Optional filter by post type (event/help).
    ///   - category: Optional filter by help category.
    ///   - limit: Maximum number of posts to fetch.
    public func fetchPosts(
        type: CommunityPostType? = nil,
        category: HelpCategory? = nil,
        limit: Int = 50
    ) async throws {
        isLoading = true
        errorMessage = nil

        do {
            // Build base query
            var filterQuery = client
                .from("community_posts")
                .select("""
                    *,
                    author:profiles!author_id(*)
                """)
                .is("deleted_at", value: nil)

            // Apply filters before transforms
            if let type = type {
                filterQuery = filterQuery.eq("type", value: type.rawValue)
            }

            if let category = category {
                filterQuery = filterQuery.eq("help_category", value: category.rawValue)
            }

            // Apply transforms after filters
            var posts: [CommunityPost] = try await filterQuery
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            // Hide dating-only events when discovery mode is "Friends" (use auth metadata, not profiles table)
            let discoveryMode = SupabaseManager.shared.getDiscoveryMode()
            if discoveryMode == .friends {
                posts = posts.filter { post in
                    if post.type != .event { return true }
                    return post.isDatingEvent != true
                }
            }

            // Check likes and attendance in parallel
            if let userId = SupabaseManager.shared.currentUser?.id {
                let postIds = posts.map { $0.id }
                let postIdStrings = postIds.map { $0.uuidString }
                let eventPostIds = posts.filter { $0.type == .event }.map { $0.id }
                let eventPostIdStrings = eventPostIds.map { $0.uuidString }

                // Run all status queries in parallel
                async let likesTask: [PostLike] = client
                    .from("post_likes")
                    .select()
                    .eq("user_id", value: userId)
                    .in("post_id", values: postIdStrings)
                    .execute()
                    .value

                // Fetch all attendee records (confirmed + pending) in one query
                async let attendeesTask: [EventAttendee] = eventPostIdStrings.isEmpty ? [] : client
                    .from("event_attendees")
                    .select()
                    .eq("user_id", value: userId)
                    .in("post_id", values: eventPostIdStrings)
                    .execute()
                    .value

                let (likes, allAttendees) = try await (likesTask, attendeesTask)

                let likedPostIds = Set(likes.compactMap { $0.postId })
                let attendingPostIds = Set(allAttendees.filter { $0.status == .confirmed }.map { $0.postId })
                let pendingPostIds = Set(allAttendees.filter { $0.status == .pending }.map { $0.postId })

                for i in posts.indices {
                    posts[i].isLikedByCurrentUser = likedPostIds.contains(posts[i].id)
                    if posts[i].type == .event {
                        posts[i].isAttendingEvent = attendingPostIds.contains(posts[i].id)
                        posts[i].hasPendingRequest = pendingPostIds.contains(posts[i].id)
                    }
                }
            }

            if let type = type {
                // Replace only posts of the requested type, keep others
                self.posts = self.posts.filter { $0.type != type } + posts
            } else {
                self.posts = posts
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches posts created by the current user.
    public func fetchMyPosts() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        var posts: [CommunityPost] = try await client
            .from("community_posts")
            .select("""
                *,
                author:profiles!author_id(*)
            """)
            .eq("author_id", value: userId)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Check for pending join requests on user's events
        let eventPostIds = posts.filter { $0.type == .event }.map { $0.id }
        if !eventPostIds.isEmpty {
            let pendingRequests: [EventAttendee] = try await client
                .from("event_attendees")
                .select()
                .eq("status", value: "pending")
                .in("post_id", values: eventPostIds.map { $0.uuidString })
                .execute()
                .value

            // Group pending requests by post_id
            let pendingByPost = Dictionary(grouping: pendingRequests) { $0.postId }

            for i in posts.indices {
                if posts[i].type == .event {
                    let pendingCount = pendingByPost[posts[i].id]?.count ?? 0
                    posts[i].pendingRequestCount = pendingCount
                }
            }
        }

        self.myPosts = posts
    }

    /// Fetches the count of new interactions on user's posts since last viewed.
    public func fetchNewInteractionCount() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        let lastViewedKey = "myPostsLastViewed_\(userId.uuidString)"
        let lastViewed = UserDefaults.standard.object(forKey: lastViewedKey) as? Date ?? Date.distantPast

        // Fetch user's post IDs
        struct PostIdRecord: Decodable {
            let id: UUID
        }

        let postRecords: [PostIdRecord] = try await client
            .from("community_posts")
            .select("id")
            .eq("author_id", value: userId)
            .is("deleted_at", value: nil)
            .execute()
            .value

        let myPostIds = postRecords.map { $0.id }

        guard !myPostIds.isEmpty else {
            self.newInteractionCount = 0
            return
        }

        let postIdStrings = myPostIds.map { $0.uuidString }

        // Count new replies on user's posts since last viewed
        let newReplies: [PostReply] = try await client
            .from("post_replies")
            .select()
            .in("post_id", values: postIdStrings)
            .neq("author_id", value: userId) // Exclude user's own replies
            .is("deleted_at", value: nil)
            .gt("created_at", value: Self.iso8601Formatter.string(from: lastViewed))
            .execute()
            .value

        // Count new pending join requests on user's events
        let pendingRequests: [EventAttendee] = try await client
            .from("event_attendees")
            .select()
            .in("post_id", values: postIdStrings)
            .eq("status", value: "pending")
            .execute()
            .value

        self.newInteractionCount = newReplies.count + pendingRequests.count
    }

    /// Marks user's posts as viewed, resetting the interaction count.
    public func markMyPostsAsViewed() {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        let lastViewedKey = "myPostsLastViewed_\(userId.uuidString)"
        UserDefaults.standard.set(Date(), forKey: lastViewedKey)
        self.newInteractionCount = 0
    }

    // MARK: - Joined Events

    /// Fetches events the current user has joined as a confirmed attendee (excludes own posts).
    public func fetchJoinedEvents() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        // Fetch confirmed attendee records for this user
        struct AttendeePostId: Decodable {
            let postId: UUID
            enum CodingKeys: String, CodingKey {
                case postId = "post_id"
            }
        }

        let attendeeRecords: [AttendeePostId] = try await client
            .from("event_attendees")
            .select("post_id")
            .eq("user_id", value: userId)
            .eq("status", value: "confirmed")
            .execute()
            .value

        let postIds = attendeeRecords.map { $0.postId }

        guard !postIds.isEmpty else {
            self.joinedEvents = []
            self.unreadEventChatCount = 0
            return
        }

        // Fetch the actual posts, excluding user's own posts
        var posts: [CommunityPost] = try await client
            .from("community_posts")
            .select("""
                *,
                author:profiles!author_id(*)
            """)
            .in("id", values: postIds.map { $0.uuidString })
            .neq("author_id", value: userId)
            .is("deleted_at", value: nil)
            .order("event_datetime", ascending: true)
            .execute()
            .value

        // Mark all as attending
        for i in posts.indices {
            posts[i].isAttendingEvent = true
        }

        self.joinedEvents = posts

        // Calculate unread counts
        await fetchUnreadEventChatCount()
    }

    /// Marks an event chat as read by saving the current timestamp.
    public func markEventChatRead(_ eventId: UUID) {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        let key = "eventChatLastRead_\(userId.uuidString)_\(eventId.uuidString)"
        UserDefaults.standard.set(Date(), forKey: key)
    }

    /// Fetches the count of joined events with unread chat messages.
    public func fetchUnreadEventChatCount() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        var unreadCount = 0
        for event in joinedEvents {
            let key = "eventChatLastRead_\(userId.uuidString)_\(event.id.uuidString)"
            let lastRead = UserDefaults.standard.object(forKey: key) as? Date ?? Date.distantPast

            struct MessageCount: Decodable {
                let count: Int
            }

            // Count messages after last-read timestamp, excluding user's own messages
            do {
                let messages: [EventMessage] = try await client
                    .from("event_messages")
                    .select("id, event_id, user_id, content, created_at")
                    .eq("event_id", value: event.id)
                    .neq("user_id", value: userId)
                    .gt("created_at", value: Self.iso8601Formatter.string(from: lastRead))
                    .execute()
                    .value

                if !messages.isEmpty {
                    unreadCount += 1
                }
            } catch {
                #if DEBUG
                print("Failed to check unread for event \(event.id): \(error)")
                #endif
            }
        }

        self.unreadEventChatCount = unreadCount
    }

    /// Checks if a specific event has unread chat messages.
    public func hasUnreadMessages(for eventId: UUID) -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return false }
        let key = "eventChatLastRead_\(userId.uuidString)_\(eventId.uuidString)"
        // If we've never read, there could be unread messages
        return UserDefaults.standard.object(forKey: key) == nil
    }

    /// Fetches a single post by ID with full details.
    ///
    /// - Parameter id: The post's UUID.
    /// - Returns: The complete post with author and attendees.
    public func fetchPost(by id: UUID) async throws -> CommunityPost {
        var post: CommunityPost = try await client
            .from("community_posts")
            .select("""
                *,
                author:profiles!author_id(*),
                attendees:event_attendees(*, profile:profiles!user_id(*))
            """)
            .eq("id", value: id)
            .single()
            .execute()
            .value

        // Check if current user liked this post
        if let userId = SupabaseManager.shared.currentUser?.id {
            let likes: [PostLike] = try await client
                .from("post_likes")
                .select()
                .eq("user_id", value: userId)
                .eq("post_id", value: id)
                .execute()
                .value

            post.isLikedByCurrentUser = !likes.isEmpty

            // Check attendance for events
            if post.type == .event {
                let attendance: [EventAttendee] = try await client
                    .from("event_attendees")
                    .select()
                    .eq("user_id", value: userId)
                    .eq("post_id", value: id)
                    .eq("status", value: "confirmed")
                    .execute()
                    .value

                post.isAttendingEvent = !attendance.isEmpty
            }
        }

        return post
    }

    // MARK: - Create Posts

    /// Creates a new event post.
    ///
    /// - Parameters:
    ///   - title: Event title.
    ///   - content: Event description.
    ///   - datetime: Event date and time.
    ///   - location: General location.
    ///   - exactLocation: Exact location (revealed after joining).
    ///   - latitude: Event latitude coordinate.
    ///   - longitude: Event longitude coordinate.
    ///   - maxAttendees: Maximum number of attendees.
    ///   - images: Array of image URLs.
    ///   - isDatingEvent: When true, only users with dating or both see this event (hidden from friends-only).
    /// - Returns: The created post.
    @discardableResult
    public func createEventPost(
        title: String,
        content: String,
        datetime: Date,
        location: String? = nil,
        exactLocation: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        maxAttendees: Int? = nil,
        privacy: EventPrivacy = .public,
        images: [String] = [],
        isDatingEvent: Bool = false
    ) async throws -> CommunityPost {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        var headerImages = images
        var attributionName: String?
        var attributionUrl: String?
        if headerImages.isEmpty, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            let key = _BackendConfiguration.shared.unsplashAccessKey
            if let result = await UnsplashManager.fetchFirstImageWithAttribution(query: title, accessKey: key) {
                headerImages = [result.imageUrl]
                attributionName = result.photographerName
                attributionUrl = result.photographerUrl
            }
        }
        let request = CommunityPostCreateRequest(
            authorId: userId,
            type: .event,
            title: title,
            content: content,
            images: headerImages,
            imageAttributionName: attributionName,
            imageAttributionUrl: attributionUrl,
            eventDatetime: datetime,
            eventLocation: location,
            eventExactLocation: exactLocation,
            eventLatitude: latitude,
            eventLongitude: longitude,
            maxAttendees: maxAttendees,
            eventPrivacy: privacy,
            isDatingEvent: isDatingEvent
        )

        let post: CommunityPost = try await client
            .from("community_posts")
            .insert(request)
            .select("""
                *,
                author:profiles!author_id(*)
            """)
            .single()
            .execute()
            .value

        // Insert into local state instead of full re-fetch
        posts.insert(post, at: 0)

        return post
    }

    /// Updates an event post. Only the author can update.
    ///
    /// - Parameters:
    ///   - postId: The post's UUID.
    ///   - title: Optional new title.
    ///   - content: Optional new content/description.
    ///   - datetime: Optional new event datetime.
    ///   - location: Optional new location.
    ///   - exactLocation: Optional new exact location.
    ///   - latitude: Optional new latitude.
    ///   - longitude: Optional new longitude.
    ///   - maxAttendees: Optional new max attendees.
    ///   - privacy: Optional new privacy.
    ///   - isDatingEvent: Optional new dating-event flag.
    public func updateEventPost(
        _ postId: UUID,
        title: String? = nil,
        content: String? = nil,
        datetime: Date? = nil,
        location: String? = nil,
        exactLocation: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        maxAttendees: Int? = nil,
        privacy: EventPrivacy? = nil,
        isDatingEvent: Bool? = nil
    ) async throws {
        var updates: [String: AnyEncodable] = [
            "updated_at": AnyEncodable(Self.iso8601Formatter.string(from: Date()))
        ]
        if let title = title { updates["title"] = AnyEncodable(title) }
        if let content = content { updates["content"] = AnyEncodable(content) }
        if let datetime = datetime { updates["event_datetime"] = AnyEncodable(Self.iso8601Formatter.string(from: datetime)) }
        if let location = location { updates["event_location"] = AnyEncodable(location) }
        if let exactLocation = exactLocation { updates["event_exact_location"] = AnyEncodable(exactLocation) }
        if let latitude = latitude { updates["event_latitude"] = AnyEncodable(latitude) }
        if let longitude = longitude { updates["event_longitude"] = AnyEncodable(longitude) }
        if let maxAttendees = maxAttendees { updates["max_attendees"] = AnyEncodable(maxAttendees) }
        if let privacy = privacy { updates["event_privacy"] = AnyEncodable(privacy.rawValue) }
        if let isDatingEvent = isDatingEvent { updates["is_dating_event"] = AnyEncodable(isDatingEvent) }

        try await client
            .from("community_posts")
            .update(updates)
            .eq("id", value: postId)
            .eq("type", value: CommunityPostType.event.rawValue)
            .execute()

        // Refresh just the updated post in local state
        if let updatedPost = try? await fetchPost(by: postId) {
            if let idx = posts.firstIndex(where: { $0.id == postId }) {
                posts[idx] = updatedPost
            }
        }
    }

    /// Creates a new help post.
    ///
    /// - Parameters:
    ///   - title: Help request title.
    ///   - content: Help request description.
    ///   - category: Help category.
    ///   - images: Array of image URLs.
    /// - Returns: The created post.
    @discardableResult
    public func createHelpPost(
        title: String,
        content: String,
        category: HelpCategory,
        images: [String] = []
    ) async throws -> CommunityPost {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        let request = CommunityPostCreateRequest(
            authorId: userId,
            type: .help,
            title: title,
            content: content,
            images: images,
            helpCategory: category
        )

        let post: CommunityPost = try await client
            .from("community_posts")
            .insert(request)
            .select("""
                *,
                author:profiles!author_id(*)
            """)
            .single()
            .execute()
            .value

        // Insert into local state instead of full re-fetch
        posts.insert(post, at: 0)

        return post
    }

    /// Soft deletes a post.
    ///
    /// - Parameter postId: The post's UUID.
    public func deletePost(_ postId: UUID) async throws {
        guard SupabaseManager.shared.currentUser?.id != nil else {
            throw CommunityError.notAuthenticated
        }

        let success: Bool = try await client
            .rpc("soft_delete_community_post", params: ["post_id": postId])
            .execute()
            .value

        guard success else {
            throw CommunityError.postNotFound
        }

        // Remove from local state
        posts.removeAll { $0.id == postId }
        myPosts.removeAll { $0.id == postId }
        joinedEvents.removeAll { $0.id == postId }
    }

    // MARK: - Replies

    /// Fetches replies for a post.
    ///
    /// - Parameter postId: The post's UUID.
    public func fetchReplies(for postId: UUID) async throws {
        var replies: [PostReply] = try await client
            .from("post_replies")
            .select("""
                *,
                author:profiles!author_id(*)
            """)
            .eq("post_id", value: postId)
            .is("deleted_at", value: nil)
            .is("parent_reply_id", value: nil)  // Top-level replies only
            .order("created_at", ascending: true)
            .execute()
            .value

        // Check if current user liked each reply
        if let userId = SupabaseManager.shared.currentUser?.id {
            let replyIds = replies.map { $0.id }
            let likes: [PostLike] = try await client
                .from("post_likes")
                .select()
                .eq("user_id", value: userId)
                .in("reply_id", values: replyIds.map { $0.uuidString })
                .execute()
                .value

            let likedReplyIds = Set(likes.compactMap { $0.replyId })

            for i in replies.indices {
                replies[i].isLikedByCurrentUser = likedReplyIds.contains(replies[i].id)
            }
        }

        self.currentReplies = replies
    }

    /// Creates a new reply on a post.
    ///
    /// - Parameters:
    ///   - postId: The post's UUID.
    ///   - content: Reply content.
    ///   - images: Array of image URLs.
    ///   - parentReplyId: Optional parent reply for threading.
    /// - Returns: The created reply.
    @discardableResult
    public func createReply(
        postId: UUID,
        content: String,
        images: [String] = [],
        parentReplyId: UUID? = nil
    ) async throws -> PostReply {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        let request = PostReplyCreateRequest(
            postId: postId,
            authorId: userId,
            content: content,
            images: images,
            parentReplyId: parentReplyId
        )

        let reply: PostReply = try await client
            .from("post_replies")
            .insert(request)
            .select("""
                *,
                author:profiles!author_id(*)
            """)
            .single()
            .execute()
            .value

        // Add to local state
        currentReplies.append(reply)

        // Update reply count in posts list
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].replyCount += 1
        }

        return reply
    }

    /// Soft deletes a reply.
    ///
    /// - Parameter replyId: The reply's UUID.
    public func deleteReply(_ replyId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        try await client
            .from("post_replies")
            .update(["deleted_at": Self.iso8601Formatter.string(from: Date())])
            .eq("id", value: replyId)
            .eq("author_id", value: userId)
            .execute()

        // Remove from local state
        currentReplies.removeAll { $0.id == replyId }
    }

    // MARK: - Engagement (Likes)

    /// Toggles like on a post.
    ///
    /// - Parameter postId: The post's UUID.
    public func togglePostLike(_ postId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        // Check if already liked
        let existingLikes: [PostLike] = try await client
            .from("post_likes")
            .select()
            .eq("user_id", value: userId)
            .eq("post_id", value: postId)
            .execute()
            .value

        if existingLikes.isEmpty {
            // Add like
            let request = PostLikeCreateRequest(userId: userId, postId: postId)
            try await client
                .from("post_likes")
                .insert(request)
                .execute()

            // Update local state
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].likeCount += 1
                posts[index].isLikedByCurrentUser = true
            }
        } else {
            // Remove like
            try await client
                .from("post_likes")
                .delete()
                .eq("user_id", value: userId)
                .eq("post_id", value: postId)
                .execute()

            // Update local state
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].likeCount = max(0, posts[index].likeCount - 1)
                posts[index].isLikedByCurrentUser = false
            }
        }
    }

    /// Toggles like on a reply.
    ///
    /// - Parameter replyId: The reply's UUID.
    public func toggleReplyLike(_ replyId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        // Check if already liked
        let existingLikes: [PostLike] = try await client
            .from("post_likes")
            .select()
            .eq("user_id", value: userId)
            .eq("reply_id", value: replyId)
            .execute()
            .value

        if existingLikes.isEmpty {
            // Add like
            let request = PostLikeCreateRequest(userId: userId, replyId: replyId)
            try await client
                .from("post_likes")
                .insert(request)
                .execute()

            // Update local state
            if let index = currentReplies.firstIndex(where: { $0.id == replyId }) {
                currentReplies[index].likeCount += 1
                currentReplies[index].isLikedByCurrentUser = true
            }
        } else {
            // Remove like
            try await client
                .from("post_likes")
                .delete()
                .eq("user_id", value: userId)
                .eq("reply_id", value: replyId)
                .execute()

            // Update local state
            if let index = currentReplies.firstIndex(where: { $0.id == replyId }) {
                currentReplies[index].likeCount = max(0, currentReplies[index].likeCount - 1)
                currentReplies[index].isLikedByCurrentUser = false
            }
        }
    }

    // MARK: - Event Attendance

    /// Joins an event.
    ///
    /// - Parameter postId: The event post's UUID.
    public func joinEvent(_ postId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        let request = EventAttendeeCreateRequest(postId: postId, userId: userId)

        try await client
            .from("event_attendees")
            .insert(request)
            .execute()

        // Update local state
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].currentAttendees = (posts[index].currentAttendees ?? 0) + 1
            posts[index].isAttendingEvent = true
        }
    }

    /// Leaves an event.
    ///
    /// - Parameter postId: The event post's UUID.
    public func leaveEvent(_ postId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        try await client
            .from("event_attendees")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()

        // Update local state
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].currentAttendees = max(0, (posts[index].currentAttendees ?? 1) - 1)
            posts[index].isAttendingEvent = false
        }
    }

    /// Fetches attendees for an event with their profiles.
    ///
    /// - Parameter postId: The event post's UUID.
    /// - Returns: Array of user profiles who are attending.
    public func fetchEventAttendees(_ postId: UUID) async throws -> [UserProfile] {
        struct AttendeeRecord: Decodable {
            let userId: UUID
            let status: String
            let profile: UserProfile

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case status
                case profile = "profiles"
            }
        }

        let attendees: [AttendeeRecord] = try await client
            .from("event_attendees")
            .select("user_id, status, profiles(*)")
            .eq("post_id", value: postId)
            .eq("status", value: "confirmed")
            .execute()
            .value

        return attendees.map { $0.profile }
    }

    /// Requests to join a private event (creates pending attendee).
    ///
    /// - Parameter postId: The event post's UUID.
    public func requestToJoinEvent(_ postId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        let request = EventAttendeeCreateRequest(postId: postId, userId: userId, status: .pending)

        try await client
            .from("event_attendees")
            .insert(request)
            .execute()

        // Update local state - mark as having pending request
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].hasPendingRequest = true
        }
    }

    /// Cancels a pending join request.
    ///
    /// - Parameter postId: The event post's UUID.
    public func cancelJoinRequest(_ postId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        try await client
            .from("event_attendees")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .eq("status", value: "pending")
            .execute()

        // Update local state
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].hasPendingRequest = false
        }
    }

    /// Fetches pending join requests for an event (host only).
    ///
    /// - Parameter postId: The event post's UUID.
    /// - Returns: Array of user profiles with pending requests.
    public func fetchPendingRequests(_ postId: UUID) async throws -> [UserProfile] {
        struct AttendeeRecord: Decodable {
            let userId: UUID
            let status: String
            let profile: UserProfile

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case status
                case profile = "profiles"
            }
        }

        let attendees: [AttendeeRecord] = try await client
            .from("event_attendees")
            .select("user_id, status, profiles(*)")
            .eq("post_id", value: postId)
            .eq("status", value: "pending")
            .execute()
            .value

        return attendees.map { $0.profile }
    }

    /// Approves a pending join request (host only).
    ///
    /// - Parameters:
    ///   - postId: The event post's UUID.
    ///   - userId: The requesting user's UUID.
    public func approveJoinRequest(postId: UUID, userId: UUID) async throws {
        try await client
            .from("event_attendees")
            .update(["status": "confirmed"])
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()

        // Update local attendee count
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].currentAttendees = (posts[index].currentAttendees ?? 0) + 1
        }
    }

    /// Denies a pending join request (host only).
    ///
    /// - Parameters:
    ///   - postId: The event post's UUID.
    ///   - userId: The requesting user's UUID.
    public func denyJoinRequest(postId: UUID, userId: UUID) async throws {
        try await client
            .from("event_attendees")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Checks if current user has a pending request for an event.
    ///
    /// - Parameter postId: The event post's UUID.
    /// - Returns: True if user has a pending request.
    public func checkPendingRequest(_ postId: UUID) async throws -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            return false
        }

        struct AttendeeRecord: Decodable {
            let status: String
        }

        let records: [AttendeeRecord] = try await client
            .from("event_attendees")
            .select("status")
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .eq("status", value: "pending")
            .execute()
            .value

        return !records.isEmpty
    }

    // MARK: - Help Post Actions

    /// Marks a help post as solved.
    ///
    /// - Parameters:
    ///   - postId: The help post's UUID.
    ///   - bestAnswerId: The reply UUID to mark as best answer.
    public func markAsSolved(postId: UUID, bestAnswerId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        struct SolvedUpdate: Encodable {
            let is_solved: Bool
            let best_answer_id: String
            let updated_at: String
        }

        try await client
            .from("community_posts")
            .update(SolvedUpdate(
                is_solved: true,
                best_answer_id: bestAnswerId.uuidString,
                updated_at: Self.iso8601Formatter.string(from: Date())
            ))
            .eq("id", value: postId)
            .eq("author_id", value: userId)  // Only author can mark as solved
            .execute()

        // Update local state
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isSolved = true
            posts[index].bestAnswerId = bestAnswerId
        }
    }

    // MARK: - Image Upload

    /// Uploads an image for a post.
    ///
    /// - Parameter imageData: The image data.
    /// - Returns: The public URL of the uploaded image.
    public func uploadPostImage(_ imageData: Data) async throws -> String {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        let imageId = UUID().uuidString
        let fileName = "\(userId.uuidString)/\(imageId).jpg"

        try await client.storage
            .from("post-images")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try client.storage
            .from("post-images")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    // MARK: - Realtime Subscriptions

    /// Subscribes to real-time post updates. If already subscribed, returns so postgresChange is never registered after join.
    public func subscribeToPosts() async {
        if postsChannel != nil { return }

        let channel = client.realtimeV2.channel("community_posts")
        postsChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "community_posts"
        )

        await channel.subscribe()

        Task {
            for await _ in insertions {
                // Refresh posts on new insert
                try? await self.fetchPosts()
            }
        }
    }

    /// Subscribes to real-time reply updates for a specific post.
    ///
    /// - Parameter postId: The post's UUID.
    public func subscribeToReplies(postId: UUID) async {
        let channel = client.realtimeV2.channel("post_replies:\(postId)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "post_replies",
            filter: "post_id=eq.\(postId)"
        )

        await channel.subscribe()
        repliesChannel = channel

        Task {
            for await insertion in insertions {
                let record = insertion.record
                if let idString = record["id"]?.stringValue,
                   let id = UUID(uuidString: idString) {
                    // Fetch the new reply with author info
                    do {
                        let reply: PostReply = try await self.client
                            .from("post_replies")
                            .select("""
                                *,
                                author:profiles!author_id(*)
                            """)
                            .eq("id", value: id)
                            .single()
                            .execute()
                            .value

                        await MainActor.run {
                            if !self.currentReplies.contains(where: { $0.id == reply.id }) {
                                self.currentReplies.append(reply)
                            }
                        }
                    } catch {
                        #if DEBUG
                        print("Failed to fetch new reply: \(error)")
                        #endif
                    }
                }
            }
        }
    }

    /// Unsubscribes from all channels and removes them so the next subscribe gets fresh channels (avoids "postgresChange after join" warning).
    public func unsubscribe() async {
        if let ch = postsChannel {
            await ch.unsubscribe()
            await client.realtimeV2.removeChannel(ch)
            postsChannel = nil
        }
        if let ch = repliesChannel {
            await ch.unsubscribe()
            await client.realtimeV2.removeChannel(ch)
            repliesChannel = nil
        }
    }

    /// Unsubscribes from replies channel only and removes it so the next subscribe gets a fresh channel.
    public func unsubscribeFromReplies() async {
        if let ch = repliesChannel {
            await ch.unsubscribe()
            await client.realtimeV2.removeChannel(ch)
            repliesChannel = nil
        }
        currentReplies = []
    }

    /// Subscribes to real-time attendee updates for a specific event.
    ///
    /// - Parameter eventId: The event's UUID.
    public func subscribeToAttendees(eventId: UUID) async {
        // Unsubscribe from any existing channel first
        await attendeesChannel?.unsubscribe()

        let channel = client.realtimeV2.channel("event_attendees_\(eventId.uuidString.prefix(8))")

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "event_attendees"
        )

        await channel.subscribe()
        attendeesChannel = channel

        #if DEBUG
        print("[EventAttendees] Subscribed to realtime channel for event: \(eventId)")
        #endif

        Task { [weak self] in
            for await change in changes {
                guard let self = self else { return }

                #if DEBUG
                print("[EventAttendees] Received change: \(change)")
                #endif

                // Extract post_id from the change
                var postIdString: String? = nil

                switch change {
                case .insert(let action):
                    postIdString = action.record["post_id"]?.stringValue
                case .update(let action):
                    postIdString = action.record["post_id"]?.stringValue
                case .delete(let action):
                    postIdString = action.oldRecord["post_id"]?.stringValue
                }

                // Only handle changes for this event
                guard let postIdStr = postIdString,
                      let postId = UUID(uuidString: postIdStr),
                      postId == eventId else {
                    #if DEBUG
                    print("[EventAttendees] Change for different event, ignoring")
                    #endif
                    continue
                }

                #if DEBUG
                print("[EventAttendees] Notifying UI of attendee change")
                #endif
                await MainActor.run {
                    self.onAttendeeChange?(eventId)
                }
            }
        }
    }

    /// Unsubscribes from attendees channel and my-attendee-changes channel.
    public func unsubscribeFromAttendees() async {
        await attendeesChannel?.unsubscribe()
        attendeesChannel = nil
        await myAttendeeChangesChannel?.unsubscribe()
        myAttendeeChangesChannel = nil
        onAttendeeChange = nil
    }

    /// Subscribes to real-time changes for the current user's attendee status.
    /// Used on the feed to detect when requests are approved/denied.
    public func subscribeToMyAttendeeChanges() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        // Unsubscribe from any existing channel first
        await myAttendeeChangesChannel?.unsubscribe()

        let channel = client.realtimeV2.channel("my_attendees_\(userId.uuidString.prefix(8))")

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "event_attendees"
        )

        await channel.subscribe()
        myAttendeeChangesChannel = channel

        #if DEBUG
        print("[MyAttendees] Subscribed to realtime channel for user: \(userId)")
        #endif

        Task { [weak self] in
            for await change in changes {
                guard let self = self else { return }

                // Extract user_id from the change to check if it's for current user
                var changeUserId: String? = nil

                switch change {
                case .insert(let action):
                    changeUserId = action.record["user_id"]?.stringValue
                case .update(let action):
                    changeUserId = action.record["user_id"]?.stringValue
                case .delete(let action):
                    changeUserId = action.oldRecord["user_id"]?.stringValue
                }

                // Only handle changes for current user
                guard let userIdStr = changeUserId,
                      userIdStr == userId.uuidString else {
                    continue
                }

                #if DEBUG
                print("[MyAttendees] Change detected for current user, refreshing posts...")
                #endif

                // Refresh posts to update attendance/pending status
                await MainActor.run {
                    Task {
                        try? await self.fetchPosts()
                    }
                }
            }
        }
    }

    // MARK: - Event Group Messages

    /// Fetches messages for an event's group chat.
    ///
    /// - Parameter eventId: The event post's UUID.
    /// - Returns: Array of event messages.
    public func fetchEventMessages(for eventId: UUID) async throws -> [EventMessage] {
        // Fetch messages
        var messages: [EventMessage] = try await client
            .from("event_messages")
            .select("*")
            .eq("event_id", value: eventId)
            .order("created_at", ascending: true)
            .execute()
            .value

        // Fetch author profiles for each unique user
        let userIds = Array(Set(messages.map { $0.userId }))
        if !userIds.isEmpty {
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select("*")
                .in("id", values: userIds)
                .execute()
                .value

            let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Attach authors to messages
            for i in messages.indices {
                messages[i].author = profileMap[messages[i].userId]
            }
        }

        return messages
    }

    /// Sends a message to an event's group chat.
    ///
    /// - Parameters:
    ///   - eventId: The event post's UUID.
    ///   - content: The message content.
    /// - Returns: The created message.
    public func sendEventMessage(eventId: UUID, content: String) async throws -> EventMessage {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }

        struct MessageCreate: Encodable {
            let event_id: UUID
            let user_id: UUID
            let content: String
        }

        let request = MessageCreate(event_id: eventId, user_id: userId, content: content)

        // Insert without author join - current user's info not needed from DB
        let message: EventMessage = try await client
            .from("event_messages")
            .insert(request)
            .select("*")
            .single()
            .execute()
            .value

        return message
    }

    /// Subscribes to real-time event messages for a specific event.
    ///
    /// - Parameter eventId: The event's UUID.
    public func subscribeToEventMessages(eventId: UUID) async {
        // Unsubscribe from any existing channel first
        await eventMessagesChannel?.unsubscribe()

        let channel = client.realtimeV2.channel("event_messages_\(eventId.uuidString.prefix(8))")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "event_messages"
        )

        await channel.subscribe()
        eventMessagesChannel = channel

        #if DEBUG
        print("[EventMessages] Subscribed to realtime channel")
        #endif

        Task { [weak self] in
            for await insertion in insertions {
                guard let self = self else { return }

                #if DEBUG
                print("[EventMessages] Received insertion: \(insertion.record)")
                #endif

                // Extract values from record
                guard let idString = insertion.record["id"]?.stringValue,
                      let id = UUID(uuidString: idString),
                      let eventIdString = insertion.record["event_id"]?.stringValue,
                      let msgEventId = UUID(uuidString: eventIdString),
                      let userIdString = insertion.record["user_id"]?.stringValue,
                      let userId = UUID(uuidString: userIdString),
                      let content = insertion.record["content"]?.stringValue else {
                    #if DEBUG
                    print("[EventMessages] Failed to parse message record")
                    #endif
                    continue
                }

                // Only handle messages for this event
                guard msgEventId == eventId else {
                    #if DEBUG
                    print("[EventMessages] Message for different event, ignoring")
                    #endif
                    continue
                }

                // Don't notify for our own messages (already added locally)
                if userId == SupabaseManager.shared.currentUser?.id {
                    #if DEBUG
                    print("[EventMessages] Own message, skipping")
                    #endif
                    continue
                }

                #if DEBUG
                print("[EventMessages] Processing message from user: \(userId)")
                #endif

                // Fetch the author profile
                var author: UserProfile? = nil
                do {
                    author = try await self.client
                        .from("profiles")
                        .select("*")
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value
                } catch {
                    #if DEBUG
                    print("[EventMessages] Failed to fetch author: \(error)")
                    #endif
                }

                let createdAt = insertion.record["created_at"]?.stringValue.flatMap { str -> Date? in
                    Self.iso8601FractionalFormatter.date(from: str)
                }

                let newMessage = EventMessage(
                    id: id,
                    eventId: msgEventId,
                    userId: userId,
                    content: content,
                    createdAt: createdAt,
                    author: author
                )

                await MainActor.run {
                    #if DEBUG
                    print("[EventMessages] Calling onNewEventMessage callback")
                    #endif
                    self.onNewEventMessage?(newMessage)
                }
            }
        }
    }

    /// Unsubscribes from event messages channel.
    public func unsubscribeFromEventMessages() async {
        await eventMessagesChannel?.unsubscribe()
        eventMessagesChannel = nil
        onNewEventMessage = nil
    }

    // MARK: - Event Chat Mutes

    /// Check if the current user has muted an event chat.
    public func isEventChatMuted(_ eventId: UUID) async throws -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }
        let response: [EventChatMute] = try await SupabaseManager.shared.client
            .from("event_chat_mutes")
            .select()
            .eq("event_id", value: eventId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return !response.isEmpty
    }

    /// Mute an event chat for the current user.
    public func muteEventChat(_ eventId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }
        try await SupabaseManager.shared.client
            .from("event_chat_mutes")
            .insert(EventChatMuteRequest(eventId: eventId, userId: userId))
            .execute()
    }

    /// Unmute an event chat for the current user.
    public func unmuteEventChat(_ eventId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw CommunityError.notAuthenticated
        }
        try await SupabaseManager.shared.client
            .from("event_chat_mutes")
            .delete()
            .eq("event_id", value: eventId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Event Message Model

public struct EventMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let eventId: UUID
    public let userId: UUID
    public let content: String
    public let createdAt: Date?
    public var author: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case author
    }

    public init(
        id: UUID,
        eventId: UUID,
        userId: UUID,
        content: String,
        createdAt: Date?,
        author: UserProfile? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.author = author
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    public var formattedTime: String {
        guard let date = createdAt else { return "" }
        return Self.timeFormatter.string(from: date)
    }
}

// MARK: - Event Chat Mute Models

struct EventChatMute: Codable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct EventChatMuteRequest: Encodable {
    let eventId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case userId = "user_id"
    }
}

// MARK: - Errors

public enum CommunityError: LocalizedError {
    case notAuthenticated
    case postNotFound
    case notAuthorized

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .postNotFound:
            return "Post not found."
        case .notAuthorized:
            return "You are not authorized to perform this action."
        }
    }
}
