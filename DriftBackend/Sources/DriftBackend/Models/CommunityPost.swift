import Foundation

// MARK: - Enums

/// Type of community post
public enum CommunityPostType: String, Codable, CaseIterable, Sendable {
    case event
    case help
}

/// Category for help posts
public enum HelpCategory: String, Codable, CaseIterable, Sendable {
    case electrical
    case solar
    case plumbing
    case woodwork
    case mechanical
    case other

    public var displayName: String {
        switch self {
        case .electrical: return "Electrical"
        case .solar: return "Solar"
        case .plumbing: return "Plumbing"
        case .woodwork: return "Woodwork"
        case .mechanical: return "Mechanical"
        case .other: return "Other"
        }
    }

    public var icon: String {
        switch self {
        case .electrical: return "bolt.fill"
        case .solar: return "sun.max.fill"
        case .plumbing: return "drop.fill"
        case .woodwork: return "hammer.fill"
        case .mechanical: return "wrench.and.screwdriver.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    public var color: String {
        switch self {
        case .electrical: return "BurntOrange"
        case .solar: return "DesertSand"
        case .plumbing: return "SkyBlue"
        case .woodwork: return "Charcoal"
        case .mechanical: return "ForestGreen"
        case .other: return "SoftGray"
        }
    }
}

/// Status for event attendees
public enum EventAttendeeStatus: String, Codable, Sendable {
    case pending
    case confirmed
    case cancelled
}

/// Privacy setting for events
public enum EventPrivacy: String, Codable, Sendable {
    case `public` = "public"
    case `private` = "private"
    case inviteOnly = "invite_only"  // Legacy - treated same as private

    // Only show public and private in UI
    public static var selectableCases: [EventPrivacy] {
        [.public, .private]
    }

    public var displayName: String {
        switch self {
        case .public: return "Public"
        case .private, .inviteOnly: return "Private"
        }
    }

    public var description: String {
        switch self {
        case .public: return "Anyone can see and join"
        case .private, .inviteOnly: return "Request to join, host approves"
        }
    }

    public var icon: String {
        switch self {
        case .public: return "globe"
        case .private, .inviteOnly: return "lock"
        }
    }

    // Treat inviteOnly same as private
    public var isPrivate: Bool {
        self == .private || self == .inviteOnly
    }
}

// MARK: - CommunityPost Model

/// A unified community post that can be either an Event or a Help request
public struct CommunityPost: Codable, Identifiable, Sendable {
    public let id: UUID
    public let authorId: UUID
    public let type: CommunityPostType

    // Common fields
    public var title: String
    public var content: String
    public var images: [String]
    public var imageAttributionName: String?
    public var imageAttributionUrl: String?
    public var likeCount: Int
    public var replyCount: Int

    // Event-specific fields (nullable for help posts)
    public var eventDatetime: Date?
    public var eventLocation: String?
    public var eventExactLocation: String?
    public var eventLatitude: Double?
    public var eventLongitude: Double?
    public var maxAttendees: Int?
    public var currentAttendees: Int?
    public var eventPrivacy: EventPrivacy?
    /// When true, only visible to users with dating or both (hidden from friends-only).
    public var isDatingEvent: Bool?

    // Help-specific fields (nullable for event posts)
    public var helpCategory: HelpCategory?
    public var isSolved: Bool?
    public var bestAnswerId: UUID?

    // Timestamps
    public let createdAt: Date?
    public var updatedAt: Date?
    public var deletedAt: Date?

    // Joined relationships
    public var author: UserProfile?
    public var attendees: [EventAttendee]?
    public var replies: [PostReply]?

    // Local UI state (not from database)
    public var isLikedByCurrentUser: Bool?
    public var isAttendingEvent: Bool?
    public var hasPendingRequest: Bool?
    /// Number of pending join requests (for event hosts)
    public var pendingRequestCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case type
        case title
        case content
        case images
        case imageAttributionName = "image_attribution_name"
        case imageAttributionUrl = "image_attribution_url"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case eventDatetime = "event_datetime"
        case eventLocation = "event_location"
        case eventExactLocation = "event_exact_location"
        case eventLatitude = "event_latitude"
        case eventLongitude = "event_longitude"
        case maxAttendees = "max_attendees"
        case currentAttendees = "current_attendees"
        case eventPrivacy = "event_privacy"
        case isDatingEvent = "is_dating_event"
        case helpCategory = "help_category"
        case isSolved = "is_solved"
        case bestAnswerId = "best_answer_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case author
        case attendees
        case replies
    }

    public init(
        id: UUID = UUID(),
        authorId: UUID,
        type: CommunityPostType,
        title: String,
        content: String,
        images: [String] = [],
        imageAttributionName: String? = nil,
        imageAttributionUrl: String? = nil,
        likeCount: Int = 0,
        replyCount: Int = 0,
        eventDatetime: Date? = nil,
        eventLocation: String? = nil,
        eventExactLocation: String? = nil,
        eventLatitude: Double? = nil,
        eventLongitude: Double? = nil,
        maxAttendees: Int? = nil,
        currentAttendees: Int? = nil,
        eventPrivacy: EventPrivacy? = nil,
        isDatingEvent: Bool? = nil,
        helpCategory: HelpCategory? = nil,
        isSolved: Bool? = nil,
        bestAnswerId: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        author: UserProfile? = nil,
        attendees: [EventAttendee]? = nil,
        replies: [PostReply]? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.type = type
        self.title = title
        self.content = content
        self.images = images
        self.imageAttributionName = imageAttributionName
        self.imageAttributionUrl = imageAttributionUrl
        self.likeCount = likeCount
        self.replyCount = replyCount
        self.eventDatetime = eventDatetime
        self.eventLocation = eventLocation
        self.eventExactLocation = eventExactLocation
        self.eventLatitude = eventLatitude
        self.eventLongitude = eventLongitude
        self.maxAttendees = maxAttendees
        self.currentAttendees = currentAttendees
        self.eventPrivacy = eventPrivacy
        self.isDatingEvent = isDatingEvent
        self.helpCategory = helpCategory
        self.isSolved = isSolved
        self.bestAnswerId = bestAnswerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.author = author
        self.attendees = attendees
        self.replies = replies
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        authorId = try container.decode(UUID.self, forKey: .authorId)
        type = try container.decode(CommunityPostType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        imageAttributionName = try container.decodeIfPresent(String.self, forKey: .imageAttributionName)
        imageAttributionUrl = try container.decodeIfPresent(String.self, forKey: .imageAttributionUrl)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        replyCount = try container.decodeIfPresent(Int.self, forKey: .replyCount) ?? 0

        // Event fields
        eventDatetime = try container.decodeIfPresent(Date.self, forKey: .eventDatetime)
        eventLocation = try container.decodeIfPresent(String.self, forKey: .eventLocation)
        eventExactLocation = try container.decodeIfPresent(String.self, forKey: .eventExactLocation)
        eventLatitude = try container.decodeIfPresent(Double.self, forKey: .eventLatitude)
        eventLongitude = try container.decodeIfPresent(Double.self, forKey: .eventLongitude)
        maxAttendees = try container.decodeIfPresent(Int.self, forKey: .maxAttendees)
        currentAttendees = try container.decodeIfPresent(Int.self, forKey: .currentAttendees)
        eventPrivacy = try container.decodeIfPresent(EventPrivacy.self, forKey: .eventPrivacy)
        isDatingEvent = try container.decodeIfPresent(Bool.self, forKey: .isDatingEvent)

        // Help fields
        helpCategory = try container.decodeIfPresent(HelpCategory.self, forKey: .helpCategory)
        isSolved = try container.decodeIfPresent(Bool.self, forKey: .isSolved)
        bestAnswerId = try container.decodeIfPresent(UUID.self, forKey: .bestAnswerId)

        // Timestamps
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)

        // Relationships
        author = try container.decodeIfPresent(UserProfile.self, forKey: .author)
        attendees = try container.decodeIfPresent([EventAttendee].self, forKey: .attendees)
        replies = try container.decodeIfPresent([PostReply].self, forKey: .replies)
    }

    // MARK: - Computed Properties

    /// Spots remaining for an event
    public var spotsLeft: Int? {
        guard type == .event, let maxCount = maxAttendees else { return nil }
        return Swift.max(0, maxCount - (currentAttendees ?? 0))
    }

    /// Whether the event is full
    public var isFull: Bool {
        guard type == .event, let maxCount = maxAttendees else { return false }
        return (currentAttendees ?? 0) >= maxCount
    }

    /// Relative time since creation
    public var timeAgo: String {
        guard let date = createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Formatted event date
    public var formattedEventDate: String? {
        guard let date = eventDatetime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d • h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - PostReply Model

/// A reply/comment on a community post
public struct PostReply: Codable, Identifiable, Sendable {
    public let id: UUID
    public let postId: UUID
    public let authorId: UUID
    public var content: String
    public var images: [String]
    public var parentReplyId: UUID?
    public var likeCount: Int
    public var isExpertReply: Bool
    public let createdAt: Date?
    public var updatedAt: Date?
    public var deletedAt: Date?

    // Joined relationships
    public var author: UserProfile?
    public var childReplies: [PostReply]?

    // Local UI state
    public var isLikedByCurrentUser: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case authorId = "author_id"
        case content
        case images
        case parentReplyId = "parent_reply_id"
        case likeCount = "like_count"
        case isExpertReply = "is_expert_reply"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case author
        case childReplies
    }

    public init(
        id: UUID = UUID(),
        postId: UUID,
        authorId: UUID,
        content: String,
        images: [String] = [],
        parentReplyId: UUID? = nil,
        likeCount: Int = 0,
        isExpertReply: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        author: UserProfile? = nil,
        childReplies: [PostReply]? = nil
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.content = content
        self.images = images
        self.parentReplyId = parentReplyId
        self.likeCount = likeCount
        self.isExpertReply = isExpertReply
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.author = author
        self.childReplies = childReplies
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        postId = try container.decode(UUID.self, forKey: .postId)
        authorId = try container.decode(UUID.self, forKey: .authorId)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        parentReplyId = try container.decodeIfPresent(UUID.self, forKey: .parentReplyId)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        isExpertReply = try container.decodeIfPresent(Bool.self, forKey: .isExpertReply) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        author = try container.decodeIfPresent(UserProfile.self, forKey: .author)
        childReplies = try container.decodeIfPresent([PostReply].self, forKey: .childReplies)
    }

    /// Relative time since creation
    public var timeAgo: String {
        guard let date = createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - EventAttendee Model

/// An attendee of an event post
public struct EventAttendee: Codable, Identifiable, Sendable {
    public let id: UUID
    public let postId: UUID
    public let userId: UUID
    public var status: EventAttendeeStatus
    public let joinedAt: Date?
    public var updatedAt: Date?

    // Joined relationships
    public var profile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case status
        case joinedAt = "joined_at"
        case updatedAt = "updated_at"
        case profile
    }

    public init(
        id: UUID = UUID(),
        postId: UUID,
        userId: UUID,
        status: EventAttendeeStatus = .confirmed,
        joinedAt: Date? = nil,
        updatedAt: Date? = nil,
        profile: UserProfile? = nil
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.status = status
        self.joinedAt = joinedAt
        self.updatedAt = updatedAt
        self.profile = profile
    }
}

// MARK: - PostLike Model

/// A like on a post or reply
public struct PostLike: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let postId: UUID?
    public let replyId: UUID?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case replyId = "reply_id"
        case createdAt = "created_at"
    }
}

// MARK: - Request Types

/// Request to create a new community post
public struct CommunityPostCreateRequest: Encodable {
    public let authorId: UUID
    public let type: CommunityPostType
    public let title: String
    public let content: String
    public let images: [String]
    public let imageAttributionName: String?
    public let imageAttributionUrl: String?

    // Event fields
    public let eventDatetime: Date?
    public let eventLocation: String?
    public let eventExactLocation: String?
    public let eventLatitude: Double?
    public let eventLongitude: Double?
    public let maxAttendees: Int?
    public let eventPrivacy: EventPrivacy?
    public let isDatingEvent: Bool?

    // Help fields
    public let helpCategory: HelpCategory?

    enum CodingKeys: String, CodingKey {
        case authorId = "author_id"
        case type
        case title
        case content
        case images
        case imageAttributionName = "image_attribution_name"
        case imageAttributionUrl = "image_attribution_url"
        case eventDatetime = "event_datetime"
        case eventLocation = "event_location"
        case eventExactLocation = "event_exact_location"
        case eventLatitude = "event_latitude"
        case eventLongitude = "event_longitude"
        case maxAttendees = "max_attendees"
        case eventPrivacy = "event_privacy"
        case isDatingEvent = "is_dating_event"
        case helpCategory = "help_category"
    }

    public init(
        authorId: UUID,
        type: CommunityPostType,
        title: String,
        content: String,
        images: [String] = [],
        imageAttributionName: String? = nil,
        imageAttributionUrl: String? = nil,
        eventDatetime: Date? = nil,
        eventLocation: String? = nil,
        eventExactLocation: String? = nil,
        eventLatitude: Double? = nil,
        eventLongitude: Double? = nil,
        maxAttendees: Int? = nil,
        eventPrivacy: EventPrivacy? = nil,
        isDatingEvent: Bool? = nil,
        helpCategory: HelpCategory? = nil
    ) {
        self.authorId = authorId
        self.type = type
        self.title = title
        self.content = content
        self.images = images
        self.imageAttributionName = imageAttributionName
        self.imageAttributionUrl = imageAttributionUrl
        self.eventDatetime = eventDatetime
        self.eventLocation = eventLocation
        self.eventExactLocation = eventExactLocation
        self.eventLatitude = eventLatitude
        self.eventLongitude = eventLongitude
        self.maxAttendees = maxAttendees
        self.eventPrivacy = eventPrivacy
        self.isDatingEvent = isDatingEvent
        self.helpCategory = helpCategory
    }
}

/// Request to create a new reply
public struct PostReplyCreateRequest: Encodable {
    public let postId: UUID
    public let authorId: UUID
    public let content: String
    public let images: [String]
    public let parentReplyId: UUID?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case authorId = "author_id"
        case content
        case images
        case parentReplyId = "parent_reply_id"
    }

    public init(
        postId: UUID,
        authorId: UUID,
        content: String,
        images: [String] = [],
        parentReplyId: UUID? = nil
    ) {
        self.postId = postId
        self.authorId = authorId
        self.content = content
        self.images = images
        self.parentReplyId = parentReplyId
    }
}

/// Request to create an event attendee
public struct EventAttendeeCreateRequest: Encodable {
    public let postId: UUID
    public let userId: UUID
    public let status: EventAttendeeStatus

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case status
    }

    public init(postId: UUID, userId: UUID, status: EventAttendeeStatus = .confirmed) {
        self.postId = postId
        self.userId = userId
        self.status = status
    }
}

/// Request to create a post like
public struct PostLikeCreateRequest: Encodable {
    public let userId: UUID
    public let postId: UUID?
    public let replyId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case postId = "post_id"
        case replyId = "reply_id"
    }

    public init(userId: UUID, postId: UUID? = nil, replyId: UUID? = nil) {
        self.userId = userId
        self.postId = postId
        self.replyId = replyId
    }
}
