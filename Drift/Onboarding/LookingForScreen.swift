//
//  LookingForScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct LookingForScreen: View {
    let onContinue: () -> Void
    
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedOptions: [String] = []
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var optionsOpacity: [Double] = Array(repeating: 0, count: 3)
    @State private var optionsOffset: [CGFloat] = Array(repeating: 20, count: 3)
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var checkmarkScale: [Double] = Array(repeating: 0, count: 3)
    @State private var checkmarkRotation: [Double] = Array(repeating: -180, count: 3)
    
    private let options = ["Male", "Female", "Non-binary"]
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    
    // Check if user is in friends-only mode
    private var isFriendsOnly: Bool {
        supabaseManager.isFriendsOnly() || 
        profileManager.currentProfile?.friendsOnly == true || 
        profileManager.currentProfile?.lookingFor == .friends
    }
    
    // Button background based on state
    @ViewBuilder
    private var buttonBackground: some View {
        if selectedOptions.isEmpty {
            Color.gray.opacity(0.3)
        } else if isFriendsOnly {
            LinearGradient(
                gradient: Gradient(colors: [skyBlue, forestGreen]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            burntOrange
        }
    }
    
    var body: some View {
        ZStack {
            // Base background
            warmWhite
                .ignoresSafeArea()
            
            // Overlay gradient when friends-only
            if isFriendsOnly {
                LinearGradient(
                    gradient: Gradient(colors: [skyBlue.opacity(0.05), forestGreen.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Progress indicator is shown in OnboardingFlow
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Looking for")
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
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            LookingForOption(
                                text: option,
                                isSelected: selectedOptions.contains(option),
                                opacity: optionsOpacity[index],
                                offset: optionsOffset[index],
                                checkmarkScale: checkmarkScale[index],
                                checkmarkRotation: checkmarkRotation[index],
                                isFriendsOnly: isFriendsOnly,
                                onTap: {
                                    toggleOption(option, at: index)
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
                            .background(buttonBackground)
                            .clipShape(Capsule())
                    }
                    .disabled(selectedOptions.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .onAppear {
            // Pre-fill lookingFor if it exists and is set to dating/both
            if selectedOptions.isEmpty, let profile = profileManager.currentProfile {
                if profile.lookingFor == .dating || profile.lookingFor == .both {
                    // Map lookingFor to selected options (this is a simplified mapping)
                    // The actual implementation depends on how lookingFor is stored
                    selectedOptions = ["Male", "Female", "Non-binary"] // Default to all
                }
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                subtitleOpacity = 1
                subtitleOffset = 0
            }
            
            for index in 0..<3 {
                withAnimation(.easeOut(duration: 0.4).delay(0.2 + Double(index) * 0.1)) {
                    optionsOpacity[index] = 1
                    optionsOffset[index] = 0
                }
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }
    
    private func toggleOption(_ option: String, at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedOptions.contains(option) {
                selectedOptions.removeAll { $0 == option }
                checkmarkScale[index] = 0
                checkmarkRotation[index] = -180
            } else {
                selectedOptions.append(option)
                checkmarkScale[index] = 1
                checkmarkRotation[index] = 0
            }
        }
    }
}

struct LookingForOption: View {
    let text: String
    let isSelected: Bool
    let opacity: Double
    let offset: CGFloat
    let checkmarkScale: Double
    let checkmarkRotation: Double
    let isFriendsOnly: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    
    private var accentColor: Color {
        isFriendsOnly ? forestGreen : burntOrange
    }
    
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
                    .foregroundColor(accentColor)
                    .scaleEffect(checkmarkScale)
                    .rotationEffect(.degrees(checkmarkRotation))
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
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
    LookingForScreen {
        print("Continue tapped")
    }
}
