//
//  Tag.Drift.swift
//  Drift
//
//  Interest tag styling for Drift design system
//

import SwiftUI

extension DriftUI {
    /// Tag variant options for the Drift design system
    public enum TagVariant {
        case `default`
        case highlighted
        case extra
    }

    /// View modifier that applies tag styling
    public struct TagStyle: ViewModifier {
        public let variant: TagVariant

        public init(variant: TagVariant) {
            self.variant = variant
        }

        public func body(content: Content) -> some View {
            content
                .font(.system(size: 12))
                .foregroundColor(DriftUI.charcoal)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                        .overlay(
                            Capsule()
                                .stroke(strokeColor, lineWidth: strokeWidth)
                        )
                )
        }

        private var backgroundColor: Color {
            switch variant {
            case .default:
                return .white
            case .highlighted:
                return DriftUI.burntOrange.opacity(0.05)
            case .extra:
                return .white
            }
        }

        private var strokeColor: Color {
            switch variant {
            case .default:
                return Color.gray.opacity(0.3)
            case .highlighted:
                return DriftUI.burntOrange
            case .extra:
                return Color.gray.opacity(0.3)
            }
        }

        private var strokeWidth: CGFloat {
            switch variant {
            case .highlighted:
                return 1.5
            default:
                return 1
            }
        }
    }
}

// MARK: - View Extension

extension View {
    public func tagStyle(_ variant: DriftUI.TagVariant) -> some View {
        self.modifier(DriftUI.TagStyle(variant: variant))
    }
}

// MARK: - Interest Tag View

/// A reusable interest tag component
struct InterestTag: View {
    let label: String
    let emoji: String?
    let variant: DriftUI.TagVariant

    /// Initialize with explicit emoji
    init(_ label: String, emoji: String?, variant: DriftUI.TagVariant = .default) {
        self.label = label
        self.emoji = emoji
        self.variant = variant
    }

    /// Initialize with automatic emoji lookup
    init(_ label: String, variant: DriftUI.TagVariant = .default) {
        self.label = label
        self.emoji = DriftUI.emoji(for: label)
        self.variant = variant
    }

    var body: some View {
        HStack(spacing: 4) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 12))
            }
            Text(label)
        }
        .tagStyle(variant)
    }
}

#Preview {
    VStack(spacing: 12) {
        InterestTag("Coffee", emoji: "☕", variant: .default)
        InterestTag("Photography", emoji: "📸", variant: .highlighted)
        InterestTag("+3 more", variant: .extra)
    }
    .padding()
}
