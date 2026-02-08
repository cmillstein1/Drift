//
//  VanProgressView.swift
//  Drift
//

import SwiftUI

struct VanProgressView: View {
    var size: CGFloat = 60

    var body: some View {
        AnimatedGIFView(name: "drift-loading-gif", contentMode: .scaleAspectFit)
            .frame(width: size, height: size)
    }
}

// MARK: - Refresh view adapter for Refresher library

struct VanRefreshView: View {
    @Binding var state: RefresherState

    var body: some View {
        VanProgressView(size: 40)
    }
}

#Preview {
    VanProgressView()
}
