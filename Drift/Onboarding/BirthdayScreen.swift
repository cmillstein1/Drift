//
//  BirthdayScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct BirthdayScreen: View {
    let onContinue: () -> Void

    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedDate = Date()
    @State private var isSaving = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var pickerOpacity: Double = 0
    @State private var pickerOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    
    private let calendar = Calendar.current
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    private var age: Int {
        calendar.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
    }
    
    private var isDateValid: Bool {
        let minDate = calendar.date(byAdding: .year, value: -100, to: Date()) ?? Date()
        let maxDate = calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        return selectedDate >= minDate && selectedDate <= maxDate
    }
    
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
                        Text("When's your birthday?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)
                        
                        Text("You must be 18 or older")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .padding(.top, 8)
                            .opacity(subtitleOpacity)
                            .offset(x: subtitleOffset)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    DatePicker(
                        "Birthday",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal, 24)
                    .opacity(pickerOpacity)
                    .offset(y: pickerOffset)
                    
                    if !isDateValid && age < 18 {
                        Text("You must be 18 or older to use Drift")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                    }
                    
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
                    .background(isDateValid ? burntOrange : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
                    .disabled(!isDateValid || isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .onAppear {
            // Pre-fill birthday if it exists
            if let existingBirthday = profileManager.currentProfile?.birthday {
                selectedDate = existingBirthday
            } else {
                // Set default date to 25 years ago
                if let defaultDate = calendar.date(byAdding: .year, value: -25, to: Date()) {
                    selectedDate = defaultDate
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
            
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                pickerOpacity = 1
                pickerOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }

    private func saveAndContinue() {
        isSaving = true
        Task {
            do {
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(birthday: selectedDate)
                )
            } catch {
                print("Failed to save birthday: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

#Preview {
    BirthdayScreen {
        print("Continue tapped")
    }
}
