//
//  Text.Drift.swift
//  Drift
//
//  Text styling for Drift design system
//

import SwiftUI

extension DriftUI {
    /// Text variant options for the Drift design system
    public enum TextVariant {
        case largeTitle
        case title
        case title2
        case headline
        case body
        case subheadline
        case footnote
        case caption
        case secondary
        case secondaryCaption
        case accent
        case accentCaption
    }

    /// View modifier that applies text styling
    public struct TextStyle: ViewModifier {
        public let variant: TextVariant

        public init(variant: TextVariant) {
            self.variant = variant
        }

        public func body(content: Content) -> some View {
            switch variant {
            case .largeTitle:
                content
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(DriftUI.charcoal)

            case .title:
                content
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(DriftUI.charcoal)

            case .title2:
                content
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DriftUI.charcoal)

            case .headline:
                content
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(DriftUI.charcoal)

            case .body:
                content
                    .font(.system(size: 15))
                    .foregroundColor(DriftUI.charcoal)

            case .subheadline:
                content
                    .font(.system(size: 14))
                    .foregroundColor(DriftUI.charcoal)

            case .footnote:
                content
                    .font(.system(size: 13))
                    .foregroundColor(DriftUI.charcoal)

            case .caption:
                content
                    .font(.system(size: 12))
                    .foregroundColor(DriftUI.charcoal)

            case .secondary:
                content
                    .font(.system(size: 14))
                    .foregroundColor(DriftUI.charcoal.opacity(0.6))

            case .secondaryCaption:
                content
                    .font(.system(size: 12))
                    .foregroundColor(DriftUI.charcoal.opacity(0.6))

            case .accent:
                content
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DriftUI.burntOrange)

            case .accentCaption:
                content
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DriftUI.burntOrange)
            }
        }
    }
}

// MARK: - View Extensions

extension Text {
    @MainActor public func textStyle(_ variant: DriftUI.TextVariant) -> some View {
        self.modifier(DriftUI.TextStyle(variant: variant))
    }
}

extension View {
    public func textStyle(_ variant: DriftUI.TextVariant) -> some View {
        self.modifier(DriftUI.TextStyle(variant: variant))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("Large Title").textStyle(.largeTitle)
        Text("Title").textStyle(.title)
        Text("Title 2").textStyle(.title2)
        Text("Headline").textStyle(.headline)
        Text("Body").textStyle(.body)
        Text("Subheadline").textStyle(.subheadline)
        Text("Footnote").textStyle(.footnote)
        Text("Caption").textStyle(.caption)
        Text("Secondary").textStyle(.secondary)
        Text("Secondary Caption").textStyle(.secondaryCaption)
        Text("Accent").textStyle(.accent)
        Text("Accent Caption").textStyle(.accentCaption)
    }
    .padding()
}
