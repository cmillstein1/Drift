//
//  EventDetailSheet.swift
//  Drift
//
//  Event detail sheet with hero image design
//

import SwiftUI
import UIKit
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
    @State private var showingEditEventSheet: Bool = false
    @State private var attendees: [UserProfile] = []
    @State private var pendingRequests: [UserProfile] = []
    @State private var hasPendingRequest: Bool = false
    @State private var cityLocation: String? = nil
    @State private var showReportSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

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

    /// Share button: show for public events, or when current user is the host (for private events).
    private var canShowShareEventButton: Bool {
        if post.eventPrivacy?.isPrivate == true {
            return isCurrentUserHost
        }
        return true
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
        .sheet(isPresented: $showingEditEventSheet) {
            CreateCommunityPostSheet(existingPost: post)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(
                targetName: post.author?.name ?? "Unknown",
                targetUserId: post.authorId,
                post: post
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Event?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                isDeleting = true
                Task {
                    do {
                        try await communityManager.deletePost(post.id)
                        dismiss()
                    } catch {
                        print("Failed to delete event: \(error)")
                    }
                    isDeleting = false
                }
            }
        } message: {
            Text("This event will be permanently deleted. This action cannot be undone.")
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

    private let heroHeight: CGFloat = 280

    private var heroImageSection: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView).minY
            let isOverscrolling = minY > 0
            let stretchHeight = isOverscrolling ? heroHeight + minY : heroHeight
            let offsetY = isOverscrolling ? -minY : 0

            ZStack(alignment: .top) {
                // Hero Image — stretches when overscrolling
                heroImage
                    .frame(width: geo.size.width, height: stretchHeight)
                    .clipped()

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.2), .black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: stretchHeight)

                // Top controls
                HStack {
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

                    if canShowShareEventButton {
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

                    Menu {
                        Button {
                            showReportSheet = true
                        } label: {
                            Label("Report", systemImage: "flag")
                        }

                        if isCurrentUserHost {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete Event", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoal)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

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
                .frame(height: stretchHeight)
            }
            .offset(y: offsetY)
        }
        .frame(height: heroHeight)
    }

    @ViewBuilder
    private var heroImage: some View {
        if let imageUrl = post.images.first, let url = URL(string: imageUrl) {
            CachedAsyncImage(url: url) { phase in
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
                burntOrange.opacity(0.35),
                sunsetRose.opacity(0.25),
                warmWhite
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "tent.fill")
                .font(.system(size: 56))
                .foregroundColor(burntOrange.opacity(0.25))
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

            // Photo attribution
            imageAttributionSection
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
            if let avatarUrl = user.primaryDisplayPhotoUrl, let url = URL(string: avatarUrl) {
                CachedAsyncImage(url: url) { image in
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
        HStack(alignment: .top, spacing: 16) {
            // Date & Time Card
            eventInfoCard(
                icon: "calendar",
                iconGradient: [burntOrange.opacity(0.1), sunsetRose.opacity(0.1)],
                iconColor: burntOrange,
                label: "DATE & TIME",
                title: post.formattedEventDate ?? "TBD",
                subtitle: "2 hours"
            )
            .frame(maxWidth: .infinity)

            // Attendees Card
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [forestGreen.opacity(0.1), skyBlue.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        Image(systemName: canSeePrivateDetails ? "person.2" : "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(forestGreen)
                    }
                    .padding(.bottom, 12)
                    Text("ATTENDEES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(charcoal.opacity(0.5))
                        .tracking(0.5)
                        .padding(.bottom, 6)
                    if canSeePrivateDetails {
                        if let max = post.maxAttendees, max > 0 {
                            Text("\(nonHostAttendees.count) joined")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(charcoal)
                                .padding(.bottom, 8)
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [forestGreen, skyBlue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: geometry.size.width * attendeeProgress, height: 8)
                                }
                            }
                            .frame(height: 8)
                        } else {
                            Text("\(nonHostAttendees.count) joined")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(charcoal)
                        }
                    } else {
                        Text("Hidden")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(charcoal.opacity(0.5))
                        Text("Join to see")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(charcoal.opacity(0.6))
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(20)
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [forestGreen.opacity(0.05), .clear]),
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .offset(x: 20, y: -20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
        }
        .frame(height: 180)
    }

    private func eventInfoCard(
        icon: String,
        iconGradient: [Color],
        iconColor: Color,
        label: String,
        title: String,
        subtitle: String
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: iconGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .padding(.bottom, 12)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(charcoal.opacity(0.5))
                    .tracking(0.5)
                    .padding(.bottom, 6)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(charcoal)
                    .padding(.bottom, 2)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoal.opacity(0.6))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(20)
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [burntOrange.opacity(0.05), .clear]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                ))
                .frame(width: 80, height: 80)
                .blur(radius: 20)
                .offset(x: 20, y: -20)
        }
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
    }

    private var locationCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                            .shadow(color: burntOrange.opacity(0.2), radius: 8, x: 0, y: 4)
                        Image(systemName: "mappin")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Location")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoal)
                }
                Text(post.eventLocation ?? "Location TBD")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)
                HStack(spacing: 8) {
                    Circle()
                        .fill(burntOrange.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Text(post.isAttendingEvent == true
                         ? (post.eventExactLocation ?? "Exact location shared")
                         : "Exact location shared after joining")
                        .font(.system(size: 14))
                        .foregroundColor(charcoal.opacity(0.6))
                }
                if let lat = post.eventLatitude, let lng = post.eventLongitude {
                    eventMapPreview(latitude: lat, longitude: lng)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [burntOrange.opacity(0.05), .clear]),
                    startPoint: .bottomTrailing,
                    endPoint: .topLeading
                ))
                .frame(width: 128, height: 128)
                .blur(radius: 30)
                .offset(x: 40, y: 40)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
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
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [burntOrange, sunsetRose]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 4, height: 24)
                Text("About This Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoal)
            }
            Text(post.content)
                .font(.system(size: 15))
                .foregroundColor(charcoal.opacity(0.7))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var imageAttributionSection: some View {
        if let name = post.imageAttributionName, !name.isEmpty,
           let urlString = post.imageAttributionUrl, !urlString.isEmpty,
           let url = URL(string: urlString) {
            HStack(spacing: 4) {
                Text("Photo by")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(charcoal.opacity(0.5))
                Link(destination: url) {
                    Text(name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(charcoal.opacity(0.7))
                        .underline()
                }
                Text("on")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(charcoal.opacity(0.5))
                Link(destination: URL(string: "https://unsplash.com")!) {
                    Text("Unsplash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(charcoal.opacity(0.7))
                        .underline()
                }
            }
            .frame(maxWidth: .infinity)
        } else if post.images.first?.lowercased().contains("unsplash") == true,
                  let url = URL(string: "https://unsplash.com") {
            HStack(spacing: 4) {
                Text("Photo by")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(charcoal.opacity(0.5))
                Link(destination: url) {
                    Text("Unsplash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(charcoal.opacity(0.7))
                        .underline()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var whosGoingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [forestGreen, skyBlue]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 4, height: 24)
                    Text("Who's Going")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(charcoal)
                }
                Spacer()
                Text("\(attendees.count) \(attendees.count == 1 ? "person" : "people")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal.opacity(0.6))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], alignment: .leading, spacing: 12) {
                ForEach(attendees, id: \.id) { attendee in
                    attendeeCard(
                        name: attendee.name ?? "Traveler",
                        avatarUrl: attendee.primaryDisplayPhotoUrl,
                        isHost: attendee.id == post.authorId
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func attendeeCard(name: String, avatarUrl: String?, isHost: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 40, height: 40)
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
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                }
                if isHost {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(forestGreen)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
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
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(burntOrange)
                            .frame(width: 48, height: 48)
                            .background(Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(burntOrange, lineWidth: 2)
                            )
                    }
                } else {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .background(Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }

                // Edit Event (host) or Join / Leave button
                if isCurrentUserHost {
                    Button {
                        showingEditEventSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                            Text("Edit Event")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: burntOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                } else {
                    Button {
                        Task {
                            if post.isAttendingEvent == true || isCurrentUserAttending {
                                try? await communityManager.leaveEvent(post.id)
                                EventHelper.shared.cancelEventReminder(eventId: post.id)
                                loadAttendees()
                            } else if hasPendingRequest {
                                try? await communityManager.cancelJoinRequest(post.id)
                                hasPendingRequest = false
                            } else if post.eventPrivacy?.isPrivate == true {
                                try? await communityManager.requestToJoinEvent(post.id)
                                hasPendingRequest = true
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
                            loadAttendees()
                        }
                    } label: {
                        Text(joinButtonText)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(joinButtonBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: joinButtonShadowColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isJoinDisabled)
                }
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

        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
                  let rootVC = window.rootViewController else { return }
            var top = rootVC
            while let presented = top.presentedViewController { top = presented }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            top.present(activityVC, animated: true)
        }
    }
}
