//
//  OnboardingBackButton.swift
//  Drift
//
//  Created by Casey Millstein on 1/22/26.
//

import SwiftUI

struct OnboardingBackButton: View {
    let action: () -> Void
    
    @State private var isPressed = false
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoalColor)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.98, blue: 0.96)
            .ignoresSafeArea()
        
        VStack {
            OnboardingBackButton {
            }
            Spacer()
        }
        .padding()
    }
}
