import Foundation

// MARK: - Enums

public enum ConversationType: String, Codable, Sendable {
    case dating
    case friends
    case activity
}

// MARK: - Conversation

public struct Conversation: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let type: ConversationType
    public var activityId: UUID?
    public let createdAt: Date?
    public var updatedAt: Date?

    // Joined data
    public var participants: [ConversationParticipant]?
    public var lastMessage: Message?
    public var otherUser: UserProfile? // For 1:1 conversations

    enum CodingKeys: String, CodingKey {
        case id, type
        case activityId = "activity_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case participants
        case lastMessage = "last_message"
    }

    public init(
        id: UUID = UUID(),
        type: ConversationType,
        activityId: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        participants: [ConversationParticipant]? = nil,
        lastMessage: Message? = nil,
        otherUser: UserProfile? = nil
    ) {
        self.id = id
        self.type = type
        self.activityId = activityId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.participants = participants
        self.lastMessage = lastMessage
        self.otherUser = otherUser
    }

    // Computed properties for UI
    public var displayName: String {
        otherUser?.displayName ?? "Unknown"
    }

    public var avatarUrl: String? {
        otherUser?.avatarUrl
    }

    /// Avatar URL for display only (user-uploaded to our storage). Use this when showing the conversation in the UI.
    public var displayAvatarUrl: String? {
        otherUser?.primaryDisplayPhotoUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }

    public func hasUnreadMessages(for userId: UUID) -> Bool {
        guard let participant = participants?.first(where: { $0.userId == userId }),
              let lastReadAt = participant.lastReadAt,
              let lastMessageDate = lastMessage?.createdAt else {
            return lastMessage != nil
        }
        return lastMessageDate > lastReadAt
    }

    /// Whether the given user has left this conversation (delete).
    /// If we can't find the participant (e.g. decode failed or not loaded), treat as not left so the conversation still shows.
    public func hasLeft(for userId: UUID) -> Bool {
        guard let participant = participants?.first(where: { $0.userId == userId }) else { return false }
        return participant.leftAt != nil
    }

    /// Whether the given user has this conversation in Hidden (reversible).
    /// If we can't find the participant, treat as not hidden so the conversation still shows.
    public func isHidden(for userId: UUID) -> Bool {
        guard let participant = participants?.first(where: { $0.userId == userId }) else { return false }
        return participant.hiddenAt != nil
    }

    /// Current user's participant for this conversation, if present.
    public func participant(for userId: UUID) -> ConversationParticipant? {
        participants?.first(where: { $0.userId == userId })
    }
}

// MARK: - ConversationParticipant

public struct ConversationParticipant: Codable, Identifiable, Sendable {
    public let id: UUID
    public let conversationId: UUID
    public let userId: UUID
    public let joinedAt: Date?
    public var lastReadAt: Date?
    public var isMuted: Bool
    public var hiddenAt: Date?
    public var leftAt: Date?

    // Joined data
    public var profile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case isMuted = "is_muted"
        case hiddenAt = "hidden_at"
        case leftAt = "left_at"
        case profile
    }

    public init(
        id: UUID = UUID(),
        conversationId: UUID,
        userId: UUID,
        joinedAt: Date? = nil,
        lastReadAt: Date? = nil,
        isMuted: Bool = false,
        hiddenAt: Date? = nil,
        leftAt: Date? = nil,
        profile: UserProfile? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.userId = userId
        self.joinedAt = joinedAt
        self.lastReadAt = lastReadAt
        self.isMuted = isMuted
        self.hiddenAt = hiddenAt
        self.leftAt = leftAt
        self.profile = profile
    }
}

// MARK: - Message

public struct Message: Codable, Identifiable, Sendable {
    public let id: UUID
    public let conversationId: UUID
    public let senderId: UUID
    public var content: String
    public var images: [String]
    public var readBy: [UUID]
    public let createdAt: Date?
    public var updatedAt: Date?
    public var deletedAt: Date?

    // Joined data
    public var sender: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content, images
        case readBy = "read_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case sender
    }

    public init(
        id: UUID = UUID(),
        conversationId: UUID,
        senderId: UUID,
        content: String,
        images: [String] = [],
        readBy: [UUID] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        sender: UserProfile? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.images = images
        self.readBy = readBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.sender = sender
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        conversationId = try container.decode(UUID.self, forKey: .conversationId)
        senderId = try container.decode(UUID.self, forKey: .senderId)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        readBy = try container.decodeIfPresent([UUID].self, forKey: .readBy) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        sender = try container.decodeIfPresent(UserProfile.self, forKey: .sender)
    }

    // Check if this message was sent by a specific user
    public func isSentBy(_ userId: UUID) -> Bool {
        senderId == userId
    }

    // Formatted timestamp for display
    public var formattedTime: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Message Request

public struct MessageRequest: Encodable {
    public let conversationId: UUID
    public let senderId: UUID
    public let content: String
    public let images: [String]

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case images
    }

    public init(conversationId: UUID, senderId: UUID, content: String, images: [String] = []) {
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.images = images
    }
}

// MARK: - Conversation Create Request

public struct ConversationCreateRequest: Encodable {
    public let type: ConversationType
    public let activityId: UUID?

    enum CodingKeys: String, CodingKey {
        case type
        case activityId = "activity_id"
    }

    public init(type: ConversationType, activityId: UUID? = nil) {
        self.type = type
        self.activityId = activityId
    }
}

// MARK: - Participant Create Request

public struct ParticipantCreateRequest: Encodable {
    public let conversationId: UUID
    public let userId: UUID

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case userId = "user_id"
    }

    public init(conversationId: UUID, userId: UUID) {
        self.conversationId = conversationId
        self.userId = userId
    }
}
