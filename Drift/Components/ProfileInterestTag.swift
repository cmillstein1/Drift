//
//  ProfileInterestTag.swift
//  Drift
//

import SwiftUI

struct ProfileInterestTag: View {
    let interest: String

    private let desertSand = Color("DesertSand")
    private let charcoalColor = Color("Charcoal")

    var body: some View {
        HStack(spacing: 6) {
            if let emoji = DriftUI.emoji(for: interest) {
                Text(emoji)
                    .font(.system(size: 14))
            }
            Text(interest)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(desertSand)
        .clipShape(Capsule())
    }
}
