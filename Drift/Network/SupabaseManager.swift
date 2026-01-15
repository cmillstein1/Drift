//
//  SupabaseManager.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import Foundation
import Combine
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: Auth.User?
    @Published var isAuthenticated = false
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUser = session.user
        self.isAuthenticated = true
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        self.currentUser = session.user
        self.isAuthenticated = true
    }
    
    func signInWithApple(identityToken: String, authorizationCode: String?) async throws {
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nil
                )
            )
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            print("Supabase Apple Sign In Error: \(error)")
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        // Google Sign In implementation
        // This requires additional setup in the app
        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign In not yet implemented"])
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
