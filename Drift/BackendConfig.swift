//
//  BackendConfig.swift
//  Drift
//
//  This file configures the DriftBackend package with API keys.
//  Third-party API keys (Campflare, RevenueCat, VerifyFaceID) are fetched at
//  runtime from a Supabase Edge Function via AppConfigManager. Unsplash key
//  is provided locally from UnsplashConfig (gitignored) so event/activity
//  headers can populate; remote config can override if set.
//

import Foundation
import DriftBackend

/// Initialize DriftBackend with configuration from config files.
/// Call this in DriftApp.init() before any backend services are accessed.
func initializeDriftBackend() {
    let config = DriftBackendConfig(
        supabaseURL: SupabaseConfig.supabaseURL,
        supabaseAnonKey: SupabaseConfig.anonKey,
        campflareAPIKey: "",
        revenueCatAPIKey: "",
        revenueCatEntitlementID: "Drift Pro",
        revenueCatMonthlyProductID: "monthly",
        revenueCatYearlyProductID: "DriftYearly",
        verifyFaceIDAPIKey: "",
        unsplashAccessKey: ""
    )
    configureDriftBackend(config)
}
