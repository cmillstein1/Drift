import Foundation
import Supabase
import Realtime

/// Manager for activities and events.
///
/// Handles activity CRUD, attendance, and realtime subscriptions.
@MainActor
public class ActivityManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = ActivityManager()

    /// All available activities.
    @Published public var activities: [Activity] = []
    /// Activities hosted by the current user.
    @Published public var myActivities: [Activity] = []
    /// Activities the current user is attending.
    @Published public var joinedActivities: [Activity] = []
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var activitiesChannel: RealtimeChannelV2?

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch Activities

    /// Fetches upcoming activities, optionally filtered by category.
    ///
    /// - Parameter category: Optional category filter.
    public func fetchActivities(category: ActivityCategory? = nil) async throws {
        isLoading = true
        errorMessage = nil

        do {
            var filterQuery = client
                .from("activities")
                .select("*, host:profiles!host_id(*), attendees:activity_attendees(*, profile:profiles(*))")
                .is("cancelled_at", value: nil)
                .gte("starts_at", value: ISO8601DateFormatter().string(from: Date()))

            if let category = category {
                filterQuery = filterQuery.eq("category", value: category.rawValue)
            }

            let activities: [Activity] = try await filterQuery
                .order("starts_at")
                .limit(50)
                .execute()
                .value

            self.activities = activities
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches activities hosted by the current user.
    public func fetchMyActivities() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ActivityError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            let activities: [Activity] = try await client
                .from("activities")
                .select("*, host:profiles!host_id(*), attendees:activity_attendees(*, profile:profiles(*))")
                .eq("host_id", value: userId)
                .order("starts_at")
                .execute()
                .value

            self.myActivities = activities
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches activities the current user is attending.
    public func fetchJoinedActivities() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ActivityError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            // First get the activity IDs the user is attending
            let attendances: [ActivityAttendee] = try await client
                .from("activity_attendees")
                .select("activity_id")
                .eq("user_id", value: userId)
                .eq("status", value: AttendeeStatus.confirmed.rawValue)
                .execute()
                .value

            let activityIds = attendances.map { $0.activityId }

            if !activityIds.isEmpty {
                let activities: [Activity] = try await client
                    .from("activities")
                    .select("*, host:profiles!host_id(*), attendees:activity_attendees(*, profile:profiles(*))")
                    .in("id", values: activityIds)
                    .is("cancelled_at", value: nil)
                    .order("starts_at")
                    .execute()
                    .value

                self.joinedActivities = activities
            } else {
                self.joinedActivities = []
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches a single activity by ID.
    ///
    /// - Parameter id: The activity's ID.
    /// - Returns: The activity with host and attendees.
    public func fetchActivity(by id: UUID) async throws -> Activity {
        return try await client
            .from("activities")
            .select("*, host:profiles!host_id(*), attendees:activity_attendees(*, profile:profiles(*))")
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    // MARK: - CRUD Operations

    /// Creates a new activity.
    ///
    /// - Parameters:
    ///   - title: The activity title.
    ///   - description: Optional description.
    ///   - category: The activity category.
    ///   - location: The general location.
    ///   - exactLocation: Optional exact location (revealed after joining).
    ///   - startsAt: When the activity starts.
    ///   - durationMinutes: Optional duration in minutes.
    ///   - maxAttendees: Maximum number of attendees.
    ///   - imageUrl: Optional image URL.
    ///   - isPrivate: When true, only the host can share the activity.
    /// - Returns: The created activity.
    @discardableResult
    public func createActivity(
        title: String,
        description: String? = nil,
        category: ActivityCategory,
        location: String,
        exactLocation: String? = nil,
        startsAt: Date,
        durationMinutes: Int? = nil,
        maxAttendees: Int = 10,
        imageUrl: String? = nil,
        isPrivate: Bool = false
    ) async throws -> Activity {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ActivityError.notAuthenticated
        }

        var headerImageUrl = imageUrl
        if headerImageUrl == nil, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            let key = _BackendConfiguration.shared.unsplashAccessKey
            if let url = await UnsplashManager.fetchFirstImageURL(query: title, accessKey: key) {
                headerImageUrl = url
            }
        }
        let request = ActivityCreateRequest(
            hostId: userId,
            title: title,
            description: description,
            category: category,
            location: location,
            exactLocation: exactLocation,
            imageUrl: headerImageUrl,
            startsAt: startsAt,
            durationMinutes: durationMinutes,
            maxAttendees: maxAttendees,
            isPrivate: isPrivate
        )

        let activity: Activity = try await client
            .from("activities")
            .insert(request)
            .select("*, host:profiles!host_id(*)")
            .single()
            .execute()
            .value

        // Refresh lists
        try await fetchActivities()
        try await fetchMyActivities()

        return activity
    }

    /// Updates an activity.
    ///
    /// - Parameters:
    ///   - activityId: The activity's ID.
    ///   - title: Optional new title.
    ///   - description: Optional new description.
    ///   - location: Optional new location.
    ///   - startsAt: Optional new start time.
    ///   - maxAttendees: Optional new max attendees.
    public func updateActivity(
        _ activityId: UUID,
        title: String? = nil,
        description: String? = nil,
        location: String? = nil,
        startsAt: Date? = nil,
        maxAttendees: Int? = nil
    ) async throws {
        var updates: [String: AnyEncodable] = [
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        if let title = title { updates["title"] = AnyEncodable(title) }
        if let description = description { updates["description"] = AnyEncodable(description) }
        if let location = location { updates["location"] = AnyEncodable(location) }
        if let startsAt = startsAt { updates["starts_at"] = AnyEncodable(ISO8601DateFormatter().string(from: startsAt)) }
        if let maxAttendees = maxAttendees { updates["max_attendees"] = AnyEncodable(maxAttendees) }

        try await client
            .from("activities")
            .update(updates)
            .eq("id", value: activityId)
            .execute()

        // Refresh lists
        try await fetchActivities()
        try await fetchMyActivities()
    }

    /// Cancels an activity.
    ///
    /// - Parameter activityId: The activity's ID.
    public func cancelActivity(_ activityId: UUID) async throws {
        try await client
            .from("activities")
            .update(["cancelled_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: activityId)
            .execute()

        // Update local state
        activities.removeAll { $0.id == activityId }
        myActivities.removeAll { $0.id == activityId }
    }

    // MARK: - Attendance

    /// Joins an activity.
    ///
    /// - Parameter activityId: The activity's ID.
    public func joinActivity(_ activityId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ActivityError.notAuthenticated
        }

        let request = AttendeeCreateRequest(activityId: activityId, userId: userId)

        try await client
            .from("activity_attendees")
            .insert(request)
            .execute()

        // Refresh lists
        try await fetchActivities()
        try await fetchJoinedActivities()
    }

    /// Leaves an activity.
    ///
    /// - Parameter activityId: The activity's ID.
    public func leaveActivity(_ activityId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ActivityError.notAuthenticated
        }

        try await client
            .from("activity_attendees")
            .delete()
            .eq("activity_id", value: activityId)
            .eq("user_id", value: userId)
            .execute()

        // Update local state
        joinedActivities.removeAll { $0.id == activityId }

        // Refresh activities to update attendee counts
        try await fetchActivities()
    }

    /// Checks if the current user is attending an activity.
    ///
    /// - Parameter activityId: The activity's ID.
    /// - Returns: `true` if the user is attending.
    public func isAttending(_ activityId: UUID) -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return false }

        if let activity = activities.first(where: { $0.id == activityId }) {
            return activity.isAttending(userId: userId)
        }

        return joinedActivities.contains { $0.id == activityId }
    }

    // MARK: - Image Upload

    /// Uploads an image for an activity.
    ///
    /// - Parameter imageData: The image data.
    /// - Returns: The public URL of the uploaded image.
    public func uploadActivityImage(_ imageData: Data) async throws -> String {
        let imageId = UUID().uuidString
        let fileName = "\(imageId).jpg"

        try await client.storage
            .from("activity-images")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try client.storage
            .from("activity-images")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    // MARK: - Realtime Subscriptions

    /// Subscribes to activity updates. If already subscribed, returns so postgresChange is never registered after join.
    public func subscribeToActivities() async {
        if activitiesChannel != nil { return }

        let channel = client.realtimeV2.channel("activities")
        activitiesChannel = channel

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "activities"
        )

        let attendeeChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "activity_attendees"
        )

        Task {
            for await _ in changes {
                try? await self.fetchActivities()
            }
        }

        Task {
            for await _ in attendeeChanges {
                try? await self.fetchActivities()
                try? await self.fetchJoinedActivities()
            }
        }

        await channel.subscribe()
    }

    /// Unsubscribes from activity updates and removes the channel so the next subscribe gets a fresh channel (avoids "postgresChange after join" warning).
    public func unsubscribe() async {
        if let ch = activitiesChannel {
            await ch.unsubscribe()
            await client.realtimeV2.removeChannel(ch)
            activitiesChannel = nil
        }
    }
}

// MARK: - Supporting Types

public enum ActivityError: LocalizedError {
    case notAuthenticated
    case activityNotFound
    case activityFull
    case notHost

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .activityNotFound:
            return "Activity not found."
        case .activityFull:
            return "This activity is already full."
        case .notHost:
            return "Only the host can perform this action."
        }
    }
}

// Helper for encoding dynamic dictionaries
struct AnyEncodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let date as Date:
            try container.encode(date)
        default:
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Cannot encode value of type \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
