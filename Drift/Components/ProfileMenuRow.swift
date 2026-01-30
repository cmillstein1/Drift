//
//  ProfileMenuRow.swift
//  Drift
//

import SwiftUI

struct ProfileMenuRow: View {
    let icon: String
    var iconBackground: Color? = nil
    var iconBackgroundGradient: [Color]? = nil
    var iconColor: Color? = nil
    var iconStyle: ProfileMenuRowIconStyle = .filled
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    var badgeColor: Color? = nil

    enum ProfileMenuRowIconStyle {
        case filled   // colored background, white/colored icon
        case outline  // light beige circle, dark charcoal outline icon
    }

    private let charcoalColor = Color("Charcoal")
    private let iconBeige = Color(red: 0.97, green: 0.96, blue: 0.93) // #F7F4EE

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                if iconStyle == .outline {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(iconBeige)
                        .frame(width: 40, height: 40)
                } else if let gradient = iconBackgroundGradient {
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
                        .fill(bg)
                        .frame(width: 40, height: 40)
                }

                Image(systemName: icon)
                    .font(.system(size: iconStyle == .outline ? 18 : 20, weight: .medium))
                    .foregroundColor(
                        iconStyle == .outline ? charcoalColor :
                        (iconBackgroundGradient != nil ? .white :
                        (iconColor ?? (iconBackground != nil ? .white : charcoalColor)))
                    )
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
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.4))
        }
        .padding(16)
    }
}
