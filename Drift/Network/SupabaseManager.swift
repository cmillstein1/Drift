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
    @Published var showWelcomeSplash = false
    @Published var showOnboarding = false
    
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
            
            // Check if user has completed onboarding
            let userMetadata = session.user.userMetadata
            let hasCompletedOnboarding = userMetadata["onboarding_completed"] as? Bool ?? false
            
            print("🔍 checkAuthStatus - hasCompletedOnboarding: \(hasCompletedOnboarding), metadata: \(userMetadata)")
            
            // If onboarding is completed, don't show splash or onboarding
            if hasCompletedOnboarding {
                self.showWelcomeSplash = false
                self.showOnboarding = false
                print("✅ User has completed onboarding - skipping onboarding flow")
            } else {
                // Only show splash/onboarding for existing sessions if they haven't completed onboarding
                self.showWelcomeSplash = false
                self.showOnboarding = true
                print("⚠️ User has NOT completed onboarding - will show onboarding flow")
            }
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            self.showWelcomeSplash = false
            self.showOnboarding = false
            print("❌ checkAuthStatus error: \(error.localizedDescription)")
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUser = session.user
        
        // Check if user has completed onboarding
        let userMetadata = session.user.userMetadata
        let hasCompletedOnboarding = userMetadata["onboarding_completed"] as? Bool ?? false
        
        // Ensure welcome splash is false for sign-ins
        self.showWelcomeSplash = false
        self.showOnboarding = !hasCompletedOnboarding
        self.isAuthenticated = true
        print("✅ Sign in successful - showWelcomeSplash: \(showWelcomeSplash), showOnboarding: \(showOnboarding)")
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        print("🚀 Starting sign up...")
        let session = try await client.auth.signUp(email: email, password: password)
        print("📝 Sign up response received")
        
            // Set all properties together on MainActor
        await MainActor.run {
            self.currentUser = session.user
            // CRITICAL: Set showWelcomeSplash BEFORE isAuthenticated
            self.showWelcomeSplash = true
            self.showOnboarding = false // Will be set to true after splash
            print("🎉 showWelcomeSplash set to TRUE: \(self.showWelcomeSplash)")
            
            // Set isAuthenticated immediately after - SwiftUI will see both together
            self.isAuthenticated = true
            print("✅ Sign up complete - showWelcomeSplash: \(self.showWelcomeSplash), isAuthenticated: \(self.isAuthenticated)")
        }
    }
    
    func signInWithApple(identityToken: String, authorizationCode: String?) async throws {
        print("🍎 Starting Apple Sign In...")
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nil
                )
            )
            print("📝 Apple Sign In response received")
            
            // Check if this is a new user by checking if account was created very recently
            // New users will have been created within the last 5 seconds
            let timeSinceCreation = Date().timeIntervalSince(session.user.createdAt)
            let isNewUser = timeSinceCreation < 5.0
            
            // Also check if user has completed onboarding by checking user metadata
            // If onboarding_completed is not set or false, show the splash
            let userMetadata = session.user.userMetadata
            let hasCompletedOnboarding = userMetadata["onboarding_completed"] as? Bool ?? false
            
            print("👤 User created: \(session.user.createdAt), time since: \(timeSinceCreation)s")
            print("👤 isNewUser: \(isNewUser), hasCompletedOnboarding: \(hasCompletedOnboarding)")
            
            // Show splash if new user OR if they haven't completed onboarding
            let shouldShowSplash = isNewUser || !hasCompletedOnboarding
            
            // Set properties similar to sign-up flow
            await MainActor.run {
                self.currentUser = session.user
                
                if shouldShowSplash {
                    // CRITICAL: Set showWelcomeSplash BEFORE isAuthenticated
                    self.showWelcomeSplash = true
                    self.showOnboarding = false // Will be set to true after splash
                    print("🎉 Showing WelcomeSplash - isNewUser: \(isNewUser), needsOnboarding: \(!hasCompletedOnboarding)")
                } else {
                    // Existing user who has completed onboarding - don't show splash
                    self.showWelcomeSplash = false
                    self.showOnboarding = false
                    print("👋 Existing user with completed onboarding - showWelcomeSplash set to FALSE")
                }
                
                // Set isAuthenticated after showWelcomeSplash
                self.isAuthenticated = true
                print("✅ Apple Sign In complete - showWelcomeSplash: \(self.showWelcomeSplash), showOnboarding: \(self.showOnboarding), isAuthenticated: \(self.isAuthenticated)")
            }
        } catch {
            print("❌ Supabase Apple Sign In Error: \(error)")
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        // Google Sign In implementation
        // This requires additional setup in the app
        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign In not yet implemented"])
    }
    
    func markOnboardingCompleted() async {
        do {
            // Update user metadata to mark onboarding as completed
            var updatedMetadata = currentUser?.userMetadata ?? [:]
            updatedMetadata["onboarding_completed"] = true
            
            // Update user with new metadata
            // The update method returns a User directly, not a session
            let updatedUser = try await client.auth.update(user: UserAttributes(data: updatedMetadata))
            self.currentUser = updatedUser
            self.showOnboarding = false
            print("✅ Onboarding marked as completed in user metadata")
        } catch {
            print("⚠️ Failed to mark onboarding as completed: \(error.localizedDescription)")
            // Don't throw - this is not critical, we'll still hide the splash
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
        self.showWelcomeSplash = false
        self.showOnboarding = false
    }
}
