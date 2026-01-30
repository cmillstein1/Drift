//
//  ProfilePromptsScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/22/26.
//

import SwiftUI
import DriftBackend

struct PromptAnswer: Identifiable, Equatable {
    let id: UUID
    var promptText: String
    var answer: String?
    
    init(id: UUID = UUID(), promptText: String, answer: String? = nil) {
        self.id = id
        self.promptText = promptText
        self.answer = answer
    }
}

struct ProfilePromptsScreen: View {
    let onContinue: () -> Void
    
    @StateObject private var profileManager = ProfileManager.shared
    @State private var promptAnswers: [PromptAnswer?] = [nil, nil, nil]
    @State private var showPromptSelection: Bool = false
    @State private var selectedPromptIndex: Int = 0
    @State private var showAnswerScreen: Bool = false
    @State private var selectedPromptForAnswer: PromptAnswer?
    @State private var isChangingPrompt: Bool = false
    @State private var isSaving = false
    
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    private var canContinue: Bool {
        promptAnswers.compactMap { $0?.answer }.filter { !$0.isEmpty }.count >= 1
    }
    
    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator is shown in OnboardingFlow
                Spacer()
                    .frame(height: 24)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(charcoalColor.opacity(0.2), lineWidth: 2)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 20))
                                .foregroundColor(charcoalColor.opacity(0.7))
                        }
                        
                        Text("Write your profile answers")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)
                            .offset(x: titleOffset)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            PromptCard(
                                promptAnswer: promptAnswers[index],
                                isSelected: false,
                                onSelect: {
                                    selectedPromptIndex = index
                                    showPromptSelection = true
                                },
                                onEdit: {
                                    if let promptAnswer = promptAnswers[index] {
                                        selectedPromptForAnswer = promptAnswer
                                        selectedPromptIndex = index
                                        showAnswerScreen = true
                                    }
                                },
                                onChangePrompt: {
                                    selectedPromptIndex = index
                                    isChangingPrompt = true
                                    showPromptSelection = true
                                }
                            )
                        }
                        
                        Text("At least 1 answer required")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                VStack(spacing: 12) {
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

                    Button(action: {
                        onContinue()
                    }) {
                        Text("Fill in later")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)
            }
        }
        .sheet(isPresented: $showPromptSelection) {
            PromptSelectionSheet(
                selectedPrompts: Set(promptAnswers.compactMap { $0?.promptText }),
                onSelect: { promptText in
                    if isChangingPrompt {
                        // Changing existing prompt - preserve answer if new prompt is selected
                        if let existing = promptAnswers[selectedPromptIndex] {
                            var updated = existing
                            updated.promptText = promptText
                            promptAnswers[selectedPromptIndex] = updated
                        } else {
                            // Shouldn't happen, but handle it
                            let newPromptAnswer = PromptAnswer(promptText: promptText)
                            promptAnswers[selectedPromptIndex] = newPromptAnswer
                        }
                        isChangingPrompt = false
                        showPromptSelection = false
                    } else {
                        // Creating new prompt answer
                        let newPromptAnswer = PromptAnswer(promptText: promptText)
                        promptAnswers[selectedPromptIndex] = newPromptAnswer
                        showPromptSelection = false
                        // Immediately show answer screen
                        selectedPromptForAnswer = newPromptAnswer
                        showAnswerScreen = true
                    }
                }
            )
        }
        .sheet(isPresented: $showAnswerScreen) {
            if let promptAnswer = selectedPromptForAnswer {
                PromptAnswerScreen(
                    promptAnswer: promptAnswer,
                    onSave: { answer in
                        // Update the answer for the selected prompt index
                        if var existing = promptAnswers[selectedPromptIndex] {
                            existing.answer = answer
                            promptAnswers[selectedPromptIndex] = existing
                        }
                        showAnswerScreen = false
                    }
                )
            }
        }
        .onAppear {
            // Pre-fill prompt answers if they exist
            if promptAnswers.allSatisfy({ $0 == nil }), let existingPrompts = profileManager.currentProfile?.promptAnswers {
                promptAnswers = existingPrompts.prefix(3).map { backendPrompt in
                    PromptAnswer(promptText: backendPrompt.prompt, answer: backendPrompt.answer)
                }
                // Pad to 3 if needed
                while promptAnswers.count < 3 {
                    promptAnswers.append(nil)
                }
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }
    
    private func saveAndContinue() {
        isSaving = true
        Task {
            do {
                // Convert prompt answers to backend format
                let promptAnswersArray = promptAnswers.compactMap { promptAnswer -> DriftBackend.PromptAnswer? in
                    guard let promptAnswer = promptAnswer,
                          let answer = promptAnswer.answer,
                          !answer.isEmpty else {
                        return nil
                    }
                    return DriftBackend.PromptAnswer(prompt: promptAnswer.promptText, answer: answer)
                }
                
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(promptAnswers: promptAnswersArray)
                )
            } catch {
                print("Failed to save prompt answers: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

struct PromptCard: View {
    let promptAnswer: PromptAnswer?
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onChangePrompt: () -> Void
    
    @State private var showMenu = false
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        Button(action: {
            if promptAnswer == nil {
                onSelect()
            } else {
                onEdit()
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let promptAnswer = promptAnswer {
                        Text(promptAnswer.promptText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .multilineTextAlignment(.leading)
                        
                        if let answer = promptAnswer.answer, !answer.isEmpty {
                            Text(answer)
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    } else {
                        Text("Select a prompt")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.7))
                        
                        Text("And write your own answer")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.5))
                            .italic()
                    }
                }
                .padding(.vertical, 14)
                
                Spacer()
                
                if promptAnswer == nil {
                    Button(action: onSelect) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(burntOrange)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Answer", systemImage: "pencil")
                        }
                        Button(action: onChangePrompt) {
                            Label("Change Prompt", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        promptAnswer == nil 
                            ? Color.gray.opacity(0.3) 
                            : burntOrange.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: promptAnswer == nil ? [5, 5] : [])
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    ProfilePromptsScreen {
        print("Continue tapped")
    }
}
