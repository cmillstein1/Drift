//
//  EventDetailSheet.swift
//  Drift
//
//  Event detail sheet with hero image design
//

import SwiftUI
import MapKit
import DriftBackend

struct EventDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let initialPost: CommunityPost

    @StateObject private var communityManager = CommunityManager.shared
    @State private var showingCalendarAdded: Bool = false
    @State private var showingGroupChat: Bool = false
    @State private var attendees: [UserProfile] = []

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    // Get live post updates
    private var post: CommunityPost {
        communityManager.posts.first(where: { $0.id == initialPost.id }) ?? initialPost
    }

    private var attendeeProgress: CGFloat {
        guard let max = post.maxAttendees, max > 0 else { return 0 }
        return min(CGFloat(attendees.count) / CGFloat(max), 1.0)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroImageSection
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)

            // Bottom Action Bar
            bottomActionBar
        }
        .background(warmWhite)
        .sheet(isPresented: $showingGroupChat) {
            EventGroupChatSheet(post: post)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadAttendees()
        }
    }

    private func loadAttendees() {
        Task {
            do {
                attendees = try await communityManager.fetchEventAttendees(initialPost.id)
            } catch {
                print("Failed to load attendees: \(error)")
            }
        }
    }

    // MARK: - Hero Image Section

    private var heroImageSection: some View {
        ZStack(alignment: .top) {
            // Hero Image
            heroImage
                .frame(height: 280)
                .clipped()

            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.2), .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)

            // Top controls
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoal)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.9))
                        .clipShape(Circle())
                }

                Spacer()

                // Share button
                Button {
                    shareEvent()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoal)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.9))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            // Category badge
            VStack {
                HStack {
                    Spacer()
                    Text("Event")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 110)

                Spacer()
            }
            .frame(height: 280)

            // Title overlay at bottom
            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Text(post.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text("Hosted by")
                        .foregroundColor(.white.opacity(0.8))
                    Text(post.author?.name ?? "Anonymous")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .font(.system(size: 15))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(height: 280)
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if let imageUrl = post.images.first, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_), .empty:
                    eventPlaceholderGradient
                @unknown default:
                    eventPlaceholderGradient
                }
            }
        } else {
            eventPlaceholderGradient
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
            Image(systemName: "tent.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
        )
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Key Info Cards Grid
            infoCardsGrid
                .padding(.top, 24)

            // Location Card
            locationCard

            // About Section
            aboutSection

            // Who's Going Section
            if !attendees.isEmpty {
                whosGoingSection
            }

            // Add to Calendar
            if let eventDate = post.eventDatetime, eventDate > Date() {
                addToCalendarButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 120)
    }

    private var infoCardsGrid: some View {
        HStack(spacing: 12) {
            // Date & Time Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text("Date & Time")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.5))

                Text(post.formattedEventDate ?? "TBD")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(charcoal)

                Text("2 hours")
                    .font(.system(size: 12))
                    .foregroundColor(charcoal.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(softGray)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Attendees Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                    Text("Attendees")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.5))

                if let max = post.maxAttendees, max > 0 {
                    Text("\(attendees.count)/\(max) joined")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(charcoal)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [forestGreen, skyBlue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * attendeeProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Text("\(attendees.count) joined")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(charcoal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(softGray)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                // Gradient icon background
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "mappin")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Location")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)
            }

            Text(post.eventLocation ?? "Location TBD")
                .font(.system(size: 15))
                .foregroundColor(charcoal)

            Text(post.isAttendingEvent == true
                 ? (post.eventExactLocation ?? "Exact location shared")
                 : "Exact location shared after joining")
                .font(.system(size: 13))
                .foregroundColor(charcoal.opacity(0.5))

            // Map preview when coordinates are available
            if let lat = post.eventLatitude, let lng = post.eventLongitude {
                eventMapPreview(latitude: lat, longitude: lng)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(softGray)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func eventMapPreview(latitude: Double, longitude: Double) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        return Button {
            openInAppleMaps(latitude: latitude, longitude: longitude)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Map(initialPosition: .region(region), interactionModes: []) {
                    Annotation("", coordinate: coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(burntOrange)
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 10))
                                .foregroundColor(burntOrange)
                                .offset(y: -4)
                        }
                    }
                }
                .allowsHitTesting(false)

                // Open in Maps hint
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                    Text("Open in Maps")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(charcoal.opacity(0.7))
                .clipShape(Capsule())
                .padding(8)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func openInAppleMaps(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = post.eventLocation ?? post.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About This Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(charcoal)

            Text(post.content)
                .font(.system(size: 15))
                .foregroundColor(charcoal.opacity(0.7))
                .lineSpacing(6)
        }
    }

    private var whosGoingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Who's Going")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)

                Spacer()

                Text("\(attendees.count) \(attendees.count == 1 ? "person" : "people")")
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.5))
            }

            // Attendee avatars from fetched data
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(attendees, id: \.id) { attendee in
                        attendeeChip(
                            name: attendee.name ?? "Traveler",
                            avatarUrl: attendee.avatarUrl,
                            isHost: attendee.id == post.authorId
                        )
                    }
                }
            }
        }
    }

    private func attendeeChip(name: String, avatarUrl: String?, isHost: Bool) -> some View {
        HStack(spacing: 8) {
            if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, sunsetRose]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }

            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoal)

            if isHost {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(forestGreen)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(softGray)
        .clipShape(Capsule())
    }

    private var addToCalendarButton: some View {
        Button {
            Task {
                if let eventDate = post.eventDatetime {
                    let success = await EventHelper.shared.addToCalendar(
                        title: post.title,
                        notes: post.content,
                        startDate: eventDate,
                        location: post.eventLocation
                    )
                    if success {
                        showingCalendarAdded = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingCalendarAdded = false
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showingCalendarAdded ? "checkmark.circle.fill" : "calendar.badge.plus")
                    .font(.system(size: 18))
                Text(showingCalendarAdded ? "Added to Calendar" : "Add to Calendar")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(showingCalendarAdded ? forestGreen : .purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(showingCalendarAdded ? forestGreen.opacity(0.1) : Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(showingCalendarAdded)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            HStack(spacing: 12) {
                // Group Chat button
                Button {
                    showingGroupChat = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(burntOrange)
                        .frame(width: 52, height: 52)
                        .background(Color.clear)
                        .overlay(
                            Circle()
                                .stroke(burntOrange, lineWidth: 2)
                        )
                }

                // Join Button
                Button {
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
                        // Reload attendees list
                        loadAttendees()
                    }
                } label: {
                    Text(post.isAttendingEvent == true ? "Joined" : "Join Activity")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(joinButtonBackground)
                        .clipShape(Capsule())
                        .shadow(color: (post.isAttendingEvent == true ? charcoal : forestGreen).opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    @ViewBuilder
    private var joinButtonBackground: some View {
        if post.isAttendingEvent == true {
            charcoal
        } else {
            LinearGradient(
                gradient: Gradient(colors: [forestGreen, skyBlue]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Actions

    private func shareEvent() {
        let text = "\(post.title) - Join me on Drift!"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
