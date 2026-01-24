//
//  SplashScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/24/26.
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            // Background color matching the app's design (fallback)
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()
            
            // Splash image - fills entire screen
            Image("Drift_Splash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    SplashScreen()
}
