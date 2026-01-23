//
//  AboutMeScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct AboutMeScreen: View {
    let onContinue: () -> Void
    
    @StateObject private var profileManager = ProfileManager.shared
    @State private var aboutText: String = ""
    @State private var isSaving = false
    
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let lightBeige = Color(red: 0.96, green: 0.95, blue: 0.93)
    
    private let minCharacters = 50
    private let maxCharacters = 500
    
    private var canContinue: Bool {
        aboutText.count >= minCharacters
    }
    
    private var charactersNeeded: Int {
        max(0, minCharacters - aboutText.count)
    }
    
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
                        Text("About me")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)
                        
                        Text("Share a bit about yourself, your van life journey, and what makes you unique.")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                            .opacity(subtitleOpacity)
                            .offset(x: subtitleOffset)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        // Text Editor
                        ZStack(alignment: .topLeading) {
                            if aboutText.isEmpty {
                                Text("Tell people about yourself... What's your van life story? What are you passionate about? What are you looking for in a connection?")
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor.opacity(0.4))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: Binding(
                                get: { aboutText },
                                set: { newValue in
                                    if newValue.count <= maxCharacters {
                                        aboutText = newValue
                                    }
                                }
                            ))
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor)
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Character Count
                        HStack {
                            if charactersNeeded > 0 {
                                Text("At least \(charactersNeeded) more characters needed")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            } else {
                                Spacer()
                            }
                            
                            Text("\(aboutText.count)/\(maxCharacters)")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .padding(.horizontal, 24)
                        
                        // Pro Tips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor.opacity(0.7))
                                
                                Text("Pro tips:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                    Text("Be authentic and specific")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                    Text("Share what makes you unique")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                    Text("Mention what you're looking for")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(lightBeige)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            VStack {
                Spacer()
                
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
                .background(canContinue ? burntOrange : Color.gray.opacity(0.3))
                .clipShape(Capsule())
                .disabled(!canContinue || isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Pre-fill bio if it exists
            if aboutText.isEmpty, let existingBio = profileManager.currentProfile?.bio {
                aboutText = existingBio
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                subtitleOpacity = 1
                subtitleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                buttonOpacity = 1
                buttonOffset = 0
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
                    ProfileUpdateRequest(bio: aboutText)
                )
            } catch {
                print("Failed to save about me: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

#Preview {
    AboutMeScreen {
        print("Continue tapped")
    }
}
