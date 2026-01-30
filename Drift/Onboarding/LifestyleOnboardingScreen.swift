//
//  LifestyleOnboardingScreen.swift
//  Drift
//
//  Onboarding screen for lifestyle preferences (WorkStyle, HomeBase, MorningPerson)
//

import SwiftUI
import DriftBackend

struct LifestyleOnboardingScreen: View {
    let onContinue: () -> Void
    var backgroundColor: Color = Color(red: 0.98, green: 0.98, blue: 0.96)

    @StateObject private var profileManager = ProfileManager.shared
    @State private var workStyle: WorkStyle?
    @State private var homeBase: String = ""
    @State private var morningPerson: Bool?
    @State private var isSaving = false

    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20

    @FocusState private var isHomeBaseFocused: Bool

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color("ForestGreen")
    private let desertSand = Color("DesertSand")

    private var hasAnySelection: Bool {
        workStyle != nil || !homeBase.isEmpty || morningPerson != nil
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 24)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Your lifestyle")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .opacity(titleOpacity)
                        .offset(x: titleOffset)

                    Text("Help us find people who match your vibe.")
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .padding(.top, 8)
                        .opacity(subtitleOpacity)
                        .offset(x: subtitleOffset)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 24) {
                        // Work Style Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How do you work?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoalColor)

                            VStack(spacing: 8) {
                                ForEach(WorkStyle.allCases, id: \.self) { style in
                                    WorkStyleOption(
                                        style: style,
                                        isSelected: workStyle == style,
                                        onSelect: { workStyle = style }
                                    )
                                }
                            }
                        }

                        // Home Base Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Where's home base?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoalColor)

                            HStack(spacing: 12) {
                                Image(systemName: "house")
                                    .font(.system(size: 20))
                                    .foregroundColor(charcoalColor.opacity(0.4))

                                TextField("City or region", text: $homeBase)
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor)
                                    .focused($isHomeBaseFocused)
                                    .textInputAutocapitalization(.words)

                                if !homeBase.isEmpty {
                                    Button {
                                        homeBase = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(charcoalColor.opacity(0.3))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isHomeBaseFocused ? burntOrange : Color.gray.opacity(0.2), lineWidth: 2)
                            )

                            Text("The place you return to between adventures")
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.5))
                        }

                        // Morning Person Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Are you a morning person?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoalColor)

                            HStack(spacing: 12) {
                                MorningPersonButton(
                                    title: "Early Bird",
                                    emoji: "🌅",
                                    isSelected: morningPerson == true,
                                    onSelect: { morningPerson = true }
                                )

                                MorningPersonButton(
                                    title: "Night Owl",
                                    emoji: "🌙",
                                    isSelected: morningPerson == false,
                                    onSelect: { morningPerson = false }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()

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
                            Text(hasAnySelection ? "Continue" : "Skip for now")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(hasAnySelection ? burntOrange : charcoalColor.opacity(0.3))
                    .clipShape(Capsule())
                    .disabled(isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isHomeBaseFocused = false
        }
        .onAppear {
            loadExistingData()
            animateIn()
        }
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5)) {
            titleOpacity = 1
            titleOffset = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            subtitleOpacity = 1
            subtitleOffset = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            contentOpacity = 1
            contentOffset = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            buttonOpacity = 1
            buttonOffset = 0
        }
    }

    private func loadExistingData() {
        if let profile = profileManager.currentProfile {
            workStyle = profile.workStyle
            homeBase = profile.homeBase ?? ""
            morningPerson = profile.morningPerson
        }
    }

    private func saveAndContinue() {
        guard hasAnySelection else {
            onContinue()
            return
        }

        isSaving = true
        Task {
            do {
                try await profileManager.updateProfile(ProfileUpdateRequest(
                    workStyle: workStyle,
                    homeBase: homeBase.isEmpty ? nil : homeBase,
                    morningPerson: morningPerson
                ))
            } catch {
                print("Failed to save lifestyle: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

// MARK: - Work Style Option

private struct WorkStyleOption: View {
    let style: WorkStyle
    let isSelected: Bool
    let onSelect: () -> Void

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)

    private var emoji: String {
        switch style {
        case .remote: return "💻"
        case .hybrid: return "🏢"
        case .locationBased: return "📍"
        case .retired: return "🌴"
        }
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 24))

                Text(style.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : charcoal)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(isSelected ? burntOrange : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? burntOrange : Color.gray.opacity(0.15), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Morning Person Button

private struct MorningPersonButton: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let onSelect: () -> Void

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 36))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .white : charcoal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? burntOrange : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? burntOrange : Color.gray.opacity(0.15), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

#Preview {
    LifestyleOnboardingScreen {
        print("Continue tapped")
    }
}
