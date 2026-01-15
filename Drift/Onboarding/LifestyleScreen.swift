//
//  LifestyleScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct LifestyleOption {
    let id: String
    let label: String
    let icon: String
    let description: String
}

struct LifestyleScreen: View {
    let onContinue: () -> Void
    
    @State private var selectedOptions: [String] = []
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var optionsOpacity: [Double] = Array(repeating: 0, count: 4)
    @State private var optionsOffset: [CGFloat] = Array(repeating: 20, count: 4)
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var iconScale: [Double] = Array(repeating: 1.0, count: 4)
    @State private var iconRotation: [Double] = Array(repeating: 0, count: 4)
    
    private let lifestyles: [LifestyleOption] = [
        LifestyleOption(id: "vanlife", label: "Van Life", icon: "car.fill", description: "Living on the road in a van or RV"),
        LifestyleOption(id: "nomad", label: "Digital Nomad", icon: "wifi", description: "Remote work from anywhere"),
        LifestyleOption(id: "backpacker", label: "Backpacker", icon: "bag.fill", description: "Traveling light and free"),
        LifestyleOption(id: "remote", label: "Remote Worker", icon: "laptopcomputer", description: "Working remotely, exploring new places")
    ]
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ProgressIndicator(currentStep: 3, totalSteps: 5)
                    .padding(.top, 32)
                    .padding(.bottom, 48)
                
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Your lifestyle")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)
                        
                        Text("Select all that apply")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.top, 8)
                            .opacity(subtitleOpacity)
                            .offset(x: subtitleOffset)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        ForEach(Array(lifestyles.enumerated()), id: \.element.id) { index, lifestyle in
                            LifestyleOptionCard(
                                lifestyle: lifestyle,
                                isSelected: selectedOptions.contains(lifestyle.id),
                                opacity: optionsOpacity[index],
                                offset: optionsOffset[index],
                                iconScale: iconScale[index],
                                iconRotation: iconRotation[index],
                                onTap: {
                                    toggleOption(lifestyle.id, at: index)
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
                            .background(selectedOptions.isEmpty ? Color.gray.opacity(0.3) : burntOrange)
                            .clipShape(Capsule())
                    }
                    .disabled(selectedOptions.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
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
    
    private func toggleOption(_ id: String, at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedOptions.contains(id) {
                selectedOptions.removeAll { $0 == id }
                iconScale[index] = 1.0
                iconRotation[index] = 0
            } else {
                selectedOptions.append(id)
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    iconScale[index] = 1.1
                    iconRotation[index] = -5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        iconRotation[index] = 5
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        iconScale[index] = 1.0
                        iconRotation[index] = 0
                    }
                }
            }
        }
    }
}

struct LifestyleOptionCard: View {
    let lifestyle: LifestyleOption
    let isSelected: Bool
    let opacity: Double
    let offset: CGFloat
    let iconScale: Double
    let iconRotation: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
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
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? forestGreen : Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: lifestyle.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lifestyle.label)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(charcoalColor)
                    
                    Text(lifestyle.description)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? forestGreen.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSelected ? forestGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
    LifestyleScreen {
        print("Continue tapped")
    }
}
