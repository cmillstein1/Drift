//
//  SafetyScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct SafetyScreen: View {
    let onComplete: () -> Void
    var backgroundColor: Color? = nil

    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var pulsingScale: CGFloat = 1.0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var descriptionOpacity: Double = 0
    @State private var descriptionOffset: CGFloat = 20
    @State private var feature1Opacity: Double = 0
    @State private var feature1Offset: CGFloat = -20
    @State private var feature2Opacity: Double = 0
    @State private var feature2Offset: CGFloat = -20
    @State private var feature3Opacity: Double = 0
    @State private var feature3Offset: CGFloat = -20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var isTransitioning: Bool = false
    @State private var contentScale: CGFloat = 1.0
    @State private var contentOpacity: Double = 1.0
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    
    private var screenBackground: Color {
        backgroundColor ?? warmWhite
    }
    
    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    VStack(spacing: 32) {
                        // Add top padding since we removed the progress indicator
                        Spacer()
                            
                        VStack(spacing: 24) {
                            ZStack {
                                Image("Campfire")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            .opacity(iconOpacity)
                            
                            VStack(spacing: 12) {
                                Text("A safe, trusted community")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .opacity(titleOpacity)
                                    .offset(y: titleOffset)
                                
                                Text("We're building Drift to be a place of authentic connections and mutual respect")
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .opacity(descriptionOpacity)
                                    .offset(y: descriptionOffset)
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                SafetyFeature(
                                    icon: "checkmark.circle.fill",
                                    iconColor: forestGreen,
                                    title: "Profile verification",
                                    description: "Optional identity verification for added trust",
                                    opacity: feature1Opacity,
                                    offset: feature1Offset
                                )
                                
                                SafetyFeature(
                                    icon: "person.2.fill",
                                    iconColor: burntOrange,
                                    title: "Community-first",
                                    description: "Respectful interactions and intentional connections",
                                    opacity: feature2Opacity,
                                    offset: feature2Offset
                                )
                                
                                SafetyFeature(
                                    icon: "checkmark.shield.fill",
                                    iconColor: skyBlue,
                                    title: "Your safety matters",
                                    description: "Report tools and safety features built in",
                                    opacity: feature3Opacity,
                                    offset: feature3Offset
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 18)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        handleStartExploring()
                    }) {
                        Text("Start Exploring")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(burntOrange)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
            .scaleEffect(contentScale)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                iconOpacity = 1
                iconScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 2.0).delay(0.5).repeatForever(autoreverses: true)) {
                pulsingScale = 1.05
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                descriptionOpacity = 1
                descriptionOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                feature1Opacity = 1
                feature1Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                feature2Opacity = 1
                feature2Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                feature3Opacity = 1
                feature3Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }
    
    private func handleStartExploring() {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        // Beautiful exit animation
        withAnimation(.easeInOut(duration: 0.6)) {
            contentScale = 0.95
            contentOpacity = 0.0
        }
        
        Task {
            // Mark onboarding as complete in auth metadata
            await supabaseManager.markOnboardingCompleted()

            // Also update the profile in the database
            do {
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(onboardingCompleted: true)
                )
            } catch {
                print("Failed to update profile: \(error)")
            }

            // Wait for animation to complete
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            
            // Then call onComplete to transition to ContentView
            await MainActor.run {
                onComplete()
            }
        }
    }
}

struct SafetyFeature: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let opacity: Double
    let offset: CGFloat
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .opacity(opacity)
        .offset(x: offset)
    }
}

#Preview {
    SafetyScreen {
        print("Complete tapped")
    }
}
