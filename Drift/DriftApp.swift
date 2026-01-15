//
//  DriftApp.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Auth

@main
struct DriftApp: App {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    // Check if user has completed onboarding - this is the source of truth
                    let hasCompletedOnboarding = supabaseManager.currentUser?.userMetadata["onboarding_completed"] as? Bool ?? false
                    
                    if hasCompletedOnboarding {
                        // User has completed onboarding - go straight to home (skip WelcomeSplash and onboarding)
                        ContentView()
                    } else if supabaseManager.showWelcomeSplash {
                        // New user - show welcome splash first (part of onboarding)
                        WelcomeSplash {
                            print("✅ WelcomeSplash onContinue called - showing onboarding")
                            supabaseManager.showWelcomeSplash = false
                            supabaseManager.showOnboarding = true
                        }
                    } else if supabaseManager.showOnboarding {
                        // Show onboarding flow
                        OnboardingFlow {
                            Task {
                                await supabaseManager.markOnboardingCompleted()
                                supabaseManager.showOnboarding = false
                            }
                        }
                    } else {
                        // If authenticated but onboarding status is unclear, default to showing onboarding
                        // This handles the case where checkAuthStatus hasn't finished yet
                        OnboardingFlow {
                            Task {
                                await supabaseManager.markOnboardingCompleted()
                                supabaseManager.showOnboarding = false
                            }
                        }
                    }
                } else {
                    // Show welcome screen with invite code input and sign-in options
                    WelcomeScreen()
                }
            }
            .onAppear {
                // Log initial state
                let hasCompletedOnboarding = supabaseManager.currentUser?.userMetadata["onboarding_completed"] as? Bool ?? false
                print("📱 DriftApp appeared - isAuthenticated: \(supabaseManager.isAuthenticated), hasCompletedOnboarding: \(hasCompletedOnboarding), showWelcomeSplash: \(supabaseManager.showWelcomeSplash), showOnboarding: \(supabaseManager.showOnboarding)")
            }
            .onChange(of: supabaseManager.currentUser) { oldValue, newValue in
                // When currentUser changes, re-evaluate onboarding status
                if let user = newValue {
                    let hasCompletedOnboarding = user.userMetadata["onboarding_completed"] as? Bool ?? false
                    print("👤 currentUser changed - hasCompletedOnboarding: \(hasCompletedOnboarding)")
                    if hasCompletedOnboarding {
                        supabaseManager.showWelcomeSplash = false
                        supabaseManager.showOnboarding = false
                    } else {
                        supabaseManager.showOnboarding = true
                    }
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
