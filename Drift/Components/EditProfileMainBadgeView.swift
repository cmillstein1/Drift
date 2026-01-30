//
//  EditProfileMainBadgeView.swift
//  Drift
//

import SwiftUI

struct EditProfileMainBadgeView: View {
    var body: some View {
        Text("MAIN")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color("BurntOrange"))
            .clipShape(Capsule())
    }
}
