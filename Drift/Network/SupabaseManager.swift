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
            let hasCompletedOnboarding = getOnboardingStatus(from: userMetadata)
            
            print("🔍 checkAuthStatus - hasCompletedOnboarding: \(hasCompletedOnboarding)")
            print("🔍 Metadata value for onboarding_completed: \(userMetadata["onboarding_completed"] ?? "nil")")
            print("🔍 Type of value: \(type(of: userMetadata["onboarding_completed"]))")
            
            // If onboarding is completed, don't show splash or onboarding
            // IMPORTANT: Only set these if they're not already correctly set to prevent loops
            if hasCompletedOnboarding {
                if self.showWelcomeSplash || self.showOnboarding {
                    self.showWelcomeSplash = false
                    self.showOnboarding = false
                    print("✅ User has completed onboarding - cleared onboarding flags")
                }
            } else {
                // Only set showOnboarding if we're not already showing welcome splash
                // This prevents resetting state unnecessarily
                if !self.showWelcomeSplash {
                    self.showOnboarding = true
                    print("⚠️ User has NOT completed onboarding - will show onboarding flow")
                }
            }
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            self.showWelcomeSplash = false
            self.showOnboarding = false
            print("❌ checkAuthStatus error: \(error.localizedDescription)")
        }
    }
    
    private func getOnboardingStatus(from metadata: [String: Any]) -> Bool {
        guard let value = metadata["onboarding_completed"] else {
            print("🔍 onboarding_completed key not found in metadata")
            return false
        }
        
        print("🔍 Raw value: \(value), type: \(type(of: value))")
        
        // Handle different types that Supabase might return
        if let boolValue = value as? Bool {
            print("🔍 Parsed as Bool: \(boolValue)")
            return boolValue
        } else if let stringValue = value as? String {
            let result = stringValue.lowercased() == "true" || stringValue == "1"
            print("🔍 Parsed as String '\(stringValue)': \(result)")
            return result
        } else if let intValue = value as? Int {
            let result = intValue != 0
            print("🔍 Parsed as Int \(intValue): \(result)")
            return result
        } else if let nsNumber = value as? NSNumber {
            let result = nsNumber.boolValue
            print("🔍 Parsed as NSNumber \(nsNumber): \(result)")
            return result
        }
        
        // Try to convert to string and check
        let stringDescription = String(describing: value)
        if stringDescription.lowercased() == "true" || stringDescription == "1" {
            print("🔍 Parsed via String(describing:): \(stringDescription) -> true")
            return true
        }
        
        print("🔍 Could not parse onboarding_completed value: \(value)")
        return false
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUser = session.user
        
        // Check if user has completed onboarding
        let userMetadata = session.user.userMetadata
        let hasCompletedOnboarding = getOnboardingStatus(from: userMetadata)
        
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
            let hasCompletedOnboarding = getOnboardingStatus(from: userMetadata)
            
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
            guard let currentUser = currentUser else {
                print("⚠️ No current user to update")
                self.showWelcomeSplash = false
                self.showOnboarding = false
                return
            }
            
            // Update user metadata to mark onboarding as completed
            var updatedMetadata = currentUser.userMetadata
            updatedMetadata["onboarding_completed"] = true
            
            print("💾 Marking onboarding as complete - metadata before: \(updatedMetadata)")
            
            // Update user with new metadata
            let updatedUser = try await client.auth.update(user: UserAttributes(data: updatedMetadata))
            
            // Update currentUser immediately
            self.currentUser = updatedUser
            
            // Explicitly set onboarding flags to false BEFORE refreshing session
            self.showWelcomeSplash = false
            self.showOnboarding = false
            
            // Refresh the session to ensure we have the latest data
            let session = try await client.auth.session
            self.currentUser = session.user
            
            let finalStatus = getOnboardingStatus(from: session.user.userMetadata)
            print("✅ Onboarding marked as completed - final status: \(finalStatus), metadata: \(session.user.userMetadata)")
            print("✅ showWelcomeSplash: \(self.showWelcomeSplash), showOnboarding: \(self.showOnboarding)")
        } catch {
            print("⚠️ Failed to mark onboarding as completed: \(error.localizedDescription)")
            // Still set flags to false to prevent loop
            self.showWelcomeSplash = false
            self.showOnboarding = false
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
