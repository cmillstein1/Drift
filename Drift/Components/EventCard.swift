//
//  EventCard.swift
//  Drift
//
//  Event card with hero image design for community events
//

import SwiftUI
import DriftBackend
import Auth
import CoreLocation

struct EventCard: View {
    let post: CommunityPost
    var onJoin: (() -> Void)? = nil

    @StateObject private var communityManager = CommunityManager.shared
    @State private var cityLocation: String? = nil

    private let charcoal = Color("Charcoal")

    private var isCurrentUserHost: Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }
        return post.authorId == currentUserId
    }

    // Check if user can see full location details
    private var canSeeFullLocation: Bool {
        if post.eventPrivacy == .public {
            return true
        }
        if isCurrentUserHost {
            return true
        }
        if post.isAttendingEvent == true {
            return true
        }
        return false
    }

    // Button text based on state
    private var joinButtonText: String {
        if post.isAttendingEvent == true {
            return "Joined"
        } else if post.hasPendingRequest == true {
            return "Requested"
        } else if post.eventPrivacy?.isPrivate == true {
            return "Request"
        } else {
            return "Join"
        }
    }

    // Button color based on state
    private var joinButtonColor: Color {
        if post.isAttendingEvent == true {
            return charcoal
        } else if post.hasPendingRequest == true {
            return Color("SkyBlue")
        } else {
            return forestGreen
        }
    }
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
                    CachedAsyncImage(url: url) { phase in
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

                // Dating tag (top right) when event is dating-only
                if post.isDatingEvent == true {
                    Text("Dating")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(charcoal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
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
                    // Location - show full or city based on privacy
                    if canSeeFullLocation {
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
                    } else if let city = cityLocation {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.5))
                            Text(city)
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                                .lineLimit(1)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(charcoal.opacity(0.4))
                        }
                    } else if post.eventLatitude != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.5))
                            Text("Location hidden")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.4))
                                .italic()

                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(charcoal.opacity(0.4))
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

                    // Join Button / Hosting indicator
                    if isCurrentUserHost {
                        Text("Hosting")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(burntOrange.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        Button {
                            if let onJoin = onJoin {
                                onJoin()
                            } else {
                                Task {
                                    if post.isAttendingEvent == true {
                                        try? await communityManager.leaveEvent(post.id)
                                        EventHelper.shared.cancelEventReminder(eventId: post.id)
                                    } else if post.hasPendingRequest == true {
                                        // Cancel pending request
                                        try? await communityManager.cancelJoinRequest(post.id)
                                    } else if post.eventPrivacy?.isPrivate == true {
                                        // Request to join private event
                                        try? await communityManager.requestToJoinEvent(post.id)
                                    } else {
                                        // Direct join for public events
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
                            Text(joinButtonText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(joinButtonColor)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .onAppear {
            // Load city for private events
            if !canSeeFullLocation && post.eventLatitude != nil {
                loadCityFromCoordinates()
            }
        }
    }

    private func loadCityFromCoordinates() {
        guard let lat = post.eventLatitude, let lng = post.eventLongitude else { return }

        let location = CLLocation(latitude: lat, longitude: lng)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var parts: [String] = []
                if let city = placemark.locality {
                    parts.append(city)
                }
                if let state = placemark.administrativeArea {
                    parts.append(state)
                }
                if !parts.isEmpty {
                    cityLocation = parts.joined(separator: ", ")
                }
            }
        }
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
