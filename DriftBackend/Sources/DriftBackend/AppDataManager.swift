import Foundation

/// Centralized manager for app-wide data initialization.
///
/// Call `initializeAppData()` once when the user becomes authenticated to preload
/// conversations (for unread badge), profile, friends, and matches.
/// This replaces redundant fetch calls scattered across screens.
@MainActor
public class AppDataManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = AppDataManager()

    /// Whether initial data has been loaded for the current session.
    @Published public private(set) var hasInitialized = false
    /// Whether initialization is currently in progress.
    @Published public private(set) var isInitializing = false

    private init() {}

    /// Initializes app data for the authenticated user.
    ///
    /// Fetches conversations (for unread count), profile, friends, pending requests,
    /// and optionally matches/likes for dating mode. Skips if already initialized
    /// for the current session.
    ///
    /// - Parameter includeDating: Whether to also fetch dating-related data (matches, likes).
    public func initializeAppData(includeDating: Bool = true) async {
        guard !hasInitialized, !isInitializing else { return }
        guard SupabaseManager.shared.currentUser != nil else { return }

        isInitializing = true
        defer { isInitializing = false }

        // Fetch conversations first (needed for unread badge on Messages tab)
        do {
            try await MessagingManager.shared.fetchConversations()
        } catch {
        }

        // Fetch friends data and notifications in parallel
        async let friendsTask: () = fetchFriendsData()
        async let profileTask: () = fetchProfileData()
        async let notificationsTask: () = fetchNotificationsData()

        _ = await (friendsTask, profileTask, notificationsTask)

        // Dating-specific data
        if includeDating && !SupabaseManager.shared.isFriendsOnly() {
            await fetchDatingData()
        }

        // Subscribe to realtime updates
        await subscribeToRealtimeUpdates(includeDating: includeDating)

        hasInitialized = true
    }

    /// Resets initialization state. Call this on sign out.
    public func reset() {
        hasInitialized = false
        isInitializing = false
    }

    /// Refreshes all data. Unlike initialize, this always runs regardless of hasInitialized.
    public func refreshAllData(includeDating: Bool = true) async {
        guard SupabaseManager.shared.currentUser != nil else { return }

        do {
            try await MessagingManager.shared.fetchConversations()
        } catch {
        }

        await fetchFriendsData()
        await fetchProfileData()
        await fetchNotificationsData()

        if includeDating && !SupabaseManager.shared.isFriendsOnly() {
            await fetchDatingData()
        }

    }

    // MARK: - Private

    private func fetchFriendsData() async {
        do {
            try await FriendsManager.shared.fetchFriends()
        } catch {
        }

        do {
            try await FriendsManager.shared.fetchPendingRequests()
        } catch {
        }

        do {
            try await FriendsManager.shared.fetchSentRequests()
        } catch {
        }
    }

    private func fetchProfileData() async {
        do {
            try await ProfileManager.shared.fetchCurrentProfile()
        } catch {
        }
    }

    private func fetchDatingData() async {
        do {
            try await FriendsManager.shared.fetchMatches()
        } catch {
        }

        do {
            try await FriendsManager.shared.fetchPeopleLikedMe()
        } catch {
        }
    }

    private func fetchNotificationsData() async {
        await NotificationsManager.shared.fetchNotifications()
    }

    private func subscribeToRealtimeUpdates(includeDating: Bool) async {
        await MessagingManager.shared.subscribeToConversations()
        await FriendsManager.shared.subscribeToFriendRequests()

        if includeDating && !SupabaseManager.shared.isFriendsOnly() {
            await FriendsManager.shared.subscribeToSwipes()
            await FriendsManager.shared.subscribeToMatches()
        }
    }
}
