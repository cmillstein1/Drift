//
//  BackendConfig.swift
//  Drift
//
//  This file configures the DriftBackend package with API keys.
//  Supabase, Campflare, and VerifyFaceID configs are in gitignored files.
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
        revenueCatAPIKey: RevenueCatConfig.apiKey,
        revenueCatEntitlementID: RevenueCatConfig.entitlementIdentifier,
        revenueCatMonthlyProductID: RevenueCatConfig.monthlyProductId,
        revenueCatYearlyProductID: RevenueCatConfig.yearlyProductId,
        verifyFaceIDAPIKey: VerifyFaceIDConfig.apiKey,
        unsplashAccessKey: ProcessInfo.processInfo.environment["UNSPLASH_ACCESS_KEY"] ?? "UnsplashConfig.accessKey"
    )
    configureDriftBackend(config)
}

// Note: SupabaseConfig, CampflareConfig, and VerifyFaceIDConfig are defined in gitignored files.
// Unsplash: set UNSPLASH_ACCESS_KEY in your Xcode scheme env, or copy
// UnsplashConfig.example.swift to UnsplashConfig.swift (gitignored) and set accessKey.
