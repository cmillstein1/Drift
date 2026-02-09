import Foundation
import Supabase
import Security

/// Response model for the get-app-config edge function.
private struct AppConfigResponse: Decodable {
    let campflareAPIKey: String
    let revenueCatAPIKey: String
    let verifyFaceIDAPIKey: String
    let unsplashAccessKey: String
}

/// Manager that fetches third-party API keys from a Supabase Edge Function at runtime.
///
/// Keys are cached in the Keychain for offline fallback. The app's splash screen
/// stays visible until `isConfigured` becomes `true`.
@MainActor
public class AppConfigManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = AppConfigManager()

    /// Whether remote keys have been fetched (or restored from cache).
    @Published public var isConfigured = false

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private static let keychainService = "com.drift.appconfig"
    private static let keychainAccount = "remote-keys"

    private init() {}

    // MARK: - Public API

    /// Fetches remote API keys from the `get-app-config` edge function, then
    /// pushes them into `_BackendConfiguration`. Falls back to Keychain cache
    /// on failure.
    public func fetchRemoteConfig() async {
        do {
            struct EmptyBody: Encodable {}

            #if DEBUG
            print("[AppConfigManager] Calling get-app-config edge function...")
            #endif

            let response: AppConfigResponse = try await client.functions.invoke(
                "get-app-config",
                options: FunctionInvokeOptions(body: EmptyBody())
            )

            #if DEBUG
            print("[AppConfigManager] Got response – campflare: \(!response.campflareAPIKey.isEmpty), revenueCat: \(!response.revenueCatAPIKey.isEmpty), verifyFaceID: \(!response.verifyFaceIDAPIKey.isEmpty), unsplash: \(!response.unsplashAccessKey.isEmpty)")
            #endif

            applyConfig(response)
            saveToKeychain(response)
        } catch {
            #if DEBUG
            print("[AppConfigManager] Edge function failed: \(error) – trying Keychain cache")
            #endif
            if let cached = loadFromKeychain() {
                applyConfig(cached)
            } else {
                #if DEBUG
                print("[AppConfigManager] No Keychain cache available – running without remote keys")
                #endif
            }
        }

        isConfigured = true
    }

    // MARK: - Private helpers

    private func applyConfig(_ response: AppConfigResponse) {
        _BackendConfiguration.shared.updateRemoteKeys(
            campflareAPIKey: response.campflareAPIKey,
            revenueCatAPIKey: response.revenueCatAPIKey,
            verifyFaceIDAPIKey: response.verifyFaceIDAPIKey,
            unsplashAccessKey: response.unsplashAccessKey
        )
    }

    // MARK: - Keychain persistence

    private func saveToKeychain(_ response: AppConfigResponse) {
        guard let data = try? JSONEncoder().encode(CodableConfig(from: response)) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadFromKeychain() -> AppConfigResponse? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let cached = try? JSONDecoder().decode(CodableConfig.self, from: data)
        else { return nil }

        return AppConfigResponse(
            campflareAPIKey: cached.campflareAPIKey,
            revenueCatAPIKey: cached.revenueCatAPIKey,
            verifyFaceIDAPIKey: cached.verifyFaceIDAPIKey,
            unsplashAccessKey: cached.unsplashAccessKey
        )
    }
}

/// Codable wrapper for Keychain storage (AppConfigResponse is Decodable-only).
private struct CodableConfig: Codable {
    let campflareAPIKey: String
    let revenueCatAPIKey: String
    let verifyFaceIDAPIKey: String
    let unsplashAccessKey: String

    init(from response: AppConfigResponse) {
        self.campflareAPIKey = response.campflareAPIKey
        self.revenueCatAPIKey = response.revenueCatAPIKey
        self.verifyFaceIDAPIKey = response.verifyFaceIDAPIKey
        self.unsplashAccessKey = response.unsplashAccessKey
    }
}
