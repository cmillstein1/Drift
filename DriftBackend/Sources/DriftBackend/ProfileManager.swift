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
    /// Incremented when dating preferences are saved; observed by DiscoverScreen to trigger re-fetch.
    @Published public var datingPrefsVersion: Int = 0
    /// Incremented when community/friends preferences are saved; observed by DiscoverScreen to trigger re-fetch.
    @Published public var communityPrefsVersion: Int = 0
    /// Incremented when discovery mode changes; observed by DiscoverScreen to trigger re-fetch.
    @Published public var discoveryModeVersion: Int = 0

    /// Guards against duplicate concurrent discover profile fetches from rapid tab switches.
    /// Separate flags for dating and friends so they don't block each other.
    private var isFetchingDiscoverDating = false
    private var isFetchingDiscoverFriends = false

    /// Resets the fetch guard for a mode so the next fetch isn't blocked.
    /// Call after cancelling an in-flight fetch task.
    public func resetFetchGuard(for lookingFor: LookingFor) {
        if lookingFor == .dating { isFetchingDiscoverDating = false }
        else { isFetchingDiscoverFriends = false }
    }

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
            try data.write(to: cacheURL(for: key), options: [.atomic, .completeFileProtection])
        } catch {
            #if DEBUG
            print("[ProfileManager] Failed to save cache (\(key)): \(error)")
            #endif
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
            #if DEBUG
            print("🔴 [ProfileManager] updateProfile: not authenticated")
            #endif
            throw ProfileError.notAuthenticated
        }

        #if DEBUG
        print("🔵 [ProfileManager] updateProfile for userId: \(userId)")
        print("🔵 [ProfileManager] workStyle: \(String(describing: updates.workStyle))")
        print("🔵 [ProfileManager] homeBase: \(String(describing: updates.homeBase))")
        print("🔵 [ProfileManager] morningPerson: \(String(describing: updates.morningPerson))")
        #endif

        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()

        #if DEBUG
        print("🔵 [ProfileManager] Update executed, now fetching profile...")
        #endif

        // Refresh profile after update
        try await fetchCurrentProfile()

        #if DEBUG
        print("🔵 [ProfileManager] After refresh - workStyle: \(String(describing: currentProfile?.workStyle))")
        print("🔵 [ProfileManager] After refresh - homeBase: \(String(describing: currentProfile?.homeBase))")
        print("🔵 [ProfileManager] After refresh - morningPerson: \(String(describing: currentProfile?.morningPerson))")
        #endif
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
    /// Uses server-side RPC (`discover_profiles_nearby`) for distance filtering when user coordinates are available.
    /// Falls back to a standard query when coordinates are unavailable or the RPC doesn't exist yet.
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
        currentUserLon: Double? = nil,
        alongMyRoute: Bool = false,
        unlimitedDistance: Bool = false,
        friendsMaxDistanceMiles: Int? = nil
    ) async throws {
        // Per-mode guard so dating and friends fetches don't block each other
        let isDating = (lookingFor == .dating)
        if isDating {
            guard !isFetchingDiscoverDating else { return }
            isFetchingDiscoverDating = true
        } else {
            guard !isFetchingDiscoverFriends else { return }
            isFetchingDiscoverFriends = true
        }

        guard let userId = SupabaseManager.shared.currentUser?.id else {
            if isDating { isFetchingDiscoverDating = false } else { isFetchingDiscoverFriends = false }
            throw ProfileError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            // When in dating mode, ensure we have current profile for preference filtering
            if lookingFor == .dating, currentProfile == nil {
                try? await fetchCurrentProfile()
            }

            // Prefer device location; fall back to profile's stored coords
            let userLat = currentUserLat ?? currentProfile?.latitude
            let userLon = currentUserLon ?? currentProfile?.longitude

            // Determine server-side distance ceiling:
            // Use the provided slider value for both dating and friends modes.
            // DiscoverScreen passes the correct value from the active filter preferences.
            let serverMaxDistance = friendsMaxDistanceMiles ?? 200

            print("[Friends Debug] fetchDiscoverProfiles called — lookingFor: \(lookingFor), alongMyRoute: \(alongMyRoute), unlimitedDistance: \(unlimitedDistance), serverMaxDistance: \(serverMaxDistance), userLat: \(userLat ?? -999), userLon: \(userLon ?? -999), excludeIds: \(excludeIds.count)")

            // Always use standard query — client-side matches() handles distance filtering.
            // This ensures profiles without coordinates are still shown (matching event behavior).
            print("[Friends Debug] → Fetching via standard query (client-side distance filtering)")
            var profiles: [UserProfile]
            profiles = try await fetchProfilesViaQuery(
                userId: userId,
                lookingFor: lookingFor,
                excludeIds: excludeIds,
                limit: limit * 2
            )
            print("[Friends Debug] Fetch returned \(profiles.count) profiles")

            // Apply dating preferences (age range + gender) when in dating mode
            if lookingFor == .dating, let current = currentProfile {
                let minAge = current.preferredMinAge ?? 18
                let maxAge = current.preferredMaxAge ?? 80
                let interestedIn = current.orientation // "women", "men", "non-binary", "everyone", or comma-separated like "men,women"

                // Parse orientation into a set of accepted values
                let acceptedGenders: Set<String>
                if let interest = interestedIn, interest != "everyone" {
                    acceptedGenders = Set(interest.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
                } else {
                    acceptedGenders = [] // empty = accept everyone
                }

                let genderMap: [String: String] = ["women": "Female", "men": "Male", "non-binary": "Non-binary"]

                profiles = profiles.filter { p in
                    let age = p.displayAge
                    let ageOk = age == 0 || (age >= minAge && age <= maxAge)

                    // Gender filter: match user's orientation preference against profile's gender
                    let genderOk: Bool
                    if acceptedGenders.isEmpty {
                        genderOk = true
                    } else if let profileGender = p.gender {
                        genderOk = acceptedGenders.contains { genderMap[$0] == profileGender }
                    } else {
                        // Profile has no gender set — still show (don't hide)
                        genderOk = true
                    }

                    return ageOk && genderOk
                }
            }

            // Dating only: show users who have completed dating onboarding (orientation, lookingFor, 3+ prompt answers)
            if lookingFor == .dating {
                profiles = profiles.filter { Self.hasCompletedDatingOnboarding(profile: $0) }
            }

            // Trim to requested limit after filtering
            profiles = Array(profiles.prefix(limit))
            print("[Friends Debug] After all filters: \(profiles.count) profiles assigned to \(lookingFor)")
            for p in profiles {
                print("[Friends Debug]   → \(p.name ?? "?") (lookingFor: \(p.lookingFor), lat: \(p.latitude ?? -999), lon: \(p.longitude ?? -999))")
            }


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
            if isDating { isFetchingDiscoverDating = false } else { isFetchingDiscoverFriends = false }
        } catch {
            isLoading = false
            if isDating { isFetchingDiscoverDating = false } else { isFetchingDiscoverFriends = false }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches profiles using the `discover_profiles_nearby` RPC for server-side distance filtering.
    /// Falls back to a standard query if the RPC doesn't exist yet (migration not applied).
    private func fetchProfilesViaRPC(
        userId: UUID,
        lat: Double,
        lon: Double,
        maxDistanceMiles: Int,
        lookingFor: LookingFor,
        excludeIds: [UUID],
        limit: Int
    ) async throws -> [UserProfile] {
        do {
            print("[Friends Debug] Calling discover_profiles_nearby RPC (lat: \(lat), lon: \(lon), maxDist: \(maxDistanceMiles))")
            let profiles: [UserProfile] = try await client
                .rpc("discover_profiles_nearby", params: [
                    "p_user_id": AnyJSON.string(userId.uuidString),
                    "p_user_lat": AnyJSON.double(lat),
                    "p_user_lon": AnyJSON.double(lon),
                    "p_max_distance_miles": AnyJSON.integer(maxDistanceMiles),
                    "p_looking_for": AnyJSON.string(lookingFor.rawValue),
                    "p_exclude_ids": AnyJSON.array(excludeIds.map { AnyJSON.string($0.uuidString) }),
                    "p_limit": AnyJSON.integer(limit)
                ])
                .execute()
                .value
            print("[Friends Debug] discover_profiles_nearby RPC returned \(profiles.count) profiles")
            return profiles
        } catch {
            print("[Friends Debug] discover_profiles_nearby RPC FAILED: \(error)")
            // RPC not available — fall back to standard query + client-side distance filter
            var profiles = try await fetchProfilesViaQuery(
                userId: userId,
                lookingFor: lookingFor,
                excludeIds: excludeIds,
                limit: limit
            )
            print("[Friends Debug] Fallback query returned \(profiles.count) profiles (before client-side filter)")
            // Apply client-side distance filter since RPC wasn't available
            profiles = profiles.filter { p in
                guard let plat = p.latitude, let plon = p.longitude else { return false }
                let miles = Self.haversineMiles(lat1: lat, lon1: lon, lat2: plat, lon2: plon)
                print("[Friends Debug]   Profile \(p.name ?? "?") at (\(plat), \(plon)) = \(Int(miles))mi → \(miles <= Double(maxDistanceMiles) ? "PASS" : "FILTERED OUT")")
                return miles <= Double(maxDistanceMiles)
            }
            print("[Friends Debug] After client-side filter: \(profiles.count) profiles")
            return profiles
        }
    }

    /// Fetches profiles using `discover_profiles_along_route` RPC for route-aware distance filtering.
    /// lat/lon are nullable — when nil, only travel stop proximity is checked server-side.
    /// Falls back to nearby RPC or standard query if this RPC doesn't exist yet.
    private func fetchProfilesViaAlongRouteRPC(
        userId: UUID,
        lat: Double?,
        lon: Double?,
        maxDistanceMiles: Int,
        lookingFor: LookingFor,
        excludeIds: [UUID],
        limit: Int
    ) async throws -> [UserProfile] {
        do {
            print("[Friends Debug] Calling discover_profiles_along_route RPC (lat: \(lat ?? -999), lon: \(lon ?? -999), maxDist: \(maxDistanceMiles))")
            var params: [String: AnyJSON] = [
                "p_user_id": AnyJSON.string(userId.uuidString),
                "p_max_distance_miles": AnyJSON.integer(maxDistanceMiles),
                "p_looking_for": AnyJSON.string(lookingFor.rawValue),
                "p_exclude_ids": AnyJSON.array(excludeIds.map { AnyJSON.string($0.uuidString) }),
                "p_limit": AnyJSON.integer(limit)
            ]
            if let lat = lat, let lon = lon {
                params["p_user_lat"] = AnyJSON.double(lat)
                params["p_user_lon"] = AnyJSON.double(lon)
            }
            let profiles: [UserProfile] = try await client
                .rpc("discover_profiles_along_route", params: params)
                .execute()
                .value
            print("[Friends Debug] discover_profiles_along_route RPC returned \(profiles.count) profiles")
            return profiles
        } catch {
            print("[Friends Debug] discover_profiles_along_route RPC FAILED: \(error)")
            print("[Friends Debug] Falling back to standard query (no distance filter)")
            // Along-my-route RPC not available — fall back to standard query (no distance filter).
            // The nearby RPC would only find profiles near the user's current location,
            // missing profiles near travel stops entirely.
            let fallbackProfiles = try await fetchProfilesViaQuery(
                userId: userId,
                lookingFor: lookingFor,
                excludeIds: excludeIds,
                limit: limit
            )
            print("[Friends Debug] Standard query fallback returned \(fallbackProfiles.count) profiles")
            return fallbackProfiles
        }
    }

    /// Standard query fetch (no distance filtering). Used as fallback when user has no coordinates or RPC is unavailable.
    private func fetchProfilesViaQuery(
        userId: UUID,
        lookingFor: LookingFor,
        excludeIds: [UUID],
        limit: Int
    ) async throws -> [UserProfile] {
        var query = client
            .from("profiles")
            .select()
            .neq("id", value: userId)
            .eq("onboarding_completed", value: true)

        switch lookingFor {
        case .dating:
            query = query.in("looking_for", values: ["dating", "both"])
        case .friends:
            query = query.in("looking_for", values: ["friends", "both"])
        case .both:
            break
        }

        var profiles: [UserProfile] = try await query
            .limit(limit)
            .execute()
            .value

        let excludeSet = Set(excludeIds)
        profiles = profiles.filter { !excludeSet.contains($0.id) }
        return profiles
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
                    endDate: stop.endDate,
                    latitude: stop.latitude,
                    longitude: stop.longitude
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

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    /// Updates the user's last active timestamp.
    public func updateLastActive() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        try await client
            .from("profiles")
            .update(["last_active_at": Self.iso8601Formatter.string(from: Date())])
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Dating Onboarding
    
    /// Checks if a profile has completed dating-specific onboarding (used for current user or discovery).
    /// Returns true if they have gender set, lookingFor set to dating/both, and at least 3 prompt answers.
    public static func hasCompletedDatingOnboarding(profile: UserProfile) -> Bool {
        let hasGender = !(profile.gender?.isEmpty ?? true)
        let isLookingForDating = profile.lookingFor == .dating || profile.lookingFor == .both
        let hasPromptAnswers = (profile.promptAnswers?.count ?? 0) >= 3
        return hasGender && isLookingForDating && hasPromptAnswers
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
        
        let hasName = !(profile.name?.isEmpty ?? true)
        let hasBirthday = profile.birthday != nil
        let hasGender = !(profile.gender?.isEmpty ?? true)
        let hasLookingFor = profile.lookingFor == .dating || profile.lookingFor == .both
        let hasPhotos = profile.displayPhotoUrls.count >= 2
        let hasInterests = profile.interests.count >= 3
        let hasBio = !(profile.bio?.isEmpty ?? true)
        let hasPromptAnswers = (profile.promptAnswers?.count ?? 0) >= 3
        let hasLocation = !(profile.location?.isEmpty ?? true)

        // Determine starting step - prioritize dating-specific screens
        // If they have basic info, start at first dating screen (Orientation)
        if !hasName { return 0 } // NameScreen
        if !hasBirthday { return 1 } // BirthdayScreen
        if !hasGender { return 2 } // OrientationScreen (first dating-specific)
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
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case location
        case startDate = "start_date"
        case endDate = "end_date"
        case latitude
        case longitude
    }
}
