import Foundation

// MARK: - Enums

public enum LookingFor: String, Codable, CaseIterable, Sendable {
    case dating
    case friends
    case both

    public var displayName: String {
        switch self {
        case .dating: return "Dating"
        case .friends: return "Friends"
        case .both: return "Both"
        }
    }
}

public enum Lifestyle: String, Codable, CaseIterable, Sendable {
    case vanLife = "van_life"
    case digitalNomad = "digital_nomad"
    case rvLife = "rv_life"
    case traveler

    public var displayName: String {
        switch self {
        case .vanLife: return "Van Life"
        case .digitalNomad: return "Digital Nomad"
        case .rvLife: return "RV Life"
        case .traveler: return "Traveler"
        }
    }
}

public enum TravelPace: String, Codable, CaseIterable, Sendable {
    case slow
    case moderate
    case fast

    public var displayName: String {
        switch self {
        case .slow: return "Slow Traveler"
        case .moderate: return "Moderate Pace"
        case .fast: return "Fast Mover"
        }
    }
}

// MARK: - UserProfile

public struct UserProfile: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String?
    public var birthday: Date?
    public var age: Int?
    public var bio: String?
    public var avatarUrl: String?
    public var photos: [String]
    public var location: String?
    public var verified: Bool

    public var lifestyle: Lifestyle?
    public var travelPace: TravelPace?
    public var nextDestination: String?
    public var travelDates: String?
    public var interests: [String]

    public var lookingFor: LookingFor
    public var friendsOnly: Bool
    public var orientation: String?

    public var createdAt: Date?
    public var updatedAt: Date?
    public var lastActiveAt: Date?
    public var onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, birthday, age, bio
        case avatarUrl = "avatar_url"
        case photos, location, verified, lifestyle
        case travelPace = "travel_pace"
        case nextDestination = "next_destination"
        case travelDates = "travel_dates"
        case interests
        case lookingFor = "looking_for"
        case friendsOnly = "friends_only"
        case orientation
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActiveAt = "last_active_at"
        case onboardingCompleted = "onboarding_completed"
    }

    public init(
        id: UUID,
        name: String? = nil,
        birthday: Date? = nil,
        age: Int? = nil,
        bio: String? = nil,
        avatarUrl: String? = nil,
        photos: [String] = [],
        location: String? = nil,
        verified: Bool = false,
        lifestyle: Lifestyle? = nil,
        travelPace: TravelPace? = nil,
        nextDestination: String? = nil,
        travelDates: String? = nil,
        interests: [String] = [],
        lookingFor: LookingFor = .both,
        friendsOnly: Bool = false,
        orientation: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        lastActiveAt: Date? = nil,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.age = age
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.photos = photos
        self.location = location
        self.verified = verified
        self.lifestyle = lifestyle
        self.travelPace = travelPace
        self.nextDestination = nextDestination
        self.travelDates = travelDates
        self.interests = interests
        self.lookingFor = lookingFor
        self.friendsOnly = friendsOnly
        self.orientation = orientation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastActiveAt = lastActiveAt
        self.onboardingCompleted = onboardingCompleted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        // Handle birthday as date-only string (YYYY-MM-DD) or full ISO8601
        if let birthdayString = try container.decodeIfPresent(String.self, forKey: .birthday) {
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(identifier: "UTC")

            if let date = dateOnlyFormatter.date(from: birthdayString) {
                birthday = date
            } else {
                let iso8601Formatter = ISO8601DateFormatter()
                birthday = iso8601Formatter.date(from: birthdayString)
            }
        } else {
            birthday = nil
        }

        age = try container.decodeIfPresent(Int.self, forKey: .age)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        photos = try container.decodeIfPresent([String].self, forKey: .photos) ?? []
        location = try container.decodeIfPresent(String.self, forKey: .location)
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
        lifestyle = try container.decodeIfPresent(Lifestyle.self, forKey: .lifestyle)
        travelPace = try container.decodeIfPresent(TravelPace.self, forKey: .travelPace)
        nextDestination = try container.decodeIfPresent(String.self, forKey: .nextDestination)
        travelDates = try container.decodeIfPresent(String.self, forKey: .travelDates)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
        lookingFor = try container.decodeIfPresent(LookingFor.self, forKey: .lookingFor) ?? .both
        friendsOnly = try container.decodeIfPresent(Bool.self, forKey: .friendsOnly) ?? false
        orientation = try container.decodeIfPresent(String.self, forKey: .orientation)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
    }

    // Computed properties for UI
    public var displayName: String {
        name ?? "Unknown"
    }

    public var initials: String {
        guard let name = name else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - TravelStop

public struct TravelStop: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var location: String
    public var startDate: Date
    public var endDate: Date?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case location
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        location: String,
        startDate: Date,
        endDate: Date? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }

    public var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: startDate)
        if let end = endDate {
            return "\(start) - \(formatter.string(from: end))"
        }
        return start
    }
}

// MARK: - Profile Update Request

public struct ProfileUpdateRequest: Encodable {
    public var name: String?
    public var birthday: Date?
    public var bio: String?
    public var avatarUrl: String?
    public var photos: [String]?
    public var location: String?
    public var lifestyle: Lifestyle?
    public var travelPace: TravelPace?
    public var nextDestination: String?
    public var travelDates: String?
    public var interests: [String]?
    public var lookingFor: LookingFor?
    public var friendsOnly: Bool?
    public var orientation: String?
    public var onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case name, birthday, bio
        case avatarUrl = "avatar_url"
        case photos, location, lifestyle
        case travelPace = "travel_pace"
        case nextDestination = "next_destination"
        case travelDates = "travel_dates"
        case interests
        case lookingFor = "looking_for"
        case friendsOnly = "friends_only"
        case orientation
        case onboardingCompleted = "onboarding_completed"
    }

    public init(
        name: String? = nil,
        birthday: Date? = nil,
        bio: String? = nil,
        avatarUrl: String? = nil,
        photos: [String]? = nil,
        location: String? = nil,
        lifestyle: Lifestyle? = nil,
        travelPace: TravelPace? = nil,
        nextDestination: String? = nil,
        travelDates: String? = nil,
        interests: [String]? = nil,
        lookingFor: LookingFor? = nil,
        friendsOnly: Bool? = nil,
        orientation: String? = nil,
        onboardingCompleted: Bool? = nil
    ) {
        self.name = name
        self.birthday = birthday
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.photos = photos
        self.location = location
        self.lifestyle = lifestyle
        self.travelPace = travelPace
        self.nextDestination = nextDestination
        self.travelDates = travelDates
        self.interests = interests
        self.lookingFor = lookingFor
        self.friendsOnly = friendsOnly
        self.orientation = orientation
        self.onboardingCompleted = onboardingCompleted
    }
}
