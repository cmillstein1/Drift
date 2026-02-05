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

    @State private var titleOpacity: Double = 0
    @State private var cardsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var isRequesting = false

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private var bellGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.45, blue: 0.35), sunsetRose],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 8)

            // Image
            Image("Temp_Noti")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .padding(.bottom, 16)

            // Title & subtitle
            VStack(spacing: 6) {
                Text("Stay connected")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(charcoalColor)

                Text("Get notified when it matters most")
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor.opacity(0.7))
            }
            .opacity(titleOpacity)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Benefit cards - condensed to 3 rows
            VStack(spacing: 10) {
                NotificationBenefitRow(
                    iconName: "bubble.left.and.bubble.right",
                    title: "Messages & matches",
                    subtitle: "Never miss a connection"
                )
                NotificationBenefitRow(
                    iconName: "person.2",
                    title: "Nearby travelers",
                    subtitle: "Find people in your area"
                )
                NotificationBenefitRow(
                    iconName: "calendar.badge.clock",
                    title: "Event updates",
                    subtitle: "Get notified about activities"
                )
            }
            .padding(.horizontal, 24)
            .opacity(cardsOpacity)

            Spacer()

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
            .padding(.bottom, 12)
            .opacity(buttonOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
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
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBeige)
                    .frame(width: 36, height: 36)

                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(charcoalColor)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    PushNotificationsScreen {
        print("Continue")
    }
}
