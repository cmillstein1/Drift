import Foundation
import Supabase

/// Manager for user profile operations.
///
/// Handles profile CRUD, discovery feed, travel schedules, and avatar uploads.
@MainActor
public class ProfileManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = ProfileManager()

    /// The current user's profile.
    @Published public var currentProfile: UserProfile?
    /// Profiles for discovery (dating/friends).
    @Published public var discoverProfiles: [UserProfile] = []
    /// Nearby friend profiles.
    @Published public var nearbyProfiles: [UserProfile] = []
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Current Profile

    /// Fetches the current user's profile from the database.
    /// If no profile exists, creates one automatically.
    public func fetchCurrentProfile() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            // First try to fetch existing profile
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            if let profile = profiles.first {
                self.currentProfile = profile
            } else {
                // Profile doesn't exist, create it
                try await client
                    .from("profiles")
                    .insert(["id": userId.uuidString])
                    .execute()

                // Fetch the newly created profile
                let newProfiles: [UserProfile] = try await client
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                    .value

                self.currentProfile = newProfiles.first
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Updates the current user's profile with the given fields.
    ///
    /// - Parameter updates: A `ProfileUpdateRequest` with fields to update.
    public func updateProfile(_ updates: ProfileUpdateRequest) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()

        // Refresh profile after update
        try await fetchCurrentProfile()
    }

    /// Fetches a profile by user ID.
    ///
    /// - Parameter id: The user's UUID.
    /// - Returns: The user's profile.
    public func fetchProfile(by id: UUID) async throws -> UserProfile {
        let profiles: [UserProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else {
            throw ProfileError.profileNotFound
        }

        return profile
    }

    // MARK: - Discovery

    /// Fetches profiles for discovery based on what the user is looking for.
    ///
    /// - Parameters:
    ///   - lookingFor: Filter by what users are looking for (dating, friends, or both).
    ///   - excludeIds: User IDs to exclude (e.g., already swiped).
    ///   - limit: Maximum number of profiles to return.
    public func fetchDiscoverProfiles(
        lookingFor: LookingFor = .both,
        excludeIds: [UUID] = [],
        limit: Int = 20
    ) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            var query = client
                .from("profiles")
                .select()
                .neq("id", value: userId)
                .eq("onboarding_completed", value: true)

            // Filter by what users are looking for
            switch lookingFor {
            case .dating:
                query = query.or("looking_for.eq.dating,looking_for.eq.both")
            case .friends:
                query = query.or("looking_for.eq.friends,looking_for.eq.both")
            case .both:
                break
            }

            let profiles: [UserProfile] = try await query
                .limit(limit)
                .execute()
                .value

            // Filter out excluded IDs
            self.discoverProfiles = profiles.filter { !excludeIds.contains($0.id) }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches nearby profiles for the friends tab.
    ///
    /// - Parameter limit: Maximum number of profiles to return.
    public func fetchNearbyFriends(limit: Int = 20) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .neq("id", value: userId)
                .eq("onboarding_completed", value: true)
                .limit(limit)
                .execute()
                .value

            self.nearbyProfiles = profiles
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Travel Schedule

    /// Fetches the current user's travel schedule.
    ///
    /// - Returns: Array of travel stops ordered by start date.
    public func fetchTravelSchedule() async throws -> [TravelStop] {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        return try await client
            .from("travel_schedule")
            .select()
            .eq("user_id", value: userId)
            .order("start_date")
            .execute()
            .value
    }

    /// Saves the user's travel schedule, replacing existing stops.
    ///
    /// - Parameter stops: The travel stops to save.
    public func saveTravelSchedule(_ stops: [TravelStop]) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        // Delete existing stops
        try await client
            .from("travel_schedule")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        // Insert new stops
        if !stops.isEmpty {
            let requests = stops.map { stop in
                TravelStopCreateRequest(
                    userId: userId,
                    location: stop.location,
                    startDate: stop.startDate,
                    endDate: stop.endDate
                )
            }

            try await client
                .from("travel_schedule")
                .insert(requests)
                .execute()
        }
    }

    // MARK: - Avatar Upload

    /// Uploads an avatar image to Supabase Storage.
    ///
    /// - Parameter imageData: The image data to upload.
    /// - Returns: The public URL of the uploaded avatar.
    public func uploadAvatar(_ imageData: Data) async throws -> String {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        let fileName = "\(userId.uuidString)/avatar.jpg"

        // Upload to storage
        try await client.storage
            .from("avatars")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        // Get public URL
        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: fileName)

        // Update profile with new avatar URL
        try await updateProfile(ProfileUpdateRequest(avatarUrl: publicURL.absoluteString))

        return publicURL.absoluteString
    }

    /// Uploads a photo to the user's photo gallery.
    ///
    /// - Parameter imageData: The image data to upload.
    /// - Returns: The public URL of the uploaded photo.
    public func uploadPhoto(_ imageData: Data) async throws -> String {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        let photoId = UUID().uuidString
        let fileName = "\(userId.uuidString)/\(photoId).jpg"

        // Upload to storage
        try await client.storage
            .from("photos")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        // Get public URL
        let publicURL = try client.storage
            .from("photos")
            .getPublicURL(path: fileName)

        // Add to profile photos array
        var currentPhotos = currentProfile?.photos ?? []
        currentPhotos.append(publicURL.absoluteString)
        try await updateProfile(ProfileUpdateRequest(photos: currentPhotos))

        return publicURL.absoluteString
    }

    /// Deletes a photo from the user's gallery.
    ///
    /// - Parameter photoUrl: The URL of the photo to delete.
    public func deletePhoto(_ photoUrl: String) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        // Extract filename from URL
        if let range = photoUrl.range(of: "\(userId.uuidString)/") {
            let fileName = "\(userId.uuidString)/\(String(photoUrl[range.upperBound...]))"

            try await client.storage
                .from("photos")
                .remove(paths: [fileName])
        }

        // Remove from profile photos array
        var currentPhotos = currentProfile?.photos ?? []
        currentPhotos.removeAll { $0 == photoUrl }
        try await updateProfile(ProfileUpdateRequest(photos: currentPhotos))
    }

    // MARK: - Last Active

    /// Updates the user's last active timestamp.
    public func updateLastActive() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        try await client
            .from("profiles")
            .update(["last_active_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: userId)
            .execute()
    }
}

// MARK: - Supporting Types

public enum ProfileError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case uploadFailed

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .profileNotFound:
            return "Profile not found."
        case .uploadFailed:
            return "Failed to upload image."
        }
    }
}

struct TravelStopCreateRequest: Encodable {
    let userId: UUID
    let location: String
    let startDate: Date
    let endDate: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case location
        case startDate = "start_date"
        case endDate = "end_date"
    }
}
