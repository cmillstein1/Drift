//
//  EmergencyButton.swift
//  Drift
//
//  Created for emergency services feature
//

import SwiftUI

struct EmergencyButton: View {
    let style: EmergencyButtonStyle
    @State private var showConfirmation = false
    @State private var isPressing = false
    @State private var pressProgress: CGFloat = 0
    @State private var pressTask: Task<Void, Never>?
    
    enum EmergencyButtonStyle {
        case prominent
        case compact
        case floating
        case menuItem
    }
    
    private let charcoalColor = Color("Charcoal")
    private let emergencyRed = Color(red: 0.86, green: 0.08, blue: 0.24) // Apple's emergency red
    private let longPressDuration: TimeInterval = 2.0 // Require 2 second hold
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: style == .compact ? 6 : (style == .menuItem ? 12 : 12)) {
                ZStack {
                    if style == .menuItem {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(emergencyRed.opacity(0.1))
                            .frame(width: 40, height: 40)
                    }
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: style == .compact ? 14 : (style == .menuItem ? 16 : 18), weight: .semibold))
                        .foregroundColor(style == .menuItem ? emergencyRed : .white)
                }
                
                if style != .compact {
                    Text("Emergency Services")
                        .font(.system(size: style == .floating ? 16 : (style == .menuItem ? 16 : 17), weight: .semibold))
                        .foregroundColor(style == .menuItem ? charcoalColor : .white)
                }
                
                if style == .menuItem {
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(emergencyRed.opacity(0.6))
                }
            }
            .foregroundColor(style == .menuItem ? .clear : .white)
            .frame(maxWidth: style == .floating ? .infinity : (style == .menuItem ? .infinity : nil))
            .frame(height: style == .floating ? 48 : (style == .menuItem ? nil : (style == .compact ? 40 : 50)))
            .padding(.horizontal, style == .compact ? 16 : (style == .menuItem ? 0 : 24))
            .padding(.vertical, style == .menuItem ? 0 : nil)
            .background(
                Group {
                    if style == .menuItem {
                        // No background for menu item style
                        EmptyView()
                    } else if style == .floating {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [emergencyRed, emergencyRed.opacity(0.9)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        Capsule()
                            .fill(emergencyRed)
                    }
                }
            )
            .shadow(color: style == .menuItem ? .clear : emergencyRed.opacity(0.4), radius: style == .floating ? 16 : 12, x: 0, y: style == .floating ? 8 : 6)
            .overlay(
                // Progress indicator for long press
                Group {
                    if isPressing {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background progress bar
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.8),
                                                Color.white.opacity(0.6)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * pressProgress)
                                
                                // Animated shimmer effect
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.clear,
                                                Color.white.opacity(0.4),
                                                Color.clear
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * pressProgress)
                                    .blur(radius: 2)
                            }
                        }
                        .clipShape(Capsule())
                        .animation(.linear(duration: 0.1), value: pressProgress)
                    }
                }
            )
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        startLongPress()
                    }
                }
                .onEnded { _ in
                    cancelLongPress()
                }
        )
        .alert("⚠️ Emergency Services", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Call \(EmergencyManager.shared.currentEmergencyNumber)", role: .destructive) {
                EmergencyManager.shared.callEmergency()
            }
        } message: {
            Text("This will immediately call \(EmergencyManager.shared.currentEmergencyNumber).\n\nYour location (GPS coordinates) will be automatically shared with emergency services.\n\nOn iPhone 14 or later with no cellular service, Emergency SOS via Satellite will be used automatically.\n\nOnly use this in a real emergency.")
        }
    }
    
    private func startLongPress() {
        isPressing = true
        pressProgress = 0
        
        let startTime = Date()
        pressTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                if Task.isCancelled { break }
                
                let elapsed = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    pressProgress = min(CGFloat(elapsed / longPressDuration), 1.0)
                }
                
                if elapsed >= longPressDuration {
                    await MainActor.run {
                        isPressing = false
                        pressProgress = 0
                        showConfirmation = true
                    }
                    break
                }
            }
        }
    }
    
    private func cancelLongPress() {
        pressTask?.cancel()
        pressTask = nil
        isPressing = false
        pressProgress = 0
    }
}

struct CompactEmergencyButton: View {
    @State private var showConfirmation = false
    @State private var isPressing = false
    @State private var pressProgress: CGFloat = 0
    @State private var pressTask: Task<Void, Never>?
    
    private let emergencyRed = Color(red: 0.86, green: 0.08, blue: 0.24)
    private let longPressDuration: TimeInterval = 2.0
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Emergency")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(emergencyRed)
            .clipShape(Capsule())
            .shadow(color: emergencyRed.opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay(
                // Progress indicator for long press
                Group {
                    if isPressing {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background progress bar
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.8),
                                                Color.white.opacity(0.6)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * pressProgress)
                                
                                // Animated shimmer effect
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.clear,
                                                Color.white.opacity(0.4),
                                                Color.clear
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * pressProgress)
                                    .blur(radius: 2)
                            }
                        }
                        .clipShape(Capsule())
                        .animation(.linear(duration: 0.1), value: pressProgress)
                    }
                }
            )
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        startLongPress()
                    }
                }
                .onEnded { _ in
                    cancelLongPress()
                }
        )
        .alert("⚠️ Emergency Services", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Call \(EmergencyManager.shared.currentEmergencyNumber)", role: .destructive) {
                EmergencyManager.shared.callEmergency()
            }
        } message: {
            Text("This will immediately call \(EmergencyManager.shared.currentEmergencyNumber).\n\nYour location (GPS coordinates) will be automatically shared with emergency services.\n\nOn iPhone 14 or later with no cellular service, Emergency SOS via Satellite will be used automatically.\n\nOnly use this in a real emergency.")
        }
    }
    
    private func startLongPress() {
        isPressing = true
        pressProgress = 0
        
        let startTime = Date()
        pressTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                if Task.isCancelled { break }
                
                let elapsed = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    pressProgress = min(CGFloat(elapsed / longPressDuration), 1.0)
                }
                
                if elapsed >= longPressDuration {
                    await MainActor.run {
                        isPressing = false
                        pressProgress = 0
                        showConfirmation = true
                    }
                    break
                }
            }
        }
    }
    
    private func cancelLongPress() {
        pressTask?.cancel()
        pressTask = nil
        isPressing = false
        pressProgress = 0
    }
}

#Preview {
    VStack(spacing: 20) {
        EmergencyButton(style: .prominent)
        EmergencyButton(style: .compact)
        EmergencyButton(style: .floating)
            .padding(.horizontal)
        CompactEmergencyButton()
    }
    .padding()
}
