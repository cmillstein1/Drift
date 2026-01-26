//
//  EventCard.swift
//  Drift
//
//  Event card with hero image design for community events
//

import SwiftUI
import DriftBackend

struct EventCard: View {
    let post: CommunityPost
    var onJoin: (() -> Void)? = nil

    @StateObject private var communityManager = CommunityManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let burntOrange = Color("BurntOrange")

    // Default event images based on category/title keywords
    private var eventImageURL: String? {
        // Check for user-uploaded images first
        if let firstImage = post.images.first, !firstImage.isEmpty {
            return firstImage
        }
        return nil
    }

    private var attendeeProgress: CGFloat {
        guard let max = post.maxAttendees, max > 0 else { return 0 }
        let current = post.currentAttendees ?? 0
        return min(CGFloat(current) / CGFloat(max), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image Section
            ZStack(alignment: .topTrailing) {
                // Image or gradient placeholder
                if let imageUrl = eventImageURL, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            eventPlaceholderGradient
                        case .empty:
                            eventPlaceholderGradient
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        @unknown default:
                            eventPlaceholderGradient
                        }
                    }
                    .frame(height: 160)
                    .clipped()
                } else {
                    eventPlaceholderGradient
                        .frame(height: 160)
                }

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.4)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)

                // Category badge
                Text("Event")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(12)
            }
            .frame(height: 160)
            .clipped()

            // Card Content
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(post.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoal)
                    .lineLimit(2)

                // Activity Details
                VStack(alignment: .leading, spacing: 8) {
                    // Location
                    if let location = post.eventLocation {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.5))
                            Text(location)
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                                .lineLimit(1)
                        }
                    }

                    // Date
                    if let formattedDate = post.formattedEventDate {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.5))
                            Text(formattedDate)
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                        }
                    }

                    // Attendees
                    if let max = post.maxAttendees {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.5))
                            Text("\(post.currentAttendees ?? 0)/\(max) going")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                        }
                    }
                }

                // Host and Join Button Row
                HStack {
                    Text("Hosted by ")
                        .font(.system(size: 14))
                        .foregroundColor(charcoal.opacity(0.5))
                    +
                    Text(post.author?.name ?? "Anonymous")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(burntOrange)

                    Spacer()

                    // Join Button
                    Button {
                        if let onJoin = onJoin {
                            onJoin()
                        } else {
                            Task {
                                if post.isAttendingEvent == true {
                                    try? await communityManager.leaveEvent(post.id)
                                    EventHelper.shared.cancelEventReminder(eventId: post.id)
                                } else {
                                    try? await communityManager.joinEvent(post.id)
                                    if let eventDate = post.eventDatetime {
                                        await EventHelper.shared.scheduleEventReminder(
                                            eventId: post.id,
                                            eventTitle: post.title,
                                            eventDate: eventDate
                                        )
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(post.isAttendingEvent == true ? "Joined" : "Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                post.isAttendingEvent == true
                                    ? charcoal
                                    : forestGreen
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var eventPlaceholderGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.8),
                Color.purple.opacity(0.5),
                Color.blue.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            VStack {
                Image(systemName: "tent.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
            }
        )
    }
}
