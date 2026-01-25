//
//  InviteLandingComponents.swift
//  Drift
//
//  Animated mesh background, gradient text, glassmorphic code fields, and Color(hex:) for invite screens.
//

import SwiftUI

// MARK: - Color Extension for Hex (3, 6, 8 digit)
// Non-optional variant for invite UI; project also has optional Color.init?(hex:) elsewhere.

extension Color {
    /// Initialize from hex string. Supports 3 (RGB 12-bit), 6 (RGB 24-bit), and 8 (ARGB 32-bit) digit codes.
    init(hexInvite hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Animated Mesh Gradient Background

struct AnimatedMeshBackground: View {
    private func lerp(_ start: CGFloat, _ end: CGFloat, _ t: CGFloat) -> CGFloat {
        start + (end - start) * t
    }

    var body: some View {
        ZStack {
            Color(hexInvite: "2A2A2A")
                .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let phase = elapsed.truncatingRemainder(dividingBy: 20) / 20

                    let orangeX: CGFloat
                    let orangeY: CGFloat
                    if phase < 0.33 {
                        orangeX = lerp(0.2, 0.8, CGFloat(phase * 3))
                        orangeY = lerp(0.5, 0.3, CGFloat(phase * 3))
                    } else if phase < 0.66 {
                        orangeX = lerp(0.8, 0.4, CGFloat((phase - 0.33) * 3))
                        orangeY = lerp(0.3, 0.8, CGFloat((phase - 0.33) * 3))
                    } else {
                        orangeX = lerp(0.4, 0.2, CGFloat((phase - 0.66) * 3))
                        orangeY = lerp(0.8, 0.5, CGFloat((phase - 0.66) * 3))
                    }

                    let greenX: CGFloat
                    let greenY: CGFloat
                    if phase < 0.33 {
                        greenX = lerp(0.8, 0.2, CGFloat(phase * 3))
                        greenY = lerp(0.8, 0.7, CGFloat(phase * 3))
                    } else if phase < 0.66 {
                        greenX = lerp(0.2, 0.7, CGFloat((phase - 0.33) * 3))
                        greenY = lerp(0.7, 0.2, CGFloat((phase - 0.33) * 3))
                    } else {
                        greenX = lerp(0.7, 0.8, CGFloat((phase - 0.66) * 3))
                        greenY = lerp(0.2, 0.8, CGFloat((phase - 0.66) * 3))
                    }

                    let blueX: CGFloat
                    let blueY: CGFloat
                    if phase < 0.33 {
                        blueX = lerp(0.4, 0.6, CGFloat(phase * 3))
                        blueY = lerp(0.2, 0.5, CGFloat(phase * 3))
                    } else if phase < 0.66 {
                        blueX = lerp(0.6, 0.3, CGFloat((phase - 0.33) * 3))
                        blueY = lerp(0.5, 0.4, CGFloat((phase - 0.33) * 3))
                    } else {
                        blueX = lerp(0.3, 0.4, CGFloat((phase - 0.66) * 3))
                        blueY = lerp(0.4, 0.2, CGFloat((phase - 0.66) * 3))
                    }

                    let orangeGradient = Gradient(colors: [
                        Color(hexInvite: "D97845").opacity(0.15),
                        Color(hexInvite: "D97845").opacity(0.08),
                        Color.clear
                    ])
                    let orangeCenter = CGPoint(x: size.width * orangeX, y: size.height * orangeY)
                    context.translateBy(x: orangeCenter.x, y: orangeCenter.y)
                    context.fill(
                        Circle().path(in: CGRect(x: -250, y: -250, width: 500, height: 500)),
                        with: .radialGradient(
                            orangeGradient,
                            center: .zero,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    context.translateBy(x: -orangeCenter.x, y: -orangeCenter.y)

                    let greenGradient = Gradient(colors: [
                        Color(hexInvite: "547756").opacity(0.15),
                        Color(hexInvite: "547756").opacity(0.08),
                        Color.clear
                    ])
                    let greenCenter = CGPoint(x: size.width * greenX, y: size.height * greenY)
                    context.translateBy(x: greenCenter.x, y: greenCenter.y)
                    context.fill(
                        Circle().path(in: CGRect(x: -250, y: -250, width: 500, height: 500)),
                        with: .radialGradient(
                            greenGradient,
                            center: .zero,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    context.translateBy(x: -greenCenter.x, y: -greenCenter.y)

                    let blueGradient = Gradient(colors: [
                        Color(hexInvite: "A8C5D6").opacity(0.1),
                        Color(hexInvite: "A8C5D6").opacity(0.05),
                        Color.clear
                    ])
                    let blueCenter = CGPoint(x: size.width * blueX, y: size.height * blueY)
                    context.translateBy(x: blueCenter.x, y: blueCenter.y)
                    context.fill(
                        Circle().path(in: CGRect(x: -250, y: -250, width: 500, height: 500)),
                        with: .radialGradient(
                            blueGradient,
                            center: .zero,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    context.translateBy(x: -blueCenter.x, y: -blueCenter.y)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Animated Gradient Text

struct AnimatedGradientText: View {
    let text: String
    var fontSize: CGFloat = 72
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .overlay(
                LinearGradient(
                    colors: [
                        Color(hexInvite: "D97845"),
                        Color(hexInvite: "E07A89"),
                        Color(hexInvite: "D97845")
                    ],
                    startPoint: UnitPoint(x: animationPhase - 0.5, y: 0.5),
                    endPoint: UnitPoint(x: animationPhase + 0.5, y: 0.5)
                )
                .mask(Text(text).font(.system(size: fontSize, weight: .bold)))
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationPhase = 2
                }
            }
    }
}

// MARK: - Glassmorphic Code Input Field (single digit, numeric)

struct InviteCodeDigitField: View {
    @Binding var text: String
    let index: Int
    let isFocused: Bool
    let onDigitChange: (Int, String, String) -> Void
    let focusBinding: FocusState<Int?>.Binding

    var body: some View {
        TextField("", text: $text)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .frame(width: 48, height: 68)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.03))
                    if !text.isEmpty {
                        LinearGradient(
                            colors: [
                                Color(hexInvite: "D97845").opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        text.isEmpty ? Color.white.opacity(0.1) : Color(hexInvite: "D97845"),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: text.isEmpty ? .clear : Color(hexInvite: "D97845").opacity(0.3),
                radius: 15,
                y: 5
            )
            .keyboardType(.numberPad)
            .focused(focusBinding, equals: index)
            .onChange(of: text) { oldValue, newValue in
                onDigitChange(index, oldValue, newValue)
            }
    }
}
