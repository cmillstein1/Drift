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
    var emoji: String = ""
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
            title: "Outdoor Adventures",
            emoji: "⛺",
            interests: [
                Interest(emoji: "⛺", label: "Hiking & Nature Walks"),
                Interest(emoji: "⛺", label: "Camping"),
                Interest(emoji: "⛺", label: "Rock Climbing"),
                Interest(emoji: "⛺", label: "Kayaking & Water Sports"),
                Interest(emoji: "⛺", label: "Mountain Biking"),
                Interest(emoji: "⛺", label: "Surfing"),
                Interest(emoji: "⛺", label: "Trail Running"),
                Interest(emoji: "⛺", label: "Wildlife Watching")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Food & Drink",
            emoji: "☕",
            interests: [
                Interest(emoji: "☕", label: "Coffee Shop Hopping"),
                Interest(emoji: "☕", label: "Local Food & Dining"),
                Interest(emoji: "☕", label: "Breweries & Wineries"),
                Interest(emoji: "☕", label: "Cooking Together"),
                Interest(emoji: "☕", label: "Food Trucks & Markets"),
                Interest(emoji: "☕", label: "Picnics"),
                Interest(emoji: "☕", label: "Vegan/Vegetarian Spots"),
                Interest(emoji: "☕", label: "Trying New Cuisines")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Creative & Culture",
            emoji: "🎨",
            interests: [
                Interest(emoji: "🎨", label: "Photography"),
                Interest(emoji: "🎨", label: "Live Music & Concerts"),
                Interest(emoji: "🎨", label: "Art Galleries & Museums"),
                Interest(emoji: "🎨", label: "Street Art Tours"),
                Interest(emoji: "🎨", label: "Writing & Journaling"),
                Interest(emoji: "🎨", label: "Painting & Drawing"),
                Interest(emoji: "🎨", label: "Film & Cinema"),
                Interest(emoji: "🎨", label: "Local Festivals")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Wellness & Mindfulness",
            emoji: "🧘",
            interests: [
                Interest(emoji: "🧘", label: "Yoga"),
                Interest(emoji: "🧘", label: "Meditation"),
                Interest(emoji: "🧘", label: "Beach Walks"),
                Interest(emoji: "🧘", label: "Sunrise/Sunset Watching"),
                Interest(emoji: "🧘", label: "Hot Springs & Spas"),
                Interest(emoji: "🧘", label: "Breathwork"),
                Interest(emoji: "🧘", label: "Sound Baths"),
                Interest(emoji: "🧘", label: "Fitness & Workouts")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Social & Nightlife",
            emoji: "🎉",
            interests: [
                Interest(emoji: "🎉", label: "Trivia Nights"),
                Interest(emoji: "🎉", label: "Board Game Cafes"),
                Interest(emoji: "🎉", label: "Dancing & Clubs"),
                Interest(emoji: "🎉", label: "Karaoke"),
                Interest(emoji: "🎉", label: "Comedy Shows"),
                Interest(emoji: "🎉", label: "Open Mic Nights"),
                Interest(emoji: "🎉", label: "Bar Hopping"),
                Interest(emoji: "🎉", label: "Networking Events")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Learning & Growth",
            emoji: "📚",
            interests: [
                Interest(emoji: "📚", label: "Book Clubs"),
                Interest(emoji: "📚", label: "Language Exchange"),
                Interest(emoji: "📚", label: "Skill Workshops"),
                Interest(emoji: "📚", label: "Podcasting"),
                Interest(emoji: "📚", label: "Philosophy Discussions"),
                Interest(emoji: "📚", label: "Tech Meetups"),
                Interest(emoji: "📚", label: "Sustainability Projects"),
                Interest(emoji: "📚", label: "Volunteering")
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
    private let forestGreen = Color("ForestGreen")
    
    private var canContinue: Bool {
        selectedInterests.count >= 3
    }
    
    var body: some View {
        ZStack {
            Color.softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator is shown in OnboardingFlow
                Spacer()
                    .frame(height: 24)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("What do you love doing?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .opacity(titleOpacity)
                        .offset(x: titleOffset)
                    
                    Text("Select at least 3 activities you enjoy. We'll help you find people who share your interests and discover local events.")
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .padding(.top, 8)
                        .opacity(subtitleOpacity)
                        .offset(x: subtitleOffset)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(Array(categories.enumerated()), id: \.element.id) { categoryIndex, category in
                            VStack(alignment: .leading, spacing: 12) {
                                // Category Header: emoji + title + collapse chevron
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        categories[categoryIndex].expanded.toggle()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text(category.emoji)
                                            .font(.system(size: 18))
                                        Text(category.title)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(charcoalColor)
                                        Spacer()
                                        Image(systemName: category.expanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(charcoalColor.opacity(0.6))
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Interest Pills (flow layout)
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
        }
        .onAppear {
            // Pre-fill interests if they exist
            if selectedInterests.isEmpty, let existingInterests = profileManager.currentProfile?.interests {
                selectedInterests = Set(existingInterests)
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
    private let unselectedBackground = Color(white: 0.96)
    
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
            Text(interest.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : charcoalColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? burntOrange : unselectedBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
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
