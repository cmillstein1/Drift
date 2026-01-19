//
//  Button.Drift.swift
//  Drift
//
//  Button styling for Drift design system
//

import SwiftUI

extension DriftUI {
    /// Button variant options for the Drift design system
    public enum ButtonVariant {
        case primary
        case primaryCompact
        case secondary
        case secondaryCompact
        case gradient
        case gradientCompact
        case outline
        case outlineCompact
        case icon
        case iconCircle
    }

    /// View modifier that applies button styling
    public struct ButtonStyle: SwiftUI.ButtonStyle {
        public let variant: ButtonVariant

        public init(variant: ButtonVariant) {
            self.variant = variant
        }

        public func makeBody(configuration: Configuration) -> some View {
            ButtonContent(
                label: configuration.label,
                variant: variant,
                isPressed: configuration.isPressed
            )
        }
    }

    private struct ButtonContent<Label: View>: View {
        let label: Label
        let variant: ButtonVariant
        let isPressed: Bool

        var body: some View {
            switch variant {
            case .primary:
                label
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DriftUI.burntOrange)
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .primaryCompact:
                label
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(DriftUI.burntOrange)
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .secondary:
                label
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DriftUI.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(DriftUI.charcoal.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .secondaryCompact:
                label
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DriftUI.charcoal)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(DriftUI.charcoal.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .gradient:
                label
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [DriftUI.skyBlue, DriftUI.forestGreen]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .gradientCompact:
                label
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [DriftUI.skyBlue, DriftUI.forestGreen]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .outline:
                label
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DriftUI.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .outlineCompact:
                label
                    .font(.system(size: 14))
                    .foregroundColor(DriftUI.charcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .icon:
                label
                    .font(.system(size: 14))
                    .foregroundColor(DriftUI.charcoal)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)

            case .iconCircle:
                label
                    .font(.system(size: 14))
                    .foregroundColor(DriftUI.charcoal)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)
            }
        }
    }
}

// MARK: - ButtonStyle Extension

extension SwiftUI.ButtonStyle where Self == DriftUI.ButtonStyle {
    public static func drift(_ variant: DriftUI.ButtonVariant) -> DriftUI.ButtonStyle {
        .init(variant: variant)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Primary Button") {}
            .buttonStyle(.drift(.primary))

        Button("Primary Compact") {}
            .buttonStyle(.drift(.primaryCompact))

        Button("Secondary Button") {}
            .buttonStyle(.drift(.secondary))

        Button("Gradient Button") {}
            .buttonStyle(.drift(.gradient))

        Button("Outline Button") {}
            .buttonStyle(.drift(.outline))

        HStack {
            Button {} label: {
                Image(systemName: "heart.fill")
            }
            .buttonStyle(.drift(.icon))

            Button {} label: {
                Image(systemName: "message")
            }
            .buttonStyle(.drift(.iconCircle))
        }
    }
    .padding()
}
