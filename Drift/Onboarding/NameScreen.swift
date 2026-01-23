//
//  NameScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct NameScreen: View {
    let onContinue: () -> Void

    @StateObject private var profileManager = ProfileManager.shared
    @State private var name: String = ""
    @State private var isSaving = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var textFieldOpacity: Double = 0
    @State private var textFieldOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @FocusState private var isTextFieldFocused: Bool
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Progress indicator is shown in OnboardingFlow
                    Spacer()
                        .frame(height: 24)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("What's your name?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)
                        
                        Text("This is how others will see you")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.top, 8)
                            .opacity(subtitleOpacity)
                            .offset(x: subtitleOffset)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    TextField("Enter your name", text: $name)
                        .font(.system(size: 17))
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isTextFieldFocused ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        )
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 24)
                        .opacity(textFieldOpacity)
                        .offset(y: textFieldOffset)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    Button(action: {
                        saveAndContinue()
                    }) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : burntOrange)
                    .clipShape(Capsule())
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
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
            
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                textFieldOpacity = 1
                textFieldOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
            
            // Auto-focus text field after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTextFieldFocused = true
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveAndContinue() {
        isSaving = true
        Task {
            do {
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(name: name.trimmingCharacters(in: .whitespaces))
                )
            } catch {
                print("Failed to save name: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

#Preview {
    NameScreen {
        print("Continue tapped")
    }
}
