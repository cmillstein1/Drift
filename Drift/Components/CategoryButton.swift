//
//  CategoryButton.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : charcoalColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? charcoalColor : Color.white)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HStack {
        CategoryButton(
            title: "All",
            isSelected: true,
            onTap: {}
        )
        CategoryButton(
            title: "Outdoor",
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
