//
//  InterestsScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct Interest: Identifiable {
    var id: String { label }
    let emoji: String
    let label: String
}

struct InterestCategory: Identifiable {
    var id: String { title }
    var title: String
    var interests: [Interest]
    var expanded: Bool
}

struct InterestsScreen: View {
    let onContinue: () -> Void

    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedInterests: Set<String> = []
    @State private var isSaving = false
    @State private var categories: [InterestCategory] = [
        InterestCategory(
            title: "Food & drink",
            interests: [
                Interest(emoji: "🍺", label: "Beer"),
                Interest(emoji: "🧋", label: "Boba tea"),
                Interest(emoji: "☕", label: "Coffee"),
                Interest(emoji: "🍝", label: "Foodie"),
                Interest(emoji: "🍸", label: "Gin"),
                Interest(emoji: "🍕", label: "Pizza"),
                Interest(emoji: "🍣", label: "Sushi"),
                Interest(emoji: "🍭", label: "Sweet tooth"),
                Interest(emoji: "🌮", label: "Tacos"),
                Interest(emoji: "🍵", label: "Tea"),
                Interest(emoji: "🌱", label: "Vegan"),
                Interest(emoji: "🥗", label: "Vegetarian"),
                Interest(emoji: "🥃", label: "Whisky"),
                Interest(emoji: "🍷", label: "Wine")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Traveling",
            interests: [
                Interest(emoji: "🎒", label: "Backpacking"),
                Interest(emoji: "🏖️", label: "Beaches"),
                Interest(emoji: "🏕️", label: "Camping"),
                Interest(emoji: "🏙️", label: "Exploring new cities"),
                Interest(emoji: "🎣", label: "Fishing trips"),
                Interest(emoji: "⛰️", label: "Hiking trips"),
                Interest(emoji: "🚗", label: "Road trips"),
                Interest(emoji: "🧖", label: "Spa weekends"),
                Interest(emoji: "🏡", label: "Staycations"),
                Interest(emoji: "❄️", label: "Winter sports")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Creative",
            interests: [
                Interest(emoji: "🎨", label: "Art"),
                Interest(emoji: "📸", label: "Photography"),
                Interest(emoji: "✍️", label: "Writing"),
                Interest(emoji: "🎭", label: "Theater"),
                Interest(emoji: "🎸", label: "Music"),
                Interest(emoji: "💃", label: "Dancing")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Active",
            interests: [
                Interest(emoji: "🏃", label: "Running"),
                Interest(emoji: "🚴", label: "Cycling"),
                Interest(emoji: "🧘", label: "Yoga"),
                Interest(emoji: "🏋️", label: "Gym"),
                Interest(emoji: "🏊", label: "Swimming"),
                Interest(emoji: "⛷️", label: "Skiing")
            ],
            expanded: true
        )
    ]
    
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    private var canContinue: Bool {
        selectedInterests.count >= 3
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
                    Text("Your interests")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .opacity(titleOpacity)
                        .offset(x: titleOffset)
                    
                    Text("Select at least 3 interests")
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .opacity(subtitleOpacity)
                        .offset(x: subtitleOffset)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(Array(categories.enumerated()), id: \.element.id) { categoryIndex, category in
                            VStack(alignment: .leading, spacing: 12) {
                                // Category Header
                                HStack {
                                    Text(category.title)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            categories[categoryIndex].expanded.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(category.expanded ? "Show less" : "Show more")
                                                .font(.system(size: 14))
                                                .foregroundColor(charcoalColor.opacity(0.6))
                                            
                                            Image(systemName: category.expanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(charcoalColor.opacity(0.6))
                                        }
                                    }
                                }
                                
                                // Interest Pills
                                if category.expanded {
                                    FlowLayout(data: category.interests, spacing: 8) { interest in
                                        InterestPill(
                                            interest: interest,
                                            isSelected: selectedInterests.contains(interest.label),
                                            onTap: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    if selectedInterests.contains(interest.label) {
                                                        selectedInterests.remove(interest.label)
                                                    } else {
                                                        selectedInterests.insert(interest.label)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 24)
                }
                
                VStack(spacing: 12) {
                    Text("\(selectedInterests.count) selected")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))

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
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(interests: Array(selectedInterests))
                )
            } catch {
                print("Failed to save interests: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

struct InterestPill: View {
    let interest: Interest
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            HStack(spacing: 8) {
                Text(interest.emoji)
                    .font(.system(size: 18))
                
                Text(interest.label)
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? burntOrange.opacity(0.05) : Color.white)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    InterestsScreen {
        print("Continue tapped")
    }
}
