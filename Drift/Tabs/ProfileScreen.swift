//
//  ProfileScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Supabase

struct ProfileScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var isSigningOut = false
    @State private var showEditProfileSheet = false
    @State private var showDiscoveryModeSheet = false
    @State private var showSettingsSheet = false
    @State private var navigateToFriendsGrid = false
    @State private var showPaywall = false

    private var profile: UserProfile? {
        profileManager.currentProfile
    }

    private var discoveryModeDescription: String {
        switch supabaseManager.getDiscoveryMode() {
        case .friends:
            return "Only Friends shown in Discover"
        case .dating, .both:
            return "Dating & Friends shown in Discover"
        }
    }

    private let softGray = Color("SoftGray")
    private let desertSand = Color("DesertSand")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        NavigationStack {
            ZStack {
                softGray.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Image
                    headerImageSection
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Name & Location
                        nameAndLocationSection
                        
                        // About Section
                        aboutSection
                        
                        // Discovery Mode
                        discoveryModeButton
                        
                        // My Friends Button
                        myFriendsButton
                        
                        // Settings Menu
                        settingsMenuSection
                        
                        // Emergency Services (outside settings section)
                        emergencyServicesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
                }
            }
            .sheet(isPresented: $showEditProfileSheet) {
                EditProfileSheetWrapper(isPresented: $showEditProfileSheet)
            }
            .sheet(isPresented: $showDiscoveryModeSheet) {
                DiscoveryModeSheet(
                    isPresented: $showDiscoveryModeSheet,
                    onSelectDatingAndFriends: {
                        Task {
                            await updateDiscoveryMode(.both)
                        }
                    },
                    onSelectFriendsOnly: {
                        Task {
                            await updateDiscoveryMode(.friends)
                        }
                    },
                    hasCompletedDatingOnboarding: profileManager.hasCompletedDatingOnboarding()
                )
                .presentationDetents([.height(480)])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "friendsGrid" {
                    FriendsGridScreen()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallScreen(isOpen: $showPaywall, source: .general)
            }
            .onAppear {
                Task {
                    do {
                        try await profileManager.fetchCurrentProfile()
                    } catch {
                        print("Failed to fetch profile: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Header Image Section
    
    private var headerImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Hero Image
            AsyncImage(url: URL(string: profile?.photos.first ?? profile?.avatarUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange.opacity(0.4), sunsetRose.opacity(0.4)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.4))
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange.opacity(0.4), sunsetRose.opacity(0.4)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.4))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 256)
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Edit Profile Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showEditProfileSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                            Text("Edit Profile")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(height: 256)
    }
    
    // MARK: - Name & Location Section
    
    private var nameAndLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and verification
            HStack(spacing: 8) {
                Text(profile?.displayName ?? "Your Name")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                if profile?.verified == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(forestGreen)
                }
            }
            
            // Location
            if let location = profile?.location, !location.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.system(size: 14))
                    Text(location)
                        .font(.system(size: 15))
                }
                .foregroundColor(charcoalColor.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(charcoalColor)
            
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundColor(charcoalColor.opacity(0.7))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Add a bio to tell others about yourself")
                    .font(.system(size: 15))
                    .foregroundColor(charcoalColor.opacity(0.4))
                    .italic()
            }
            
            // Interest Tags
            if let interests = profile?.interests, !interests.isEmpty {
                FlowLayout(data: interests.map { InterestItem($0) }, spacing: 8) { item in
                    ProfileInterestTag(interest: item.name)
                }
                .padding(.top, 8)
            }
            
            // Travel Info
            if profile?.travelPace != nil || profile?.nextDestination != nil {
                Divider()
                    .background(Color.gray.opacity(0.1))
                    .padding(.top, 4)
                
                VStack(spacing: 12) {
                    if let travelPace = profile?.travelPace {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                Text("Travel Pace")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text(travelPace.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(charcoalColor)
                        }
                    }
                    
                    if let nextDestination = profile?.nextDestination {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                Text("Next Destination")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text(nextDestination)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(burntOrange)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Discovery Mode Button
    
    private var discoveryModeButton: some View {
        Button(action: {
            showDiscoveryModeSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discovery Mode")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoalColor)
                    
                    Text(discoveryModeDescription)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - My Friends Button
    
    private var myFriendsButton: some View {
        NavigationLink(value: "friendsGrid") {
            HStack(spacing: 12) {
                // Icon container with backdrop blur
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .background(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Friends")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("View all your connections")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        skyBlue,
                        forestGreen
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Settings Menu Section
    
    private var settingsMenuSection: some View {
        VStack(spacing: 0) {
            // Drift Pro
            Button(action: {
                if revenueCatManager.hasProAccess {
                    revenueCatManager.showCustomerCenter()
                } else {
                    showPaywall = true
                }
            }) {
                ProfileMenuRow(
                    icon: "crown.fill",
                    iconBackgroundGradient: [Color(red: 0.98, green: 0.76, blue: 0.18), Color(red: 0.96, green: 0.55, blue: 0.12)],
                    title: "Drift Pro",
                    subtitle: revenueCatManager.hasProAccess ? "Renews Jan 18, 2026" : "Upgrade to unlock features",
                    badge: revenueCatManager.hasProAccess ? "Active" : nil,
                    badgeColor: forestGreen
                )
            }
            
            menuDivider
            
            // Notifications
            Button(action: {
                // Notifications action
            }) {
                ProfileMenuRow(
                    icon: "bell.fill",
                    iconBackground: skyBlue,
                    title: "Notifications",
                    subtitle: nil
                )
            }
            
            menuDivider
            
            // Privacy & Safety
            Button(action: {
                // Privacy action
            }) {
                ProfileMenuRow(
                    icon: "shield.fill",
                    iconBackground: forestGreen,
                    title: "Privacy & Safety",
                    subtitle: nil
                )
            }
            
            menuDivider
            
            // Help & Support
            Button(action: {
                // Help action
            }) {
                ProfileMenuRow(
                    icon: "questionmark.circle.fill",
                    iconBackground: Color.purple,
                    title: "Help & Support",
                    subtitle: nil
                )
            }
            
            menuDivider
            
            // Restart Onboarding
            Button(action: {
                Task {
                    await restartOnboarding()
                }
            }) {
                ProfileMenuRow(
                    icon: "arrow.counterclockwise",
                    iconBackground: burntOrange,
                    title: "Restart Onboarding",
                    subtitle: nil
                )
            }
            
            menuDivider
            
            // Log Out
            Button(action: {
                Task {
                    await handleSignOut()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    
                    if isSigningOut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    } else {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.4))
                }
                .padding(20)
            }
            .disabled(isSigningOut)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Emergency Services Section
    
    private var emergencyServicesSection: some View {
        VStack(spacing: 8) {
            EmergencyButton(style: .floating)
            
            Text("Hold for 2 seconds to call")
                .font(.system(size: 11))
                .foregroundColor(charcoalColor.opacity(0.5))
        }
    }
    
    private var menuDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 72)
    }
    
    // MARK: - Helper Functions
    
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
            var updatedMetadata = supabaseManager.currentUser?.userMetadata ?? [:]
            updatedMetadata["onboarding_completed"] = AnyJSON.string("false")
            updatedMetadata["friendsOnly"] = nil

            if supabaseManager.currentUser != nil {
                let updatedUser = try await supabaseManager.client.auth.update(user: UserAttributes(data: updatedMetadata))
                supabaseManager.currentUser = updatedUser

                try await profileManager.updateProfile(
                    ProfileUpdateRequest(
                        name: "",
                        onboardingCompleted: false
                    )
                )

                try await profileManager.fetchCurrentProfile()

                supabaseManager.isShowingPreferenceSelection = true
                supabaseManager.isShowingOnboarding = false
                supabaseManager.isShowingFriendOnboarding = false
                supabaseManager.isShowingWelcomeSplash = false
            }
        } catch {
            print("Failed to restart onboarding: \(error.localizedDescription)")
        }
    }
    
    private func updateDiscoveryMode(_ mode: SupabaseManager.DiscoveryMode) async {
        do {
            try await supabaseManager.updateDiscoveryMode(mode)
            if mode == .both || mode == .dating {
                // Check if dating onboarding is complete
                let hasCompletedDatingOnboarding = profileManager.hasCompletedDatingOnboarding()
                if !hasCompletedDatingOnboarding {
                    // Determine starting step for partial onboarding
                    let startStep = profileManager.getDatingOnboardingStartStep()
                    // Store the start step for partial onboarding
                    UserDefaults.standard.set(startStep, forKey: "datingOnboardingStartStep")
                    supabaseManager.isShowingOnboarding = true
                    supabaseManager.isShowingWelcomeSplash = false
                    supabaseManager.isShowingPreferenceSelection = false
                }
            }
        } catch {
            // Error handling silently
        }
    }
    
    private func getMutualInterests(for profile: UserProfile) -> [String] {
        let currentUserInterests = supabaseManager.currentUser.flatMap { _ in
            profileManager.currentProfile?.interests
        } ?? []
        return Set(currentUserInterests).intersection(Set(profile.interests)).map { $0 }
    }
    
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

// MARK: - Profile Interest Tag

struct ProfileInterestTag: View {
    let interest: String
    
    private let desertSand = Color("DesertSand")
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 6) {
            if let emoji = DriftUI.emoji(for: interest) {
                Text(emoji)
                    .font(.system(size: 14))
            }
            Text(interest)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(desertSand)
        .clipShape(Capsule())
    }
}

private struct InterestItem: Identifiable {
    let id: String
    let name: String
    
    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

// MARK: - Profile Menu Row

struct ProfileMenuRow: View {
    let icon: String
    var iconBackground: Color? = nil
    var iconBackgroundGradient: [Color]? = nil
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    var badgeColor: Color? = nil
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                if let gradient = iconBackgroundGradient {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                } else if let bg = iconBackground {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bg.opacity(0.1))
                        .frame(width: 40, height: 40)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconBackgroundGradient != nil ? .white : iconBackground ?? charcoalColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Badge
            if let badge = badge, let badgeColor = badgeColor {
                Text(badge)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(badgeColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.4))
        }
        .padding(20)
    }
}

// MARK: - Profile Stat Card

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(charcoalColor)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Simple Stat Card (for BuilderScreen compatibility)

struct StatCard: View {
    let value: String
    let label: String
    
    private let charcoalColor = Color("Charcoal")
    
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProfileScreen()
}
