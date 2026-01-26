//
//  EventDetailSheet.swift
//  Drift
//
//  Event detail sheet with hero image design
//

import SwiftUI
import MapKit
import CoreLocation
import DriftBackend
import Auth

struct EventDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let initialPost: CommunityPost

    @StateObject private var communityManager = CommunityManager.shared
    @State private var showingCalendarAdded: Bool = false
    @State private var showingGroupChat: Bool = false
    @State private var attendees: [UserProfile] = []
    @State private var pendingRequests: [UserProfile] = []
    @State private var hasPendingRequest: Bool = false
    @State private var cityLocation: String? = nil

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

    // Check if current user is the host
    private var isCurrentUserHost: Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }
        return post.authorId == currentUserId
    }

    // Attendees excluding the host
    private var nonHostAttendees: [UserProfile] {
        attendees.filter { $0.id != post.authorId }
    }

    // Check if current user is in the attendees list (more reliable than post.isAttendingEvent)
    private var isCurrentUserAttending: Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }
        return attendees.contains { $0.id == currentUserId }
    }

    // Check if user can see private details (is attending, has pending request, or is host)
    private var canSeePrivateDetails: Bool {
        if post.eventPrivacy == .public {
            return true
        }
        // Host can always see
        if isCurrentUserHost {
            return true
        }
        // Attending users can see (check both post flag and attendees list)
        if post.isAttendingEvent == true || isCurrentUserAttending {
            return true
        }
        return false
    }

    // Check if user can access chat (must be attending or host)
    private var canAccessChat: Bool {
        if isCurrentUserHost {
            return true
        }
        if post.isAttendingEvent == true || isCurrentUserAttending {
            return true
        }
        return false
    }

    private var attendeeProgress: CGFloat {
        guard let max = post.maxAttendees, max > 0 else { return 0 }
        return min(CGFloat(nonHostAttendees.count) / CGFloat(max), 1.0)
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
            loadPendingRequestStatus()
            if isCurrentUserHost {
                loadPendingRequests()
            }
            // Load city for private events
            if post.eventPrivacy?.isPrivate == true && !canSeePrivateDetails {
                loadCityFromCoordinates()
            }
            // Subscribe to realtime attendee changes
            setupAttendeeRealtime()
        }
        .onDisappear {
            Task {
                await communityManager.unsubscribeFromAttendees()
            }
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

    private func loadPendingRequestStatus() {
        Task {
            do {
                hasPendingRequest = try await communityManager.checkPendingRequest(initialPost.id)
            } catch {
                print("Failed to check pending request: \(error)")
            }
        }
    }

    private func loadPendingRequests() {
        Task {
            do {
                pendingRequests = try await communityManager.fetchPendingRequests(initialPost.id)
            } catch {
                print("Failed to load pending requests: \(error)")
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

    private func setupAttendeeRealtime() {
        // Set up callback for attendee changes
        communityManager.onAttendeeChange = { [self] eventId in
            guard eventId == initialPost.id else { return }
            print("[EventDetailSheet] Attendee change detected, refreshing...")
            loadAttendees()
            loadPendingRequestStatus()
            if isCurrentUserHost {
                loadPendingRequests()
            }
        }

        // Subscribe to realtime changes
        Task {
            await communityManager.subscribeToAttendees(eventId: initialPost.id)
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

            // Location Card - hidden for private events unless attending
            if canSeePrivateDetails {
                locationCard
            } else {
                privateLocationCard
            }

            // About Section
            aboutSection

            // Who's Going Section - hidden for private events unless attending
            if canSeePrivateDetails && !attendees.isEmpty {
                whosGoingSection
            }

            // Pending Requests Section - only for host of private events
            if isCurrentUserHost && post.eventPrivacy?.isPrivate == true && !pendingRequests.isEmpty {
                pendingRequestsSection
            }

            // Add to Calendar - only for attendees
            if canSeePrivateDetails, let eventDate = post.eventDatetime, eventDate > Date() {
                addToCalendarButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 120)
    }

    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.clock")
                        .font(.system(size: 16))
                        .foregroundColor(burntOrange)
                    Text("Pending Requests")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoal)
                }

                Spacer()

                Text("\(pendingRequests.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(burntOrange)
                    .clipShape(Capsule())
            }

            ForEach(pendingRequests, id: \.id) { user in
                pendingRequestRow(user: user)
            }
        }
        .padding(16)
        .background(burntOrange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(burntOrange.opacity(0.2), lineWidth: 1)
        )
    }

    private func pendingRequestRow(user: UserProfile) -> some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 44, height: 44)
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
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            }

            // Name
            Text(user.name ?? "Traveler")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(charcoal)

            Spacer()

            // Deny button
            Button {
                Task {
                    try? await communityManager.denyJoinRequest(postId: post.id, userId: user.id)
                    loadPendingRequests()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.4))
                    .clipShape(Circle())
            }

            // Approve button
            Button {
                Task {
                    try? await communityManager.approveJoinRequest(postId: post.id, userId: user.id)
                    loadPendingRequests()
                    loadAttendees()
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(forestGreen)
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var privateLocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange.opacity(0.6), sunsetRose.opacity(0.6)]),
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

                Spacer()

                // Private badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Private")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
            }

            if let city = cityLocation {
                Text(city)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(charcoal)
            } else if post.eventLatitude != nil {
                Text("Loading area...")
                    .font(.system(size: 15))
                    .foregroundColor(charcoal.opacity(0.5))
            }

            Text("Exact location revealed after approval")
                .font(.system(size: 13))
                .foregroundColor(charcoal.opacity(0.4))

            // Zoomed-out map preview for approximate area
            if let lat = post.eventLatitude, let lng = post.eventLongitude {
                privateMapPreview(latitude: lat, longitude: lng)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(softGray)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func privateMapPreview(latitude: Double, longitude: Double) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        // Zoomed out view - ~5km radius
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        return ZStack {
            Map(initialPosition: .region(region), interactionModes: []) {
                // Show a larger, less precise circle instead of exact pin
                MapCircle(center: coordinate, radius: 1500)
                    .foregroundStyle(burntOrange.opacity(0.2))
                    .stroke(burntOrange.opacity(0.5), lineWidth: 2)
            }
            .allowsHitTesting(false)

            // Overlay text
            VStack {
                Spacer()
                Text("Approximate area")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(charcoal.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    Image(systemName: canSeePrivateDetails ? "person.2" : "lock.fill")
                        .font(.system(size: 14))
                    Text("Attendees")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.5))

                if canSeePrivateDetails {
                    if let max = post.maxAttendees, max > 0 {
                        Text("\(nonHostAttendees.count)/\(max) joined")
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
                        Text("\(nonHostAttendees.count) joined")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(charcoal)
                    }
                } else {
                    Text("Hidden")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(charcoal.opacity(0.5))

                    Text("Join to see")
                        .font(.system(size: 12))
                        .foregroundColor(charcoal.opacity(0.4))
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
                // Group Chat button - only for attendees and host
                if canAccessChat {
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
                } else {
                    // Disabled chat button for non-attendees
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.4))
                        .frame(width: 52, height: 52)
                        .background(Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }

                // Join Button
                Button {
                    Task {
                        if post.isAttendingEvent == true || isCurrentUserAttending {
                            // Leave event
                            try? await communityManager.leaveEvent(post.id)
                            EventHelper.shared.cancelEventReminder(eventId: post.id)
                            loadAttendees() // Refresh attendees after leaving
                        } else if hasPendingRequest {
                            // Cancel pending request
                            try? await communityManager.cancelJoinRequest(post.id)
                            hasPendingRequest = false
                        } else if post.eventPrivacy?.isPrivate == true {
                            // Request to join private event
                            try? await communityManager.requestToJoinEvent(post.id)
                            hasPendingRequest = true
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
                        // Reload attendees list
                        loadAttendees()
                    }
                } label: {
                    Text(joinButtonText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(joinButtonBackground)
                        .clipShape(Capsule())
                        .shadow(color: joinButtonShadowColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isJoinDisabled)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    // Check if event is full (exclude host from count)
    private var isEventFull: Bool {
        guard let max = post.maxAttendees, max > 0 else { return false }
        return nonHostAttendees.count >= max
    }

    private var isJoinDisabled: Bool {
        // Host can never leave/join - they're always hosting
        if isCurrentUserHost {
            return true
        }
        // Already attending - can leave (not disabled)
        if post.isAttendingEvent == true || isCurrentUserAttending {
            return false
        }
        // Can't join if full
        if isEventFull {
            return true
        }
        return false
    }

    private var joinButtonText: String {
        if isCurrentUserHost {
            return "You're Hosting"
        } else if post.isAttendingEvent == true || isCurrentUserAttending {
            return "Joined"
        } else if hasPendingRequest {
            return "Requested"
        } else if isEventFull {
            return "Event Full"
        } else if post.eventPrivacy?.isPrivate == true {
            return "Request to Join"
        } else {
            return "Join Activity"
        }
    }

    private var joinButtonShadowColor: Color {
        if isCurrentUserHost {
            return burntOrange
        } else if post.isAttendingEvent == true || isCurrentUserAttending {
            return charcoal
        } else if hasPendingRequest {
            return skyBlue
        } else if isEventFull {
            return Color.gray
        } else {
            return forestGreen
        }
    }

    @ViewBuilder
    private var joinButtonBackground: some View {
        if isCurrentUserHost {
            LinearGradient(
                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if post.isAttendingEvent == true || isCurrentUserAttending {
            charcoal
        } else if hasPendingRequest {
            skyBlue
        } else if isEventFull {
            Color.gray.opacity(0.5)
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
