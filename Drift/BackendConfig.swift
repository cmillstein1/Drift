//
//  BackendConfig.swift
//  Drift
//
//  This file configures the DriftBackend package with API keys.
//  Supabase and Campflare configs are in gitignored files.
//

import Foundation
import DriftBackend

/// Initialize DriftBackend with configuration from config files
/// Call this in DriftApp.init() before any backend services are accessed
func initializeDriftBackend() {
    let config = DriftBackendConfig(
        supabaseURL: SupabaseConfig.supabaseURL,
        supabaseAnonKey: SupabaseConfig.anonKey,
        campflareAPIKey: CampflareConfig.apiKey,
        revenueCatAPIKey: "test_YJMEfoMqdCFelANmBrkdyUoUDsI",
        revenueCatEntitlementID: "Drift Pro",
        revenueCatMonthlyProductID: "monthly",
        revenueCatYearlyProductID: "DriftYearly",
        verifyFaceIDAPIKey: VerifyFaceIDConfig.apiKey
    )
    configureDriftBackend(config)
}

// Note: SupabaseConfig and CampflareConfig are defined in gitignored files:
// - Drift/Network/SupabaseConfig.swift (gitignored)
// - Drift/Network/CampflareConfig.swift (gitignored)
//
// These files should have the following structure:
//
// struct SupabaseConfig {
//     static let supabaseURL = "https://your-project.supabase.co"
//     static let anonKey = "your-anon-key"
// }
//
// struct CampflareConfig {
//     static let apiKey = "your-api-key"
// }
//
// struct VerifyFaceIDConfig {
//     static let apiKey = "your-api-key"
// }