//
//  PushNotificationsScreen.swift
//  Drift
//
//  Push notifications prompt — shown after Enable Location in onboarding.
//

import SwiftUI
import UserNotifications

struct PushNotificationsScreen: View {
    let onContinue: () -> Void

    @State private var iconScale: CGFloat = 0.9
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var cardsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var isRequesting = false

    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)

    private var bellGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.45, blue: 0.35), sunsetRose],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top padding (no progress indicator)
                    Spacer()
                        .frame(height: 24)

                    ZStack {
                        Image("Temp_Noti")
                              .resizable()
                              .frame(width: 200, height: 200)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                    // Title & subtitle
                    VStack(spacing: 8) {
                        Text("Stay connected")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(charcoalColor)
                            .opacity(titleOpacity)

                        Text("Get notified when it matters most")
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor.opacity(0.7))
                            .opacity(titleOpacity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)

                    // Benefit cards (outline style like profile Notifications / Privacy)
                    VStack(spacing: 12) {
                        NotificationBenefitRow(
                            iconName: "message",
                            title: "New messages",
                            subtitle: "Never miss a conversation"
                        )
                        NotificationBenefitRow(
                            iconName: "heart",
                            title: "New matches",
                            subtitle: "Know when someone connects"
                        )
                        NotificationBenefitRow(
                            iconName: "person.2",
                            title: "Nearby travelers",
                            subtitle: "Find people in your area"
                        )
                        NotificationBenefitRow(
                            iconName: "mappin.circle",
                            title: "Event updates",
                            subtitle: "Get notified about activities"
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(cardsOpacity)

                    Spacer()
                        .frame(height: 40)

                    // Enable Notifications button
                    Button(action: requestNotificationPermission) {
                        HStack(spacing: 10) {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                Text("Enable Notifications")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(bellGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .disabled(isRequesting)
                    .padding(.horizontal, 24)
                    .opacity(buttonOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                iconScale = 1
                iconOpacity = 1
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                cardsOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                buttonOpacity = 1
            }
        }
    }

    private func requestNotificationPermission() {
        isRequesting = true
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in
            DispatchQueue.main.async {
                isRequesting = false
                onContinue()
            }
        }
    }
}

private struct NotificationBenefitRow: View {
    let iconName: String
    let title: String
    let subtitle: String

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let iconBeige = Color(red: 0.97, green: 0.96, blue: 0.93)

    var body: some View {
        HStack(spacing: 12) {
            // Icon — outline style like ProfileScreen (Notifications, Privacy): light bg, dark icon, corner radius 16
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconBeige)
                    .frame(width: 40, height: 40)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(charcoalColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    PushNotificationsScreen {
        print("Continue")
    }
}
