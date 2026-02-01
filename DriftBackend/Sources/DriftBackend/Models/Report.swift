import Foundation

// MARK: - Report Enums

/// Category for user reports
public enum ReportCategory: String, Codable, CaseIterable, Sendable {
    case spam
    case harassment
    case inappropriate
    case scam
    case other

    public var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .inappropriate: return "Inappropriate Content"
        case .scam: return "Scam/Fraud"
        case .other: return "Other"
        }
    }

    public var icon: String {
        switch self {
        case .spam: return "exclamationmark.bubble"
        case .harassment: return "hand.raised"
        case .inappropriate: return "eye.slash"
        case .scam: return "exclamationmark.shield"
        case .other: return "ellipsis.circle"
        }
    }

    public var description: String {
        switch self {
        case .spam: return "Unsolicited promotional content"
        case .harassment: return "Bullying or threatening behavior"
        case .inappropriate: return "Offensive or explicit content"
        case .scam: return "Attempts to deceive or defraud"
        case .other: return "Other concerns"
        }
    }
}

/// Type of content being reported
public enum ReportContentType: String, Codable, Sendable {
    case profile
    case post
    case message
    case activity
}

// MARK: - ContentSnapshot

/// Snapshot of reported content (preserved even if original is deleted)
public struct ContentSnapshot: Codable, Sendable {
    public let type: ReportContentType
    public var userName: String?
    public var userAvatar: String?
    public var title: String?
    public var content: String?
    public var images: [String]?

    enum CodingKeys: String, CodingKey {
        case type
        case userName
        case userAvatar
        case title
        case content
        case images
    }

    public init(
        type: ReportContentType,
        userName: String? = nil,
        userAvatar: String? = nil,
        title: String? = nil,
        content: String? = nil,
        images: [String]? = nil
    ) {
        self.type = type
        self.userName = userName
        self.userAvatar = userAvatar
        self.title = title
        self.content = content
        self.images = images
    }

    /// Create a snapshot from a UserProfile
    public static func from(profile: UserProfile) -> ContentSnapshot {
        ContentSnapshot(
            type: .profile,
            userName: profile.displayName,
            userAvatar: profile.avatarUrl,
            content: profile.bio
        )
    }

    /// Create a snapshot from a CommunityPost
    public static func from(post: CommunityPost) -> ContentSnapshot {
        ContentSnapshot(
            type: .post,
            userName: post.author?.displayName,
            userAvatar: post.author?.avatarUrl,
            title: post.title,
            content: post.content,
            images: post.images.isEmpty ? nil : post.images
        )
    }

    /// Create a snapshot from a Message
    public static func from(message: Message, senderProfile: UserProfile?) -> ContentSnapshot {
        ContentSnapshot(
            type: .message,
            userName: senderProfile?.displayName ?? message.sender?.displayName,
            userAvatar: senderProfile?.avatarUrl ?? message.sender?.avatarUrl,
            content: message.content,
            images: message.images.isEmpty ? nil : message.images
        )
    }

    /// Create a snapshot from an Activity
    public static func from(activity: Activity) -> ContentSnapshot {
        ContentSnapshot(
            type: .activity,
            userName: activity.host?.displayName,
            userAvatar: activity.host?.avatarUrl,
            title: activity.title,
            content: activity.description,
            images: activity.imageUrl != nil ? [activity.imageUrl!] : nil
        )
    }
}

// MARK: - Report Request

/// Request body for creating a report via Edge Function
public struct ReportRequest: Encodable, Sendable {
    public let reportedUserId: String
    public let category: String
    public let description: String?
    public let postId: String?
    public let messageId: String?
    public let activityId: String?
    public let contentSnapshot: ContentSnapshot

    enum CodingKeys: String, CodingKey {
        case reportedUserId = "reported_user_id"
        case category
        case description
        case postId = "post_id"
        case messageId = "message_id"
        case activityId = "activity_id"
        case contentSnapshot = "content_snapshot"
    }

    public init(
        reportedUserId: UUID,
        category: ReportCategory,
        description: String? = nil,
        postId: UUID? = nil,
        messageId: UUID? = nil,
        activityId: UUID? = nil,
        contentSnapshot: ContentSnapshot
    ) {
        self.reportedUserId = reportedUserId.uuidString
        self.category = category.rawValue
        self.description = description?.isEmpty == true ? nil : description
        self.postId = postId?.uuidString
        self.messageId = messageId?.uuidString
        self.activityId = activityId?.uuidString
        self.contentSnapshot = contentSnapshot
    }
}

// MARK: - Report Response

/// Response from the send-report Edge Function
public struct ReportResponse: Decodable, Sendable {
    public let success: Bool
    public let reportId: String?
    public let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case reportId = "report_id"
        case error
    }
}
