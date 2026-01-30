//
//  SupabaseManager+DeleteAccount.swift
//  DriftBackend
//
//  Self-service account deletion via delete-account Edge Function.
//

import Foundation
import Supabase

@MainActor
extension SupabaseManager {

    /// Deletes the current user's account via the delete-account Edge Function, then signs out.
    /// All user data is removed server-side; this action is irreversible.
    ///
    /// - Throws: An error if the Edge Function call fails. If sign out fails after a successful delete (e.g. session already invalid), local state is still cleared.
    public func deleteAccount() async throws {
        let session = try await client.auth.session
        struct EmptyBody: Encodable {}
        struct DeleteAccountResponse: Decodable {
            let success: Bool
        }
        let response: DeleteAccountResponse = try await client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(
                headers: ["Authorization": "Bearer \(session.accessToken)"],
                body: EmptyBody()
            )
        )
        guard response.success else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Account deletion failed"])
        }
        clearAuthState()
        do {
            try await client.auth.signOut()
        } catch {
            // User is already deleted; session may be invalid. Local state is already cleared.
        }
    }
}
