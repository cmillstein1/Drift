//
//  ProfileScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Supabase

struct ProfileScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var isSigningOut = false
    @State private var showEditProfileSheet = false
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1637690244677-320c56d21de2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx2YW4lMjBsaWZlJTIwc3Vuc2V0fGVufDF8fHx8MTc2ODUwNjA1Mnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Color.gray.opacity(0.2)
                                ProgressView()
                            }
                        }
                        .frame(height: 256)
                        .clipped()
                        
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                softGray
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 256)
                        
                        // Settings button - top right
                        Button(action: {
                            // Handle settings
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(charcoalColor)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.9))
                                        .background(.ultraThinMaterial)
                                )
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                        
                        // Edit Profile button - bottom right
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showEditProfileSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 16))
                                            .foregroundColor(charcoalColor)
                                        
                                        Text("Edit Profile")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .overlay(
                                                Capsule()
                                                    .stroke(charcoalColor.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .padding(.bottom, 16)
                                .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text("Alex Turner")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(forestGreen)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                
                                Text("Big Sur, California")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        
                        // Subscription Status
                        SubscriptionStatusView()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        
                        // Preference Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Discovery Mode")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoalColor)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            
                            Toggle(isOn: Binding(
                                get: { supabaseManager.isFriendsOnly() },
                                set: { newValue in
                                    Task {
                                        await updatePreference(friendsOnly: newValue)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(supabaseManager.isFriendsOnly() ? "Friends Only" : "Dating & Friends")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                    
                                    Text(supabaseManager.isFriendsOnly() ? "Only see friends in Discover" : "See both dating and friends in Discover")
                                        .font(.system(size: 13))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        
                        // Manage Subscription Button (for testing)
                        Button(action: {
                            revenueCatManager.showCustomerCenter()
                        }) {
                            HStack {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 16))
                                Text("Manage Subscription")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.4))
                            }
                            .foregroundColor(charcoalColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        
                        HStack(spacing: 12) {
                            StatCard(value: "24", label: "Connections")
                            StatCard(value: "12", label: "Activities")
                            StatCard(value: "8", label: "Places")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            Text("Van-lifer and photographer exploring the West Coast. I love early morning hikes, good coffee, and meeting fellow adventurers on the road.")
                                .font(.system(size: 15))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .lineSpacing(4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Tag(text: "Van Life")
                                    Tag(text: "Photography")
                                    Tag(text: "Surf")
                                    Tag(text: "Early Riser")
                                }
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Travel Pace")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("Slow Traveler")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor)
                                }
                                
                                HStack {
                                    Text("Next Destination")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("Portland, OR")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(burntOrange)
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    await restartOnboarding()
                                }
                            }) {
                                Text("Restart Onboarding")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(charcoalColor.opacity(0.2), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            
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
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .disabled(isSigningOut)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfileSheet) {
            EditProfileSheet(isPresented: $showEditProfileSheet)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
    
    private func restartOnboarding() async {
        do {
            // Clear onboarding completion flag in user metadata
            var updatedMetadata = supabaseManager.currentUser?.userMetadata ?? [:]
            updatedMetadata["onboarding_completed"] = AnyJSON.string("false")
            
            if let currentUser = supabaseManager.currentUser {
                let updatedUser = try await supabaseManager.client.auth.update(user: UserAttributes(data: updatedMetadata))
                supabaseManager.currentUser = updatedUser
                
                // Show preference selection screen so user can choose Dating & Friends or Friends Only again
                supabaseManager.showPreferenceSelection = true
                supabaseManager.showOnboarding = false
                supabaseManager.showFriendOnboarding = false
                supabaseManager.showWelcomeSplash = false
                
                print("✅ Onboarding restarted - user will see preference selection screen")
            }
        } catch {
            print("⚠️ Failed to restart onboarding: \(error.localizedDescription)")
        }
    }
    
    private func updatePreference(friendsOnly: Bool) async {
        do {
            try await supabaseManager.updatePreference(friendsOnly: friendsOnly)
            print("✅ Preference updated - friendsOnly: \(friendsOnly)")
            
            // If switching from Friends Only to Dating & Friends, check if onboarding is needed
            if !friendsOnly {
                let hasCompletedOnboarding = getOnboardingStatus(from: supabaseManager.currentUser?.userMetadata ?? [:])
                if !hasCompletedOnboarding {
                    // User switched to Dating & Friends but hasn't completed onboarding
                    // Trigger onboarding flow
                    supabaseManager.showOnboarding = true
                    supabaseManager.showWelcomeSplash = false
                    supabaseManager.showPreferenceSelection = false
                }
            }
        } catch {
            print("⚠️ Failed to update preference: \(error.localizedDescription)")
        }
    }
    
    // Helper function to parse onboarding status (same as in DriftApp)
    private func getOnboardingStatus(from metadata: [String: Any]) -> Bool {
        guard let value = metadata["onboarding_completed"] else {
            return false
        }
        
        if let boolValue = value as? Bool {
            return boolValue
        } else if let stringValue = value as? String {
            return stringValue.lowercased() == "true" || stringValue == "1"
        } else if let intValue = value as? Int {
            return intValue != 0
        } else if let nsNumber = value as? NSNumber {
            return nsNumber.boolValue
        }
        
        let stringDescription = String(describing: value)
        return stringDescription.lowercased() == "true" || stringDescription == "1"
    }
}

struct StatCard: View {
    let value: String
    let label: String
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(charcoalColor)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
}

struct Tag: View {
    let text: String
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(charcoalColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(desertSand)
            .clipShape(Capsule())
    }
}

#Preview {
    ProfileScreen()
}
