//
//  DriftApp.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Auth

// Helper function to parse onboarding status from metadata
private func getOnboardingStatus(from metadata: [String: Any]) -> Bool {
    guard let value = metadata["onboarding_completed"] else {
        return false
    }
    
    // Handle both Bool and String representations
    if let boolValue = value as? Bool {
        return boolValue
    } else if let stringValue = value as? String {
        return stringValue.lowercased() == "true"
    } else if let intValue = value as? Int {
        return intValue != 0
    }
    
    return false
}

@main
struct DriftApp: App {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    
    init() {
        // Initialize RevenueCat early
        _ = RevenueCatManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    // Check if user has completed onboarding - this is the source of truth
                    let hasCompletedOnboarding = getOnboardingStatus(from: supabaseManager.currentUser?.userMetadata ?? [:])
                    let hasPreference = supabaseManager.hasSelectedPreference()
                    
                    if hasCompletedOnboarding {
                        // User has completed onboarding - go straight to home (skip WelcomeSplash and onboarding)
                        ContentView()
                    } else if supabaseManager.showWelcomeSplash {
                        // New user - show welcome splash first (part of onboarding)
                        WelcomeSplash {
                            print("✅ WelcomeSplash onContinue called - showing preference selection")
                            supabaseManager.showWelcomeSplash = false
                            supabaseManager.showPreferenceSelection = true
                        }
                    } else if supabaseManager.showPreferenceSelection {
                        // Show preference selection screen
                        PreferenceSelectionScreen()
                    } else if supabaseManager.showFriendOnboarding {
                        // Show friend onboarding flow
                        FriendOnboardingFlow {
                            // SafetyScreen will mark onboarding as complete internally
                            supabaseManager.showFriendOnboarding = false
                        }
                    } else if supabaseManager.showOnboarding {
                        // Show onboarding flow
                        OnboardingFlow {
                            // SafetyScreen will mark onboarding as complete
                            // Just need to clear the flag here
                            supabaseManager.showOnboarding = false
                        }
                    } else {
                        // If authenticated but onboarding status is unclear, check auth status again
                        ContentView()
                            .task {
                                await supabaseManager.checkAuthStatus()
                            }
                    }
                } else {
                    // Show welcome screen with invite code input and sign-in options
                    WelcomeScreen()
                }
            }
            .onAppear {
                // Log initial state
                let hasCompletedOnboarding = getOnboardingStatus(from: supabaseManager.currentUser?.userMetadata ?? [:])
                print("📱 DriftApp appeared - isAuthenticated: \(supabaseManager.isAuthenticated), hasCompletedOnboarding: \(hasCompletedOnboarding), showWelcomeSplash: \(supabaseManager.showWelcomeSplash), showOnboarding: \(supabaseManager.showOnboarding)")
            }
            .onChange(of: supabaseManager.currentUser) { oldValue, newValue in
                // When currentUser changes, re-evaluate onboarding status
                // Only update if we're not already in the correct state
                if let user = newValue {
                    let hasCompletedOnboarding = getOnboardingStatus(from: user.userMetadata)
                    print("👤 currentUser changed - hasCompletedOnboarding: \(hasCompletedOnboarding), current showOnboarding: \(supabaseManager.showOnboarding)")
                    
                    // Only update state if it needs to change AND we're not currently in onboarding flow
                    if hasCompletedOnboarding {
                        // If onboarding is complete, always clear flags (prevents loop)
                        supabaseManager.showWelcomeSplash = false
                        supabaseManager.showOnboarding = false
                        print("✅ Updated state: cleared onboarding flags (onboarding complete)")
                    }
                    // Don't set showOnboarding to true here - let checkAuthStatus handle it
                    // This prevents the onChange from triggering a loop
                }
            }
            .onChange(of: supabaseManager.isAuthenticated) { oldValue, newValue in
                print("🔐 Auth state changed: \(oldValue) -> \(newValue), showWelcomeSplash: \(supabaseManager.showWelcomeSplash)")
                if newValue && supabaseManager.showWelcomeSplash {
                    print("✅ User authenticated AND showWelcomeSplash is TRUE - should show WelcomeSplash")
                } else if newValue && !supabaseManager.showWelcomeSplash {
                    print("⚠️ User authenticated BUT showWelcomeSplash is FALSE - will show ContentView")
                }
            }
            .onChange(of: supabaseManager.showWelcomeSplash) { oldValue, newValue in
                print("🎉 Welcome splash state changed: \(oldValue) -> \(newValue), isAuthenticated: \(supabaseManager.isAuthenticated)")
            }
        }
    }
}
