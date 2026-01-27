//
//  DatingSettingsSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/18/26.
//

import SwiftUI
import DriftBackend

// MARK: - Interested In Options

enum InterestedIn: String, CaseIterable {
    case women
    case men
    case nonBinary = "non-binary"
    case everyone
    
    var displayName: String {
        switch self {
        case .women: return "Women"
        case .men: return "Men"
        case .nonBinary: return "Non-binary"
        case .everyone: return "Everyone"
        }
    }
}

// MARK: - Dating Settings Sheet

struct DatingSettingsSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    
    @State private var interestedIn: InterestedIn = .women
    @State private var distance: Double = 36
    @State private var minAge: Double = 24
    @State private var maxAge: Double = 34
    @State private var showInterestedInModal: Bool = false
    @State private var showVerification: Bool = false
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let softGray = Color("SoftGray")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    
    private var isVerified: Bool {
        profileManager.currentProfile?.verified ?? false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Dating Preferences")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // I'm interested in
                    Button(action: {
                        showInterestedInModal = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("I'm interested in")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                
                                Text(interestedIn.displayName)
                                    .font(.system(size: 13))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.4))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .padding(.top, 8)
                    
                    // Maximum Distance
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Maximum distance")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            Spacer()
                            
                            Text("\(Int(distance)) mi")
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        Slider(value: $distance, in: 1...200, step: 1)
                            .tint(burntOrange)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    
                    // Age Range
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Age range")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            Spacer()
                            
                            Text("\(Int(minAge)) – \(Int(maxAge))")
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        // Age Range Slider (custom dual-thumb)
                        AgeRangeSlider(
                            minValue: $minAge,
                            maxValue: $maxAge,
                            range: 18...80,
                            accentColor: burntOrange,
                            gradientColors: [burntOrange, sunsetRose]
                        )
                        
                        // Age Labels
                        HStack {
                            Text("18")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.4))
                            Spacer()
                            Text("80")
                                .font(.system(size: 12))
                                .foregroundColor(charcoalColor.opacity(0.4))
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    
                    // Safety & Trust Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Safety & Trust")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        
                        // Verification
                        Button(action: {
                            if !isVerified {
                                showVerification = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    if isVerified {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 40, height: 40)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(softGray)
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(isVerified ? .white : charcoalColor.opacity(0.4))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isVerified ? "Verified" : "Verify Your Identity")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                    
                                    Text(isVerified ? "Identity confirmed" : "Build trust with a verification badge")
                                        .font(.system(size: 12))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if !isVerified {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(charcoalColor.opacity(0.4))
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(warmWhite)
            .scrollContentBackground(.hidden)
        }
        .background(warmWhite)
        .onAppear {
            loadPreferences()
        }
        .onDisappear {
            savePreferences()
        }
        .sheet(isPresented: $showInterestedInModal) {
            InterestedInSheet(
                isPresented: $showInterestedInModal,
                selection: $interestedIn
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showVerification) {
            VerificationView()
        }
    }
    
    private func loadPreferences() {
        guard let profile = profileManager.currentProfile else { return }
        if let orientation = profile.orientation {
            interestedIn = InterestedIn(rawValue: orientation) ?? .women
        }
        if let min = profile.preferredMinAge {
            minAge = Double(min)
        }
        if let max = profile.preferredMaxAge {
            maxAge = Double(max)
        }
        if let dist = profile.preferredMaxDistanceMiles {
            distance = Double(dist)
        }
    }

    private func savePreferences() {
        let profile = profileManager.currentProfile
        let currentMin = profile?.preferredMinAge.map(Double.init) ?? 24
        let currentMax = profile?.preferredMaxAge.map(Double.init) ?? 34
        let currentDist = profile?.preferredMaxDistanceMiles.map(Double.init) ?? 36
        let currentOrientation = profile?.orientation
        let orientationChanged = interestedIn.rawValue != (currentOrientation ?? "")
        let prefsChanged = Int(minAge) != Int(currentMin) || Int(maxAge) != Int(currentMax) || Int(distance) != Int(currentDist)
        guard prefsChanged || orientationChanged else { return }
        Task {
            do {
                try await profileManager.updateProfile(ProfileUpdateRequest(
                    orientation: orientationChanged ? interestedIn.rawValue : nil,
                    preferredMinAge: Int(minAge),
                    preferredMaxAge: Int(maxAge),
                    preferredMaxDistanceMiles: Int(distance)
                ))
            } catch {
                print("Failed to save dating preferences: \(error)")
            }
        }
    }
}

// MARK: - Age Range Slider

struct AgeRangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    let accentColor: Color
    let gradientColors: [Color]
    
    @State private var isDraggingMin = false
    @State private var isDraggingMax = false
    
    private let thumbSize: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let minPercent = (minValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            let maxPercent = (maxValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                // Active range track
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(maxPercent - minPercent) * width, height: 4)
                    .offset(x: CGFloat(minPercent) * width)
                
                // Min thumb
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat(minPercent) * width - thumbSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingMin = true
                                let newPercent = max(0, min(value.location.x / width, CGFloat((maxValue - 1 - range.lowerBound) / (range.upperBound - range.lowerBound))))
                                let newValue = range.lowerBound + Double(newPercent) * (range.upperBound - range.lowerBound)
                                minValue = max(range.lowerBound, min(newValue, maxValue - 1))
                            }
                            .onEnded { _ in
                                isDraggingMin = false
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat(maxPercent) * width - thumbSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingMax = true
                                let newPercent = max(CGFloat((minValue + 1 - range.lowerBound) / (range.upperBound - range.lowerBound)), min(value.location.x / width, 1))
                                let newValue = range.lowerBound + Double(newPercent) * (range.upperBound - range.lowerBound)
                                maxValue = max(minValue + 1, min(newValue, range.upperBound))
                            }
                            .onEnded { _ in
                                isDraggingMax = false
                            }
                    )
            }
        }
        .frame(height: thumbSize)
    }
}

// MARK: - Interested In Sheet

struct InterestedInSheet: View {
    @Binding var isPresented: Bool
    @Binding var selection: InterestedIn
    @Environment(\.dismiss) var dismiss
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("I'm interested in")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Options
            VStack(spacing: 12) {
                ForEach(InterestedIn.allCases, id: \.self) { option in
                    Button(action: {
                        selection = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            Spacer()
                            
                            if selection == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(burntOrange)
                            } else {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selection == option ? burntOrange : Color.gray.opacity(0.2), lineWidth: selection == option ? 2 : 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
        }
        .background(warmWhite)
    }
}

#Preview {
    DatingSettingsSheet(isPresented: .constant(true))
}
