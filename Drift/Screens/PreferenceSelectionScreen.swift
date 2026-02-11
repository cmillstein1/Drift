//
//  PreferenceSelectionScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Supabase

struct PreferenceSelectionScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedPreference: PreferenceType? = nil
    @State private var isSaving = false
    @State private var appearAnimation = false

    enum PreferenceType {
        case datingAndFriends
        case friendsOnly
    }

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)

    // Community gradient colors (matches DiscoverModeSwitcher)
    private let communitySkyBlue = Color(red: 0.66, green: 0.77, blue: 0.84)    // #A8C5D6
    private let communityForestGreen = Color(red: 0.33, green: 0.47, blue: 0.34) // #547756

    private var communityGradient: LinearGradient {
        LinearGradient(
            colors: [communitySkyBlue, communityForestGreen],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    softGray,
                    softGray.opacity(0.95),
                    Color.white.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [burntOrange.opacity(0.08), pink500.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [communitySkyBlue.opacity(0.08), communityForestGreen.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 300)
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Title Section
                VStack(spacing: 12) {
                    Text("How do you want to\nconnect?")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                    Text("Choose your adventure on Drift")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 15)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                // Preference Options
                VStack(spacing: 20) {
                    // Dating and Friends Option
                    PreferenceCard(
                        title: "Dating & Friends",
                        description: "Find romance and friendships on the road",
                        icon: "heart.fill",
                        gradient: LinearGradient(
                            colors: [burntOrange, pink500],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isSelected: selectedPreference == .datingAndFriends,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPreference = .datingAndFriends
                            }
                        }
                    )
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 30)

                    // Community Option
                    PreferenceCard(
                        title: "Community",
                        description: "Connect with fellow travelers and build lasting bonds",
                        icon: "person.3.fill",
                        gradient: communityGradient,
                        isSelected: selectedPreference == .friendsOnly,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPreference = .friendsOnly
                            }
                        }
                    )
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 40)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Contextual message based on selection
                if let preference = selectedPreference {
                    Text(preference == .datingAndFriends ?
                         "You can change this anytime in settings" :
                         "Focus on building friendships and community connections")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Continue Button
                Button(action: {
                    Task {
                        await handleContinue()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                }
                .contentShape(Capsule())
                .foregroundColor(.white)
                .background(
                    Group {
                        if selectedPreference != nil {
                            LinearGradient(
                                colors: selectedPreference == .datingAndFriends ?
                                    [burntOrange, pink500] : [communitySkyBlue, communityForestGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.25)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(Capsule())
                .shadow(color: selectedPreference != nil ? .black.opacity(0.15) : .clear, radius: 12, x: 0, y: 6)
                .scaleEffect(selectedPreference != nil ? 1.0 : 0.98)
                .disabled(selectedPreference == nil || isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .opacity(appearAnimation ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }
    
    private func handleContinue() async {
        guard let preference = selectedPreference else { return }

        isSaving = true

        do {
            if let currentUser = supabaseManager.currentUser {
                // Update metadata based on preference
                var updatedMetadata = currentUser.userMetadata

                switch preference {
                case .datingAndFriends:
                    updatedMetadata["friendsOnly"] = AnyJSON.string("false")
                    updatedMetadata["discoveryMode"] = AnyJSON.string("both")
                case .friendsOnly:
                    updatedMetadata["friendsOnly"] = AnyJSON.string("true")
                    updatedMetadata["discoveryMode"] = AnyJSON.string("friends")
                }

                let updatedUser = try await supabaseManager.client.auth.update(
                    user: UserAttributes(data: updatedMetadata)
                )
                supabaseManager.currentUser = updatedUser

                // Navigate based on preference
                switch preference {
                case .friendsOnly:
                    // Friends only - proceed to friend onboarding
                    supabaseManager.isShowingPreferenceSelection = false
                    supabaseManager.isShowingFriendOnboarding = true
                case .datingAndFriends:
                    // Clear any stale onboarding start step to ensure we start from the beginning
                    UserDefaults.standard.removeObject(forKey: "datingOnboardingStartStep")
                    // Dating modes - proceed to normal onboarding
                    supabaseManager.isShowingPreferenceSelection = false
                    supabaseManager.isShowingOnboarding = true
                }
            }
        } catch {
            print("Failed to save preference: \(error.localizedDescription)")
        }

        isSaving = false
    }
}

struct PreferenceCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let isSelected: Bool
    let onTap: () -> Void

    private let charcoalColor = Color("Charcoal")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon with glow effect when selected
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(gradient)
                            .frame(width: 56, height: 56)
                            .blur(radius: 10)
                            .opacity(0.4)
                    }

                    RoundedRectangle(cornerRadius: 14)
                        .fill(gradient)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(isSelected ? 1.05 : 1.0)

                // Text
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.55))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.clear : Color.gray.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(gradient)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? .black.opacity(0.12) : .black.opacity(0.04),
                        radius: isSelected ? 16 : 8,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? gradient : LinearGradient(
                            colors: [Color.clear, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PreferenceSelectionScreen()
}
