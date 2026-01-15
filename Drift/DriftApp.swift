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
            if supabaseManager.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
