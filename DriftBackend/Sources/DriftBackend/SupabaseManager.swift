import Combine
import CryptoKit
import Foundation
import Supabase

/// Manager for Supabase authentication and user data.
///
/// Handles user authentication via email/password and Apple Sign In,
/// manages onboarding state, and tracks user preferences.
///
/// ## Usage
///
/// ```swift
/// let manager = SupabaseManager.shared
/// try await manager.signInWithEmail(email: "user@example.com", password: "password")
/// ```
@MainActor
public class SupabaseManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = SupabaseManager()
    /// The Supabase client for API requests.
    public let client: SupabaseClient
    /// The currently authenticated user, or `nil` if not signed in.
    @Published public var currentUser: Auth.User?
    /// Whether a user is currently authenticated.
    @Published public var isAuthenticated = false
    /// Whether authentication status is currently being checked.
    @Published public var isCheckingAuth = true
    /// Whether the welcome splash screen should be displayed.
    @Published public var isShowingWelcomeSplash = false
    /// Whether the onboarding flow should be displayed.
    @Published public var isShowingOnboarding = false
    /// Whether the preference selection screen should be displayed.
    @Published public var isShowingPreferenceSelection = false
    /// Whether the friend onboarding flow should be displayed.
    @Published public var isShowingFriendOnboarding = false
    /// Whether the current user has already redeemed an invite code. `nil` = not yet checked.
    @Published public var hasRedeemedInvite: Bool?

    /// The current raw nonce for Apple Sign-In, stored between request configuration and token exchange.
    private var currentNonce: String?

    private init() {
        guard let supabaseURL = URL(string: _BackendConfiguration.shared.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(_BackendConfiguration.shared.supabaseURL). Check SupabaseConfig.swift.")
        }
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: _BackendConfiguration.shared.supabaseAnonKey
        )
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication Status

    /// Checks the current authentication status and updates state accordingly.
    public func checkAuthStatus() async {
        self.isCheckingAuth = true
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            let userMetadata = session.user.userMetadata
            let hasCompletedOnboarding = parseOnboardingStatus(from: userMetadata)
            let hasPreference = hasSelectedPreference()
            if hasCompletedOnboarding {
                if self.isShowingWelcomeSplash || self.isShowingOnboarding || self.isShowingPreferenceSelection {
                    self.isShowingWelcomeSplash = false
                    self.isShowingOnboarding = false
                    self.isShowingPreferenceSelection = false
                }
            } else {
                if !hasPreference {
                    if !self.isShowingWelcomeSplash {
                        self.isShowingPreferenceSelection = true
                        self.isShowingOnboarding = false
                    }
                } else {
                    if !self.isShowingWelcomeSplash && !self.isShowingPreferenceSelection {
                        self.isShowingOnboarding = true
                    }
                }
            }
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            self.hasRedeemedInvite = nil
            self.isShowingWelcomeSplash = false
            self.isShowingOnboarding = false
            self.isShowingPreferenceSelection = false
        }
        self.isCheckingAuth = false
    }

    // MARK: - Sign In

    /// Signs in a user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Throws: An error if sign in fails.
    public func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUser = session.user
        let userMetadata = session.user.userMetadata
        let hasCompletedOnboarding = parseOnboardingStatus(from: userMetadata)
        let hasPreference = hasSelectedPreference()
        self.isShowingWelcomeSplash = false
        self.isShowingPreferenceSelection = !hasPreference
        self.isShowingOnboarding = hasPreference && !hasCompletedOnboarding
        self.isAuthenticated = true
    }

    /// Signs up a new user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Throws: An error if sign up fails.
    public func signUpWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        self.currentUser = session.user
        let hasPreference = self.hasSelectedPreference()
        if hasPreference {
            let hasCompletedOnboarding = self.parseOnboardingStatus(from: session.user.userMetadata)
            self.isShowingWelcomeSplash = false
            self.isShowingOnboarding = !hasCompletedOnboarding
            self.isShowingPreferenceSelection = false
        } else {
            self.isShowingWelcomeSplash = true
            self.isShowingOnboarding = false
            self.isShowingPreferenceSelection = false
        }
        self.isAuthenticated = true
    }

    /// Generates a random nonce for Apple Sign-In and returns the SHA256-hashed version.
    ///
    /// Call this in the `onRequest` closure of `SignInWithAppleButton` and set
    /// the returned hash as `request.nonce`. The raw nonce is stored internally
    /// and passed automatically during `signInWithApple(identityToken:authorizationCode:)`.
    ///
    /// - Returns: The SHA256-hashed nonce string to set on `ASAuthorizationAppleIDRequest.nonce`.
    public func prepareAppleSignInNonce() -> String {
        let rawNonce = generateRandomNonce()
        self.currentNonce = rawNonce
        let hashed = SHA256.hash(data: Data(rawNonce.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    /// Signs in a user with Apple Sign In credentials.
    ///
    /// - Parameters:
    ///   - identityToken: The identity token from Apple.
    ///   - authorizationCode: The authorization code from Apple.
    /// - Throws: An error if sign in fails.
    public func signInWithApple(identityToken: String, authorizationCode: String?) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: identityToken,
                nonce: currentNonce
            )
        )
        currentNonce = nil
        let userMetadata = session.user.userMetadata
        let hasCompletedOnboarding = parseOnboardingStatus(from: userMetadata)
        let isNewUser = !hasCompletedOnboarding
        let shouldShowSplash = isNewUser
        self.currentUser = session.user
        let hasPreference = self.hasSelectedPreference()
        if shouldShowSplash {
            if hasPreference {
                self.isShowingWelcomeSplash = false
                self.isShowingPreferenceSelection = false
                self.isShowingOnboarding = true
            } else {
                self.isShowingWelcomeSplash = true
                self.isShowingPreferenceSelection = false
                self.isShowingOnboarding = false
            }
        } else {
            self.isShowingWelcomeSplash = false
            self.isShowingPreferenceSelection = !hasPreference
            self.isShowingOnboarding = false
        }
        self.isAuthenticated = true
    }

    /// Signs in a user with Google Sign In using OAuth.
    ///
    /// - Throws: An error if sign in fails.
    public func signInWithGoogle() async throws {
        // Use a custom URL scheme that the app can handle
        // This must match what's configured in Info.plist (CFBundleURLSchemes)
        // AND in Supabase dashboard under Authentication > URL Configuration
        let redirectURL = URL(string: "com.drift.app://auth/callback")!

        // Start OAuth flow - Supabase Swift will open ASWebAuthenticationSession
        // The callback will be handled via the URL scheme
        let session = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: redirectURL
        )

        // The session is returned after OAuth completes
        let userMetadata = session.user.userMetadata
        let hasCompletedOnboarding = parseOnboardingStatus(from: userMetadata)
        let isNewUser = !hasCompletedOnboarding
        let shouldShowSplash = isNewUser

        self.currentUser = session.user
        let hasPreference = self.hasSelectedPreference()
        if shouldShowSplash {
            if hasPreference {
                self.isShowingWelcomeSplash = false
                self.isShowingPreferenceSelection = false
                self.isShowingOnboarding = true
            } else {
                self.isShowingWelcomeSplash = true
                self.isShowingPreferenceSelection = false
                self.isShowingOnboarding = false
            }
        } else {
            self.isShowingWelcomeSplash = false
            self.isShowingPreferenceSelection = !hasPreference
            self.isShowingOnboarding = false
        }
        self.isAuthenticated = true
    }

    /// Signs out the current user.
    ///
    /// - Throws: An error if sign out fails.
    public func signOut() async throws {
        try await client.auth.signOut()
        clearAuthState()
    }

    /// Clears in-memory auth state (used after delete account or when sign out fails).
    public func clearAuthState() {
        self.currentUser = nil
        self.isAuthenticated = false
        self.hasRedeemedInvite = nil
        self.isShowingWelcomeSplash = false
        self.isShowingOnboarding = false
        self.isShowingPreferenceSelection = false
        self.isShowingFriendOnboarding = false
    }

    // MARK: - Onboarding

    /// Marks the user's onboarding as completed.
    public func markOnboardingCompleted() async {
        do {
            guard let currentUser = currentUser else {
                self.isShowingWelcomeSplash = false
                self.isShowingOnboarding = false
                return
            }
            var updatedMetadata = currentUser.userMetadata
            updatedMetadata["onboarding_completed"] = AnyJSON.string("true")
            let updatedUser = try await client.auth.update(user: UserAttributes(data: updatedMetadata))
            self.currentUser = updatedUser
            self.isShowingWelcomeSplash = false
            self.isShowingOnboarding = false
            let session = try await client.auth.session
            self.currentUser = session.user
        } catch {
            self.isShowingWelcomeSplash = false
            self.isShowingOnboarding = false
        }
    }

    // MARK: - Preferences

    /// Discovery mode options
    public enum DiscoveryMode: String {
        case friends = "friends"
        case dating = "dating"
        case both = "both"
    }

    /// Gets the user's current discovery mode.
    ///
    /// - Returns: The discovery mode (friends, dating, or both).
    public func getDiscoveryMode() -> DiscoveryMode {
        guard let user = currentUser else { return .both }

        // Check new discoveryMode key first
        if let modeValue = user.userMetadata["discoveryMode"] {
            let modeString = String(describing: modeValue).lowercased().replacingOccurrences(of: "\"", with: "")
            if let mode = DiscoveryMode(rawValue: modeString) {
                return mode
            }
        }

        // Backward compatibility: check old friendsOnly key
        if parseBoolFromMetadata(user.userMetadata, key: "friendsOnly") {
            return .friends
        }

        return .both
    }

    /// Whether the user has selected friends-only mode.
    ///
    /// - Returns: `true` if the user prefers friends-only mode.
    public func isFriendsOnly() -> Bool {
        return getDiscoveryMode() == .friends
    }

    /// Whether the user has selected dating-only mode.
    ///
    /// - Returns: `true` if the user prefers dating-only mode.
    public func isDatingOnly() -> Bool {
        return getDiscoveryMode() == .dating
    }

    /// Whether the user has made a preference selection.
    ///
    /// - Returns: `true` if the user has selected a preference.
    public func hasSelectedPreference() -> Bool {
        guard let user = currentUser else { return false }
        return user.userMetadata["discoveryMode"] != nil || user.userMetadata["friendsOnly"] != nil
    }

    /// Updates the user's discovery mode preference.
    ///
    /// - Parameter mode: The discovery mode to set.
    /// - Throws: An error if the update fails.
    public func updateDiscoveryMode(_ mode: DiscoveryMode) async throws {
        guard let currentUser = currentUser else {
            throw NSError(
                domain: "SupabaseManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No current user"]
            )
        }
        var updatedMetadata = currentUser.userMetadata
        updatedMetadata["discoveryMode"] = AnyJSON.string(mode.rawValue)
        // Clear old key for cleanliness
        updatedMetadata["friendsOnly"] = nil
        let updatedUser = try await client.auth.update(user: UserAttributes(data: updatedMetadata))
        self.currentUser = updatedUser
    }

    /// Updates the user's friends-only preference (legacy support).
    ///
    /// - Parameter isFriendsOnly: Whether to enable friends-only mode.
    /// - Throws: An error if the update fails.
    public func updatePreference(isFriendsOnly: Bool) async throws {
        try await updateDiscoveryMode(isFriendsOnly ? .friends : .both)
    }

    // MARK: - Private

    /// Generates a cryptographically random nonce string (32 random bytes, hex-encoded).
    private func generateRandomNonce(byteCount: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &randomBytes)
        precondition(status == errSecSuccess, "Failed to generate random bytes for nonce")
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func parseOnboardingStatus(from metadata: [String: Any]) -> Bool {
        guard let value = metadata["onboarding_completed"] else {
            return false
        }
        if let boolValue = value as? Bool {
            return boolValue
        } else if let stringValue = value as? String {
            return stringValue.lowercased() == "true" || stringValue == "1"
        } else if let intValue = value as? Int {
            return intValue != 0
        } else if let nsNumber = value as? NSNumber {
            return nsNumber.boolValue
        }
        let stringDescription = String(describing: value)
        return stringDescription.lowercased() == "true" || stringDescription == "1"
    }

    private func parseBoolFromMetadata(_ metadata: [String: Any], key: String) -> Bool {
        guard let value = metadata[key] else {
            return false
        }
        if let boolValue = value as? Bool {
            return boolValue
        } else if let stringValue = value as? String {
            return stringValue.lowercased() == "true" || stringValue == "1"
        } else if let intValue = value as? Int {
            return intValue != 0
        } else if let nsNumber = value as? NSNumber {
            return nsNumber.boolValue
        }
        let stringDescription = String(describing: value)
        return stringDescription.lowercased() == "true" || stringDescription == "1"
    }
}

// MARK: - Public Helpers

/// Parses onboarding completion status from user metadata.
///
/// - Parameter metadata: The user metadata dictionary.
/// - Returns: `true` if onboarding has been completed.
public func getOnboardingStatus(from metadata: [String: Any]) -> Bool {
    guard let value = metadata["onboarding_completed"] else {
        return false
    }
    if let boolValue = value as? Bool {
        return boolValue
    } else if let stringValue = value as? String {
        return stringValue.lowercased() == "true"
    } else if let intValue = value as? Int {
        return intValue != 0
    }
    return false
}
