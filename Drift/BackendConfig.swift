//
//  BackendConfig.swift
//  Drift
//
//  This file configures the DriftBackend package with API keys.
//  Third-party API keys (Campflare, RevenueCat, VerifyFaceID, Unsplash)
//  are fetched at runtime from a Supabase Edge Function via AppConfigManager.
//  Only Supabase URL + anon key are provided locally (gitignored).
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
