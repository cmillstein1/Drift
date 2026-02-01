import Foundation
import Supabase
import FirebaseMessaging

/// Manager for push notification token registration and preference syncing.
///
/// Handles storing FCM tokens to Supabase and syncing notification preferences.
/// Works in conjunction with Firebase Messaging configured in the app delegate.
///
/// ## Usage
///
/// ```swift
/// // Called from AppDelegate when FCM token is received
/// await PushNotificationManager.shared.updateFCMToken(token)
///
/// // Sync preferences from settings UI
/// await PushNotificationManager.shared.syncPreferences(["newMessages": true, "newMatches": false])
/// ```
@MainActor
public class PushNotificationManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = PushNotificationManager()

    /// The current FCM token, if available.
    @Published public var fcmToken: String?

    /// Whether push notification permission has been granted.
    @Published public var isPermissionGranted: Bool = false

    /// Whether a token update is in progress.
    @Published public var isUpdatingToken: Bool = false

    private var supabaseClient: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - FCM Token Management

    /// Updates the FCM token in Supabase for the current user.
    ///
    /// Called from the app delegate when Firebase Messaging receives a new registration token.
    /// The token is stored in the user's profile for server-side push notification targeting.
    ///
    /// - Parameter token: The FCM registration token.
    public func updateFCMToken(_ token: String) async {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            #if DEBUG
            print("[PushNotificationManager] Cannot update FCM token: user not authenticated")
            #endif
            return
        }

        self.fcmToken = token
        self.isUpdatingToken = true

        do {
            try await supabaseClient
                .from("profiles")
                .update(["fcm_token": token])
                .eq("id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("[PushNotificationManager] FCM token saved to Supabase")
            #endif
        } catch {
            #if DEBUG
            print("[PushNotificationManager] Failed to save FCM token: \(error.localizedDescription)")
            #endif
        }

        self.isUpdatingToken = false
    }

    /// Clears the FCM token from Supabase when user logs out.
    ///
    /// Should be called during sign out to prevent push notifications
    /// from being sent to a device after the user has logged out.
    public func clearFCMToken() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        do {
            try await supabaseClient
                .from("profiles")
                .update(ClearTokenPayload())
                .eq("id", value: userId.uuidString)
                .execute()

            self.fcmToken = nil

            #if DEBUG
            print("[PushNotificationManager] FCM token cleared from Supabase")
            #endif
        } catch {
            #if DEBUG
            print("[PushNotificationManager] Failed to clear FCM token: \(error.localizedDescription)")
            #endif
        }
    }

    /// Payload for clearing FCM token (sets to null)
    private struct ClearTokenPayload: Encodable {
        let fcm_token: String? = nil
    }

    // MARK: - Notification Preferences

    /// Notification preference categories matching the UI settings.
    public enum NotificationCategory: String, CaseIterable, Codable {
        case newMessages
        case newMatches
        case nearbyTravelers
        case eventUpdates
    }

    /// Syncs notification preferences to Supabase.
    ///
    /// Preferences are stored as a JSONB column on the profiles table,
    /// allowing server-side Edge Functions to check user preferences
    /// before sending push notifications.
    ///
    /// - Parameter preferences: Dictionary mapping category names to enabled state.
    public func syncPreferences(_ preferences: [String: Bool]) async {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            #if DEBUG
            print("[PushNotificationManager] Cannot sync preferences: user not authenticated")
            #endif
            return
        }

        do {
            try await supabaseClient
                .from("profiles")
                .update(["notification_prefs": preferences])
                .eq("id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("[PushNotificationManager] Notification preferences synced to Supabase")
            #endif
        } catch {
            #if DEBUG
            print("[PushNotificationManager] Failed to sync preferences: \(error.localizedDescription)")
            #endif
        }
    }

    /// Fetches the current notification preferences from Supabase.
    ///
    /// - Returns: Dictionary of preferences, or default values if fetch fails.
    public func fetchPreferences() async -> [String: Bool] {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            return defaultPreferences
        }

        do {
            let response: [PreferencesRow] = try await supabaseClient
                .from("profiles")
                .select("notification_prefs")
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            if let prefs = response.first?.notification_prefs {
                return prefs
            }
        } catch {
            #if DEBUG
            print("[PushNotificationManager] Failed to fetch preferences: \(error.localizedDescription)")
            #endif
        }

        return defaultPreferences
    }

    /// Default notification preferences (all enabled).
    public var defaultPreferences: [String: Bool] {
        [
            "newMessages": true,
            "newMatches": true,
            "nearbyTravelers": true,
            "eventUpdates": true
        ]
    }

    // MARK: - Permission Status

    /// Checks the current notification permission status.
    public func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isPermissionGranted = settings.authorizationStatus == .authorized
    }

    /// Requests notification permission from the user.
    ///
    /// - Returns: Whether permission was granted.
    @discardableResult
    public func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            self.isPermissionGranted = granted
            return granted
        } catch {
            #if DEBUG
            print("[PushNotificationManager] Permission request failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Helper Types

    private struct PreferencesRow: Codable {
        let notification_prefs: [String: Bool]?
    }
}

// MARK: - UserNotifications Import
import UserNotifications
