//
//  InterestsCard.swift
//  Drift
//
//  Interests display card with emoji prefixes
//

import SwiftUI

struct InterestsCard: View {
    let interests: [String]

    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")

    var body: some View {
        if !interests.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Interests")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(charcoal)

                // Interest tags with emojis
                InterestsWrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(interests, id: \.self) { interest in
                        HStack(spacing: 4) {
                            if let emoji = DriftUI.emoji(for: interest) {
                                Text(emoji)
                                    .font(.system(size: 14))
                            }
                            Text(interest)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoal)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(desertSand)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// WrappingHStack for interests layout
private struct InterestsWrappingHStack: Layout {
    var alignment: HorizontalAlignment = .leading
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }
            currentX += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    VStack {
        InterestsCard(interests: [
            "Camping", "Hiking", "Photography", "Coffee", "Art",
            "Sunrises", "Van Life", "Reading", "Indie Music", "Yoga",
            "Sustainability", "Road Trips"
        ])
    }
    .padding()
    .background(Color("SoftGray"))
}
