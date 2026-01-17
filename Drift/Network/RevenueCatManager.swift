//
//  RevenueCatManager.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import Foundation
import Combine
import RevenueCat
import SwiftUI

@MainActor
class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var hasProAccess: Bool = false
    
    override private init() {
        super.init()
        configureRevenueCat()
    }
    
    // MARK: - Configuration
    
    private func configureRevenueCat() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        
        // Set up delegate
        Purchases.shared.delegate = self
        
        // Load initial customer info
        Task {
            await loadCustomerInfo()
            await loadOfferings()
        }
    }
    
    // MARK: - Customer Info
    
    func loadCustomerInfo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.hasProAccess = info.entitlements[RevenueCatConfig.entitlementIdentifier]?.isActive == true
            
            print("✅ Customer Info loaded - Has Pro: \(hasProAccess)")
        } catch {
            print("❌ Error loading customer info: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Offerings
    
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            
            print("✅ Offerings loaded: \(offerings.current?.availablePackages.count ?? 0) packages")
        } catch {
            print("❌ Error loading offerings: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Purchases
    
    func purchase(package: Package) async -> Result<CustomerInfo, Error> {
        isLoading = true
        errorMessage = nil
        
        do {
            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            if userCancelled {
                isLoading = false
                return .failure(NSError(domain: "RevenueCat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase was cancelled"]))
            }
            
            self.customerInfo = customerInfo
            self.hasProAccess = customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier]?.isActive == true
            
            print("✅ Purchase successful - Has Pro: \(hasProAccess)")
            isLoading = false
            return .success(customerInfo)
        } catch {
            print("❌ Purchase error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            return .failure(error)
        }
    }
    
    func restorePurchases() async -> Result<CustomerInfo, Error> {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            self.hasProAccess = customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier]?.isActive == true
            
            print("✅ Purchases restored - Has Pro: \(hasProAccess)")
            isLoading = false
            return .success(customerInfo)
        } catch {
            print("❌ Restore error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            return .failure(error)
        }
    }
    
    // MARK: - Entitlement Checking
    
    func checkEntitlement() -> Bool {
        guard let customerInfo = customerInfo else {
            return false
        }
        return customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier]?.isActive == true
    }
    
    // MARK: - Customer Center
    
    func showCustomerCenter() {
        Purchases.shared.showManageSubscriptions { error in
            if let error = error {
                print("❌ Error showing customer center: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Package Helpers
    
    func getMonthlyPackage() -> Package? {
        // Try to find package by identifier first
        if let package = offerings?.current?.availablePackages.first(where: { $0.storeProduct.productIdentifier == RevenueCatConfig.monthlyProductId }) {
            return package
        }
        // Fallback to checking if identifier contains "monthly"
        return offerings?.current?.availablePackages.first { $0.storeProduct.productIdentifier.contains("monthly") }
    }
    
    func getYearlyPackage() -> Package? {
        // Try to find package by identifier first
        if let package = offerings?.current?.availablePackages.first(where: { $0.storeProduct.productIdentifier == RevenueCatConfig.yearlyProductId }) {
            return package
        }
        // Fallback to checking if identifier contains "DriftYearly" or "yearly"
        return offerings?.current?.availablePackages.first { 
            $0.storeProduct.productIdentifier.contains("DriftYearly") || 
            $0.storeProduct.productIdentifier.contains("yearly")
        }
    }
    
    func getPackage(for plan: SubscriptionPlan) -> Package? {
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
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.hasProAccess = customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier]?.isActive == true
            print("🔄 Customer info updated - Has Pro: \(hasProAccess)")
        }
    }
}
