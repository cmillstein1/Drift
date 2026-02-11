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
    @State private var showEditProfile = false
    @State private var showDiscoveryModeSheet = false
    @State private var showDatingSettings = false
    @State private var showFriendsSettings = false
    @State private var friendsFilterPreferences = NearbyFriendsFilterPreferences.fromStorage()
    @State private var navigateToFriendsGrid = false
    @State private var showPaywall = false
    @State private var showGenerateInvite = false
    @State private var showNotificationsSheet = false
    @State private var showMyPostsSheet = false
    @State private var showEventsJoinedSheet = false
    @State private var navigationPath: [String] = []
    @StateObject private var communityManager = CommunityManager.shared
    @State private var lastProfileFetch: Date = .distantPast

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
    
    private var hasDatingEnabled: Bool {
        supabaseManager.getDiscoveryMode() != .friends
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private let softGray = Color("SoftGray")
    private let desertSand = Color("DesertSand")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                softGray.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Report scroll offset so tab bar can slide away when scrolling
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("profileScroll")).minY
                            )
                        }
                        .frame(height: 0)
                        // Header Section - extends to top
                        headerSection
                            .ignoresSafeArea(edges: .top)
                        
                        // Main Content
                        VStack(spacing: 16) {
                            // Discovery Mode
                            discoveryModeButton

                            // My Posts
                            myPostsButton

                            // Events Joined
                            eventsJoinedButton

                            // Settings Menu
                            settingsMenuSection
                            
                            // Emergency Services Button
                            emergencyServicesButton
                            
                            // App version
                            Text("Drift v\(appVersion)")
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
                .coordinateSpace(name: "profileScroll")
                .ignoresSafeArea(edges: .top)
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
                    }
                )
                .presentationDetents([.height(480)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDatingSettings) {
                DatingSettingsSheet(isPresented: $showDatingSettings)
                    .presentationDetents([.height(600), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFriendsSettings) {
                NearbyFriendsFilterSheet(
                    isPresented: $showFriendsSettings,
                    preferences: $friendsFilterPreferences
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "verification" {
                    VerificationView()
                } else if destination == "editProfile" {
                    EditProfileScreen(onBack: {
                        navigationPath.removeLast()
                    })
                } else if destination == "privacySafetySupport" {
                    PrivacySafetySupportScreen()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallScreen(isOpen: $showPaywall, source: .general)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showGenerateInvite) {
                GenerateInviteSheet(isPresented: $showGenerateInvite)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsSettingsSheet(isPresented: $showNotificationsSheet)
                    .presentationDetents([.height(680), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMyPostsSheet) {
                MyPostsSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showEventsJoinedSheet) {
                EventsJoinedSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                // Skip re-fetch if data is less than 30 seconds old
                guard Date().timeIntervalSince(lastProfileFetch) > 30 else { return }
                Task {
                    do {
                        try await profileManager.fetchCurrentProfile()
                    } catch {
                        #if DEBUG
                        print("Failed to fetch profile: \(error)")
                        #endif
                    }
                    await revenueCatManager.loadCustomerInfo()
                    try? await communityManager.fetchNewInteractionCount()
                    try? await communityManager.fetchJoinedEvents()
                    lastProfileFetch = Date()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Header with background image
            ZStack {
                // Background image with black opacity overlay - extends into safe area
                ZStack {
                    Image("Profile_Header")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                    
                    // Black opacity overlay
                    Color.black.opacity(0.3)
                }
                .ignoresSafeArea(edges: .top)
                
                // Profile Info - moved down to reduce spacing
                VStack(spacing: 0) {
                    Spacer()
                    
                    HStack(alignment: .bottom, spacing: 16) {
                        // Profile Photo
                        ZStack(alignment: .bottomTrailing) {
                            CachedAsyncImage(url: URL(string: profile?.primaryDisplayPhotoUrl ?? "")) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 112, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            // Verification Badge
                            if profile?.verified == true {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(forestGreen)
                                }
                                .offset(x: 8, y: 8)
                            }
                        }
                        
                        // Name & Location
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text(profile?.displayName ?? "Your Name")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if let p = profile, p.displayAge > 0 {
                                    Text(", \(p.displayAge)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Location
                            if let location = profile?.location, !location.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(location)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            // Edit Profile Button
                            NavigationLink(value: "editProfile") {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Edit Profile")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(charcoalColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .background(Color.white)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .frame(height: 220)
        }
    }
    
    // MARK: - Discovery Mode + Generate Code (HStack of two rounded rects)
    
    private var discoveryModeButton: some View {
        HStack(spacing: 12) {
            // Discovery Mode
            Button(action: {
                showDiscoveryModeSheet = true
            }) {
                VStack(spacing: 10) {
                    Image("DiscoverMode")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 56)
                    Text("Discovery Mode")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(charcoalColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Generate Code
            Button(action: {
                showGenerateInvite = true
            }) {
                VStack(spacing: 10) {
                    Image("InviteFriends")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 56)
                    Text("Invite Friends")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(charcoalColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - My Posts Button

    private var myPostsButton: some View {
        Button(action: {
            showMyPostsSheet = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(burntOrange.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(burntOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("My Posts")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                    Text("Events and help requests you've created")
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.5))
                }

                Spacer()

                // Interaction badge
                if communityManager.newInteractionCount > 0 {
                    Text("\(communityManager.newInteractionCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(burntOrange)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Events Joined Button

    private var eventsJoinedButton: some View {
        Button(action: {
            showEventsJoinedSheet = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Events Joined")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                    Text("Events you're attending")
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.5))
                }

                Spacer()

                // Unread notification dot
                if communityManager.unreadEventChatCount > 0 {
                    Circle()
                        .fill(burntOrange)
                        .frame(width: 10, height: 10)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
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
                    subtitle: revenueCatManager.hasProAccess ? "Active subscription" : "Upgrade to unlock features",
                    badge: revenueCatManager.hasProAccess ? "Active" : nil,
                    badgeColor: forestGreen
                )
            }
            
            menuDivider

            // Dating Preferences (only when dating is enabled)
            if hasDatingEnabled {
                Button(action: {
                    showDatingSettings = true
                }) {
                    ProfileMenuRow(
                        icon: "heart",
                        iconStyle: .outline,
                        title: "Dating Preferences",
                        subtitle: nil
                    )
                }

                menuDivider
            }

            // Community Preferences
            Button(action: {
                showFriendsSettings = true
            }) {
                ProfileMenuRow(
                    icon: "person.2",
                    iconStyle: .outline,
                    title: "Community Preferences",
                    subtitle: nil
                )
            }

            menuDivider

            // Notifications
            Button(action: {
                showNotificationsSheet = true
            }) {
                ProfileMenuRow(
                    icon: "bell",
                    iconStyle: .outline,
                    title: "Notifications",
                    subtitle: nil
                )
            }
            
            menuDivider
            
            // Privacy, Safety & Support (Blocked users, etc.) — navigation push
            NavigationLink(value: "privacySafetySupport") {
                ProfileMenuRow(
                    icon: "lock",
                    iconStyle: .outline,
                    title: "Privacy, Safety & Support",
                    subtitle: "Blocked users, help and more"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            menuDivider
            
            // Generate Invite Code
//            Button(action: {
//                showGenerateInvite = true
//            }) {
//                ProfileMenuRow(
//                    icon: "gift",
//                    iconStyle: .outline,
//                    title: "Generate Invite Code",
//                    subtitle: nil
//                )
//            }
//            
//            menuDivider
            
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.4))
                }
                .padding(16)
            }
            .disabled(isSigningOut)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Emergency Services Button
    
    private var emergencyServicesButton: some View {
        EmergencyButton(style: .inline)
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
        await PushNotificationManager.shared.clearFCMToken()
        do {
            try await supabaseManager.signOut()
        } catch {
            #if DEBUG
            print("Error signing out: \(error.localizedDescription)")
            #endif
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
            #if DEBUG
            print("Failed to restart onboarding: \(error.localizedDescription)")
            #endif
        }
    }
    
    private func updateDiscoveryMode(_ mode: SupabaseManager.DiscoveryMode) async {
        do {
            try await supabaseManager.updateDiscoveryMode(mode)
            profileManager.discoveryModeVersion += 1
            if mode == .both || mode == .dating {
                // If user already completed onboarding, just update their lookingFor
                // so they appear in dating discovery — don't force them through onboarding again
                let alreadyOnboarded = profileManager.currentProfile?.onboardingCompleted ?? false
                if alreadyOnboarded {
                    if profileManager.currentProfile?.lookingFor != .both && profileManager.currentProfile?.lookingFor != .dating {
                        try await profileManager.updateProfile(ProfileUpdateRequest(lookingFor: .both))
                    }
                } else {
                    let hasCompletedDatingOnboarding = profileManager.hasCompletedDatingOnboarding()
                    if !hasCompletedDatingOnboarding {
                        let startStep = profileManager.getDatingOnboardingStartStep()
                        UserDefaults.standard.set(startStep, forKey: "datingOnboardingStartStep")
                        supabaseManager.isShowingOnboarding = true
                        supabaseManager.isShowingWelcomeSplash = false
                        supabaseManager.isShowingPreferenceSelection = false
                    }
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
    
    // Use supabaseManager.getOnboardingStatus(from:) instead of a local duplicate
}


private struct InterestItem: Identifiable {
    let id: String
    let name: String
    
    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

#Preview {
    ProfileScreen()
}
