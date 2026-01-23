//
//  DriftApp.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Supabase

@main
struct DriftApp: App {
    @ObservedObject private var supabaseManager: SupabaseManager
    @StateObject private var revenueCatManager: RevenueCatManager
    @StateObject private var profileManager: ProfileManager

    init() {
        // Initialize DriftBackend with API keys FIRST
        initializeDriftBackend()

        // Now safe to access managers
        self._supabaseManager = ObservedObject(wrappedValue: SupabaseManager.shared)
        self._revenueCatManager = StateObject(wrappedValue: RevenueCatManager.shared)
        self._profileManager = StateObject(wrappedValue: ProfileManager.shared)
    }

    /// Check onboarding status - must have both the flag AND actual profile data
    private var hasCompletedOnboarding: Bool {
        // Check if profile exists and has required data filled in
        if let profile = profileManager.currentProfile {
            // Profile must have name filled in to be considered complete
            let hasRequiredData = profile.name != nil && !profile.name!.isEmpty
            let isMarkedComplete = profile.onboardingCompleted ||
                getOnboardingStatus(from: supabaseManager.currentUser?.userMetadata ?? [:])

            // Only consider complete if BOTH conditions are met
            return hasRequiredData && isMarkedComplete
        }

        // If profile not loaded yet, check auth metadata but be conservative
        // Return false to trigger onboarding check
        return false
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if supabaseManager.isAuthenticated {
                    if profileManager.isLoading && profileManager.currentProfile == nil {
                        // Wait for profile to load before deciding
                        ZStack {
                            Color(red: 0.98, green: 0.98, blue: 0.96)
                                .ignoresSafeArea()
                            ProgressView()
                        }
                    } else if hasCompletedOnboarding {
                        // User has completed onboarding - go straight to home (skip WelcomeSplash and onboarding)
                        ContentView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                            .zIndex(1)
                    } else if supabaseManager.isShowingWelcomeSplash {
                        // New user - show welcome splash first (part of onboarding)
                        WelcomeSplash {
                            supabaseManager.isShowingWelcomeSplash = false
                            supabaseManager.isShowingPreferenceSelection = true
                        }
                    } else if supabaseManager.isShowingPreferenceSelection {
                        // Show preference selection screen
                        PreferenceSelectionScreen()
                    } else if supabaseManager.isShowingFriendOnboarding {
                        // Show friend onboarding flow
                        FriendOnboardingFlow {
                            // SafetyScreen will mark onboarding as complete internally
                            supabaseManager.isShowingFriendOnboarding = false
                        }
                    } else if supabaseManager.isShowingOnboarding {
                        // Show onboarding flow
                        OnboardingFlow {
                            // SafetyScreen will mark onboarding as complete
                            // Just need to clear the flag here
                            withAnimation(.easeInOut(duration: 0.6)) {
                                supabaseManager.isShowingOnboarding = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(0)
                    } else if supabaseManager.isShowingPreferenceSelection {
                        // Show preference selection screen
                        PreferenceSelectionScreen()
                    } else {
                        // User is authenticated but hasn't completed onboarding
                        // and no specific flag is set - redirect to preference selection
                        PreferenceSelectionScreen()
                            .onAppear {
                                supabaseManager.isShowingPreferenceSelection = true
                            }
                    }
                } else {
                    // Show welcome screen with invite code input and sign-in options
                    WelcomeScreen()
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.6), value: supabaseManager.isShowingOnboarding)
            .task(id: supabaseManager.isAuthenticated) {
                // Fetch profile when authenticated to check onboarding status
                if supabaseManager.isAuthenticated && profileManager.currentProfile == nil {
                    do {
                        try await profileManager.fetchCurrentProfile()
                    } catch {
                        print("Failed to fetch profile: \(error)")
                    }
                }
            }
            .onChange(of: supabaseManager.isAuthenticated) { _, isAuthenticated in
                // Fetch profile when user logs in
                if isAuthenticated {
                    Task {
                        do {
                            try await profileManager.fetchCurrentProfile()
                        } catch {
                            print("Failed to fetch profile: \(error)")
                        }
                    }
                }
            }
            .onChange(of: supabaseManager.currentUser) { oldValue, newValue in
                if let user = newValue {
                    let metadataComplete = getOnboardingStatus(from: user.userMetadata)
                    if metadataComplete || hasCompletedOnboarding {
                        supabaseManager.isShowingWelcomeSplash = false
                        supabaseManager.isShowingOnboarding = false
                    }
                }
            }
        }
    }
}
