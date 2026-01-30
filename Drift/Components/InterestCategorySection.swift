//
//  InterestCategorySection.swift
//  Drift
//

import SwiftUI

struct InterestCategorySection: View {
    @Binding var category: InterestCategory
    @Binding var selectedInterests: Set<String>

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    category.expanded.toggle()
                }
            }) {
                HStack {
                    Text(category.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(charcoalColor)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.4))
                        .rotationEffect(.degrees(category.expanded ? 180 : 0))
                }
            }

            if category.expanded {
                FlowLayout(data: category.interests, spacing: 8) { interest in
                    InterestCategorySectionPill(
                        interest: interest,
                        isSelected: selectedInterests.contains(interest.label),
                        onTap: {
                            if selectedInterests.contains(interest.label) {
                                selectedInterests.remove(interest.label)
                            } else {
                                selectedInterests.insert(interest.label)
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

private struct InterestCategorySectionPill: View {
    let interest: Interest
    let isSelected: Bool
    let onTap: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let desertSand = Color("DesertSand")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(interest.emoji)
                    .font(.system(size: 14))
                Text(interest.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : charcoalColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? burntOrange : desertSand)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
