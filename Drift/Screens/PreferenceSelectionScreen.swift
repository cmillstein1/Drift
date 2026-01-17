//
//  PreferenceSelectionScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Supabase
import Auth

struct PreferenceSelectionScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedPreference: PreferenceType? = nil
    @State private var isSaving = false
    
    enum PreferenceType {
        case datingAndFriends
        case friendsOnly
    }
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Title Section
                VStack(spacing: 16) {
                    Text("What are you looking for?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose how you want to connect with others")
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                
                // Preference Options
                VStack(spacing: 20) {
                    // Dating and Friends Option
                    PreferenceCard(
                        title: "Dating & Friends",
                        description: "Explore both romantic connections and friendships. Full access to all features.",
                        icon: "heart.fill",
                        gradient: LinearGradient(
                            colors: [burntOrange, pink500],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isSelected: selectedPreference == .datingAndFriends,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPreference = .datingAndFriends
                            }
                        }
                    )
                    
                    // Friends Only Option
                    PreferenceCard(
                        title: "Friends Only",
                        description: "Focus on building meaningful friendships. Skip dating features for now.",
                        icon: "person.2.fill",
                        gradient: LinearGradient(
                            colors: [skyBlue, forestGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isSelected: selectedPreference == .friendsOnly,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPreference = .friendsOnly
                            }
                        }
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    Task {
                        await handleContinue()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(
                    selectedPreference != nil ?
                    LinearGradient(
                        colors: [burntOrange, pink500],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: selectedPreference != nil ? .black.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
                .disabled(selectedPreference == nil || isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleContinue() async {
        guard let preference = selectedPreference else { return }
        
        isSaving = true
        
        do {
            // Save preference to user metadata
            let isFriendsOnly = preference == .friendsOnly
            
            if let currentUser = supabaseManager.currentUser {
                // Update metadata
                var updatedMetadata = currentUser.userMetadata
                updatedMetadata["friendsOnly"] = AnyJSON.string(isFriendsOnly ? "true" : "false")
                
                let updatedUser = try await supabaseManager.client.auth.update(
                    user: UserAttributes(data: updatedMetadata)
                )
                supabaseManager.currentUser = updatedUser
                
                // If friends only, proceed to friend onboarding
                if isFriendsOnly {
                    supabaseManager.showPreferenceSelection = false
                    supabaseManager.showFriendOnboarding = true
                } else {
                    // If dating and friends, proceed to normal onboarding
                    supabaseManager.showPreferenceSelection = false
                    supabaseManager.showOnboarding = true
                }
            }
        } catch {
            print("❌ Failed to save preference: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
}

struct PreferenceCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradient)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? gradient : LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? gradient : LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PreferenceSelectionScreen()
}
