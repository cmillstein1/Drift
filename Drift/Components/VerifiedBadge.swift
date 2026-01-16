//
//  VerifiedBadge.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct VerifiedBadge: View {
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(forestGreen)
            
            Text("Verified")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.9))
        )
    }
}

#Preview {
    ZStack {
        //Color.gray.opacity(0.2)
        VerifiedBadge()
    }
}
