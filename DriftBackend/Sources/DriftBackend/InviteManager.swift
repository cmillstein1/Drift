import Foundation
import Supabase

/// Manager for invite code generation and redemption.
///
/// Handles generating invite codes via Supabase edge functions
/// and redeeming them during signup.
@MainActor
public class InviteManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = InviteManager()
    
    /// The currently generated invite code.
    @Published public var currentInviteCode: String?
    /// Whether an invite code is currently being generated.
    @Published public var isGenerating = false
    /// The last error message, if any.
    @Published public var error: String?
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    private init() {}
    
    // MARK: - Generate Invite Code
    
    /// Generates a new invite code via the Supabase edge function.
    public func generateInviteCode() async {
        isGenerating = true
        error = nil
        
        // Check if user is authenticated
        guard SupabaseManager.shared.isAuthenticated,
              let currentUser = SupabaseManager.shared.currentUser else {
            self.error = "You must be signed in to generate an invite code"
            self.isGenerating = false
            return
        }
        
        do {
            // Ensure we have a valid session - this will throw if not authenticated
            let session = try await client.auth.session
            
            let accessToken = session.accessToken
            
            print("🔐 [InviteManager] Session found")
            print("🔐 [InviteManager] User ID: \(session.user.id)")
            print("🔐 [InviteManager] Access token length: \(accessToken.count)")
            print("🔐 [InviteManager] Access token prefix: \(String(accessToken.prefix(30)))...")
            print("🔐 [InviteManager] Access token starts with 'Bearer': \(accessToken.hasPrefix("Bearer "))")
            print("🔐 [InviteManager] Full access token (first 100 chars): \(String(accessToken.prefix(100)))")
            
            struct EmptyBody: Encodable {}
            
            print("📤 [InviteManager] Using Supabase client functions.invoke (should auto-handle auth)...")
            
            // Use the Supabase client's built-in function invocation
            // This should automatically handle authentication correctly
            let invitation: Invitation = try await client.functions.invoke(
                "generate-invite",
                options: FunctionInvokeOptions(body: EmptyBody())
            )
            
            print("✅ [InviteManager] Successfully generated invite code: \(invitation.code)")
            
            self.currentInviteCode = invitation.code
            self.isGenerating = false
            self.error = nil
        } catch {
            print("❌ [InviteManager] Failed to generate invite code: \(error)")
            print("❌ [InviteManager] Error type: \(type(of: error))")
            print("❌ [InviteManager] Error description: \(error.localizedDescription)")
            
            if let urlError = error as? URLError {
                print("❌ [InviteManager] URLError code: \(urlError.code.rawValue)")
                print("❌ [InviteManager] URLError description: \(urlError.localizedDescription)")
            }
            
            let errorMessage = error.localizedDescription
            if errorMessage.contains("401") || errorMessage.contains("Unauthorized") {
                self.error = "Authentication failed. Please sign out and sign in again, then try again."
            } else {
                self.error = errorMessage
            }
            self.isGenerating = false
        }
    }
    
    // MARK: - Validate Invite Code
    
    /// Validates an invite code without redeeming it.
    /// Used during signup to verify the code is valid before creating the account.
    /// This function works without authentication since it's called before signup.
    ///
    /// - Parameter code: The invite code to validate.
    /// - Returns: `true` if the code is valid, `false` otherwise.
    public func validateInviteCode(_ code: String) async -> Bool {
        struct ValidateBody: Encodable {
            let code: String
            let userId: String?  // Optional userId - if null, edge function should only validate
            let validateOnly: Bool  // Flag for validation-only mode (no redemption)
        }
        
        do {
            // Call the edge function without auth headers (validation should work without auth)
            // The edge function should handle validation-only requests without requiring authentication
            // IMPORTANT: Your edge function must check for validateOnly: true and skip auth requirement
            let result: RedeemResult = try await client.functions.invoke(
                "redeem-invite",
                options: FunctionInvokeOptions(
                    body: ValidateBody(code: code, userId: nil, validateOnly: true)
                )
            )
            return result.success
        } catch {
            // Check if it's an auth error - this means the edge function needs to be updated
            let errorMessage = error.localizedDescription
            if errorMessage.contains("401") || errorMessage.contains("Unauthorized") {
                print("⚠️ Edge function requires auth for validation. Update your redeem-invite function to allow validation without auth when validateOnly: true")
                // Still return false, but log the issue
            }
            print("Invite code validation error: \(errorMessage)")
            return false
        }
    }
    
    // MARK: - Redeem Invite Code
    
    /// Validates and redeems an invite code during signup.
    ///
    /// - Parameters:
    ///   - code: The invite code to redeem.
    ///   - userId: The user ID of the new user.
    /// - Throws: An error if redemption fails.
    public func redeemInviteCode(_ code: String, userId: UUID) async throws {
        // Get the current session to include auth token
        let session = try await client.auth.session
        let accessToken = session.accessToken
        
        struct RedeemBody: Encodable {
            let code: String
            let userId: String
        }
        
        let result: RedeemResult = try await client.functions.invoke(
            "redeem-invite",
            options: FunctionInvokeOptions(
                headers: ["Authorization": "Bearer \(accessToken)"],
                body: RedeemBody(code: code, userId: userId.uuidString)
            )
        )
        
        if !result.success {
            throw InviteError.redemptionFailed(result.error ?? "Unknown error")
        }
    }

    // MARK: - Check Invite Status

    /// Returns whether the current user has already redeemed an invite code.
    /// Used after sign-in to decide whether to show the Enter Invite Code screen.
    /// Uses the redeem-invite edge function with checkUserStatus: true.
    public func hasUserRedeemedInvite() async -> Bool {
        guard SupabaseManager.shared.isAuthenticated else { return false }
        do {
            let session = try await client.auth.session
            struct CheckStatusBody: Encodable {
                let checkUserStatus = true
            }
            let response: InviteStatusResponse = try await client.functions.invoke(
                "redeem-invite",
                options: FunctionInvokeOptions(
                    headers: ["Authorization": "Bearer \(session.accessToken)"],
                    body: CheckStatusBody()
                )
            )
            return response.hasRedeemed
        } catch {
            print("Invite status check error: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Models

/// Represents an invitation code.
public struct Invitation: Codable {
    public let id: UUID
    public let code: String
    public let createdBy: UUID
    public let createdAt: Date?
    public let expiresAt: Date?
    public let isUsed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, code
        case createdBy = "created_by"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case isUsed = "is_used"
    }
    
    public init(id: UUID, code: String, createdBy: UUID, createdAt: Date?, expiresAt: Date?, isUsed: Bool) {
        self.id = id
        self.code = code
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isUsed = isUsed
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        isUsed = try container.decode(Bool.self, forKey: .isUsed)
        
        // Handle dates as ISO8601 strings from edge function
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: createdAtString) ?? ISO8601DateFormatter().date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let expiresAtString = try container.decodeIfPresent(String.self, forKey: .expiresAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            expiresAt = formatter.date(from: expiresAtString) ?? ISO8601DateFormatter().date(from: expiresAtString)
        } else {
            expiresAt = nil
        }
    }
}

/// Response from check-invite-status edge function.
public struct InviteStatusResponse: Codable {
    public let hasRedeemed: Bool
    public init(hasRedeemed: Bool) {
        self.hasRedeemed = hasRedeemed
    }
}

/// Result of redeeming an invite code.
public struct RedeemResult: Codable {
    public let success: Bool
    public let error: String?
    
    public init(success: Bool, error: String?) {
        self.success = success
        self.error = error
    }
}

/// Errors that can occur during invite operations.
public enum InviteError: Error {
    case signupFailed
    case redemptionFailed(String)
    
    public var localizedDescription: String {
        switch self {
        case .signupFailed:
            return "Failed to create account"
        case .redemptionFailed(let message):
            return message
        }
    }
}
