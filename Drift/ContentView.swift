//
//  ContentView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Auth

struct ContentView: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var isSigningOut = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Welcome!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let user = supabaseManager.currentUser {
                Text("Signed in as: \(user.email ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await handleSignOut()
                }
            }) {
                if isSigningOut {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Log Out")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(8)
            .disabled(isSigningOut)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    private func handleSignOut() async {
        isSigningOut = true
        do {
            try await supabaseManager.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
        isSigningOut = false
    }
}

#Preview {
    ContentView()
}
