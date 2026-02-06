//
//  DriftApp.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Supabase
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Image caching: URLCache as disk fallback; in-memory caching handled by ImageCache (CachedAsyncImage)
        let memoryCapacity = 50 * 1024 * 1024   // 50 MB memory
        let diskCapacity = 150 * 1024 * 1024    // 150 MB disk
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)

        // Push notifications: set delegate and register
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
        print("[FCM] APNs device token received (\(deviceToken.count) bytes) – FCM will get token next")
        #endif
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("[FCM] APNs registration FAILED (Simulator or missing capability): \(error.localizedDescription)")
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate (foreground + user tap handling)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        #if DEBUG
        let content = notification.request.content
        print("[FCM] Notification received (foreground): \(content.title) – \(content.body)")
        #endif
        completionHandler([.banner, .badge, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        #if DEBUG
        let content = response.notification.request.content
        print("[FCM] Notification tapped: \(content.title) – \(content.body)")
        #endif
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        #if DEBUG
        print("[FCM] Notification received (background): \(userInfo)")
        #endif
        completionHandler(.newData)
    }
}

// MARK: - MessagingDelegate (FCM token)
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        #if DEBUG
        if let token = fcmToken {
            print("[FCM] Registration token (use this in Firebase → Send test message):")
            print("[FCM] \(token)")
        } else {
            print("[FCM] Registration token is nil – check APNs and internet")
        }
        #endif

        // Store FCM token in Supabase for server-side push notification targeting
        if let token = fcmToken {
            Task { @MainActor in
                await PushNotificationManager.shared.updateFCMToken(token)
            }
        }
    }
}

@main
struct DriftApp: App {
    @ObservedObject private var supabaseManager: SupabaseManager
    @StateObject private var revenueCatManager: RevenueCatManager
    @StateObject private var profileManager: ProfileManager
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Initialize DriftBackend with API keys FIRST
        initializeDriftBackend()

        // Now safe to access managers
        self._supabaseManager = ObservedObject(wrappedValue: SupabaseManager.shared)
        self._revenueCatManager = StateObject(wrappedValue: RevenueCatManager.shared)
        self._profileManager = StateObject(wrappedValue: ProfileManager.shared)
    }

    /// Check onboarding status - must have both the flag AND actual profile data
    private var hasCompletedOnboarding: Bool {
        // Check if profile exists and has required data filled in
        if let profile = profileManager.currentProfile {
            // Profile must have name filled in to be considered complete
            let hasRequiredData = profile.name != nil && !profile.name!.isEmpty
            let isMarkedComplete = profile.onboardingCompleted ||
                getOnboardingStatus(from: supabaseManager.currentUser?.userMetadata ?? [:])

            // Only consider complete if BOTH conditions are met
            return hasRequiredData && isMarkedComplete
        }

        // If profile not loaded yet, check auth metadata but be conservative
        // Return false to trigger onboarding check
        return false
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Show splash screen while checking auth status
                if supabaseManager.isCheckingAuth {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(2)
                } else if supabaseManager.isAuthenticated {
                    // Resolve invite status first; if nil we need to check the backend
                    if supabaseManager.hasRedeemedInvite == nil {
                        ZStack {
                            Color(red: 0.98, green: 0.98, blue: 0.96)
                                .ignoresSafeArea()
                            ProgressView()
                        }
                        .transition(.opacity)
                        .task {
                            let redeemed = await InviteManager.shared.hasUserRedeemedInvite()
                            supabaseManager.hasRedeemedInvite = redeemed
                        }
                    } else if supabaseManager.hasRedeemedInvite == false {
                        // User has not entered a code yet – show Enter Invite Code screen
                        EnterInviteCodeScreen()
                            .transition(.opacity)
                    } else if profileManager.isLoading && profileManager.currentProfile == nil {
                        // Wait for profile to load before deciding
                        ZStack {
                            Color(red: 0.98, green: 0.98, blue: 0.96)
                                .ignoresSafeArea()
                            ProgressView()
                        }
                    } else if supabaseManager.isShowingOnboarding && UserDefaults.standard.object(forKey: "datingOnboardingStartStep") != nil {
                        // Partial dating onboarding - user switching from community to dating mode
                        OnboardingFlow {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                supabaseManager.isShowingOnboarding = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(2)
                    } else if hasCompletedOnboarding {
                        // User has completed onboarding - go straight to home (skip WelcomeSplash and onboarding)
                        ContentView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                            .zIndex(1)
                    } else if supabaseManager.isShowingWelcomeSplash {
                        // New user - show welcome splash first (part of onboarding)
                        WelcomeSplash {
                            supabaseManager.isShowingWelcomeSplash = false
                            supabaseManager.isShowingPreferenceSelection = true
                        }
                    } else if supabaseManager.isShowingPreferenceSelection {
                        // Show preference selection screen
                        PreferenceSelectionScreen()
                    } else if supabaseManager.isShowingFriendOnboarding {
                        // Show friend onboarding flow
                        FriendOnboardingFlow {
                            // SafetyScreen will mark onboarding as complete internally
                            supabaseManager.isShowingFriendOnboarding = false
                        }
                    } else if supabaseManager.isShowingOnboarding {
                        // Show onboarding flow
                        OnboardingFlow {
                            // SafetyScreen will mark onboarding as complete
                            // Just need to clear the flag here
                            withAnimation(.easeInOut(duration: 0.6)) {
                                supabaseManager.isShowingOnboarding = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(0)
                    } else if supabaseManager.isShowingPreferenceSelection {
                        // Show preference selection screen
                        PreferenceSelectionScreen()
                    } else {
                        // User is authenticated but hasn't completed onboarding
                        // and no specific flag is set - redirect to preference selection
                        PreferenceSelectionScreen()
                            .onAppear {
                                supabaseManager.isShowingPreferenceSelection = true
                            }
                    }
                } else {
                    // Show sign-in screen (Apple / Google / Email)
                    WelcomeScreen()
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.6), value: supabaseManager.isShowingOnboarding)
            .animation(.easeInOut(duration: 0.3), value: supabaseManager.isCheckingAuth)
            .animation(.easeInOut(duration: 0.6), value: supabaseManager.hasRedeemedInvite)
            .task(id: supabaseManager.isAuthenticated) {
                if supabaseManager.isAuthenticated {
                    // Link RevenueCat to this user so subscription is recognized across devices
                    if let userId = supabaseManager.currentUser?.id.uuidString {
                        await revenueCatManager.logIn(userId: userId)
                    }
                    // Fetch profile when authenticated to check onboarding status
                    if profileManager.currentProfile == nil {
                        do {
                            try await profileManager.fetchCurrentProfile()
                        } catch {
                            print("Failed to fetch profile: \(error)")
                        }
                    }
                } else {
                    await revenueCatManager.logOut()
                }
            }
            .onChange(of: supabaseManager.isAuthenticated) { _, isAuthenticated in
                // Fetch profile when user logs in
                if isAuthenticated {
                    Task {
                        do {
                            try await profileManager.fetchCurrentProfile()
                        } catch {
                            print("Failed to fetch profile: \(error)")
                        }
                    }
                }
            }
            .onChange(of: supabaseManager.currentUser) { oldValue, newValue in
                if let user = newValue {
                    let metadataComplete = getOnboardingStatus(from: user.userMetadata)
                    // Only auto-dismiss onboarding if not in partial dating onboarding mode
                    // (indicated by datingOnboardingStartStep being set)
                    let isPartialDatingOnboarding = UserDefaults.standard.object(forKey: "datingOnboardingStartStep") != nil
                    if (metadataComplete || hasCompletedOnboarding) && !isPartialDatingOnboarding {
                        supabaseManager.isShowingWelcomeSplash = false
                        supabaseManager.isShowingOnboarding = false
                    }
                }
            }
            .onOpenURL { url in
                // Handle OAuth callback from Google Sign In
                // Supabase Swift will automatically handle the URL and complete the auth flow
                Task {
                    do {
                        // The session should already be set by signInWithOAuth, but we can verify
                        try await supabaseManager.checkAuthStatus()
                    } catch {
                        print("Failed to handle OAuth callback: \(error)")
                    }
                }
            }
        }
    }
}
