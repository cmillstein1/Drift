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

        // Parse notification payload and route to the relevant screen (deeplink).
        // FCM puts custom data at top-level userInfo; also support nested userInfo["data"].
        func string(_ key: String) -> String? {
            (userInfo["data"] as? [String: Any])?[key] as? String
                ?? userInfo[key] as? String
        }
        if let type = string("type") {
            Task { @MainActor in
                switch type {
                case "message":
                    if let idString = string("conversation_id"), let id = UUID(uuidString: idString) {
                        DeepLinkRouter.shared.pending = .conversation(id: id)
                    }
                case "match":
                    if let idString = string("matched_user_id"), let id = UUID(uuidString: idString) {
                        DeepLinkRouter.shared.pending = .matchedUser(id: id)
                    }
                case "event_join", "event_chat":
                    if let idString = string("post_id"), let id = UUID(uuidString: idString) {
                        DeepLinkRouter.shared.pending = .eventPost(id: id)
                    }
                case "reply":
                    if let idString = string("post_id"), let id = UUID(uuidString: idString) {
                        DeepLinkRouter.shared.pending = .communityPost(id: id)
                    }
                default:
                    break
                }
            }
        }

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
    @StateObject private var appConfigManager: AppConfigManager

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showSplash = true

    init() {
        // Initialize DriftBackend with bootstrap config (Supabase URL + anon key only).
        // Third-party API keys are fetched at runtime via AppConfigManager.
        initializeDriftBackend()

        // Now safe to access managers
        self._supabaseManager = ObservedObject(wrappedValue: SupabaseManager.shared)
        self._revenueCatManager = StateObject(wrappedValue: RevenueCatManager.shared)
        self._profileManager = StateObject(wrappedValue: ProfileManager.shared)
        self._appConfigManager = StateObject(wrappedValue: AppConfigManager.shared)
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

        // Profile not loaded yet — fall back to auth metadata so returning
        // users aren't shown the preference/onboarding screens while the
        // profile is still being fetched.
        return getOnboardingStatus(from: supabaseManager.currentUser?.userMetadata ?? [:])
    }

    /// All initial loading is done — destination view is ready to show
    private var appIsReady: Bool {
        if supabaseManager.isCheckingAuth { return false }
        if !supabaseManager.isAuthenticated { return true }
        // Wait for remote API keys before dismissing splash
        if !appConfigManager.isConfigured { return false }
        if supabaseManager.hasRedeemedInvite == nil { return false }
        if supabaseManager.hasRedeemedInvite == false { return true }
        if profileManager.isLoading && profileManager.currentProfile == nil { return false }
        return true
    }

    private func dismissSplashIfReady() {
        guard appIsReady && showSplash else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSplash = false
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Content layer — renders destination underneath the splash overlay
                if supabaseManager.isAuthenticated && !supabaseManager.isCheckingAuth {
                    if supabaseManager.hasRedeemedInvite == false {
                        // 1. User has not entered a code yet – show Enter Invite Code screen
                        EnterInviteCodeScreen()
                            .transition(.opacity)
                    } else if supabaseManager.isShowingWelcomeSplash {
                        // 2. New user - show welcome splash first (part of onboarding)
                        WelcomeSplash {
                            supabaseManager.isShowingWelcomeSplash = false
                            supabaseManager.isShowingPreferenceSelection = true
                        }
                    } else if supabaseManager.isShowingPreferenceSelection && !hasCompletedOnboarding {
                        // 3. Show preference selection screen (only for users who haven't finished onboarding)
                        PreferenceSelectionScreen()
                    } else if supabaseManager.isShowingFriendOnboarding {
                        // 4. Show friend onboarding flow
                        FriendOnboardingFlow {
                            supabaseManager.isShowingFriendOnboarding = false
                        }
                    } else if supabaseManager.isShowingOnboarding && UserDefaults.standard.object(forKey: "datingOnboardingStartStep") != nil {
                        // 5. Partial dating onboarding - user switching from community to dating mode
                        OnboardingFlow {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                supabaseManager.isShowingOnboarding = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(2)
                    } else if supabaseManager.isShowingOnboarding {
                        // 6. Show onboarding flow
                        OnboardingFlow {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                supabaseManager.isShowingOnboarding = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(0)
                    } else if hasCompletedOnboarding {
                        // 7. User has completed onboarding - show home
                        ContentView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                            .zIndex(1)
                    } else {
                        // 8. Authenticated but hasn't completed onboarding
                        // and no specific flag is set - redirect to preference selection
                        PreferenceSelectionScreen()
                            .onAppear {
                                supabaseManager.isShowingPreferenceSelection = true
                            }
                    }
                } else if !supabaseManager.isCheckingAuth {
                    // Show sign-in screen (Apple / Google / Email)
                    WelcomeScreen()
                }

                // Splash overlay — stays on top until content is ready
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.6), value: supabaseManager.isShowingOnboarding)
            .animation(.easeInOut(duration: 0.6), value: supabaseManager.hasRedeemedInvite)
            .animation(.easeOut(duration: 0.5), value: showSplash)
            .onChange(of: supabaseManager.isCheckingAuth) { _, _ in dismissSplashIfReady() }
            .onChange(of: supabaseManager.hasRedeemedInvite) { _, _ in dismissSplashIfReady() }
            .onChange(of: profileManager.isLoading) { _, _ in dismissSplashIfReady() }
            .onChange(of: supabaseManager.isAuthenticated) { oldValue, newValue in
                if newValue && !oldValue {
                    // User just signed in — re-show splash to cover the loading
                    // period (profile fetch, config, invite check) so onboarding
                    // screens don't flash briefly.
                    showSplash = true
                }
                dismissSplashIfReady()
            }
            .onChange(of: appConfigManager.isConfigured) { _, _ in dismissSplashIfReady() }
            .task(id: supabaseManager.isAuthenticated) {
                if supabaseManager.isAuthenticated {
                    // Fetch remote API keys from edge function (splash stays up until done)
                    await appConfigManager.fetchRemoteConfig()

                    // Now that keys are available, configure RevenueCat SDK
                    revenueCatManager.configureSDK()

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
                    // Re-send FCM token now that user is authenticated
                    if let token = Messaging.messaging().fcmToken {
                        await PushNotificationManager.shared.updateFCMToken(token)
                    }
                    // Check invite status now that auth is ready
                    if supabaseManager.hasRedeemedInvite == nil {
                        let redeemed = await InviteManager.shared.hasUserRedeemedInvite()
                        supabaseManager.hasRedeemedInvite = redeemed
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
            .onChange(of: hasCompletedOnboarding) { _, isComplete in
                if isComplete {
                    // Profile loaded and confirmed onboarding done — clear any
                    // stale onboarding flags that checkAuthStatus may have set
                    // before the profile was available.
                    let isPartialDatingOnboarding = UserDefaults.standard.object(forKey: "datingOnboardingStartStep") != nil
                    if !isPartialDatingOnboarding {
                        supabaseManager.isShowingPreferenceSelection = false
                        supabaseManager.isShowingOnboarding = false
                        supabaseManager.isShowingWelcomeSplash = false
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
                        supabaseManager.isShowingPreferenceSelection = false
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
