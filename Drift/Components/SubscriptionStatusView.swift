//
//  SubscriptionStatusView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import RevenueCat

struct SubscriptionStatusView: View {
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var showPaywall = false
    @State private var showCustomerCenter = false
    @State private var isRestoring = false
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        VStack(spacing: 16) {
            if revenueCatManager.hasProAccess {
                // Active Subscription
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundColor(burntOrange)
                        
                        Text("Drift Pro")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        
                        Spacer()
                        
                        Text("Active")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(forestGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(forestGreen.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    if let customerInfo = revenueCatManager.customerInfo,
                       let entitlement = customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier],
                       let expirationDate = entitlement.expirationDate {
                        Text("Renews \(formatDate(expirationDate))")
                            .font(.system(size: 13))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: {
                        revenueCatManager.showCustomerCenter()
                    }) {
                        Text("Manage Subscription")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(burntOrange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // No Subscription
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Drift Pro")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoalColor)
                            
                            Text("Unlock all premium features")
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24))
                            .foregroundColor(burntOrange)
                    }
                    
                    Button(action: {
                        showPaywall = true
                    }) {
                        Text("View Plans")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [burntOrange, Color(red: 0.93, green: 0.36, blue: 0.51)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        Task {
                            isRestoring = true
                            let result = await revenueCatManager.restorePurchases()
                            isRestoring = false
                            
                            if case .failure(let error) = result {
                                // Show error alert
                                print("❌ Restore failed: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: charcoalColor.opacity(0.6)))
                            } else {
                                Text("Restore Purchases")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .disabled(isRestoring)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallScreen(isOpen: $showPaywall, source: .general)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    SubscriptionStatusView()
        .padding()
        .background(Color("SoftGray"))
}
