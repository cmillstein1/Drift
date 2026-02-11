//
//  FriendWelcomeScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct FriendWelcomeScreen: View {
    let onContinue: () -> Void
    
    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = -180
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var descriptionOpacity: Double = 0
    @State private var descriptionOffset: CGFloat = 20
    @State private var feature1Opacity: Double = 0
    @State private var feature1Offset: CGFloat = 20
    @State private var feature2Opacity: Double = 0
    @State private var feature2Offset: CGFloat = 20
    @State private var feature3Opacity: Double = 0
    @State private var feature3Offset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    
    private let softGray = Color("SoftGray")
    private let desertSand = Color("DesertSand")
    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [desertSand, softGray]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Hero Section
                VStack(spacing: 32) {
                    // Icon with animation
                    ZStack {
                        // Pulsing glow
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .opacity(0.3)
                            .blur(radius: 20)
                            .scaleEffect(iconScale)
                        
                        // Main icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [forestGreen, skyBlue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                    }
                    
                    // Title
                    VStack(spacing: 12) {
                        Text("Find Your Crew")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(y: titleOffset)
                        
                        Text("Connect with fellow travelers, join local adventures, and build a community wherever you roam")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .opacity(descriptionOpacity)
                            .offset(y: descriptionOffset)
                    }
                    
                    // Feature Pills
                    VStack(spacing: 12) {
                        FeaturePill(
                            icon: "person.3.fill",
                            text: "Meet like-minded nomads",
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            opacity: feature1Opacity,
                            offset: feature1Offset
                        )
                        
                        FeaturePill(
                            icon: "calendar",
                            text: "Join local activities & events",
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [skyBlue, burntOrange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            opacity: feature2Opacity,
                            offset: feature2Offset
                        )
                        
                        FeaturePill(
                            icon: "location.north.circle.fill",
                            text: "Discover new adventures",
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [burntOrange, forestGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            opacity: feature3Opacity,
                            offset: feature3Offset
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // CTA Button
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)
            }
        }
        .onAppear {
            // Animate icon
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                iconScale = 1
                iconRotation = 0
            }
            
            // Animate title
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            // Animate description
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                descriptionOpacity = 1
                descriptionOffset = 0
            }
            
            // Animate features
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                feature1Opacity = 1
                feature1Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                feature2Opacity = 1
                feature2Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                feature3Opacity = 1
                feature3Offset = 0
            }
            
            // Animate button
            withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }
}

struct FeaturePill: View {
    let icon: String
    let text: String
    let gradient: LinearGradient
    let opacity: Double
    let offset: CGFloat
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
                .background(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .opacity(opacity)
        .offset(y: offset)
    }
}

#Preview {
    FriendWelcomeScreen {
    }
}
