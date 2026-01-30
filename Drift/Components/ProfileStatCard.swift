//
//  ProfileStatCard.swift
//  Drift
//

import SwiftUI

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    private let charcoalColor = Color("Charcoal")

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(charcoalColor)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
