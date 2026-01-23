//
//  OrientationScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct OrientationScreen: View {
    let onContinue: () -> Void
    
    @State private var selectedOrientation: String = ""
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var optionsOpacity: [Double] = Array(repeating: 0, count: 4)
    @State private var optionsOffset: [CGFloat] = Array(repeating: 20, count: 4)
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var checkmarkScale: [Double] = Array(repeating: 0, count: 4)
    @State private var checkmarkRotation: [Double] = Array(repeating: -180, count: 4)
    
    private let orientations = ["Male", "Female", "Non-binary", "Prefer not to say"]
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator is shown in OnboardingFlow
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("I am")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)
                        
                        Text("Select one")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.top, 8)
                            .opacity(subtitleOpacity)
                            .offset(x: subtitleOffset)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(orientations.enumerated()), id: \.offset) { index, option in
                            OrientationOption(
                                text: option,
                                isSelected: selectedOrientation == option,
                                opacity: optionsOpacity[index],
                                offset: optionsOffset[index],
                                checkmarkScale: checkmarkScale[index],
                                checkmarkRotation: checkmarkRotation[index],
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedOrientation = option
                                        
                                        for i in 0..<4 {
                                            if i == index {
                                                checkmarkScale[i] = 1
                                                checkmarkRotation[i] = 0
                                            } else {
                                                checkmarkScale[i] = 0
                                                checkmarkRotation[i] = -180
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: {
                        onContinue()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedOrientation.isEmpty ? Color.gray.opacity(0.3) : burntOrange)
                            .clipShape(Capsule())
                    }
                    .disabled(selectedOrientation.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                subtitleOpacity = 1
                subtitleOffset = 0
            }
            
            for index in 0..<4 {
                withAnimation(.easeOut(duration: 0.4).delay(0.2 + Double(index) * 0.1)) {
                    optionsOpacity[index] = 1
                    optionsOffset[index] = 0
                }
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    private let burntOrange = Color("BurntOrange")
    private let charcoalColor = Color("Charcoal")
    
    private var percentage: Int {
        Int((Double(currentStep) / Double(totalSteps)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Step text and percentage
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.7))
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(burntOrange)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Filled portion
                    Capsule()
                        .fill(burntOrange)
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 8)
        }
    }
}

struct OrientationOption: View {
    let text: String
    let isSelected: Bool
    let opacity: Double
    let offset: CGFloat
    let checkmarkScale: Double
    let checkmarkRotation: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            HStack {
                Text(text)
                    .font(.system(size: 17))
                    .foregroundColor(charcoalColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(burntOrange)
                    .scaleEffect(checkmarkScale)
                    .rotationEffect(.degrees(checkmarkRotation))
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? burntOrange.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(opacity)
        .offset(y: offset)
    }
}

#Preview {
    OrientationScreen {
        print("Continue tapped")
    }
}
