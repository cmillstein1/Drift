//
//  WelcomeSplash.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct WelcomeSplash: View {
    let onContinue: () -> Void
    
    @State private var compassRotation: Double = 0
    @State private var compassScale: CGFloat = 0
    @State private var glowScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    
    // Color definitions matching the design system
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73) // #F5DEBA
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96) // #FCF9F5
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92) // #87CEEB
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20) // #CC6633
    private let charcoal = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    desertSand,
                    warmWhite,
                    skyBlue.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Compass Icon with Animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(burntOrange.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .scaleEffect(glowScale)
                    
                    // Compass Icon
                    Image(systemName: "safari")
                        .font(.system(size: 96, weight: .light))
                        .foregroundColor(burntOrange)
                        .scaleEffect(compassScale)
                        .rotationEffect(.degrees(compassRotation))
                }
                .padding(.bottom, 32)
                
                // Text
                Text("Just a few things about you")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(charcoal)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Animate compass glow
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                glowScale = 1
            }
            
            // Animate compass scale and rotation
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                compassScale = 1
            }
            
            withAnimation(.easeInOut(duration: 2.0)) {
                compassRotation = 360
            }
            
            // Animate text
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                textOpacity = 1
                textOffset = 0
            }
            
            // Auto-advance after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onContinue()
            }
        }
        .task {
            // Mark onboarding as completed when splash is shown
            await markOnboardingCompleted()
        }
    }
    
    private func markOnboardingCompleted() async {
        // This will be called when the splash appears
        // The actual completion will be marked when onContinue is called
        // For now, we'll let the app handle it
    }
}

#Preview {
    WelcomeSplash {
        print("Continue tapped")
    }
}
