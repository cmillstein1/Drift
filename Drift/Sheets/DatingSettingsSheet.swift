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
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Dating Preferences")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(softGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // Content
            VStack(alignment: .leading, spacing: 0) {
                // I'm interested in
                Button(action: {
                    showInterestedInModal = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I'm interested in")
                                .font(.system(size: 17))
                                .foregroundColor(charcoalColor)
                            
                            Text(interestedIn.displayName)
                                .font(.system(size: 15))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.4))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Maximum Distance
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Maximum distance")
                            .font(.system(size: 17))
                            .foregroundColor(charcoalColor)
                        
                        Text("\(Int(distance)) mi")
                            .font(.system(size: 15))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Slider(value: $distance, in: 1...200, step: 1)
                        .tint(burntOrange)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // Age Range
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Age range")
                            .font(.system(size: 17))
                            .foregroundColor(charcoalColor)
                        
                        Text("\(interestedIn.displayName) \(Int(minAge))–\(Int(maxAge))")
                            .font(.system(size: 15))
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
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Spacer()
            }
        }
        .background(Color.white)
        .onAppear {
            loadPreferences()
        }
        .sheet(isPresented: $showInterestedInModal) {
            InterestedInSheet(
                isPresented: $showInterestedInModal,
                selection: $interestedIn
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func loadPreferences() {
        // Load from profile if available
        if let orientation = profileManager.currentProfile?.orientation {
            interestedIn = InterestedIn(rawValue: orientation) ?? .women
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
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("I'm interested in")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(softGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // Options
            VStack(spacing: 0) {
                ForEach(InterestedIn.allCases, id: \.self) { option in
                    Button(action: {
                        selection = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.displayName)
                                .font(.system(size: 17))
                                .foregroundColor(charcoalColor)
                            
                            Spacer()
                            
                            if selection == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(burntOrange)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    
                    if option != InterestedIn.allCases.last {
                        Divider()
                            .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Color.white)
    }
}

#Preview {
    DatingSettingsSheet(isPresented: .constant(true))
}
