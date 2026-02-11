//
//  TravelStyleScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct TravelStyle: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let imageName: String
    let gradient: LinearGradient
}

struct SocialPreference: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

struct TravelStyleScreen: View {
    let onContinue: () -> Void
    
    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedStyle: String? = nil
    @State private var selectedSocial: String? = nil
    @State private var isSaving = false
    @State private var currentStyleIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private var travelStyles: [TravelStyle] {
        [
            TravelStyle(
                id: "van-life",
                title: "Van Life",
                description: "Living on the road, waking up to new views",
                icon: "car.fill",
                imageName: "VanLife",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            TravelStyle(
                id: "digital-nomad",
                title: "Digital Nomad",
                description: "Working remotely from anywhere in the world",
                icon: "backpack.fill",
                imageName: "DigitalNomad",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            TravelStyle(
                id: "slow-travel",
                title: "Slow Travel",
                description: "Taking time to truly experience each place",
                icon: "house.fill",
                imageName: "SlowTraveler",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [forestGreen, desertSand]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            TravelStyle(
                id: "frequent-traveler",
                title: "Frequent Traveler",
                description: "Always chasing the next adventure",
                icon: "airplane",
                imageName: "AdventureSeeker",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [desertSand, burntOrange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        ]
    }
    
    private var socialPreferences: [SocialPreference] {
        [
            SocialPreference(
                id: "solo",
                title: "Solo Explorer",
                description: "Travel alone, meet people along the way",
                icon: "person.fill"
            ),
            SocialPreference(
                id: "group",
                title: "Group Traveler",
                description: "Prefer traveling with friends or groups",
                icon: "person.2.fill"
            )
        ]
    }
    
    private var canContinue: Bool {
        selectedStyle != nil && selectedSocial != nil
    }

    /// Maps travel style id from UI to backend Lifestyle enum.
    private func lifestyle(for styleId: String?) -> Lifestyle? {
        guard let id = styleId else { return nil }
        switch id {
        case "van-life": return .vanLife
        case "digital-nomad": return .digitalNomad
        case "slow-travel", "frequent-traveler": return .traveler
        case "rv-life": return .rvLife
        default: return .traveler
        }
    }

    private func saveAndContinue() {
        guard let styleId = selectedStyle, let _ = selectedSocial else { return }
        guard let lifestyleValue = lifestyle(for: styleId) else { onContinue(); return }
        isSaving = true
        Task {
            do {
                try await profileManager.updateProfile(
                    ProfileUpdateRequest(lifestyle: lifestyleValue)
                )
            } catch {
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }

    private func selectStyleAtIndex(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStyleIndex = index
            selectedStyle = travelStyles[index].id
        }
    }

    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 8) {
                            Text("How do you travel?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(charcoalColor)

                            Text("Swipe to choose your style")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                        // Image Carousel
                        let imageSpacing: CGFloat = 260
                        ZStack {
                            ForEach(Array(travelStyles.enumerated()), id: \.element.id) { index, style in
                                let offset = CGFloat(index - currentStyleIndex) * imageSpacing + dragOffset
                                let isActive = index == currentStyleIndex

                                Image(style.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 240, height: 170)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .opacity(isActive ? 1 : 0.35)
                                    .shadow(color: isActive ? .black.opacity(0.15) : .clear, radius: 12, x: 0, y: 6)
                                    .offset(x: offset)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .clipped()
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let predicted = value.predictedEndTranslation.width
                                    let threshold: CGFloat = imageSpacing / 3
                                    var newIndex = currentStyleIndex
                                    if predicted < -threshold {
                                        newIndex = min(currentStyleIndex + 1, travelStyles.count - 1)
                                    } else if predicted > threshold {
                                        newIndex = max(currentStyleIndex - 1, 0)
                                    }
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        currentStyleIndex = newIndex
                                        selectedStyle = travelStyles[newIndex].id
                                        dragOffset = 0
                                    }
                                }
                        )

                        // Title and description for current style
                        VStack(spacing: 6) {
                            Text(travelStyles[currentStyleIndex].title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(charcoalColor)

                            Text(travelStyles[currentStyleIndex].description)
                                .font(.system(size: 15))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .padding(.top, 12)

                        // Page indicator dots
                        HStack(spacing: 8) {
                            ForEach(0..<travelStyles.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentStyleIndex ? charcoalColor : charcoalColor.opacity(0.25))
                                    .frame(
                                        width: index == currentStyleIndex ? 24 : 8,
                                        height: 8
                                    )
                                    .animation(.spring(response: 0.3), value: currentStyleIndex)
                            }
                        }
                        .padding(.top, 16)

                        // Social Preference Section
                        VStack(spacing: 16) {
                            Text("SOCIAL PREFERENCE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(charcoalColor.opacity(0.5))
                                .tracking(1)
                                .padding(.top, 32)

                            HStack(spacing: 16) {
                                ForEach(socialPreferences) { pref in
                                    SocialPreferenceCard(
                                        preference: pref,
                                        isSelected: selectedSocial == pref.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedSocial = pref.id
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }

            // Bottom CTA
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Button(action: {
                        if canContinue {
                            saveAndContinue()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .frame(height: 56)
                        .background(
                            canContinue ?
                            LinearGradient(
                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: canContinue ? .black.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canContinue || isSaving)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                .background(Color.softGray)
            }
        }
        .onAppear {
            selectedStyle = travelStyles[0].id
        }
    }
}

struct SocialPreferenceCard: View {
    let preference: SocialPreference
    let isSelected: Bool
    let onTap: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("SoftGray"))
                        .frame(width: 56, height: 56)

                    Image(systemName: preference.icon)
                        .font(.system(size: 24))
                        .foregroundColor(
                            preference.id == "solo" ? burntOrange : forestGreen
                        )
                }

                VStack(spacing: 4) {
                    Text(preference.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(charcoalColor)

                    Text(preference.description)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? forestGreen : Color.gray.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TravelStyleScreen {
    }
}
