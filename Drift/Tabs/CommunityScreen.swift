//
//  CommunityScreen.swift
//  Drift
//
//  Community feed combining activities, builder help, and marketplace
//

import SwiftUI
import DriftBackend

// MARK: - Filter Enum

enum CommunityFilter: String, CaseIterable {
    case all = "All"
    case events = "Events"
    case buildHelp = "Help"

    var icon: String {
        switch self {
        case .all: return ""
        case .events: return "tent"
        case .buildHelp: return "wrench.and.screwdriver"
        }
    }

    var postType: CommunityPostType? {
        switch self {
        case .all: return nil
        case .events: return .event
        case .buildHelp: return .help
        }
    }
}

// MARK: - Main Screen

struct CommunityScreen: View {
    @State private var selectedFilter: CommunityFilter = .all
    @State private var showCreateSheet: Bool = false
    @State private var selectedPost: CommunityPost? = nil
    @StateObject private var communityManager = CommunityManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private func loadData() {
        Task {
            do {
                try await communityManager.fetchPosts(type: selectedFilter.postType)
                await communityManager.subscribeToPosts()
            } catch {
                print("Failed to load community data: \(error)")
            }
        }
    }

    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 20) {
                    // Title row with + button
                    HStack {
                        Text("Community")
                            //.font(.system(size: 32, weight: .bold))
                            .font(.campfire(.regular, size: 24))
                            .foregroundColor(charcoal)
                        
                        Spacer()
                        
                        // Create Post Button
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: burntOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Tab Navigation - Pill style with sliding indicator
                    CommunitySegmentedControl(
                        selectedFilter: $selectedFilter
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(softGray)

                // Posts Feed
                List {
                    if filteredPosts.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray.opacity(0.4))
                            }

                            Text("No posts yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(charcoal)

                            Text("Be the first to share something with the community!")
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 400)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredPosts) { post in
                            Group {
                                if post.type == .event {
                                    EventCard(post: post)
                                } else {
                                    CommunityPostCard(post: post)
                                }
                            }
                            .onTapGesture {
                                selectedPost = post
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable {
                    do {
                        try await communityManager.fetchPosts(type: selectedFilter.postType)
                        print("[CommunityScreen] Refresh completed, posts count: \(communityManager.posts.count)")
                    } catch {
                        print("[CommunityScreen] Refresh failed: \(error)")
                    }
                }
            }

        }
        .onAppear {
            loadData()
            setupAttendeeRealtime()
        }
        .onDisappear {
            Task {
                await communityManager.unsubscribeFromAttendees()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCommunityPostSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedPost) { post in
            if post.type == .event {
                EventDetailSheet(initialPost: post)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            } else {
                CommunityPostDetailSheet(initialPost: post)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            loadData()
        }
    }

    private func setupAttendeeRealtime() {
        Task {
            await communityManager.subscribeToMyAttendeeChanges()
        }
    }

    // Filtered posts based on selected filter
    private var filteredPosts: [CommunityPost] {
        // Filter is applied at fetch time, so just return all posts
        communityManager.posts
    }
}

// MARK: - Community Segmented Control

struct CommunitySegmentedControl: View {
    @Binding var selectedFilter: CommunityFilter
    @Namespace private var animation
    
    private let charcoal = Color("Charcoal")
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(CommunityFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        if !filter.icon.isEmpty {
                            Image(systemName: filter.icon)
                                .font(.system(size: 14))
                        }
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedFilter == filter ? .white : charcoal.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedFilter == filter {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(charcoal)
                                .matchedGeometryEffect(id: "communitySegment", in: animation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Community Post Card

struct CommunityPostCard: View {
    let post: CommunityPost
    @StateObject private var communityManager = CommunityManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    private var avatarBackgroundColor: Color {
        switch post.type {
        case .event: return Color.purple.opacity(0.15)
        case .help: return burntOrange.opacity(0.15)
        }
    }

    private var avatarIconColor: Color {
        switch post.type {
        case .event: return Color.purple
        case .help: return burntOrange
        }
    }

    private var badgeBackgroundColor: Color {
        switch post.type {
        case .event: return Color.purple.opacity(0.1)
        case .help: return burntOrange.opacity(0.1)
        }
    }

    private var typeIcon: String {
        switch post.type {
        case .event: return "calendar"
        case .help: return "wrench.and.screwdriver"
        }
    }

    private var typeLabel: String {
        switch post.type {
        case .event: return "EVENT"
        case .help: return "HELP"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post Header
            HStack(spacing: 12) {
                // Avatar with type-specific color
                if let avatarUrl = post.author?.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(avatarIconColor)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(avatarBackgroundColor)
                            .frame(width: 44, height: 44)

                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(avatarIconColor)
                    }
                }

                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author?.name ?? "Anonymous")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(charcoal)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(post.timeAgo)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(charcoal.opacity(0.5))
                }

                Spacer()

                // Type Badge
                HStack(spacing: 6) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 12))
                    Text(typeLabel)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(avatarIconColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(badgeBackgroundColor)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoal)
                    .lineSpacing(2)

                Text(post.content)
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.7))
                    .lineSpacing(4)
                    .lineLimit(2)

                // Metadata Tags
                if post.eventLocation != nil || post.helpCategory != nil {
                    HStack(spacing: 8) {
                        if let location = post.eventLocation {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text(location)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(charcoal.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(softGray)
                            .clipShape(Capsule())
                        }

                        if let category = post.helpCategory {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 10))
                                Text(category.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(category.color))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(category.color).opacity(0.1))
                            .clipShape(Capsule())
                        }

                        // Event date badge
                        if let formattedDate = post.formattedEventDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(formattedDate)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Post Footer
            Rectangle()
                .fill(softGray)
                .frame(height: 1)

            HStack {
                // Engagement Stats
                HStack(spacing: 20) {
                    if post.replyCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 14))
                            Text("\(post.replyCount)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(charcoal.opacity(0.4))
                    }

                    Button {
                        Task {
                            try? await communityManager.togglePostLike(post.id)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: post.isLikedByCurrentUser == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 14))
                            Text("\(post.likeCount)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(post.isLikedByCurrentUser == true ? burntOrange : charcoal.opacity(0.4))
                    }
                }

                Spacer()

                // Action Button
                switch post.type {
                case .event:
                    Button {
                        Task {
                            if post.isAttendingEvent == true {
                                try? await communityManager.leaveEvent(post.id)
                            } else {
                                try? await communityManager.joinEvent(post.id)
                            }
                        }
                    } label: {
                        Text(post.isAttendingEvent == true ? "Joined" : "Join Event")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(post.isAttendingEvent == true ? charcoal : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(post.isAttendingEvent == true ? Color.clear : charcoal)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(charcoal, lineWidth: post.isAttendingEvent == true ? 2 : 0)
                            )
                    }

                case .help:
                    if post.isSolved == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Solved")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(forestGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(forestGreen.opacity(0.1))
                        .clipShape(Capsule())
                    } else {
                        Text("View")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                Capsule()
                                    .stroke(burntOrange, lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Create Post Sheet

struct CreateCommunityPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// When non-nil, the sheet is in edit mode for this event post: pre-filled and shows "Update" instead of "Post".
    var existingPost: CommunityPost? = nil
    @StateObject private var communityManager = CommunityManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedType: CommunityPostType? = .event
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var eventPrivacy: EventPrivacy = .public
    @State private var showPrivacyDetails: Bool = false
    @State private var isDatingActivity: Bool = false
    @State private var selectedCategory: HelpCategory? = nil
    @State private var location: String = ""
    @State private var eventLatitude: Double? = nil
    @State private var eventLongitude: Double? = nil
    @State private var showLocationPicker: Bool = false
    @State private var maxAttendees: String = ""
    @State private var eventDate: Date = Date()
    @State private var eventTime: Date = Date()
    @State private var isSubmitting: Bool = false

    private var isEditMode: Bool { existingPost != nil && existingPost?.type == .event }

    /// Only show "Dating activity" option when user has dating (or both) enabled; friends-only users do not see it.
    private var hasDatingEnabled: Bool {
        guard let lookingFor = profileManager.currentProfile?.lookingFor else { return false }
        return lookingFor == .dating || lookingFor == .both
    }

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    private var isFormValid: Bool {
        guard let type = selectedType else { return false }
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasDetails = !details.trimmingCharacters(in: .whitespaces).isEmpty

        if type == .help {
            return hasTitle && hasDetails && selectedCategory != nil
        }
        return hasTitle && hasDetails
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text(isEditMode ? "Edit Event" : "Create Post")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(charcoal)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoal)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .onAppear { prefillIfEditing() }

            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Post Type Selection - hide when editing
                    if !isEditMode {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Post Type *")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoal)

                            HStack(spacing: 12) {
                                PostTypeCard(
                                    type: .event,
                                    isSelected: selectedType == .event,
                                    onTap: { selectedType = .event }
                                )
                                PostTypeCard(
                                    type: .help,
                                    isSelected: selectedType == .help,
                                    onTap: { selectedType = .help }
                                )
                            }
                        }
                    }

                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoal)

                        TextField("What's this about?", text: $title)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }

                    // Details Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14))
                            Text("Details")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(charcoal)

                        TextField("Tell people more...", text: $details, axis: .vertical)
                            .font(.system(size: 16))
                            .lineLimit(4...8)
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }

                    // Conditional Fields
                    if selectedType == .event {
                        eventFields
                    } else if selectedType == .help {
                        helpFields
                    }
                }
                .padding(24)
            }

            // Footer with Post Button
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)

                Button {
                    submitPost()
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSubmitting ? (isEditMode ? "Updating..." : "Posting...") : (isEditMode ? "Update" : "Post"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(isFormValid && !isSubmitting ? .white : Color.gray.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isFormValid && !isSubmitting ? burntOrange : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
                }
                .disabled(!isFormValid || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(warmWhite)
        }
        .background(warmWhite)
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(
                locationName: $location,
                latitude: $eventLatitude,
                longitude: $eventLongitude
            )
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func prefillIfEditing() {
        guard let p = existingPost, p.type == .event else { return }
        selectedType = .event
        title = p.title
        details = p.content
        eventPrivacy = p.eventPrivacy ?? .public
        isDatingActivity = p.isDatingEvent ?? false
        location = p.eventLocation ?? ""
        eventLatitude = p.eventLatitude
        eventLongitude = p.eventLongitude
        maxAttendees = p.maxAttendees.map { String($0) } ?? ""
        if let dt = p.eventDatetime {
            let cal = Calendar.current
            eventDate = cal.startOfDay(for: dt)
            eventTime = dt
        }
    }

    private func submitPost() {
        guard let type = selectedType, isFormValid else { return }
        isSubmitting = true

        Task {
            do {
                if type == .event {
                    // Combine date and time
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: eventTime)
                    var combined = DateComponents()
                    combined.year = dateComponents.year
                    combined.month = dateComponents.month
                    combined.day = dateComponents.day
                    combined.hour = timeComponents.hour
                    combined.minute = timeComponents.minute
                    let eventDatetime = calendar.date(from: combined) ?? eventDate

                    if let postId = existingPost?.id, existingPost?.type == .event {
                        try await communityManager.updateEventPost(
                            postId,
                            title: title.trimmingCharacters(in: .whitespaces),
                            content: details.trimmingCharacters(in: .whitespaces),
                            datetime: eventDatetime,
                            location: location.isEmpty ? nil : location,
                            latitude: eventLatitude,
                            longitude: eventLongitude,
                            maxAttendees: Int(maxAttendees),
                            privacy: eventPrivacy,
                            isDatingEvent: isDatingActivity
                        )
                    } else {
                        _ = try await communityManager.createEventPost(
                            title: title.trimmingCharacters(in: .whitespaces),
                            content: details.trimmingCharacters(in: .whitespaces),
                            datetime: eventDatetime,
                            location: location.isEmpty ? nil : location,
                            latitude: eventLatitude,
                            longitude: eventLongitude,
                            maxAttendees: Int(maxAttendees),
                            privacy: eventPrivacy,
                            images: [],
                            isDatingEvent: isDatingActivity
                        )
                    }
                } else {
                    _ = try await communityManager.createHelpPost(
                        title: title.trimmingCharacters(in: .whitespaces),
                        content: details.trimmingCharacters(in: .whitespaces),
                        category: selectedCategory ?? .other,
                        images: []
                    )
                }
                dismiss()
            } catch {
                print("Failed to create post: \(error)")
                isSubmitting = false
            }
        }
    }

    // MARK: - Event Fields

    @ViewBuilder
    private var eventFields: some View {
        VStack(spacing: 16) {
            // Date & Time Row
            HStack(spacing: 12) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                        Text("Date *")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoal)

                    DatePicker("", selection: $eventDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }

                // Time
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text("Time")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoal)

                    DatePicker("", selection: $eventTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }
            }

            // Location
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                        .font(.system(size: 14))
                    Text("Location")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal)

                Button {
                    showLocationPicker = true
                } label: {
                    HStack {
                        if location.isEmpty {
                            Text("Select location on map")
                                .font(.system(size: 16))
                                .foregroundColor(charcoal.opacity(0.4))
                        } else {
                            Text(location)
                                .font(.system(size: 16))
                                .foregroundColor(charcoal)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "map")
                            .font(.system(size: 16))
                            .foregroundColor(burntOrange)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(eventLatitude != nil ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
            }

            // Max Attendees
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                    Text("Max Attendees")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal)

                TextField("Leave empty for unlimited", text: $maxAttendees)
                    .font(.system(size: 16))
                    .keyboardType(.numberPad)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }

            // Privacy Settings
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "lock")
                            .font(.system(size: 14))
                        Text("Privacy Settings")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(charcoal)

                    Spacer()

                    Button {
                        withAnimation {
                            showPrivacyDetails.toggle()
                        }
                    } label: {
                        Text(showPrivacyDetails ? "Hide" : "Learn more")
                            .font(.system(size: 14))
                            .foregroundColor(burntOrange)
                    }
                }

                // Privacy Options
                VStack(spacing: 12) {
                    PrivacyOptionButton(
                        title: EventPrivacy.public.displayName,
                        description: EventPrivacy.public.description,
                        icon: EventPrivacy.public.icon,
                        iconColor: forestGreen,
                        isSelected: eventPrivacy == .public,
                        accentColor: burntOrange,
                        onTap: { eventPrivacy = .public }
                    )

                    PrivacyOptionButton(
                        title: EventPrivacy.private.displayName,
                        description: EventPrivacy.private.description,
                        icon: EventPrivacy.private.icon,
                        iconColor: charcoal,
                        isSelected: eventPrivacy == .private,
                        accentColor: burntOrange,
                        onTap: { eventPrivacy = .private }
                    )
                }

                // Privacy Details
                if showPrivacyDetails {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(skyBlue)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Public:** Anyone can see all details and join directly.")
                            Text("**Private:** Date and description visible, but location and attendees hidden until approved. You approve each join request.")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(charcoal.opacity(0.7))
                    }
                    .padding(12)
                    .background(skyBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
            )

            // Dating activity (only for users with dating or both; friends-only never see this)
            if hasDatingEnabled {
                HStack(spacing: 12) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 16))
                        .foregroundColor(burntOrange)
                    Text("Dating activity?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoal)
                    Spacer()
                    Toggle("", isOn: $isDatingActivity)
                        .toggleStyle(SwitchToggleStyle(tint: burntOrange))
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Help Fields

    @ViewBuilder
    private var helpFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoal)

            Menu {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    if let category = selectedCategory {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(category.color))
                        Text(category.displayName)
                            .font(.system(size: 16))
                            .foregroundColor(charcoal)
                    } else {
                        Text("Select a category...")
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(charcoal.opacity(0.4))
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }

}

// MARK: - Privacy Option Button

struct PrivacyOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    private let charcoal = Color("Charcoal")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(charcoal)

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(charcoal.opacity(0.6))
                }

                Spacer()

                if isSelected {
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 20, height: 20)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? accentColor.opacity(0.05) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - Post Type Card

struct PostTypeCard: View {
    let type: CommunityPostType
    let isSelected: Bool
    let onTap: () -> Void

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    private var iconColor: Color {
        switch type {
        case .event: return .purple
        case .help: return burntOrange
        }
    }

    private var icon: String {
        switch type {
        case .event: return "calendar"
        case .help: return "wrench.and.screwdriver"
        }
    }

    private var title: String {
        switch type {
        case .event: return "Event"
        case .help: return "Help"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? iconColor : charcoal.opacity(0.6))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? charcoal : charcoal.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? burntOrange.opacity(0.05) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

#Preview {
    CommunityScreen()
}
