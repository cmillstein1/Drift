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
                description: "Living on the road in a converted van",
                icon: "car.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            TravelStyle(
                id: "digital-nomad",
                title: "Digital Nomad",
                description: "Working remotely from different locations",
                icon: "backpack.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            TravelStyle(
                id: "slow-travel",
                title: "Slow Travel",
                description: "Staying months at a time in each place",
                icon: "house.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [forestGreen, desertSand]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            TravelStyle(
                id: "frequent-traveler",
                title: "Frequent Traveler",
                description: "Always exploring new destinations",
                icon: "airplane",
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
                description: "I travel alone and like meeting people along the way",
                icon: "person.fill"
            ),
            SocialPreference(
                id: "group",
                title: "Group Traveler",
                description: "I prefer traveling with friends or joining groups",
                icon: "person.3.fill"
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

    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your travel style?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(charcoalColor)
                    
                    Text("Help us connect you with your kind of people")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Travel Lifestyle
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TRAVEL LIFESTYLE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(charcoalColor.opacity(0.5))
                                .tracking(1)
                            
                            VStack(spacing: 12) {
                                ForEach(travelStyles) { style in
                                    TravelStyleCard(
                                        style: style,
                                        isSelected: selectedStyle == style.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedStyle = style.id
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Social Preference
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SOCIAL PREFERENCE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(charcoalColor.opacity(0.5))
                                .tracking(1)
                            
                            VStack(spacing: 12) {
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom CTA - Pinned to bottom with solid background
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Button - Make entire area clickable
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
    }
}

struct TravelStyleCard: View {
    let style: TravelStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.white)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: style.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                    
                    Text(style.description)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : charcoalColor.opacity(0.6))
                }
                
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)

                    Circle()
                        .fill(forestGreen)
                        .frame(width: 12, height: 12)
                }
                .opacity(isSelected ? 1 : 0)
            }
            .padding(16)
            .background(
                ZStack {
                    if isSelected {
                        style.gradient
                    } else {
                        Color.white
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 0 : 1
                    )
            )
            .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SocialPreferenceCard: View {
    let preference: SocialPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let skyBlue = Color("SkyBlue")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                gradient: Gradient(colors: [skyBlue, forestGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [softGray, softGray]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: preference.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(preference.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    
                    Text(preference.description)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [skyBlue, forestGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                }
                .opacity(isSelected ? 1 : 0)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? skyBlue : Color.gray.opacity(0.2),
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
