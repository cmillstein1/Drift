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
    case market = "Market"

    var icon: String {
        switch self {
        case .all: return ""
        case .events: return "tent"
        case .buildHelp: return "wrench.and.screwdriver"
        case .market: return "bag"
        }
    }
}

// MARK: - Post Type Enum

enum CommunityPostType: String {
    case event
    case help
    case market
    
    var badgeColor: Color {
        switch self {
        case .event: return .purple
        case .help: return Color("BurntOrange")
        case .market: return Color("SkyBlue")
        }
    }
    
    var icon: String {
        switch self {
        case .event: return "tent"
        case .help: return "wrench.and.screwdriver"
        case .market: return "bag"
        }
    }
}

// MARK: - Post Model

struct CommunityPost: Identifiable {
    let id: UUID
    let type: CommunityPostType
    let authorName: String
    let authorAvatar: String?
    let timeAgo: String
    let location: String?
    let category: String?
    let title: String
    let content: String
    let likes: Int?
    let replies: Int?
    let price: String?
}

// MARK: - Main Screen

struct CommunityScreen: View {
    @State private var selectedFilter: CommunityFilter = .all
    @State private var showCreateSheet: Bool = false
    @State private var selectedActivity: Activity? = nil
    @State private var selectedHelpPost: CommunityPost? = nil
    @State private var selectedMarketPost: CommunityPost? = nil
    @StateObject private var activityManager = ActivityManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private func loadData() {
        Task {
            do {
                try await activityManager.fetchActivities(category: nil)
                await activityManager.subscribeToActivities()
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
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPosts) { post in
                            CommunityPostCard(post: post)
                                .onTapGesture {
                                    switch post.type {
                                    case .event:
                                        // Convert CommunityPost to Activity for detail view
                                        selectedActivity = activityFromPost(post)
                                    case .help:
                                        // Show help detail sheet
                                        selectedHelpPost = post
                                    case .market:
                                        // Show marketplace detail sheet
                                        selectedMarketPost = post
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, LayoutConstants.tabBarBottomPadding + 20)
                }

                // Empty State
                if filteredPosts.isEmpty {
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 32)
                }
            }

        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCommunityPostSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailSheet(activity: activity)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $selectedHelpPost) { post in
            BuilderHelpDetailSheet(post: post)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedMarketPost) { post in
            MarketplaceDetailSheet(post: post)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // Convert CommunityPost to Activity for detail view
    private func activityFromPost(_ post: CommunityPost) -> Activity {
        Activity(
            id: post.id,
            hostId: UUID(), // Placeholder
            title: post.title,
            description: post.content,
            category: .social, // Default category for community events
            location: post.location ?? "Location TBD",
            exactLocation: nil,
            imageUrl: nil,
            startsAt: Date().addingTimeInterval(86400), // Placeholder: tomorrow
            durationMinutes: 60,
            maxAttendees: 10,
            currentAttendees: post.likes ?? 0,
            host: UserProfile(
                id: UUID(),
                name: post.authorName,
                avatarUrl: post.authorAvatar,
                verified: false,
                lifestyle: .vanLife,
                interests: [],
                lookingFor: .friends
            )
        )
    }

    // Filtered posts based on selected filter
    private var filteredPosts: [CommunityPost] {
        let allPosts = samplePosts
        switch selectedFilter {
        case .all:
            return allPosts
        case .events:
            return allPosts.filter { $0.type == .event }
        case .buildHelp:
            return allPosts.filter { $0.type == .help }
        case .market:
            return allPosts.filter { $0.type == .market }
        }
    }

    // Sample data
    private var samplePosts: [CommunityPost] {
        [
            CommunityPost(
                id: UUID(),
                type: .event,
                authorName: "Sarah Mitchell",
                authorAvatar: nil,
                timeAgo: "Just now",
                location: "Nearby",
                category: nil,
                title: "Morning Yoga Flow",
                content: "Anyone interested in a 30min flow tomorrow morning? I have extra mats!",
                likes: 12,
                replies: nil,
                price: nil
            ),
            CommunityPost(
                id: UUID(),
                type: .help,
                authorName: "Dave Builder",
                authorAvatar: nil,
                timeAgo: "1h ago",
                location: nil,
                category: "Electrical",
                title: "Inverter keeps tripping?",
                content: "I have a 2000W Renogy inverter that trips every time I turn on my blender. Battery bank is full. Anyone seen this?",
                likes: nil,
                replies: 5,
                price: nil
            ),
            CommunityPost(
                id: UUID(),
                type: .market,
                authorName: "Mike Seller",
                authorAvatar: nil,
                timeAgo: "2h ago",
                location: nil,
                category: "For Sale",
                title: "Dometic CFX3 55 Fridge",
                content: "Barely used, 55L capacity. Works great. Selling because I upgraded to a larger unit.",
                likes: nil,
                replies: nil,
                price: "$450"
            ),
            CommunityPost(
                id: UUID(),
                type: .event,
                authorName: "Jordan Park",
                authorAvatar: nil,
                timeAgo: "3h ago",
                location: "Big Sur, CA",
                category: nil,
                title: "Weekend Surf Session",
                content: "Heading to the beach this Saturday. Anyone want to join? Beginner friendly!",
                likes: 8,
                replies: nil,
                price: nil
            ),
            CommunityPost(
                id: UUID(),
                type: .help,
                authorName: "Emily Watts",
                authorAvatar: nil,
                timeAgo: "5h ago",
                location: nil,
                category: "Solar",
                title: "Best solar panel angle?",
                content: "Installing 400W panels on my roof. What angle works best for year-round use?",
                likes: nil,
                replies: 12,
                price: nil
            ),
        ]
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

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    private var avatarBackgroundColor: Color {
        switch post.type {
        case .event: return Color.purple.opacity(0.15)
        case .help: return burntOrange.opacity(0.15)
        case .market: return skyBlue.opacity(0.15)
        }
    }
    
    private var avatarIconColor: Color {
        switch post.type {
        case .event: return Color.purple
        case .help: return burntOrange
        case .market: return skyBlue
        }
    }
    
    private var badgeBackgroundColor: Color {
        switch post.type {
        case .event: return Color.purple.opacity(0.1)
        case .help: return burntOrange.opacity(0.1)
        case .market: return skyBlue.opacity(0.1)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post Header
            HStack(spacing: 12) {
                // Avatar with type-specific color
                ZStack {
                    Circle()
                        .fill(avatarBackgroundColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 18))
                        .foregroundColor(avatarIconColor)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
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
                    Image(systemName: post.type.icon)
                        .font(.system(size: 12))
                    Text(post.type.rawValue.uppercased())
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
                if post.location != nil || post.category != nil {
                    HStack(spacing: 8) {
                        if let location = post.location {
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
                        
                        if let category = post.category {
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(charcoal.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(softGray)
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
                    if let replies = post.replies {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 14))
                            Text("\(replies)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(charcoal.opacity(0.4))
                    }
                    
                    if let likes = post.likes {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 14))
                            Text("\(likes)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(charcoal.opacity(0.4))
                    }
                }
                
                Spacer()
                
                // Action Button
                switch post.type {
                case .event:
                    Button {
                        // Join action
                    } label: {
                        Text("Join Event")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(charcoal)
                            .clipShape(Capsule())
                    }
                    
                case .help:
                    Button {
                        // Help action
                    } label: {
                        Text("Offer Help")
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
                    
                case .market:
                    if let price = post.price {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign")
                                .font(.system(size: 14))
                            Text(price.replacingOccurrences(of: "$", with: ""))
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(forestGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(forestGreen.opacity(0.1))
                        .clipShape(Capsule())
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
    @State private var selectedType: CommunityPostType? = .event
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var eventPrivacy: String = "public"
    @State private var showPrivacyDetails: Bool = false
    @State private var category: String = ""
    @State private var condition: String = ""
    @State private var price: String = ""
    @State private var location: String = ""
    @State private var eventDate: Date = Date()
    @State private var eventTime: Date = Date()
    
    // Market photo upload
    @State private var marketPhotos: [Int: Data] = [:] // Index -> Image data
    @State private var showingImagePicker: Bool = false
    @State private var selectedPhotoIndex: Int = 0

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    private var isFormValid: Bool {
        selectedType != nil && !title.trimmingCharacters(in: .whitespaces).isEmpty && !details.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Create Post")
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

            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Post Type Selection
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
                            PostTypeCard(
                                type: .market,
                                isSelected: selectedType == .market,
                                onTap: { selectedType = .market }
                            )
                        }
                    }

                    // Photos (Market only) - Above Title
                    if selectedType == .market {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 14))
                                Text("Photos")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(charcoal)

                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { index in
                                    MarketPhotoSquare(
                                        index: index,
                                        imageData: marketPhotos[index],
                                        onTap: {
                                            selectedPhotoIndex = index
                                            showingImagePicker = true
                                        },
                                        onRemove: {
                                            marketPhotos.removeValue(forKey: index)
                                        }
                                    )
                                }
                            }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            MarketImagePicker(imageData: Binding(
                                get: { marketPhotos[selectedPhotoIndex] },
                                set: { marketPhotos[selectedPhotoIndex] = $0 }
                            ))
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
                    } else if selectedType == .market {
                        marketFields
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
                    dismiss()
                } label: {
                    Text("Post")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFormValid ? .white : Color.gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? burntOrange : Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                .disabled(!isFormValid)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(warmWhite)
        }
        .background(warmWhite)
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

                TextField("Where will this happen?", text: $location)
                    .font(.system(size: 16))
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
                        title: "Public",
                        description: "Anyone can see and join",
                        icon: "globe",
                        iconColor: forestGreen,
                        isSelected: eventPrivacy == "public",
                        accentColor: burntOrange,
                        onTap: { eventPrivacy = "public" }
                    )

                    PrivacyOptionButton(
                        title: "Private",
                        description: "Only invited people can see",
                        icon: "lock",
                        iconColor: charcoal,
                        isSelected: eventPrivacy == "private",
                        accentColor: burntOrange,
                        onTap: { eventPrivacy = "private" }
                    )

                    PrivacyOptionButton(
                        title: "Invite Only",
                        description: "You approve each request",
                        icon: "person.2",
                        iconColor: burntOrange,
                        isSelected: eventPrivacy == "invite-only",
                        accentColor: burntOrange,
                        onTap: { eventPrivacy = "invite-only" }
                    )
                }

                // Privacy Details
                if showPrivacyDetails {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(skyBlue)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Public:** Your event appears in the community feed and can be discovered by all users.")
                            Text("**Private:** Only people you invite can see and join the event.")
                            Text("**Invite Only:** Event is visible but you manually approve each join request.")
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
                Button("Electrical & Solar") { category = "Electrical & Solar" }
                Button("Plumbing & Water") { category = "Plumbing & Water" }
                Button("Insulation") { category = "Insulation" }
                Button("Woodwork & Furniture") { category = "Woodwork & Furniture" }
                Button("Mechanical & Engine") { category = "Mechanical & Engine" }
                Button("Other") { category = "Other" }
            } label: {
                HStack {
                    Text(category.isEmpty ? "Select a category..." : category)
                        .font(.system(size: 16))
                        .foregroundColor(category.isEmpty ? Color.gray.opacity(0.5) : charcoal)
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

    // MARK: - Market Fields

    @ViewBuilder
    private var marketFields: some View {
        VStack(spacing: 16) {
            // Price
            VStack(alignment: .leading, spacing: 8) {
                Text("Price")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoal)

                HStack(spacing: 8) {
                    Image(systemName: "dollarsign")
                        .font(.system(size: 16))
                        .foregroundColor(charcoal.opacity(0.4))

                    TextField("0.00", text: $price)
                        .font(.system(size: 16))
                        .keyboardType(.decimalPad)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
            }

            // Condition
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoal)

                Menu {
                    Button("New") { condition = "New" }
                    Button("Like New") { condition = "Like New" }
                    Button("Good") { condition = "Good" }
                    Button("Fair") { condition = "Fair" }
                } label: {
                    HStack {
                        Text(condition.isEmpty ? "Select condition..." : condition)
                            .font(.system(size: 16))
                            .foregroundColor(condition.isEmpty ? Color.gray.opacity(0.5) : charcoal)
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
}

// MARK: - Market Photo Square

struct MarketPhotoSquare: View {
    let index: Int
    let imageData: Data?
    let onTap: () -> Void
    let onRemove: () -> Void
    
    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            
            ZStack {
                if let data = imageData, let uiImage = UIImage(data: data) {
                    // Photo exists
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            // Remove button
                            Button(action: onRemove) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            .offset(x: 6, y: -6),
                            alignment: .topTrailing
                        )
                } else {
                    // Empty slot
                    Button(action: onTap) {
                        VStack(spacing: 6) {
                            Image(systemName: index == 0 ? "camera.fill" : "plus")
                                .font(.system(size: index == 0 ? 24 : 20, weight: .medium))
                                .foregroundColor(index == 0 ? burntOrange : charcoal.opacity(0.4))
                            
                            if index == 0 {
                                Text("Add")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(charcoal.opacity(0.6))
                            }
                        }
                        .frame(width: size, height: size)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index == 0 ? burntOrange : Color.gray.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: index == 0 ? [] : [6])
                                )
                        )
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Market Image Picker

struct MarketImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MarketImagePicker
        
        init(_ parent: MarketImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.imageData = editedImage.jpegData(compressionQuality: 0.8)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.imageData = originalImage.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
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
        case .market: return Color("SkyBlue")
        }
    }

    private var title: String {
        switch type {
        case .event: return "Event"
        case .help: return "Help"
        case .market: return "Market"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
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
