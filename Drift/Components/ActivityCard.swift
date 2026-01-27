//
//  ActivityCard.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct ActivityCard: View {
    let activity: Activity
    var onTap: (() -> Void)? = nil
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: activity.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                }
                .frame(height: 160)
                .clipped()

                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(activity.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))

                        Text(activity.location)
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))

                        Text(activity.formattedDateTime)
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))

                        Text("\(activity.currentAttendees)/\(activity.maxAttendees) going")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }

                HStack {
                    HStack(spacing: 0) {
                        Text("Hosted by ")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        Text(activity.host?.displayName ?? "Unknown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                    }

                    Spacer()

                    Button(action: {
                        // Handle join
                    }) {
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(forestGreen)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    ActivityCard(
        activity: Activity(
            hostId: UUID(),
            title: "Sunrise Hike",
            category: .outdoor,
            location: "Big Sur Trail",
            imageUrl: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?w=800",
            startsAt: Date().addingTimeInterval(86400),
            maxAttendees: 8,
            currentAttendees: 4
        )
    )
    .padding()
}
