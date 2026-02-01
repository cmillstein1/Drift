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

        print("[AppDataManager] Initializing app data...")

        // Fetch conversations first (needed for unread badge on Messages tab)
        do {
            try await MessagingManager.shared.fetchConversations()
            print("[AppDataManager] Conversations loaded, unread count: \(MessagingManager.shared.unreadCount)")
        } catch {
            print("[AppDataManager] Failed to fetch conversations: \(error)")
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
        print("[AppDataManager] App data initialization complete")
    }

    /// Resets initialization state. Call this on sign out.
    public func reset() {
        hasInitialized = false
        isInitializing = false
        print("[AppDataManager] Reset initialization state")
    }

    /// Refreshes all data. Unlike initialize, this always runs regardless of hasInitialized.
    public func refreshAllData(includeDating: Bool = true) async {
        guard SupabaseManager.shared.currentUser != nil else { return }

        print("[AppDataManager] Refreshing all app data...")

        do {
            try await MessagingManager.shared.fetchConversations()
        } catch {
            print("[AppDataManager] Failed to refresh conversations: \(error)")
        }

        await fetchFriendsData()
        await fetchProfileData()
        await fetchNotificationsData()

        if includeDating && !SupabaseManager.shared.isFriendsOnly() {
            await fetchDatingData()
        }

        print("[AppDataManager] Refresh complete")
    }

    // MARK: - Private

    private func fetchFriendsData() async {
        do {
            try await FriendsManager.shared.fetchFriends()
        } catch {
            print("[AppDataManager] Failed to fetch friends: \(error)")
        }

        do {
            try await FriendsManager.shared.fetchPendingRequests()
        } catch {
            print("[AppDataManager] Failed to fetch pending requests: \(error)")
        }

        do {
            try await FriendsManager.shared.fetchSentRequests()
        } catch {
            print("[AppDataManager] Failed to fetch sent requests: \(error)")
        }
    }

    private func fetchProfileData() async {
        do {
            try await ProfileManager.shared.fetchCurrentProfile()
        } catch {
            print("[AppDataManager] Failed to fetch profile: \(error)")
        }
    }

    private func fetchDatingData() async {
        do {
            try await FriendsManager.shared.fetchMatches()
        } catch {
            print("[AppDataManager] Failed to fetch matches: \(error)")
        }

        do {
            try await FriendsManager.shared.fetchPeopleLikedMe()
        } catch {
            print("[AppDataManager] Failed to fetch likes: \(error)")
        }
    }

    private func fetchNotificationsData() async {
        await NotificationsManager.shared.fetchNotifications()
        print("[AppDataManager] Notifications loaded, unread count: \(NotificationsManager.shared.unreadCount)")
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
