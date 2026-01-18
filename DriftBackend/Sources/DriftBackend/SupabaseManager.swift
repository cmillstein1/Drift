import Combine
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
    /// Whether the welcome splash screen should be displayed.
    @Published public var isShowingWelcomeSplash = false
    /// Whether the onboarding flow should be displayed.
    @Published public var isShowingOnboarding = false
    /// Whether the preference selection screen should be displayed.
    @Published public var isShowingPreferenceSelection = false
    /// Whether the friend onboarding flow should be displayed.
    @Published public var isShowingFriendOnboarding = false

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: _BackendConfiguration.shared.supabaseURL)!,
            supabaseKey: _BackendConfiguration.shared.supabaseAnonKey
        )
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication Status

    /// Checks the current authentication status and updates state accordingly.
    public func checkAuthStatus() async {
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
            self.isShowingWelcomeSplash = false
            self.isShowingOnboarding = false
            self.isShowingPreferenceSelection = false
        }
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
        await MainActor.run {
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
                nonce: nil
            )
        )
        let timeSinceCreation = Date().timeIntervalSince(session.user.createdAt)
        let isNewUser = timeSinceCreation < 5.0
        let userMetadata = session.user.userMetadata
        let hasCompletedOnboarding = parseOnboardingStatus(from: userMetadata)
        let shouldShowSplash = isNewUser || !hasCompletedOnboarding
        await MainActor.run {
            self.currentUser = session.user
            let hasPreference = self.hasSelectedPreference()
            if shouldShowSplash {
                if hasPreference {
                    self.isShowingWelcomeSplash = false
                    self.isShowingPreferenceSelection = false
                    self.isShowingOnboarding = !hasCompletedOnboarding
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
    }

    /// Signs in a user with Google Sign In.
    ///
    /// - Throws: Always throws as this feature is not yet implemented.
    public func signInWithGoogle() async throws {
        throw NSError(
            domain: "SupabaseManager",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Google Sign In not yet implemented"]
        )
    }

    /// Signs out the current user.
    ///
    /// - Throws: An error if sign out fails.
    public func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
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

    /// Whether the user has selected friends-only mode.
    ///
    /// - Returns: `true` if the user prefers friends-only mode.
    public func isFriendsOnly() -> Bool {
        guard let user = currentUser else { return false }
        return parseBoolFromMetadata(user.userMetadata, key: "friendsOnly")
    }

    /// Whether the user has made a preference selection.
    ///
    /// - Returns: `true` if the user has selected a preference.
    public func hasSelectedPreference() -> Bool {
        guard let user = currentUser else { return false }
        return user.userMetadata["friendsOnly"] != nil
    }

    /// Updates the user's friends-only preference.
    ///
    /// - Parameter isFriendsOnly: Whether to enable friends-only mode.
    /// - Throws: An error if the update fails.
    public func updatePreference(isFriendsOnly: Bool) async throws {
        guard let currentUser = currentUser else {
            throw NSError(
                domain: "SupabaseManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No current user"]
            )
        }
        var updatedMetadata = currentUser.userMetadata
        updatedMetadata["friendsOnly"] = AnyJSON.string(isFriendsOnly ? "true" : "false")
        let updatedUser = try await client.auth.update(user: UserAttributes(data: updatedMetadata))
        self.currentUser = updatedUser
    }

    // MARK: - Private

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
