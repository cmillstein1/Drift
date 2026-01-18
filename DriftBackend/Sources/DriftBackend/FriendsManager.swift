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
    /// Dating matches (mutual likes).
    @Published public var matches: [Match] = []
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var friendsChannel: RealtimeChannelV2?
    private var matchesChannel: RealtimeChannelV2?

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
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches pending incoming friend requests.
    public func fetchPendingRequests() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            let requests: [Friend] = try await client
                .from("friends")
                .select("*, requester:profiles!requester_id(*)")
                .eq("addressee_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value

            self.pendingRequests = requests
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Sends a friend request to another user.
    ///
    /// - Parameter userId: The ID of the user to send a request to.
    public func sendFriendRequest(to userId: UUID) async throws {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw FriendsError.notAuthenticated
        }

        let request = FriendRequest(requesterId: currentUserId, addresseeId: userId)

        try await client
            .from("friends")
            .insert(request)
            .execute()
    }

    /// Responds to a friend request.
    ///
    /// - Parameters:
    ///   - requestId: The ID of the friend request.
    ///   - accept: Whether to accept or decline the request.
    public func respondToFriendRequest(_ requestId: UUID, accept: Bool) async throws {
        let newStatus: FriendStatus = accept ? .accepted : .declined

        try await client
            .from("friends")
            .update(["status": newStatus.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: requestId)
            .execute()

        // Refresh lists
        try await fetchPendingRequests()
        if accept {
            try await fetchFriends()
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
            throw FriendsError.notAuthenticated
        }

        let request = SwipeRequest(swiperId: currentUserId, swipedId: userId, direction: direction)

        try await client
            .from("swipes")
            .insert(request)
            .execute()

        // If right swipe, check for match
        if direction == .right || direction == .up {
            // The database trigger will create the match if mutual
            // Fetch to see if there's a new match
            let matches: [Match] = try await client
                .from("matches")
                .select()
                .or("and(user1_id.eq.\(min(currentUserId, userId)),user2_id.eq.\(max(currentUserId, userId)))")
                .eq("is_match", value: true)
                .execute()
                .value

            if let match = matches.first {
                // It's a match! Fetch the other user's profile
                let otherUserId = match.otherUserId(currentUserId: currentUserId)
                let profile = try await ProfileManager.shared.fetchProfile(by: otherUserId)

                var matchWithProfile = match
                matchWithProfile.otherUserProfile = profile
                return matchWithProfile
            }
        }

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

            // Fetch profiles for each match
            var matchesWithProfiles: [Match] = []
            for match in matches {
                let otherUserId = match.otherUserId(currentUserId: userId)
                let profile = try await ProfileManager.shared.fetchProfile(by: otherUserId)
                var matchWithProfile = match
                matchWithProfile.otherUserProfile = profile
                matchesWithProfiles.append(matchWithProfile)
            }

            self.matches = matchesWithProfiles
            isLoading = false
        } catch {
            isLoading = false
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

    // MARK: - Realtime Subscriptions

    /// Subscribes to realtime updates for friend requests.
    public func subscribeToFriendRequests() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        friendsChannel = client.realtimeV2.channel("friends:\(userId)")

        let insertions = friendsChannel?.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "friends",
            filter: "addressee_id=eq.\(userId)"
        )

        let updates = friendsChannel?.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "friends",
            filter: "or(requester_id.eq.\(userId),addressee_id.eq.\(userId))"
        )

        Task {
            if let insertions = insertions {
                for await _ in insertions {
                    try? await self.fetchPendingRequests()
                }
            }
        }

        Task {
            if let updates = updates {
                for await _ in updates {
                    try? await self.fetchFriends()
                    try? await self.fetchPendingRequests()
                }
            }
        }

        await friendsChannel?.subscribe()
    }

    /// Subscribes to realtime updates for matches.
    public func subscribeToMatches() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        matchesChannel = client.realtimeV2.channel("matches:\(userId)")

        let insertions = matchesChannel?.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "matches",
            filter: "or(user1_id.eq.\(userId),user2_id.eq.\(userId))"
        )

        Task {
            if let insertions = insertions {
                for await _ in insertions {
                    try? await self.fetchMatches()
                }
            }
        }

        await matchesChannel?.subscribe()
    }

    /// Unsubscribes from all realtime channels.
    public func unsubscribe() async {
        await friendsChannel?.unsubscribe()
        await matchesChannel?.unsubscribe()
        friendsChannel = nil
        matchesChannel = nil
    }
}

// MARK: - Supporting Types

public enum FriendsError: LocalizedError {
    case notAuthenticated
    case requestFailed
    case alreadyFriends

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .requestFailed:
            return "Failed to send friend request."
        case .alreadyFriends:
            return "You are already friends with this user."
        }
    }
}
