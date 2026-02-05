//
//  DiscoverModeSwitcher.swift
//  Drift
//

import SwiftUI

struct DiscoverModeSwitcher: View {
    @Binding var mode: DiscoverMode
    var style: DiscoverScreen.ModeSwitcherStyle
    @Namespace private var animation

    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)

    private let friendsGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.66, green: 0.77, blue: 0.84),  // #A8C5D6 Sky Blue
            Color(red: 0.33, green: 0.47, blue: 0.34)   // #547756 Forest Green
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        HStack(spacing: 4) {
            // Friends first (primary: travel community) for App Store positioning
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    mode = .friends
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 13))
                    Text("Community")
                        .font(.system(size: 13, weight: mode == .friends ? .semibold : .medium))
                }
                .foregroundColor(friendsTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if mode == .friends {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(friendsGradient)
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                            .matchedGeometryEffect(id: "discoverSegmentBg", in: animation)
                    }
                }
            }
            .buttonStyle(.plain)

            // Dating second
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    mode = .dating
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                    Text("Dating")
                        .font(.system(size: 13, weight: mode == .dating ? .semibold : .medium))
                }
                .foregroundColor(datingTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if mode == .dating {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [burntOrange, pink500],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                            .matchedGeometryEffect(id: "discoverSegmentBg", in: animation)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(5)
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(containerOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    // MARK: - Style-dependent colors

    private var datingTextColor: Color {
        switch style {
        case .dark:
            return mode == .dating ? .white : .white.opacity(0.9)
        case .light:
            return mode == .dating ? .white : .gray.opacity(0.6)
        }
    }

    private var friendsTextColor: Color {
        switch style {
        case .dark:
            return mode == .friends ? .white : .white.opacity(0.9)
        case .light:
            return mode == .friends ? .white : .gray.opacity(0.6)
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        switch style {
        case .dark:
            ZStack {
                Color.black.opacity(0.2)
                Rectangle().fill(.ultraThinMaterial.opacity(0.5))
            }
        case .light:
            Color.white
        }
    }

    @ViewBuilder
    private var containerOverlay: some View {
        switch style {
        case .dark:
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        case .light:
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .dark:
            return .black.opacity(0.2)
        case .light:
            return .black.opacity(0.05)
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .dark: return 8
        case .light: return 4
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .dark: return 4
        case .light: return 2
        }
    }
}
