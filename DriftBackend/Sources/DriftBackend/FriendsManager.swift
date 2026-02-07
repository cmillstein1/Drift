import Foundation
import Supabase
import Realtime

/// Manager for friend connections and dating matches.
///
/// Handles friend requests, swipes, matches, and realtime subscriptions.
@MainActor
public class FriendsManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = FriendsManager()

    /// Accepted friends list.
    @Published public var friends: [Friend] = []
    /// Pending incoming friend requests.
    @Published public var pendingRequests: [Friend] = []
    /// Pending outgoing friend requests (requests we sent).
    @Published public var sentRequests: [Friend] = []
    /// Dating matches (mutual likes).
    @Published public var matches: [Match] = []
    /// People who have liked the current user (pending likes - not yet mutual).
    @Published public var peopleLikedMe: [UserProfile] = []
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var friendsChannel: RealtimeChannelV2?
    private var matchesChannel: RealtimeChannelV2?
    private var swipesChannel: RealtimeChannelV2?

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Friends

    /// Fetches accepted friends for the current user.
    public func fetchFriends() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            let friends: [Friend] = try await client
                .from("friends")
                .select("*, requester:profiles!requester_id(*), addressee:profiles!addressee_id(*)")
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .eq("status", value: "accepted")
                .execute()
                .value

            self.friends = friends
            isLoading = false
        } catch {
            isLoading = false
            if isURLCancelled(error) { return }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches pending incoming friend requests.
    /// - Parameter silent: When true, does not set `isLoading` (e.g. for realtime background refresh).
    public func fetchPendingRequests(silent: Bool = false) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        if !silent {
            isLoading = true
            errorMessage = nil
        }

        do {
            let requests: [Friend] = try await client
                .from("friends")
                .select("*, requester:profiles!requester_id(*)")
                .eq("addressee_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value

            self.pendingRequests = requests
            if !silent { isLoading = false }
        } catch {
            if !silent { isLoading = false }
            if isURLCancelled(error) { return }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches pending outgoing friend requests (requests we sent).
    public func fetchSentRequests() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        do {
            let requests: [Friend] = try await client
                .from("friends")
                .select("*, addressee:profiles!addressee_id(*)")
                .eq("requester_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value

            self.sentRequests = requests
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Check if a friend request has already been sent to a user.
    public func hasSentRequest(to userId: UUID) -> Bool {
        sentRequests.contains { $0.addresseeId == userId }
    }

    /// Sends a friend request to another user.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user to send a request to.
    ///   - message: Optional message to include with the request (becomes first message when accepted).
    /// - Returns: The created Friend request.
    /// - Note: If a previous request was declined, the old row is removed so a new request can be sent.
    @discardableResult
    public func sendFriendRequest(to userId: UUID, message: String? = nil) async throws -> Friend {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        // Check for existing row (unique constraint on requester_id, addressee_id)
        let existing: [Friend] = try await client
            .from("friends")
            .select()
            .eq("requester_id", value: currentUserId)
            .eq("addressee_id", value: userId)
            .execute()
            .value

        if let row = existing.first {
            switch row.status {
            case .accepted:
                throw FriendsError.alreadyFriends
            case .pending:
                throw FriendsError.requestAlreadySent
            case .blocked:
                throw FriendsError.requestFailed
            case .declined:
                // Remove declined row so we can send a new request
                try await client
                    .from("friends")
                    .delete()
                    .eq("id", value: row.id)
                    .execute()
                sentRequests.removeAll { $0.id == row.id }
            }
        }

        let request = FriendRequest(requesterId: currentUserId, addresseeId: userId)

        let createdRequest: Friend = try await client
            .from("friends")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        // If there's a message, store it for when the request is accepted
        if let message = message, !message.isEmpty {
            try await client
                .from("friend_request_messages")
                .insert([
                    "friend_id": createdRequest.id.uuidString,
                    "sender_id": currentUserId.uuidString,
                    "content": message
                ])
                .execute()
        }

        // Update local state
        var requestWithProfile = createdRequest
        requestWithProfile.addresseeProfile = try? await ProfileManager.shared.fetchProfile(by: userId)
        sentRequests.append(requestWithProfile)

        return createdRequest
    }

    /// Responds to a friend request.
    ///
    /// - Parameters:
    ///   - requestId: The ID of the friend request.
    ///   - accept: Whether to accept or decline the request.
    /// - Returns: The created conversation if accepted, nil otherwise.
    /// - Note: When declining, the request row is deleted so the requester can send a new request later.
    @discardableResult
    public func respondToFriendRequest(_ requestId: UUID, accept: Bool) async throws -> Conversation? {
        // First fetch the request to get the requester's ID
        let request: Friend? = pendingRequests.first { $0.id == requestId }

        if accept {
            try await client
                .from("friends")
                .update(["status": FriendStatus.accepted.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: requestId)
                .execute()

            // Update local state instead of full re-fetch
            pendingRequests.removeAll { $0.id == requestId }
            if var acceptedRequest = request {
                acceptedRequest.status = .accepted
                friends.append(acceptedRequest)
            }

            var conversation: Conversation? = nil
            if let requesterId = request?.requesterId {
                conversation = try await MessagingManager.shared.fetchOrCreateConversation(
                    with: requesterId,
                    type: .friends
                )
            }
            return conversation
        } else {
            // Decline: delete the row so the requester can send another friend request later
            try await client
                .from("friends")
                .delete()
                .eq("id", value: requestId)
                .execute()

            // Update local state instead of full re-fetch
            pendingRequests.removeAll { $0.id == requestId }
            return nil
        }
    }

    /// Removes a friend connection.
    ///
    /// - Parameter friendId: The ID of the friend relationship to remove.
    public func removeFriend(_ friendId: UUID) async throws {
        try await client
            .from("friends")
            .delete()
            .eq("id", value: friendId)
            .execute()

        // Update local state
        friends.removeAll { $0.id == friendId }
    }

    /// Blocks a user.
    ///
    /// - Parameter userId: The ID of the user to block.
    public func blockUser(_ userId: UUID) async throws {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        // Check if there's an existing friend relationship
        let existing: [Friend] = try await client
            .from("friends")
            .select()
            .or("and(requester_id.eq.\(currentUserId),addressee_id.eq.\(userId)),and(requester_id.eq.\(userId),addressee_id.eq.\(currentUserId))")
            .execute()
            .value

        if let friend = existing.first {
            // Update existing to blocked
            try await client
                .from("friends")
                .update(["status": FriendStatus.blocked.rawValue])
                .eq("id", value: friend.id)
                .execute()
        } else {
            // Create new blocked relationship
            let request = FriendRequest(requesterId: currentUserId, addresseeId: userId, status: .blocked)
            try await client
                .from("friends")
                .insert(request)
                .execute()
        }
    }

    /// Fetches users that the current user has blocked.
    /// Returns friend rows (status blocked) where current user is requester, with addressee profile.
    public func fetchBlockedUsers() async throws -> [Friend] {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        let rows: [Friend] = try await client
            .from("friends")
            .select("*, requester:profiles!requester_id(*), addressee:profiles!addressee_id(*)")
            .eq("requester_id", value: currentUserId)
            .eq("status", value: FriendStatus.blocked.rawValue)
            .execute()
            .value

        return rows
    }

    /// Removes a block (deletes the blocked friend row so the user is no longer blocked).
    public func unblockUser(_ userId: UUID) async throws {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        try await client
            .from("friends")
            .delete()
            .or("and(requester_id.eq.\(currentUserId),addressee_id.eq.\(userId)),and(requester_id.eq.\(userId),addressee_id.eq.\(currentUserId))")
            .eq("status", value: FriendStatus.blocked.rawValue)
            .execute()
    }

    /// Returns user IDs that should be excluded from discover and messages: users the current user has blocked, plus users who have blocked the current user.
    public func fetchBlockedExclusionUserIds() async throws -> [UUID] {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        let rows: [Friend] = try await client
            .from("friends")
            .select()
            .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId)")
            .eq("status", value: FriendStatus.blocked.rawValue)
            .execute()
            .value

        let excluded: [UUID] = rows.map { row in
            row.requesterId == currentUserId ? row.addresseeId : row.requesterId
        }
        return Array(Set(excluded))
    }

    // MARK: - Swipes & Matches

    /// Records a swipe on a profile.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user being swiped on.
    ///   - direction: The swipe direction (left, right, or up for super like).
    /// - Returns: A `Match` if mutual interest is detected, otherwise `nil`.
    @discardableResult
    public func swipe(on userId: UUID, direction: SwipeDirection) async throws -> Match? {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            print("❌ [SWIPE] Not authenticated")
            throw FriendsError.notAuthenticated
        }

        print("🔄 [SWIPE] Starting swipe...")
        print("🔄 [SWIPE] Current user: \(currentUserId)")
        print("🔄 [SWIPE] Target user: \(userId)")
        print("🔄 [SWIPE] Direction: \(direction)")

        let request = SwipeRequest(swiperId: currentUserId, swipedId: userId, direction: direction)

        do {
            try await client
                .from("swipes")
                .insert(request)
                .execute()
            print("✅ [SWIPE] Swipe recorded successfully")
        } catch {
            print("❌ [SWIPE] Failed to record swipe: \(error)")
            throw error
        }

        // If right swipe or super like, check for mutual interest
        if direction == .right || direction == .up {
            print("💕 [SWIPE] Checking for mutual interest...")

            // Check if the other user has already swiped right on us
            do {
                let theirSwipes: [SwipeRecord] = try await client
                    .from("swipes")
                    .select()
                    .eq("swiper_id", value: userId)
                    .eq("swiped_id", value: currentUserId)
                    .in("direction", values: ["right", "up"])
                    .execute()
                    .value

                print("🔍 [SWIPE] Their swipes on me: \(theirSwipes.count)")
                for swipe in theirSwipes {
                    print("   - Swipe ID: \(swipe.id), direction: \(swipe.direction)")
                }

                // If they've already liked us, it's a match!
                if !theirSwipes.isEmpty {
                    print("🎉 [SWIPE] MUTUAL INTEREST DETECTED! Creating match...")

                    // Check if match already exists
                    let existingMatches: [Match] = try await client
                        .from("matches")
                        .select()
                        .or("and(user1_id.eq.\(currentUserId),user2_id.eq.\(userId)),and(user1_id.eq.\(userId),user2_id.eq.\(currentUserId))")
                        .execute()
                        .value

                    print("🔍 [SWIPE] Existing matches found: \(existingMatches.count)")

                    var match: Match

                    if let existingMatch = existingMatches.first {
                        print("✅ [SWIPE] Using existing match: \(existingMatch.id)")
                        match = existingMatch
                    } else {
                        print("🆕 [SWIPE] Creating new match record...")
                        // Create the match record
                        let newMatch = MatchRequest(
                            user1Id: min(currentUserId, userId),
                            user2Id: max(currentUserId, userId),
                            isMatch: true
                        )

                        let createdMatches: [Match] = try await client
                            .from("matches")
                            .insert(newMatch)
                            .select()
                            .execute()
                            .value

                        guard let createdMatch = createdMatches.first else {
                            print("❌ [SWIPE] Failed to create match - no match returned")
                            return nil
                        }
                        print("✅ [SWIPE] Match created: \(createdMatch.id)")
                        match = createdMatch
                    }

                    // Fetch the other user's profile
                    print("👤 [SWIPE] Fetching matched user's profile...")
                    let profile = try await ProfileManager.shared.fetchProfile(by: userId)
                    print("✅ [SWIPE] Profile fetched: \(profile.displayName)")

                    // Create a dating conversation so they can message each other
                    print("💬 [SWIPE] Creating conversation...")
                    _ = try await MessagingManager.shared.fetchOrCreateConversation(
                        with: userId,
                        type: .dating
                    )
                    print("✅ [SWIPE] Conversation created")

                    var matchWithProfile = match
                    matchWithProfile.otherUserProfile = profile
                    print("🎊 [SWIPE] RETURNING MATCH! User should see match animation")
                    return matchWithProfile
                } else {
                    print("💔 [SWIPE] No mutual interest - they haven't liked me yet")
                }
            } catch {
                print("❌ [SWIPE] Error checking for mutual interest: \(error)")
                throw error
            }
        } else {
            print("👎 [SWIPE] Left swipe - no match check needed")
        }

        print("🔄 [SWIPE] Returning nil (no match)")
        return nil
    }

    /// Fetches all matches for the current user.
    public func fetchMatches() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            let matches: [Match] = try await client
                .from("matches")
                .select()
                .or("user1_id.eq.\(userId),user2_id.eq.\(userId)")
                .eq("is_match", value: true)
                .order("matched_at", ascending: false)
                .execute()
                .value

            // Batch-fetch profiles for all matches in a single query
            let otherUserIds = matches.map { $0.otherUserId(currentUserId: userId) }
            let profileMap = try await ProfileManager.shared.fetchProfiles(by: otherUserIds)

            var matchesWithProfiles: [Match] = []
            for match in matches {
                let otherUserId = match.otherUserId(currentUserId: userId)

                // Ensure a dating conversation exists for this match
                _ = try? await MessagingManager.shared.fetchOrCreateConversation(
                    with: otherUserId,
                    type: .dating
                )

                var matchWithProfile = match
                matchWithProfile.otherUserProfile = profileMap[otherUserId]
                matchesWithProfiles.append(matchWithProfile)
            }

            self.matches = matchesWithProfiles
            isLoading = false
        } catch {
            isLoading = false
            if isURLCancelled(error) { return }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches IDs of profiles the user has already swiped on.
    ///
    /// - Returns: Array of user IDs that have been swiped.
    public func fetchSwipedUserIds() async throws -> [UUID] {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        let swipes: [Swipe] = try await client
            .from("swipes")
            .select()
            .eq("swiper_id", value: userId)
            .execute()
            .value

        return swipes.map { $0.swipedId }
    }

    /// Fetches profiles of people who have liked the current user but haven't been liked back yet.
    public func fetchPeopleLikedMe() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        print("🔍 Fetching people who liked me (userId: \(userId))")

        do {
        // Get all swipes where someone swiped right on the current user
        let incomingLikes: [Swipe] = try await client
            .from("swipes")
            .select()
            .eq("swiped_id", value: userId)
            .or("direction.eq.right,direction.eq.up")
            .execute()
            .value

        print("💕 Found \(incomingLikes.count) incoming likes")

        // Get IDs of people the current user has already swiped on
        let mySwipedIds = try await fetchSwipedUserIds()
        print("👆 I have swiped on \(mySwipedIds.count) people")

        // Filter to only people we haven't swiped on yet
        let pendingLikeUserIds = incomingLikes
            .map { $0.swiperId }
            .filter { !mySwipedIds.contains($0) }

        print("⏳ Pending likes (not yet responded): \(pendingLikeUserIds.count)")

        // Batch-fetch profiles for all likers in a single query
        let profileMap = try await ProfileManager.shared.fetchProfiles(by: pendingLikeUserIds)
        let profiles = pendingLikeUserIds.compactMap { profileMap[$0] }
        for profile in profiles {
            print("✅ Loaded profile: \(profile.displayName)")
        }

        self.peopleLikedMe = profiles
        print("📊 Total peopleLikedMe: \(self.peopleLikedMe.count)")
        } catch {
            if isURLCancelled(error) { return }
            throw error
        }
    }

    /// Removes a profile from peopleLikedMe (e.g. after user likes or passes). Use for optimistic UI.
    public func removeFromPeopleLikedMe(id: UUID) {
        peopleLikedMe.removeAll { $0.id == id }
    }

    // MARK: - Realtime Subscriptions

    /// Subscribes to realtime updates for friend requests. If already subscribed, returns immediately.
    public func subscribeToFriendRequests() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        if friendsChannel != nil { return }

        let channel = client.realtimeV2.channel("friends:\(userId)")
        friendsChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "friends",
            filter: "addressee_id=eq.\(userId)"
        )

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "friends",
            filter: "or(requester_id.eq.\(userId),addressee_id.eq.\(userId))"
        )

        Task {
            for await _ in insertions {
                try? await self.fetchPendingRequests(silent: true)
            }
        }

        Task {
            for await _ in updates {
                try? await self.fetchFriends()
                try? await self.fetchPendingRequests(silent: true)
            }
        }

        await channel.subscribe()
        // Initial fetch so we have pending count immediately and catch any missed events
        try? await fetchPendingRequests(silent: true)
    }

    /// Subscribes to realtime updates for matches. If already subscribed, returns immediately.
    public func subscribeToMatches() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        if matchesChannel != nil { return }

        let channel = client.realtimeV2.channel("matches:\(userId)")
        matchesChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "matches",
            filter: "or(user1_id.eq.\(userId),user2_id.eq.\(userId))"
        )

        Task {
            for await _ in insertions {
                try? await self.fetchMatches()
            }
        }

        await channel.subscribe()
    }

    /// Subscribes to realtime updates for incoming swipes (likes). If already subscribed, returns immediately.
    public func subscribeToSwipes() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        if swipesChannel != nil { return }

        let channel = client.realtimeV2.channel("swipes:\(userId)")
        swipesChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "swipes",
            filter: "swiped_id=eq.\(userId)"
        )

        Task {
            for await insertion in insertions {
                // Only refresh if it was a right swipe (like)
                if let directionValue = insertion.record["direction"]?.stringValue,
                   directionValue == "right" || directionValue == "up" {
                    try? await self.fetchPeopleLikedMe()
                }
            }
        }

        await channel.subscribe()
    }

    /// Unsubscribes from all realtime channels and removes them so the next subscribe gets fresh channels (postgresChange before join).
    public func unsubscribe() async {
        if let ch = friendsChannel {
            await client.realtimeV2.removeChannel(ch)
            friendsChannel = nil
        }
        if let ch = matchesChannel {
            await client.realtimeV2.removeChannel(ch)
            matchesChannel = nil
        }
        if let ch = swipesChannel {
            await client.realtimeV2.removeChannel(ch)
            swipesChannel = nil
        }
    }

    private func isURLCancelled(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }
}

// MARK: - Supporting Types

public enum FriendsError: LocalizedError {
    case notAuthenticated
    case requestFailed
    case alreadyFriends
    case requestAlreadySent

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .requestFailed:
            return "Failed to send friend request."
        case .alreadyFriends:
            return "You are already friends with this user."
        case .requestAlreadySent:
            return "A friend request has already been sent."
        }
    }
}
