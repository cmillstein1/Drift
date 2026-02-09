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

        #if DEBUG
        print("[DeleteAccount] Starting account deletion...")
        print("[DeleteAccount] User ID: \(session.user.id)")
        print("[DeleteAccount] Token length: \(session.accessToken.count)")
        print("[DeleteAccount] Token expires at: \(Date(timeIntervalSince1970: session.expiresAt))")
        print("[DeleteAccount] Token (first 40): \(String(session.accessToken.prefix(40)))...")
        // Decode JWT payload to inspect claims
        let parts = session.accessToken.split(separator: ".")
        if parts.count >= 2 {
            var base64 = String(parts[1])
            // Pad base64 to multiple of 4
            while base64.count % 4 != 0 { base64.append("=") }
            if let data = Data(base64Encoded: base64),
               let json = String(data: data, encoding: .utf8) {
                print("[DeleteAccount] JWT payload: \(json)")
            }
        }
        #endif

        struct EmptyBody: Encodable {}
        struct DeleteAccountResponse: Decodable {
            let success: Bool
            let error: String?
        }

        do {
            // Don't pass manual Authorization header — the SDK's fetchWithAuth
            // adapter overwrites it anyway with auth.session.accessToken
            let decoded: DeleteAccountResponse = try await client.functions.invoke(
                "delete-account",
                options: FunctionInvokeOptions(body: EmptyBody())
            ) { data, response in
                #if DEBUG
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("[DeleteAccount] HTTP \(response.statusCode) — body: \(bodyString)")
                #endif
                return try JSONDecoder().decode(DeleteAccountResponse.self, from: data)
            }

            guard decoded.success else {
                let msg = decoded.error ?? "Account deletion failed"
                #if DEBUG
                print("[DeleteAccount] Server returned success=false: \(msg)")
                #endif
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
            }

            #if DEBUG
            print("[DeleteAccount] Success! Clearing auth state...")
            #endif
        } catch let error as FunctionsError {
            #if DEBUG
            print("[DeleteAccount] FunctionsError: \(error)")
            if case .httpError(let code, let data) = error {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("[DeleteAccount] HTTP \(code) — body: \(body)")
            }
            #endif
            throw error
        }

        clearAuthState()
        do {
            try await client.auth.signOut()
        } catch {
            // User is already deleted; session may be invalid. Local state is already cleared.
        }
    }
}
