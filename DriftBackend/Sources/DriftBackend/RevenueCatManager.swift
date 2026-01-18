import Combine
import Foundation
import SwiftUI

import RevenueCat

/// Available subscription plan types.
public enum SubscriptionPlan: String, CaseIterable, Sendable {
    /// Monthly subscription plan.
    case monthly = "monthly"
    /// Yearly subscription plan.
    case yearly = "yearly"
}

/// Manager for RevenueCat subscription purchases.
///
/// Handles in-app purchases, subscription management, and entitlement verification.
///
/// ## Usage
///
/// ```swift
/// let manager = RevenueCatManager.shared
/// if manager.hasProAccess {
///     // User has pro subscription
/// }
/// ```
@MainActor
public class RevenueCatManager: NSObject, ObservableObject {
    /// Shared singleton instance.
    public static let shared = RevenueCatManager()
    /// Current customer information from RevenueCat.
    @Published public var customerInfo: CustomerInfo?
    /// Available subscription offerings.
    @Published public var offerings: Offerings?
    /// Whether a purchase operation is in progress.
    @Published public var isLoading = false
    /// Error message from the last failed operation.
    @Published public var errorMessage: String?
    /// Whether the user has an active pro subscription.
    @Published public var hasProAccess: Bool = false

    override private init() {
        super.init()
        configureRevenueCat()
    }

    // MARK: - Configuration

    private func configureRevenueCat() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: _BackendConfiguration.shared.revenueCatAPIKey)
        Purchases.shared.delegate = self
        Task {
            await loadCustomerInfo()
            await loadOfferings()
        }
    }

    // MARK: - Customer Info

    /// Loads the current customer information from RevenueCat.
    public func loadCustomerInfo() async {
        isLoading = true
        errorMessage = nil
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.hasProAccess = info.entitlements[_BackendConfiguration.shared.revenueCatEntitlementID]?.isActive == true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Offerings

    /// Loads available subscription offerings.
    public func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Purchases

    /// Purchases a subscription package.
    ///
    /// - Parameter package: The package to purchase.
    /// - Returns: A result containing the updated customer info or an error.
    public func purchase(package: Package) async -> Result<CustomerInfo, Error> {
        isLoading = true
        errorMessage = nil
        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            if userCancelled {
                isLoading = false
                return .failure(
                    NSError(
                        domain: "RevenueCat",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Purchase was cancelled"]
                    )
                )
            }
            self.customerInfo = customerInfo
            self.hasProAccess = customerInfo.entitlements[_BackendConfiguration.shared.revenueCatEntitlementID]?.isActive == true
            isLoading = false
            return .success(customerInfo)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return .failure(error)
        }
    }

    /// Restores previous purchases.
    ///
    /// - Returns: A result containing the updated customer info or an error.
    public func restorePurchases() async -> Result<CustomerInfo, Error> {
        isLoading = true
        errorMessage = nil
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            self.hasProAccess = customerInfo.entitlements[_BackendConfiguration.shared.revenueCatEntitlementID]?.isActive == true
            isLoading = false
            return .success(customerInfo)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return .failure(error)
        }
    }

    // MARK: - Entitlements

    /// Checks if the user has the pro entitlement.
    ///
    /// - Returns: `true` if the user has an active pro subscription.
    public func checkEntitlement() -> Bool {
        guard let customerInfo = customerInfo else {
            return false
        }
        return customerInfo.entitlements[_BackendConfiguration.shared.revenueCatEntitlementID]?.isActive == true
    }

    // MARK: - Customer Center

    /// Shows the subscription management UI.
    public func showCustomerCenter() {
        Purchases.shared.showManageSubscriptions { _ in }
    }

    // MARK: - Package Helpers

    /// Returns the monthly subscription package.
    ///
    /// - Returns: The monthly package if available.
    public func getMonthlyPackage() -> Package? {
        if let package = offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == _BackendConfiguration.shared.revenueCatMonthlyProductID
        }) {
            return package
        }
        return offerings?.current?.availablePackages.first {
            $0.storeProduct.productIdentifier.contains("monthly")
        }
    }

    /// Returns the yearly subscription package.
    ///
    /// - Returns: The yearly package if available.
    public func getYearlyPackage() -> Package? {
        if let package = offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == _BackendConfiguration.shared.revenueCatYearlyProductID
        }) {
            return package
        }
        return offerings?.current?.availablePackages.first {
            $0.storeProduct.productIdentifier.contains("DriftYearly") ||
            $0.storeProduct.productIdentifier.contains("yearly")
        }
    }

    /// Returns the package for a specific subscription plan.
    ///
    /// - Parameter plan: The subscription plan type.
    /// - Returns: The corresponding package if available.
    public func getPackage(for plan: SubscriptionPlan) -> Package? {
        switch plan {
        case .monthly:
            return getMonthlyPackage()
        case .yearly:
            return getYearlyPackage()
        }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.hasProAccess = customerInfo.entitlements[_BackendConfiguration.shared.revenueCatEntitlementID]?.isActive == true
        }
    }
}
