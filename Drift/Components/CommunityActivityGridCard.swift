//
//  CommunityActivityGridCard.swift
//  Drift
//
//  Created by Casey Millstein on 2/4/26.
//

import SwiftUI
import DriftBackend

struct CommunityActivityGridCard: View {
    let activity: Activity
    var onTap: (() -> Void)? = nil

    private let charcoalColor = Color("Charcoal")

    /// Parse hex color from ActivityCategory.color
    private var categoryColor: Color {
        Color(hex: activity.category.color) ?? Color.gray
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image section with category badge
            ZStack(alignment: .topLeading) {
                // Activity image or gradient fallback
                if let imageUrl = activity.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            categoryGradientFallback
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            categoryGradientFallback
                        @unknown default:
                            categoryGradientFallback
                        }
                    }
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
                } else {
                    categoryGradientFallback
                }

                // Category badge (top-left)
                HStack(spacing: 4) {
                    Image(systemName: activity.category.icon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(activity.category.displayName)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor)
                .clipShape(Capsule())
                .padding(8)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Content section
            VStack(alignment: .leading, spacing: 6) {
                // Title (2 lines max)
                Text(activity.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(charcoalColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(charcoalColor.opacity(0.5))
                    Text(activity.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .lineLimit(1)
                }

                // Attendee count
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(charcoalColor.opacity(0.5))
                    Text("\(activity.currentAttendees)/\(activity.maxAttendees) going")
                        .font(.system(size: 11))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    @ViewBuilder
    private var categoryGradientFallback: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    categoryColor,
                    categoryColor.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            .frame(maxWidth: .infinity)

            Image(systemName: activity.category.icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        CommunityActivityGridCard(
            activity: Activity(
                hostId: UUID(),
                title: "Sunrise Hike at Big Sur Trail",
                category: .outdoor,
                location: "Big Sur, CA",
                imageUrl: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800",
                startsAt: Date().addingTimeInterval(86400),
                maxAttendees: 8,
                currentAttendees: 4
            )
        )
        .frame(width: 170)

        CommunityActivityGridCard(
            activity: Activity(
                hostId: UUID(),
                title: "Coffee & Code Session",
                category: .work,
                location: "Local Cafe",
                startsAt: Date().addingTimeInterval(172800),
                maxAttendees: 6,
                currentAttendees: 2
            )
        )
        .frame(width: 170)
    }
    .padding()
}
