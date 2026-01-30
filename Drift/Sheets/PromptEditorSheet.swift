//
//  PromptEditorSheet.swift
//  Drift
//

import SwiftUI
import DriftBackend

struct PromptEditorSheet: View {
    @Binding var promptAnswer: DriftBackend.PromptAnswer
    @Binding var isPresented: Bool
    var onDidSave: (() -> Void)? = nil

    @State private var selectedPrompt: String = ""
    @State private var answer: String = ""
    @State private var showPromptSelection = false

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    private let maxAnswerLength = 300

    var body: some View {
        NavigationView {
            ZStack {
                softGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Prompt field (no label)
                        Button(action: {
                            showPromptSelection = true
                        }) {
                            HStack {
                                Text(selectedPrompt.isEmpty ? "Select a prompt" : selectedPrompt)
                                    .font(.system(size: 16, weight: selectedPrompt.isEmpty ? .regular : .semibold))
                                    .foregroundColor(selectedPrompt.isEmpty ? charcoalColor.opacity(0.6) : charcoalColor)
                                Spacer()

                                Image(systemName: "pencil")


                            }
                            .padding(20)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Answer field (no label, with character count)
                        VStack(alignment: .trailing, spacing: 8) {
                            TextEditor(text: Binding(
                                get: { answer },
                                set: { newValue in
                                    if newValue.count <= maxAnswerLength {
                                        answer = newValue
                                    }
                                }
                            ))
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(minHeight: 150)
                            .overlay(
                                Group {
                                    if answer.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("Your answer")
                                                    .foregroundColor(charcoalColor.opacity(0.4))
                                                    .padding(.leading, 20)
                                                    .padding(.top, 24)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .allowsHitTesting(false)
                            )

                            Text("\(answer.count)/\(maxAnswerLength)")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.5))
                        }

                        // Tips section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.yellow)
                                Text("Tips for a great answer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                tipRow("Be specific and authentic - share real details about yourself")
                                tipRow("Keep it conversational and approachable")
                                tipRow("Give others something to connect with or ask about")
                            }
                        }
                        .padding(20)
                        .background(warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(charcoalColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        promptAnswer = DriftBackend.PromptAnswer(prompt: selectedPrompt, answer: answer)
                        isPresented = false
                        onDidSave?()
                    }
                    .foregroundColor(burntOrange)
                    .disabled(selectedPrompt.isEmpty || answer.isEmpty)
                }
            }
            .onAppear {
                selectedPrompt = promptAnswer.prompt
                answer = promptAnswer.answer
            }
            .sheet(isPresented: $showPromptSelection) {
                PromptSelectionSheet(
                    selectedPrompts: Set([selectedPrompt].filter { !$0.isEmpty }),
                    onSelect: { promptText in
                        selectedPrompt = promptText
                        showPromptSelection = false
                    }
                )
            }
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.6))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.8))
        }
    }
}
