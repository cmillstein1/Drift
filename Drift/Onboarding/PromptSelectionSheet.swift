//
//  PromptSelectionSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/22/26.
//

import SwiftUI

struct PromptSelectionSheet: View {
    let selectedPrompts: Set<String>
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    // Available prompts based on the image
    private let availablePrompts = [
        "The best trip I ever took was...",
        "My perfect van setup includes...",
        "You can find me on weekends...",
        "I'm really good at...",
        "A life goal of mine is...",
        "The way to my heart is...",
        "I geek out on...",
        "My most controversial travel opinion...",
        "My simple pleasure is...",
        "Dating me looks like...",
        "I'm looking for someone who...",
        "My ideal first date is...",
        "I never leave home without...",
        "My biggest travel fear is...",
        "The best part of van life is...",
        "I'm most proud of...",
        "My travel style is...",
        "I'm currently reading/watching...",
        "My favorite road trip snack is...",
        "I'm happiest when..."
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.96)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(availablePrompts, id: \.self) { prompt in
                            PromptOptionButton(
                                prompt: prompt,
                                isSelected: selectedPrompts.contains(prompt),
                                isDisabled: selectedPrompts.contains(prompt),
                                onTap: {
                                    if !selectedPrompts.contains(prompt) {
                                        onSelect(prompt)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Select a prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct PromptOptionButton: View {
    let prompt: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        HStack {
            Text(prompt)
                .font(.system(size: 16))
                .foregroundColor(isDisabled ? charcoalColor.opacity(0.4) : charcoalColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(burntOrange)
            }
        }
        .padding(16)
        .background(isDisabled ? Color.gray.opacity(0.1) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? burntOrange : Color.gray.opacity(0.2),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            if !isDisabled {
                onTap()
            }
        }
    }
}

#Preview {
    PromptSelectionSheet(selectedPrompts: ["The best trip I ever took was..."]) { prompt in
    }
}
