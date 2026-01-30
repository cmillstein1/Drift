//
//  StatCard.swift
//  Drift
//

import SwiftUI

struct StatCard: View {
    let value: String
    let label: String

    private let charcoalColor = Color("Charcoal")

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(charcoalColor)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
