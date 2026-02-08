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
    /// Profiles for discovery (dating feed).
    @Published public var discoverProfiles: [UserProfile] = []
    /// Profiles for discover friends feed (kept separate so switching segments doesn’t overwrite dating).
    @Published public var discoverProfilesFriends: [UserProfile] = []
    /// Nearby friend profiles.
    @Published public var nearbyProfiles: [UserProfile] = []
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    /// Guards against duplicate concurrent discover profile fetches from rapid tab switches.
    private var isFetchingDiscover = false

    /// In-memory profile cache with timestamps for TTL expiration.
    private var profileCache: [UUID: (profile: UserProfile, fetchedAt: Date)] = [:]
    /// Profiles are considered fresh for 60 seconds.
    private let profileCacheTTL: TimeInterval = 60

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Disk Cache

    private func cacheURL(for key: String) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("drift_\(key).json")
    }

    private func saveToDisk(_ profiles: [UserProfile], key: String) {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: cacheURL(for: key), options: .atomic)
        } catch {
            print("[ProfileManager] Failed to save cache (\(key)): \(error)")
        }
    }

    private func loadFromDisk(key: String) -> [UserProfile]? {
        let url = cacheURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([UserProfile].self, from: data)
    }

    /// Populates discover profile arrays from disk cache if they are currently empty.
    /// Call synchronously on appear before kicking off async fetches.
    public func loadCachedDiscoverProfiles() {
        if discoverProfiles.isEmpty,
           let cached = loadFromDisk(key: "discover_dating_profiles") {
            discoverProfiles = cached
        }
        if discoverProfilesFriends.isEmpty,
           let cached = loadFromDisk(key: "discover_friends_profiles") {
            discoverProfilesFriends = cached
        }
    }

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
            print("🔴 [ProfileManager] updateProfile: not authenticated")
            throw ProfileError.notAuthenticated
        }

        print("🔵 [ProfileManager] updateProfile for userId: \(userId)")
        print("🔵 [ProfileManager] workStyle: \(String(describing: updates.workStyle))")
        print("🔵 [ProfileManager] homeBase: \(String(describing: updates.homeBase))")
        print("🔵 [ProfileManager] morningPerson: \(String(describing: updates.morningPerson))")

        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()

        print("🔵 [ProfileManager] Update executed, now fetching profile...")

        // Refresh profile after update
        try await fetchCurrentProfile()

        print("🔵 [ProfileManager] After refresh - workStyle: \(String(describing: currentProfile?.workStyle))")
        print("🔵 [ProfileManager] After refresh - homeBase: \(String(describing: currentProfile?.homeBase))")
        print("🔵 [ProfileManager] After refresh - morningPerson: \(String(describing: currentProfile?.morningPerson))")
    }

    /// Fetches a profile by user ID, returning a cached version if available and fresh.
    ///
    /// - Parameter id: The user's UUID.
    /// - Returns: The user's profile.
    public func fetchProfile(by id: UUID) async throws -> UserProfile {
        // Return cached profile if still fresh
        if let cached = profileCache[id],
           Date().timeIntervalSince(cached.fetchedAt) < profileCacheTTL {
            return cached.profile
        }

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

        profileCache[id] = (profile: profile, fetchedAt: Date())
        return profile
    }

    /// Fetches multiple profiles by ID in a single query, using cache when available.
    ///
    /// - Parameter ids: The user UUIDs to fetch.
    /// - Returns: Dictionary mapping UUID to profile.
    public func fetchProfiles(by ids: [UUID]) async throws -> [UUID: UserProfile] {
        var result: [UUID: UserProfile] = [:]
        var uncachedIds: [UUID] = []

        for id in ids {
            if let cached = profileCache[id],
               Date().timeIntervalSince(cached.fetchedAt) < profileCacheTTL {
                result[id] = cached.profile
            } else {
                uncachedIds.append(id)
            }
        }

        if !uncachedIds.isEmpty {
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .in("id", values: uncachedIds)
                .execute()
                .value

            let now = Date()
            for profile in profiles {
                profileCache[profile.id] = (profile: profile, fetchedAt: now)
                result[profile.id] = profile
            }
        }

        return result
    }

    // MARK: - Discovery

    /// Fetches profiles for discovery based on what the user is looking for.
    ///
    /// - Parameters:
    ///   - lookingFor: Filter by what users are looking for (dating, friends, or both).
    ///   - excludeIds: User IDs to exclude (e.g., already swiped).
    ///   - limit: Maximum number of profiles to return.
    ///   - currentUserLat: Current user's latitude for distance filter (e.g. from device location); nil = use profile's stored coords.
    ///   - currentUserLon: Current user's longitude for distance filter; nil = use profile's stored coords.
    public func fetchDiscoverProfiles(
        lookingFor: LookingFor = .both,
        excludeIds: [UUID] = [],
        limit: Int = 20,
        currentUserLat: Double? = nil,
        currentUserLon: Double? = nil
    ) async throws {
        guard !isFetchingDiscover else { return }
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        isFetchingDiscover = true
        isLoading = true
        errorMessage = nil

        do {
            // When in dating mode, ensure we have current profile for preference filtering
            if lookingFor == .dating, currentProfile == nil {
                try? await fetchCurrentProfile()
            }

            var query = client
                .from("profiles")
                .select()
                .neq("id", value: userId)
                .eq("onboarding_completed", value: true)

            // Filter by what users are looking for
            switch lookingFor {
            case .dating:
                query = query.in("looking_for", values: ["dating", "both"])
            case .friends:
                query = query.in("looking_for", values: ["friends", "both"])
            case .both:
                break
            }

            var profiles: [UserProfile] = try await query
                .limit(limit * 2) // Fetch extra to allow for age/distance filtering
                .execute()
                .value

            // Filter out excluded IDs using Set for O(1) lookups
            let excludeSet = Set(excludeIds)
            profiles = profiles.filter { !excludeSet.contains($0.id) }

            // Apply dating preferences (age range and distance) when in dating mode
            if lookingFor == .dating, let current = currentProfile {
                let minAge = current.preferredMinAge ?? 18
                let maxAge = current.preferredMaxAge ?? 80
                let maxDistanceMiles = current.preferredMaxDistanceMiles
                // Prefer device location for distance; fall back to profile's stored coords
                let userLat = currentUserLat ?? current.latitude
                let userLon = currentUserLon ?? current.longitude

                profiles = profiles.filter { p in
                    let age = p.displayAge
                    let ageOk = age == 0 || (age >= minAge && age <= maxAge)
                    guard ageOk else { return false }

                    // Distance: only filter when both user and profile have coordinates
                    if let ulat = userLat, let ulon = userLon, let maxMi = maxDistanceMiles, maxMi > 0,
                       let plat = p.latitude, let plon = p.longitude {
                        let miles = Self.haversineMiles(lat1: ulat, lon1: ulon, lat2: plat, lon2: plon)
                        if miles > Double(maxMi) { return false }
                    }
                    return true
                }
            }

            // Dating only: show users who have completed dating onboarding (orientation, lookingFor, 3+ prompt answers)
            if lookingFor == .dating {
                profiles = profiles.filter { Self.hasCompletedDatingOnboarding(profile: $0) }
            }

            // Trim to requested limit after filtering
            profiles = Array(profiles.prefix(limit))

            // Strip coordinates for users who have hidden their location (so they don't appear on the map)
            profiles = profiles.map { stripLocationIfHidden($0) }

            switch lookingFor {
            case .dating:
                self.discoverProfiles = profiles
                saveToDisk(profiles, key: "discover_dating_profiles")
            case .friends:
                self.discoverProfilesFriends = profiles
                saveToDisk(profiles, key: "discover_friends_profiles")
            case .both:
                self.discoverProfiles = profiles
                self.discoverProfilesFriends = profiles
                saveToDisk(profiles, key: "discover_dating_profiles")
                saveToDisk(profiles, key: "discover_friends_profiles")
            }
            isLoading = false
            isFetchingDiscover = false
        } catch {
            isLoading = false
            isFetchingDiscover = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Distance in miles between two points (Haversine formula). Used for dating and friends distance filtering.
    private static func haversineMiles(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3959.0 // Earth radius in miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
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

            // Strip coordinates for users who have hidden their location (so they don't appear on the map)
            self.nearbyProfiles = profiles.map { stripLocationIfHidden($0) }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Returns a copy of the profile with latitude/longitude set to nil when hideLocationOnMap is true.
    private func stripLocationIfHidden(_ profile: UserProfile) -> UserProfile {
        guard profile.hideLocationOnMap else { return profile }
        var stripped = profile
        stripped.latitude = nil
        stripped.longitude = nil
        return stripped
    }

    // MARK: - Travel Schedule

    /// Fetches the current user's travel schedule.
    ///
    /// - Returns: Array of travel stops ordered by start date.
    public func fetchTravelSchedule() async throws -> [TravelStop] {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw ProfileError.notAuthenticated
        }

        return try await fetchTravelSchedule(for: userId)
    }

    /// Fetches travel schedule for a specific user.
    ///
    /// - Parameter userId: The user ID to fetch travel schedule for.
    /// - Returns: Array of travel stops ordered by start date.
    public func fetchTravelSchedule(for userId: UUID) async throws -> [TravelStop] {
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

        // Use lowercase UUID to match auth.uid() in RLS policies
        let fileName = "\(userId.uuidString.lowercased())/avatar.jpg"

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

        let photoId = UUID().uuidString.lowercased()
        let fileName = "\(userId.uuidString.lowercased())/\(photoId).jpg"

        // Upload to storage
        try await client.storage
            .from("photos")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
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
        if let range = photoUrl.range(of: "\(userId.uuidString.lowercased())/") {
            let fileName = "\(userId.uuidString.lowercased())/\(String(photoUrl[range.upperBound...]))"

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
    
    // MARK: - Dating Onboarding
    
    /// Checks if a profile has completed dating-specific onboarding (used for current user or discovery).
    /// Returns true if they have orientation, lookingFor set to dating/both, and at least 3 prompt answers.
    public static func hasCompletedDatingOnboarding(profile: UserProfile) -> Bool {
        let hasOrientation = profile.orientation != nil && !profile.orientation!.isEmpty
        let isLookingForDating = profile.lookingFor == .dating || profile.lookingFor == .both
        let hasPromptAnswers = profile.promptAnswers != nil && !profile.promptAnswers!.isEmpty && profile.promptAnswers!.count >= 3
        return hasOrientation && isLookingForDating && hasPromptAnswers
    }

    /// Checks if the current user has completed dating-specific onboarding.
    public func hasCompletedDatingOnboarding() -> Bool {
        guard let profile = currentProfile else { return false }
        return Self.hasCompletedDatingOnboarding(profile: profile)
    }
    
    /// Determines which onboarding step to start from for partial dating onboarding.
    /// Returns the step index (0-10) based on what data is already filled.
    /// For users switching from friends-only to dating, we focus on dating-specific screens.
    public func getDatingOnboardingStartStep() -> Int {
        guard let profile = currentProfile else { return 2 } // Start at Orientation (first dating-specific screen)
        
        // For partial onboarding, we want to show dating-specific screens
        // Skip basic info (name, birthday) if they already have it, but always show dating-specific screens
        
        let hasName = profile.name != nil && !profile.name!.isEmpty
        let hasBirthday = profile.birthday != nil
        let hasOrientation = profile.orientation != nil && !profile.orientation!.isEmpty
        let hasLookingFor = profile.lookingFor == .dating || profile.lookingFor == .both
        let hasPhotos = !profile.photos.isEmpty && profile.photos.count >= 2
        let hasInterests = !profile.interests.isEmpty && profile.interests.count >= 3
        let hasBio = profile.bio != nil && !profile.bio!.isEmpty
        let hasPromptAnswers = profile.promptAnswers != nil && !profile.promptAnswers!.isEmpty && profile.promptAnswers!.count >= 3
        let hasLocation = profile.location != nil && !profile.location!.isEmpty
        
        // Determine starting step - prioritize dating-specific screens
        // If they have basic info, start at first dating screen (Orientation)
        if !hasName { return 0 } // NameScreen
        if !hasBirthday { return 1 } // BirthdayScreen
        if !hasOrientation { return 2 } // OrientationScreen (first dating-specific)
        if !hasLookingFor { return 3 } // LookingForScreen
        if !hasPhotos { return 4 } // PhotoUploadScreen (may have some, need 2+)
        if !hasInterests { return 5 } // InterestsScreen (may have some, need 3+)
        if !hasBio { return 6 } // AboutMeScreen
        if !hasPromptAnswers { return 7 } // ProfilePromptsScreen (dating-specific)
        if !hasLocation { return 8 } // LocationScreen
        return 9 // HometownScreen (always show, can be skipped)
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
