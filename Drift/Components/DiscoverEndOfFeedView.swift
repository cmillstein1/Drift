//
//  DiscoverEndOfFeedView.swift
//  Drift
//
//  End-of-feed message: compass in circle, "You're all caught up!", subtitle.
//

import SwiftUI

struct DiscoverEndOfFeedView: View {
    private let desertSand = Color("DesertSand")
    private let burntOrange = Color("BurntOrange")
    private let charcoal = Color("Charcoal")

    var body: some View {
        VStack(spacing: 24) {
            // Compass icon in sandy circle
            ZStack {
                Circle()
                    .fill(desertSand)
                    .frame(width: 64, height: 64)
                Image(systemName: "safari")
                    .font(.system(size: 32))
                    .foregroundColor(burntOrange)
            }

            VStack(spacing: 8) {
                Text("You're all caught up!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoal)
                    .multilineTextAlignment(.center)

                Text("Check back later for more stories from the road")
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    DiscoverEndOfFeedView()
        .padding()
        .background(Color("SoftGray"))
}
