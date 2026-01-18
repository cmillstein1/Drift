import Foundation

// MARK: - VanBuilderChannel

public struct VanBuilderChannel: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let icon: String
    public let color: String
    public var memberCount: Int
    public var trending: Bool
    public let sortOrder: Int
    public let createdAt: Date?

    // Local state for UI
    public var unreadCount: Int?
    public var isMember: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color
        case memberCount = "member_count"
        case trending
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        icon: String,
        color: String,
        memberCount: Int = 0,
        trending: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date? = nil,
        unreadCount: Int? = nil,
        isMember: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.memberCount = memberCount
        self.trending = trending
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.unreadCount = unreadCount
        self.isMember = isMember
    }

    public var formattedMemberCount: String {
        if memberCount >= 1000 {
            return "\(memberCount / 1000)k members"
        }
        return "\(memberCount) members"
    }
}

// MARK: - ChannelMembership

public struct ChannelMembership: Codable, Identifiable, Sendable {
    public let id: UUID
    public let channelId: String
    public let userId: UUID
    public let joinedAt: Date?
    public var lastReadAt: Date?
    public var notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case notificationsEnabled = "notifications_enabled"
    }

    public init(
        id: UUID = UUID(),
        channelId: String,
        userId: UUID,
        joinedAt: Date? = nil,
        lastReadAt: Date? = nil,
        notificationsEnabled: Bool = true
    ) {
        self.id = id
        self.channelId = channelId
        self.userId = userId
        self.joinedAt = joinedAt
        self.lastReadAt = lastReadAt
        self.notificationsEnabled = notificationsEnabled
    }
}

// MARK: - ChannelMessage

public struct ChannelMessage: Codable, Identifiable, Sendable {
    public let id: UUID
    public let channelId: String
    public let userId: UUID
    public var content: String
    public var images: [String]

    // Engagement
    public var likes: Int
    public var replyCount: Int
    public var likedBy: [UUID]

    // Threading
    public var parentId: UUID?

    // Moderation
    public var isPinned: Bool
    public var isExpertPost: Bool

    public let createdAt: Date?
    public var updatedAt: Date?
    public var deletedAt: Date?

    // Joined data
    public var user: UserProfile?
    public var replies: [ChannelMessage]?

    enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case userId = "user_id"
        case content, images, likes
        case replyCount = "reply_count"
        case likedBy = "liked_by"
        case parentId = "parent_id"
        case isPinned = "is_pinned"
        case isExpertPost = "is_expert_post"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case user, replies
    }

    public init(
        id: UUID = UUID(),
        channelId: String,
        userId: UUID,
        content: String,
        images: [String] = [],
        likes: Int = 0,
        replyCount: Int = 0,
        likedBy: [UUID] = [],
        parentId: UUID? = nil,
        isPinned: Bool = false,
        isExpertPost: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        user: UserProfile? = nil,
        replies: [ChannelMessage]? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.userId = userId
        self.content = content
        self.images = images
        self.likes = likes
        self.replyCount = replyCount
        self.likedBy = likedBy
        self.parentId = parentId
        self.isPinned = isPinned
        self.isExpertPost = isExpertPost
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.user = user
        self.replies = replies
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        channelId = try container.decode(String.self, forKey: .channelId)
        userId = try container.decode(UUID.self, forKey: .userId)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        replyCount = try container.decodeIfPresent(Int.self, forKey: .replyCount) ?? 0
        likedBy = try container.decodeIfPresent([UUID].self, forKey: .likedBy) ?? []
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isExpertPost = try container.decodeIfPresent(Bool.self, forKey: .isExpertPost) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        user = try container.decodeIfPresent(UserProfile.self, forKey: .user)
        replies = try container.decodeIfPresent([ChannelMessage].self, forKey: .replies)
    }

    // Computed properties
    public var timestamp: String {
        guard let date = createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    public func isLikedBy(_ userId: UUID) -> Bool {
        likedBy.contains(userId)
    }

    public var isReply: Bool {
        parentId != nil
    }
}

// MARK: - VanBuilderExpert

public struct VanBuilderExpert: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var specialty: String
    public var bio: String?
    public var rating: Double
    public var reviewCount: Int
    public var verified: Bool
    public var availableForBooking: Bool
    public var hourlyRate: Double?
    public let createdAt: Date?

    // Joined data
    public var profile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case specialty, bio, rating
        case reviewCount = "review_count"
        case verified
        case availableForBooking = "available_for_booking"
        case hourlyRate = "hourly_rate"
        case createdAt = "created_at"
        case profile
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        specialty: String,
        bio: String? = nil,
        rating: Double = 0,
        reviewCount: Int = 0,
        verified: Bool = true,
        availableForBooking: Bool = true,
        hourlyRate: Double? = nil,
        createdAt: Date? = nil,
        profile: UserProfile? = nil
    ) {
        self.id = id
        self.userId = userId
        self.specialty = specialty
        self.bio = bio
        self.rating = rating
        self.reviewCount = reviewCount
        self.verified = verified
        self.availableForBooking = availableForBooking
        self.hourlyRate = hourlyRate
        self.createdAt = createdAt
        self.profile = profile
    }

    public var formattedRating: String {
        String(format: "%.1f", rating)
    }

    public var formattedHourlyRate: String? {
        guard let rate = hourlyRate else { return nil }
        return String(format: "$%.0f/hr", rate)
    }
}

// MARK: - VanBuilderResource

public struct VanBuilderResource: Codable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String?
    public var category: String
    public var fileUrl: String?
    public var thumbnailUrl: String?
    public let uploadedBy: UUID?
    public var views: Int
    public var saves: Int
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, category
        case fileUrl = "file_url"
        case thumbnailUrl = "thumbnail_url"
        case uploadedBy = "uploaded_by"
        case views, saves
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        category: String,
        fileUrl: String? = nil,
        thumbnailUrl: String? = nil,
        uploadedBy: UUID? = nil,
        views: Int = 0,
        saves: Int = 0,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.fileUrl = fileUrl
        self.thumbnailUrl = thumbnailUrl
        self.uploadedBy = uploadedBy
        self.views = views
        self.saves = saves
        self.createdAt = createdAt
    }

    public var formattedViews: String {
        if views >= 1000 {
            return "\(views / 1000)k views"
        }
        return "\(views) views"
    }
}

// MARK: - Channel Message Create Request

public struct ChannelMessageCreateRequest: Encodable {
    public let channelId: String
    public let userId: UUID
    public let content: String
    public let images: [String]
    public let parentId: UUID?

    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case userId = "user_id"
        case content
        case images
        case parentId = "parent_id"
    }

    public init(
        channelId: String,
        userId: UUID,
        content: String,
        images: [String] = [],
        parentId: UUID? = nil
    ) {
        self.channelId = channelId
        self.userId = userId
        self.content = content
        self.images = images
        self.parentId = parentId
    }
}

// MARK: - Channel Membership Create Request

public struct ChannelMembershipCreateRequest: Encodable {
    public let channelId: String
    public let userId: UUID

    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case userId = "user_id"
    }

    public init(channelId: String, userId: UUID) {
        self.channelId = channelId
        self.userId = userId
    }
}
