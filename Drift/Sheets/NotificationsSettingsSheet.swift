//
//  NotificationsSettingsSheet.swift
//  Drift
//
//  Push notification on/off — opened from Profile → Notifications.
//

import SwiftUI
import UserNotifications
import UIKit
import FirebaseMessaging
import DriftBackend

// MARK: - Notification category preference (stored in UserDefaults)
private enum NotificationCategory: String, CaseIterable, Identifiable {
    case newMessages
    case newMatches
    case nearbyTravelers
    case eventUpdates

    var id: String { rawValue }

    var userDefaultsKey: String { "notification_pref_\(rawValue)" }

    static func isEnabled(_ category: NotificationCategory) -> Bool {
        UserDefaults.standard.object(forKey: category.userDefaultsKey) as? Bool ?? true
    }

    static func setEnabled(_ category: NotificationCategory, _ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: category.userDefaultsKey)
    }
}

struct NotificationsSettingsSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var supabaseManager = SupabaseManager.shared

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false
    @State private var showOpenSettingsHint = false
    @State private var fcmToken: String?
    @State private var tokenCopied = false
    /// Local state for category toggles; keys are NotificationCategory.rawValue.
    @State private var categoryEnabled: [String: Bool] = [:]
    /// Snapshot when sheet appeared, to detect unsaved changes.
    @State private var initialCategoryEnabled: [String: Bool] = [:]

    private var isDatingEnabled: Bool {
        supabaseManager.getDiscoveryMode() != .friends
    }

    private let charcoalColor = Color("Charcoal")
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let burntOrange = Color("BurntOrange")
    private let skyBlue = Color("SkyBlue")
    private let forestGreen = Color("ForestGreen")

    private var isEnabled: Bool {
        notificationStatus == .authorized
    }

    private var notificationRows: [(category: NotificationCategory, icon: String, iconColor: Color, title: String)] {
        var rows: [(NotificationCategory, String, Color, String)] = [
            (.newMessages, "message.fill", skyBlue, "New messages"),
            (.nearbyTravelers, "person.2.fill", forestGreen, "Nearby travelers"),
            (.eventUpdates, "mappin.circle.fill", burntOrange, "Event updates"),
        ]
        if isDatingEnabled {
            rows.insert((.newMatches, "heart.fill", Color(red: 0.93, green: 0.36, blue: 0.51), "New matches"), at: 1)
        }
        return rows
    }

    private var hasUnsavedChanges: Bool {
        for (key, value) in categoryEnabled {
            if initialCategoryEnabled[key] != value { return true }
        }
        return initialCategoryEnabled.count != categoryEnabled.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                    .padding(.top, 8)

                Spacer()

                if hasUnsavedChanges {
                    Button(action: saveAndDismiss) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                } else {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .frame(width: 32, height: 32)
                            .background(softGray)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(softGray)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Manage how you receive push notifications from Drift.")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // Main toggle row
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(skyBlue)
                                .frame(width: 44, height: 44)

                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(charcoalColor)
                            Text(statusSubtitle)
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }

                        Spacer()

                        if notificationStatus == .notDetermined {
                            Button(action: requestPermission) {
                                if isRequesting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: burntOrange))
                                        .scaleEffect(0.9)
                                } else {
                                    Text("Enable")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(burntOrange)
                                        .clipShape(Capsule())
                                }
                            }
                            .disabled(isRequesting)
                        } else if notificationStatus == .authorized {
                            Toggle("", isOn: Binding(
                                get: { true },
                                set: { newValue in
                                    if !newValue { openSettings() }
                                }
                            ))
                            .labelsHidden()
                            .tint(forestGreen)
                        } else {
                            Button(action: openSettings) {
                                Text("Open Settings")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(burntOrange)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    if notificationStatus == .denied {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(burntOrange)

                            Text("Push notifications are off. Turn them on in Settings to get new messages, matches, and event updates.")
                                .font(.system(size: 13))
                                .foregroundColor(charcoalColor.opacity(0.7))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(softGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        Button(action: openSettings) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(burntOrange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }

                    if isEnabled {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("You'll get notifications for:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                .padding(.bottom, 12)

                            VStack(spacing: 0) {
                                ForEach(Array(notificationRows.enumerated()), id: \.element.category) { index, item in
                                    Button {
                                        let key = item.category.rawValue
                                        let current = categoryEnabled[key] ?? NotificationCategory.isEnabled(item.category)
                                        categoryEnabled[key] = !current
                                    } label: {
                                        NotificationSettingRow(
                                            icon: item.icon,
                                            iconColor: item.iconColor,
                                            title: item.title,
                                            isEnabled: categoryEnabled[item.category.rawValue] ?? NotificationCategory.isEnabled(item.category)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if index < notificationRows.count - 1 {
                                        Divider()
                                            .padding(.leading, 20 + 36 + 14)
                                            .padding(.vertical, 0)
                                    }
                                }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }

//                        // FCM token for testing in Firebase Console
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Test in Firebase")
//                                .font(.system(size: 14, weight: .medium))
//                                .foregroundColor(charcoalColor)
//                            Text("Copy the device token below. In Firebase Console → Engage → Messaging → New campaign, use \"Send test message\" and paste this token.")
//                                .font(.system(size: 12))
//                                .foregroundColor(charcoalColor.opacity(0.6))
//                            if let token = fcmToken {
//                                HStack(spacing: 8) {
//                                    Text(token)
//                                        .font(.system(size: 10, design: .monospaced))
//                                        .foregroundColor(charcoalColor.opacity(0.8))
//                                        .lineLimit(2)
//                                        .truncationMode(.middle)
//                                    Button(action: {
//                                        UIPasteboard.general.string = token
//                                        tokenCopied = true
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { tokenCopied = false }
//                                    }) {
//                                        Text(tokenCopied ? "Copied" : "Copy")
//                                            .font(.system(size: 13, weight: .semibold))
//                                            .foregroundColor(burntOrange)
//                                    }
//                                }
//                                .padding(12)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .background(softGray)
//                                .clipShape(RoundedRectangle(cornerRadius: 10))
//                            } else {
//                                ProgressView()
//                                    .scaleEffect(0.8)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .padding(12)
//                            }
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 8)
//                        .padding(.bottom, 24)
                }
            }
            .background(softGray)
        }
        .background(softGray)
        .onAppear {
            fetchNotificationStatus()
            fetchFCMToken()
            loadCategoryPreferences()
        }
        .onChange(of: notificationStatus) { _, newValue in
            if newValue == .authorized { fetchFCMToken() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            fetchNotificationStatus()
            fetchFCMToken()
        }
    }

    private var statusSubtitle: String {
        switch notificationStatus {
        case .authorized: return "On"
        case .denied: return "Off — change in Settings"
        case .notDetermined: return "Off"
        case .provisional, .ephemeral: return "On"
        @unknown default: return "Unknown"
        }
    }

    private func fetchNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func fetchFCMToken() {
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("FCM token error: \(error.localizedDescription)")
                    return
                }
                fcmToken = token
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                isRequesting = false
                fetchNotificationStatus()
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func loadCategoryPreferences() {
        var current: [String: Bool] = [:]
        var initial: [String: Bool] = [:]
        for category in NotificationCategory.allCases {
            let on = NotificationCategory.isEnabled(category)
            current[category.rawValue] = on
            initial[category.rawValue] = on
        }
        categoryEnabled = current
        initialCategoryEnabled = initial
    }

    private func saveAndDismiss() {
        for (key, value) in categoryEnabled {
            if let category = NotificationCategory(rawValue: key) {
                NotificationCategory.setEnabled(category, value)
            }
        }
        initialCategoryEnabled = categoryEnabled
        dismiss()
    }
}

private struct NotificationSettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isEnabled: Bool = true

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                )

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(charcoalColor)

            Spacer()

            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(forestGreen)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    NotificationsSettingsSheet(isPresented: .constant(true))
}
