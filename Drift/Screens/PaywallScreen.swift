//
//  PaywallScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import RevenueCat

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

enum PaywallSource {
    case swipeLimit
    case createActivity
    case expertHelp
    case likesYou
    case general
}

struct PaywallScreen: View {
    @Binding var isOpen: Bool
    var source: PaywallSource = .general
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        if isOpen {
            GeometryReader { geometry in
                let heroHeight = geometry.size.height * 0.55
                let cardOverlap: CGFloat = 24
                
                ZStack(alignment: .top) {
                    // Hero
                    VStack(spacing: 0) {
                        ZStack(alignment: .bottom) {
                            Image("Discover_Temp-2")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: heroHeight)
                                .clipped()
                            
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Built for Life in Motion")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Unlock features designed for people who live on the move helping you connect, explore, and navigate wherever you are.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.95))
                                    .lineLimit(3)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 44)
                        }
                        .frame(height: heroHeight)
                        .overlay(alignment: .topTrailing) {
                            Button(action: { withAnimation { isOpen = false } }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                            .padding(.top, geometry.safeAreaInsets.top + 12)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    
                    // White card overlapping hero, rounded top corners
                    VStack(spacing: 0) {
                        // Feature list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Drift Pro includes")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(charcoalColor.opacity(0.5))
                                .textCase(.uppercase)
                                .padding(.horizontal, 4)

                            FeatureChip(title: "Unlimited Likes", color: forestGreen)
                            FeatureChip(title: "Create Private Events", color: forestGreen)
                            FeatureChip(title: "See Who Likes You", color: forestGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                        VStack(spacing: 10) {
                            PlanCard(
                                title: "Annual Plan",
                                subtitle: annualSubtitle,
                                price: yearlyPriceString,
                                originalPrice: yearlyOriginalPriceString,
                                isSelected: selectedPlan == .yearly,
                                badge: "MOST POPULAR",
                                badgeColor: burntOrange
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedPlan = .yearly
                                }
                            }
                            PlanCard(
                                title: "Monthly Plan",
                                subtitle: monthlySubtitle,
                                price: monthlyPriceString,
                                originalPrice: nil,
                                isSelected: selectedPlan == .monthly,
                                badge: nil,
                                badgeColor: .clear
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedPlan = .monthly
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        Text("Your next adventure starts here.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.bottom, 8)
                        
                        Button(action: {
                            Task { await handlePurchase() }
                        }) {
                            HStack(spacing: 8) {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                }
                                Text(isPurchasing ? "Processing..." : "Get Drift Pro")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(forestGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isPurchasing || revenueCatManager.isLoading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                        
                        if let error = purchaseError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 4)
                        }
                        
                        Spacer(minLength: 0)
                        
                        Text("Cancel anytime.")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.5))
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .padding(.top, heroHeight - cardOverlap)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
            .onAppear {
                Task { await revenueCatManager.loadOfferings() }
            }
        }
    }
    
    private var annualSubtitle: String {
        guard let pkg = revenueCatManager.getYearlyPackage() else { return "$5.83/month • Save 42%" }
        let product = pkg.storeProduct
        let perMonth = NSDecimalNumber(decimal: product.price).doubleValue / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.priceFormatter?.currencyCode ?? "USD"
        let perMonthStr = formatter.string(from: NSNumber(value: perMonth)) ?? "$5.83"
        return "\(perMonthStr)/month • Save 42%"
    }
    
    private var monthlySubtitle: String? {
        nil
    }
    
    private var yearlyPriceString: String {
        revenueCatManager.getYearlyPackage()?.storeProduct.localizedPriceString ?? "$69.99"
    }
    
    private var yearlyOriginalPriceString: String? {
        guard let pkg = revenueCatManager.getYearlyPackage() else { return "$119.88" }
        let product = pkg.storeProduct
        let yearly = NSDecimalNumber(decimal: product.price).doubleValue
        let monthly: Double = {
            guard let p = revenueCatManager.getMonthlyPackage()?.storeProduct else { return 9.99 }
            return NSDecimalNumber(decimal: p.price).doubleValue
        }()
        let fullYear = monthly * 12
        guard fullYear > yearly else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.priceFormatter?.currencyCode ?? "USD"
        return formatter.string(from: NSNumber(value: fullYear)) ?? "$119.88"
    }
    
    private var monthlyPriceString: String {
        revenueCatManager.getMonthlyPackage()?.storeProduct.localizedPriceString ?? "$9.99"
    }
    
    private func handlePurchase() async {
        isPurchasing = true
        purchaseError = nil
        guard let package = revenueCatManager.getPackage(for: selectedPlan) else {
            purchaseError = "Product not available. Please try again later."
            isPurchasing = false
            return
        }
        let result = await revenueCatManager.purchase(package: package)
        switch result {
        case .success:
            withAnimation { isOpen = false }
        case .failure(let error):
            if !error.localizedDescription.contains("cancelled") {
                purchaseError = error.localizedDescription
            }
        }
        isPurchasing = false
    }
}

// MARK: - Feature chip (2x2 grid, larger text)

private struct FeatureChip: View {
    let title: String
    let color: Color
    private let softGray = Color("SoftGray")
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("Charcoal"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(softGray.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Plan card (same size for Annual and Monthly, larger text)

private struct PlanCard: View {
    let title: String
    let subtitle: String?
    let price: String
    let originalPrice: String?
    let isSelected: Bool
    let badge: String?
    let badgeColor: Color
    let action: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    
    private let cardHeight: CGFloat = 92
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? forestGreen : charcoalColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(forestGreen)
                            .frame(width: 14, height: 14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let badge = badge, !badge.isEmpty {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(badgeColor)
                            .clipShape(Capsule())
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    if let sub = subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 13))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoalColor)
                    if let orig = originalPrice {
                        Text(orig)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.5))
                            .strikethrough(true)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(softGray.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? forestGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showPaywall = true
        var body: some View {
            ZStack {
                Color.gray.opacity(0.3)
                PaywallScreen(isOpen: $showPaywall, source: .general)
            }
        }
    }
    return PreviewWrapper()
}
