//
//  DiscoveryModeSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/18/26.
//

import SwiftUI
import DriftBackend

struct DiscoveryModeSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var supabaseManager = SupabaseManager.shared

    var onSelectDatingAndFriends: () -> Void
    var onSelectFriendsOnly: () -> Void
    var hasCompletedDatingOnboarding: Bool

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)

    private var currentMode: SupabaseManager.DiscoveryMode {
        supabaseManager.getDiscoveryMode()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Discovery Mode")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(softGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Choose what you'd like to see in your Discover feed")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    VStack(spacing: 12) {
                        // Dating & Friends Card
                        DiscoveryModeOption(
                            title: "Dating & Friends",
                            description: "See both dating matches and friend connections. Perfect for finding romance and community.",
                            icon: "heart.fill",
                            isSelected: currentMode == .both || currentMode == .dating,
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            accentColor: burntOrange,
                            showSetupNote: !hasCompletedDatingOnboarding && currentMode == .friends
                        ) {
                            onSelectDatingAndFriends()
                            dismiss()
                        }

                        // Friends Only Card
                        DiscoveryModeOption(
                            title: "Friends Only",
                            description: "Focus on platonic connections only. Great for finding travel buddies and community.",
                            icon: "person.2.fill",
                            isSelected: currentMode == .friends,
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [skyBlue, forestGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            accentColor: forestGreen,
                            showSetupNote: false
                        ) {
                            onSelectFriendsOnly()
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Info Note
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(burntOrange)

                        Text("You can change this anytime from your profile. Your existing connections and messages will always remain.")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color.white)
    }
}

struct DiscoveryModeOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let gradient: LinearGradient
    let accentColor: Color
    let showSetupNote: Bool
    let onTap: () -> Void

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? gradient : LinearGradient(colors: [softGray], startPoint: .top, endPoint: .bottom))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : charcoalColor.opacity(0.6))
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(accentColor)
                            .opacity(isSelected ? 1 : 0)
                    }

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if showSetupNote {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(burntOrange)

                            Text("Quick 2-min setup required")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(charcoalColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? accentColor : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DiscoveryModeSheet(
        isPresented: .constant(true),
        onSelectDatingAndFriends: {},
        onSelectFriendsOnly: {},
        hasCompletedDatingOnboarding: false
    )
}
