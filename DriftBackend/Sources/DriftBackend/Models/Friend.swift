import Foundation

// MARK: - Enums

public enum FriendStatus: String, Codable, Sendable {
    case pending
    case accepted
    case declined
    case blocked
}

public enum SwipeDirection: String, Codable, Sendable {
    case left
    case right
    case up // Super like
}

public enum SwipeType: String, Codable, Sendable {
    case dating
    case friends
}

// MARK: - Friend

public struct Friend: Codable, Identifiable, Sendable {
    public let id: UUID
    public let requesterId: UUID
    public let addresseeId: UUID
    public var status: FriendStatus
    public let createdAt: Date?
    public var updatedAt: Date?

    // Joined data from related tables
    public var requesterProfile: UserProfile?
    public var addresseeProfile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case requesterProfile = "requester"
        case addresseeProfile = "addressee"
    }

    public init(
        id: UUID = UUID(),
        requesterId: UUID,
        addresseeId: UUID,
        status: FriendStatus = .pending,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        requesterProfile: UserProfile? = nil,
        addresseeProfile: UserProfile? = nil
    ) {
        self.id = id
        self.requesterId = requesterId
        self.addresseeId = addresseeId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.requesterProfile = requesterProfile
        self.addresseeProfile = addresseeProfile
    }

    /// Get the other user's profile given the current user's ID
    public func otherProfile(currentUserId: UUID) -> UserProfile? {
        if requesterId == currentUserId {
            return addresseeProfile
        } else {
            return requesterProfile
        }
    }
}

// MARK: - Match

public struct Match: Codable, Identifiable, Sendable {
    public let id: UUID
    public let user1Id: UUID
    public let user2Id: UUID
    public var user1LikedAt: Date?
    public var user2LikedAt: Date?
    public var matchedAt: Date?
    public var isMatch: Bool
    public let createdAt: Date?

    // Joined data - the other user's profile
    public var otherUserProfile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case user1LikedAt = "user1_liked_at"
        case user2LikedAt = "user2_liked_at"
        case matchedAt = "matched_at"
        case isMatch = "is_match"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        user1Id: UUID,
        user2Id: UUID,
        user1LikedAt: Date? = nil,
        user2LikedAt: Date? = nil,
        matchedAt: Date? = nil,
        isMatch: Bool = false,
        createdAt: Date? = nil,
        otherUserProfile: UserProfile? = nil
    ) {
        self.id = id
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.user1LikedAt = user1LikedAt
        self.user2LikedAt = user2LikedAt
        self.matchedAt = matchedAt
        self.isMatch = isMatch
        self.createdAt = createdAt
        self.otherUserProfile = otherUserProfile
    }

    /// Get the other user's ID given the current user's ID
    public func otherUserId(currentUserId: UUID) -> UUID {
        if user1Id == currentUserId {
            return user2Id
        } else {
            return user1Id
        }
    }
}

// MARK: - Swipe

public struct Swipe: Codable, Identifiable, Sendable {
    public let id: UUID
    public let swiperId: UUID
    public let swipedId: UUID
    public let direction: SwipeDirection
    public let type: SwipeType?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case swiperId = "swiper_id"
        case swipedId = "swiped_id"
        case direction
        case type
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        swiperId: UUID,
        swipedId: UUID,
        direction: SwipeDirection,
        type: SwipeType? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.swiperId = swiperId
        self.swipedId = swipedId
        self.direction = direction
        self.type = type
        self.createdAt = createdAt
    }
}

// MARK: - Friend Request

public struct FriendRequest: Encodable {
    public let requesterId: UUID
    public let addresseeId: UUID
    public let status: FriendStatus

    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
    }

    public init(requesterId: UUID, addresseeId: UUID, status: FriendStatus = .pending) {
        self.requesterId = requesterId
        self.addresseeId = addresseeId
        self.status = status
    }
}

// MARK: - Swipe Request

public struct SwipeRequest: Encodable {
    public let swiperId: UUID
    public let swipedId: UUID
    public let direction: SwipeDirection
    public let type: SwipeType

    enum CodingKeys: String, CodingKey {
        case swiperId = "swiper_id"
        case swipedId = "swiped_id"
        case direction
        case type
    }

    public init(swiperId: UUID, swipedId: UUID, direction: SwipeDirection, type: SwipeType) {
        self.swiperId = swiperId
        self.swipedId = swipedId
        self.direction = direction
        self.type = type
    }
}

// MARK: - Swipe Record (for decoding)

public struct SwipeRecord: Decodable {
    public let id: UUID
    public let swiperId: UUID
    public let swipedId: UUID
    public let direction: String
    public let type: String?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case swiperId = "swiper_id"
        case swipedId = "swiped_id"
        case direction
        case type
        case createdAt = "created_at"
    }
}

// MARK: - Match Request (for creating)

public struct MatchRequest: Encodable {
    public let user1Id: UUID
    public let user2Id: UUID
    public let isMatch: Bool

    enum CodingKeys: String, CodingKey {
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case isMatch = "is_match"
    }

    public init(user1Id: UUID, user2Id: UUID, isMatch: Bool) {
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.isMatch = isMatch
    }
}
