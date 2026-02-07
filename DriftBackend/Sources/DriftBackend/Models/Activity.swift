import Foundation

// MARK: - Enums

public enum ActivityCategory: String, Codable, CaseIterable, Sendable {
    case outdoor
    case work
    case social
    case foodDrink = "food_drink"
    case wellness
    case adventure

    public var displayName: String {
        switch self {
        case .outdoor: return "Outdoor"
        case .work: return "Work"
        case .social: return "Social"
        case .foodDrink: return "Food & Drink"
        case .wellness: return "Wellness"
        case .adventure: return "Adventure"
        }
    }

    public var icon: String {
        switch self {
        case .outdoor: return "leaf.fill"
        case .work: return "laptopcomputer"
        case .social: return "person.2.fill"
        case .foodDrink: return "fork.knife"
        case .wellness: return "heart.fill"
        case .adventure: return "figure.hiking"
        }
    }

    public var color: String {
        switch self {
        case .outdoor: return "#22C55E"
        case .work: return "#3B82F6"
        case .social: return "#F59E0B"
        case .foodDrink: return "#EF4444"
        case .wellness: return "#EC4899"
        case .adventure: return "#8B5CF6"
        }
    }
}

public enum AttendeeStatus: String, Codable, Sendable {
    case pending
    case confirmed
    case cancelled
}

// MARK: - Activity

public struct Activity: Codable, Identifiable, Sendable {
    public let id: UUID
    public let hostId: UUID
    public var title: String
    public var description: String?
    public var category: ActivityCategory
    public var location: String
    public var exactLocation: String?
    public var imageUrl: String?
    /// Photographer name for Unsplash attribution (displayed on detail screen).
    public var imageAttributionName: String?
    /// Photographer's Unsplash profile URL for attribution link.
    public var imageAttributionUrl: String?

    public var startsAt: Date
    public var endsAt: Date?
    public var durationMinutes: Int?

    public var maxAttendees: Int
    public var currentAttendees: Int

    public let createdAt: Date?
    public var updatedAt: Date?
    public var cancelledAt: Date?

    /// When true, only the host can share this activity. When false, anyone can share.
    public var isPrivate: Bool

    // Joined data
    public var host: UserProfile?
    public var attendees: [ActivityAttendee]?

    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title, description, category, location
        case exactLocation = "exact_location"
        case imageUrl = "image_url"
        case imageAttributionName = "image_attribution_name"
        case imageAttributionUrl = "image_attribution_url"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case durationMinutes = "duration_minutes"
        case maxAttendees = "max_attendees"
        case currentAttendees = "current_attendees"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case cancelledAt = "cancelled_at"
        case isPrivate = "is_private"
        case host, attendees
    }

    public init(
        id: UUID = UUID(),
        hostId: UUID,
        title: String,
        description: String? = nil,
        category: ActivityCategory,
        location: String,
        exactLocation: String? = nil,
        imageUrl: String? = nil,
        imageAttributionName: String? = nil,
        imageAttributionUrl: String? = nil,
        startsAt: Date,
        endsAt: Date? = nil,
        durationMinutes: Int? = nil,
        maxAttendees: Int = 10,
        currentAttendees: Int = 0,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        cancelledAt: Date? = nil,
        isPrivate: Bool = false,
        host: UserProfile? = nil,
        attendees: [ActivityAttendee]? = nil
    ) {
        self.id = id
        self.hostId = hostId
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.exactLocation = exactLocation
        self.imageUrl = imageUrl
        self.imageAttributionName = imageAttributionName
        self.imageAttributionUrl = imageAttributionUrl
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.durationMinutes = durationMinutes
        self.maxAttendees = maxAttendees
        self.currentAttendees = currentAttendees
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cancelledAt = cancelledAt
        self.isPrivate = isPrivate
        self.host = host
        self.attendees = attendees
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        hostId = try container.decode(UUID.self, forKey: .hostId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decode(ActivityCategory.self, forKey: .category)
        location = try container.decode(String.self, forKey: .location)
        exactLocation = try container.decodeIfPresent(String.self, forKey: .exactLocation)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        imageAttributionName = try container.decodeIfPresent(String.self, forKey: .imageAttributionName)
        imageAttributionUrl = try container.decodeIfPresent(String.self, forKey: .imageAttributionUrl)
        startsAt = try container.decode(Date.self, forKey: .startsAt)
        endsAt = try container.decodeIfPresent(Date.self, forKey: .endsAt)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        maxAttendees = try container.decodeIfPresent(Int.self, forKey: .maxAttendees) ?? 10
        currentAttendees = try container.decodeIfPresent(Int.self, forKey: .currentAttendees) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        cancelledAt = try container.decodeIfPresent(Date.self, forKey: .cancelledAt)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        host = try container.decodeIfPresent(UserProfile.self, forKey: .host)
        attendees = try container.decodeIfPresent([ActivityAttendee].self, forKey: .attendees)
    }

    // Computed properties
    public var spotsLeft: Int {
        max(0, maxAttendees - currentAttendees)
    }

    public var isFull: Bool {
        currentAttendees >= maxAttendees
    }

    public var isCancelled: Bool {
        cancelledAt != nil
    }

    public var isPast: Bool {
        startsAt < Date()
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: startsAt)
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startsAt)
    }

    public var formattedDateTime: String {
        "\(formattedDate) at \(formattedTime)"
    }

    public func isAttending(userId: UUID) -> Bool {
        attendees?.contains(where: { $0.userId == userId && $0.status == .confirmed }) ?? false
    }

    public func isHost(userId: UUID) -> Bool {
        hostId == userId
    }
}

// MARK: - ActivityAttendee

public struct ActivityAttendee: Codable, Identifiable, Sendable {
    public let id: UUID
    public let activityId: UUID
    public let userId: UUID
    public var status: AttendeeStatus
    public let joinedAt: Date?

    // Joined data
    public var profile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case activityId = "activity_id"
        case userId = "user_id"
        case status
        case joinedAt = "joined_at"
        case profile
    }

    public init(
        id: UUID = UUID(),
        activityId: UUID,
        userId: UUID,
        status: AttendeeStatus = .confirmed,
        joinedAt: Date? = nil,
        profile: UserProfile? = nil
    ) {
        self.id = id
        self.activityId = activityId
        self.userId = userId
        self.status = status
        self.joinedAt = joinedAt
        self.profile = profile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        activityId = try container.decode(UUID.self, forKey: .activityId)
        userId = try container.decode(UUID.self, forKey: .userId)

        // Handle status as string since it comes from DB
        let statusString = try container.decodeIfPresent(String.self, forKey: .status) ?? "confirmed"
        status = AttendeeStatus(rawValue: statusString) ?? .confirmed

        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt)
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
    }
}

// MARK: - Activity Create Request

public struct ActivityCreateRequest: Encodable {
    public let hostId: UUID
    public let title: String
    public let description: String?
    public let category: ActivityCategory
    public let location: String
    public let exactLocation: String?
    public let imageUrl: String?
    public let imageAttributionName: String?
    public let imageAttributionUrl: String?
    public let startsAt: Date
    public let endsAt: Date?
    public let durationMinutes: Int?
    public let maxAttendees: Int
    public let isPrivate: Bool

    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case title, description, category, location
        case exactLocation = "exact_location"
        case imageUrl = "image_url"
        case imageAttributionName = "image_attribution_name"
        case imageAttributionUrl = "image_attribution_url"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case durationMinutes = "duration_minutes"
        case maxAttendees = "max_attendees"
        case isPrivate = "is_private"
    }

    public init(
        hostId: UUID,
        title: String,
        description: String? = nil,
        category: ActivityCategory,
        location: String,
        exactLocation: String? = nil,
        imageUrl: String? = nil,
        imageAttributionName: String? = nil,
        imageAttributionUrl: String? = nil,
        startsAt: Date,
        endsAt: Date? = nil,
        durationMinutes: Int? = nil,
        maxAttendees: Int = 10,
        isPrivate: Bool = false
    ) {
        self.hostId = hostId
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.exactLocation = exactLocation
        self.imageUrl = imageUrl
        self.imageAttributionName = imageAttributionName
        self.imageAttributionUrl = imageAttributionUrl
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.durationMinutes = durationMinutes
        self.maxAttendees = maxAttendees
        self.isPrivate = isPrivate
    }
}

// MARK: - Attendee Create Request

public struct AttendeeCreateRequest: Encodable {
    public let activityId: UUID
    public let userId: UUID
    public let status: AttendeeStatus

    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case userId = "user_id"
        case status
    }

    public init(activityId: UUID, userId: UUID, status: AttendeeStatus = .confirmed) {
        self.activityId = activityId
        self.userId = userId
        self.status = status
    }
}
