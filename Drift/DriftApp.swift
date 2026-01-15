//
//  DriftApp.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

@main
struct DriftApp: App {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    if supabaseManager.showWelcomeSplash {
                        WelcomeSplash {
                            print("✅ WelcomeSplash onContinue called - setting showWelcomeSplash to false")
                            Task {
                                await supabaseManager.markOnboardingCompleted()
                                supabaseManager.showWelcomeSplash = false
                            }
                        }
                    } else {
                        ContentView()
                    }
                } else {
                    // Show welcome screen with invite code input and sign-in options
                    WelcomeScreen()
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
