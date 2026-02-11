//
//  PromptAnswerScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/22/26.
//

import SwiftUI

struct PromptAnswerScreen: View {
    let promptAnswer: PromptAnswer
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var answerText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let maxCharacters = 150
    
    private var canSave: Bool {
        !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var characterCount: Int {
        answerText.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.96)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Prompt Title
                        VStack(alignment: .leading, spacing: 16) {
                            Text(promptAnswer.promptText)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(charcoalColor)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                        
                        // Answer Input
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack(alignment: .topLeading) {
                                if answerText.isEmpty {
                                    Text("Type your answer here...")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.4))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: Binding(
                                    get: { answerText },
                                    set: { newValue in
                                        if newValue.count <= maxCharacters {
                                            answerText = newValue
                                        }
                                    }
                                ))
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isTextFieldFocused ? burntOrange : Color.gray.opacity(0.3),
                                            lineWidth: 2
                                        )
                                )
                                .focused($isTextFieldFocused)
                            }
                            
                            HStack {
                                Text("Let your personality shine through!")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                
                                Spacer()
                                
                                Text("\(characterCount)/\(maxCharacters)")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Save Button
                        Button(action: {
                            onSave(answerText.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }) {
                            Text("Save Answer")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(canSave ? burntOrange : Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                        .disabled(!canSave)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(charcoalColor)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Load existing answer if available
            if let existingAnswer = promptAnswer.answer {
                answerText = existingAnswer
            }
            // Focus the text field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PromptAnswerScreen(
        promptAnswer: PromptAnswer(promptText: "The best trip I ever took was...")
    ) { answer in
    }
}
