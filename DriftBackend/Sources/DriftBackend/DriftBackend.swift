import Foundation

/// Configuration for all DriftBackend services.
///
/// Provide API keys and configuration values for Supabase, Campflare,
/// and RevenueCat integrations.
///
/// ## Usage
///
/// ```swift
/// let config = DriftBackendConfig(
///     supabaseURL: "https://your-project.supabase.co",
///     supabaseAnonKey: "your-anon-key",
///     campflareAPIKey: "your-campflare-key",
///     revenueCatAPIKey: "your-revenuecat-key"
/// )
/// configureDriftBackend(config)
/// ```
public struct DriftBackendConfig {
    /// Supabase project URL.
    public let supabaseURL: String
    /// Supabase anonymous API key.
    public let supabaseAnonKey: String
    /// Campflare API key for campground data.
    public let campflareAPIKey: String
    /// RevenueCat API key for subscriptions.
    public let revenueCatAPIKey: String
    /// RevenueCat entitlement identifier for pro access.
    public let revenueCatEntitlementID: String
    /// RevenueCat monthly subscription product identifier.
    public let revenueCatMonthlyProductID: String
    /// RevenueCat yearly subscription product identifier.
    public let revenueCatYearlyProductID: String
    /// VerifyFaceID API key for face verification.
    public let verifyFaceIDAPIKey: String

    /// Creates a new backend configuration.
    ///
    /// - Parameters:
    ///   - supabaseURL: Supabase project URL.
    ///   - supabaseAnonKey: Supabase anonymous API key.
    ///   - campflareAPIKey: Campflare API key.
    ///   - revenueCatAPIKey: RevenueCat API key.
    ///   - revenueCatEntitlementID: Entitlement ID for pro access.
    ///   - revenueCatMonthlyProductID: Monthly product identifier.
    ///   - revenueCatYearlyProductID: Yearly product identifier.
    ///   - verifyFaceIDAPIKey: VerifyFaceID API key for face verification.
    public init(
        supabaseURL: String,
        supabaseAnonKey: String,
        campflareAPIKey: String,
        revenueCatAPIKey: String,
        revenueCatEntitlementID: String = "Drift Pro",
        revenueCatMonthlyProductID: String = "monthly",
        revenueCatYearlyProductID: String = "DriftYearly",
        verifyFaceIDAPIKey: String = ""
    ) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
        self.campflareAPIKey = campflareAPIKey
        self.revenueCatAPIKey = revenueCatAPIKey
        self.revenueCatEntitlementID = revenueCatEntitlementID
        self.revenueCatMonthlyProductID = revenueCatMonthlyProductID
        self.revenueCatYearlyProductID = revenueCatYearlyProductID
        self.verifyFaceIDAPIKey = verifyFaceIDAPIKey
    }
}

/// Initializes the DriftBackend with the provided configuration.
///
/// Call this early in your app lifecycle, typically in `App.init()`,
/// before using any backend managers.
///
/// - Parameter config: The backend configuration containing API keys.
public func configureDriftBackend(_ config: DriftBackendConfig) {
    _BackendConfiguration.shared.configure(with: config)
}

/// Internal configuration storage for backend services.
internal class _BackendConfiguration {
    static let shared = _BackendConfiguration()
    private(set) var config: DriftBackendConfig?

    private init() {}

    func configure(with config: DriftBackendConfig) {
        self.config = config
    }

    var supabaseURL: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.supabaseURL
    }

    var supabaseAnonKey: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.supabaseAnonKey
    }

    var campflareAPIKey: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.campflareAPIKey
    }

    var revenueCatAPIKey: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.revenueCatAPIKey
    }

    var revenueCatEntitlementID: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.revenueCatEntitlementID
    }

    var revenueCatMonthlyProductID: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.revenueCatMonthlyProductID
    }

    var revenueCatYearlyProductID: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.revenueCatYearlyProductID
    }
    
    var verifyFaceIDAPIKey: String {
        guard let config = config else {
            fatalError("DriftBackend not configured. Call configureDriftBackend() first.")
        }
        return config.verifyFaceIDAPIKey
    }
}
