//
//  PaywallScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

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
    case general
}

enum SubscriptionPlan: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
}

struct PaywallScreen: View {
    @Binding var isOpen: Bool
    var source: PaywallSource = .general
    @State private var selectedPlan: SubscriptionPlan = .yearly
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51) // Approximate sunset rose
    
    var body: some View {
        if isOpen {
            ZStack {
                // Backdrop
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isOpen = false
                        }
                    }
                
                // Modal Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Close Button
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isOpen = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                    .frame(width: 40, height: 40)
                                    .background(softGray)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                        
                        ScrollView {
                            VStack(spacing: 24) {
                                // Hero Section
                                VStack(spacing: 8) {
                                    Text("Go Further Together")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(charcoalColor)
                                    
                                    Text("Everything you need to meet intention people, build real connections, and share the journey - wherever the road takes you")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 8)
                                
                                // Features Grid
                                VStack(spacing: 12) {
                                    FeatureRow(
                                        icon: "heart.fill",
                                        title: "Unlimited Swiping",
                                        description: "Connect with as many travelers as you want, no daily limits",
                                        gradient: LinearGradient(
                                            colors: [burntOrange, sunsetRose],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    
                                    FeatureRow(
                                        icon: "calendar",
                                        title: "Create Activities",
                                        description: "Host meetups, group adventures, and local events in any location",
                                        gradient: LinearGradient(
                                            colors: [skyBlue, forestGreen],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    
                                    FeatureRow(
                                        icon: "sparkles",
                                        title: "Expert Building Help",
                                        description: "Get personalized advice from van conversion and nomad lifestyle experts",
                                        gradient: LinearGradient(
                                            colors: [forestGreen, burntOrange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    
                                    FeatureRow(
                                        icon: "person.2.fill",
                                        title: "See Who Liked You",
                                        description: "Know who's interested before you swipe and skip the guesswork",
                                        gradient: LinearGradient(
                                            colors: [sunsetRose, burntOrange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                }
                                .padding(.horizontal, 24)
                                
                                // Pricing Toggle
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(softGray)
                                            .frame(height: 50)
                                        
                                        // Sliding Background
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white)
                                            .frame(width: (geometry.size.width - 8) / 2, height: 42)
                                            .offset(x: selectedPlan == .monthly ? 4 : (geometry.size.width - 8) / 2 + 4)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPlan)
                                        
                                        HStack(spacing: 0) {
                                            // Monthly Button
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedPlan = .monthly
                                                }
                                            }) {
                                                VStack(spacing: 2) {
                                                    Text("Monthly")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(selectedPlan == .monthly ? charcoalColor : charcoalColor.opacity(0.6))
                                                    
                                                    Text("$14.99/mo")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(selectedPlan == .monthly ? burntOrange : charcoalColor.opacity(0.4))
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 42)
                                            }
                                            
                                            // Yearly Button
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedPlan = .yearly
                                                }
                                            }) {
                                                VStack(spacing: 2) {
                                                    HStack(spacing: 4) {
                                                        Text("Yearly")
                                                            .font(.system(size: 14, weight: .medium))
                                                            .foregroundColor(selectedPlan == .yearly ? charcoalColor : charcoalColor.opacity(0.6))
                                                        
                                                        Text("SAVE 40%")
                                                            .font(.system(size: 9, weight: .semibold))
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(
                                                                LinearGradient(
                                                                    colors: [burntOrange, sunsetRose],
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                            .clipShape(Capsule())
                                                    }
                                                    
                                                    Text("$8.99/mo")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(selectedPlan == .yearly ? burntOrange : charcoalColor.opacity(0.4))
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 42)
                                            }
                                        }
                                        .padding(4)
                                    }
                                }
                                .frame(height: 50)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 100) // Space for fixed CTA
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(32, corners: [.topLeft, .topRight])
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
                    
                    // Fixed Bottom CTA
                    VStack(spacing: 8) {
                        Button(action: {
                            // Handle subscription
                            print("Start Free 7-Day Trial")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18))
                                
                                Text("Start Free 7-Day Trial")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [burntOrange, sunsetRose],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        
                        Text("Cancel anytime. No commitment required.")
                            .font(.system(size: 10))
                            .foregroundColor(charcoalColor.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.1)),
                        alignment: .top
                    )
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1000)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    
    private let charcoalColor = Color("Charcoal")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoalColor)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(14)
        .background(softGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
