//
//  CommunityScreen.swift
//  Drift
//
//  Community feed combining activities, builder help, and marketplace
//

import SwiftUI
import DriftBackend

enum CommunityFilter: String, CaseIterable {
    case all = "All Posts"
    case events = "Events"
    case buildHelp = "Build Help"
    case market = "Market"

    var icon: String {
        switch self {
        case .all: return ""
        case .events: return "tent"
        case .buildHelp: return "wrench.and.screwdriver"
        case .market: return "storefront"
        }
    }

    var iconColor: Color {
        switch self {
        case .all: return .clear
        case .events: return .purple
        case .buildHelp: return .orange
        case .market: return .blue
        }
    }
}

struct CommunityScreen: View {
    @State private var selectedFilter: CommunityFilter = .all
    @State private var showCreateSheet: Bool = false
    @StateObject private var activityManager = ActivityManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared

    // Colors from HTML design
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37) // #FF5E5E
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let bgCanvas = Color(red: 0.98, green: 0.98, blue: 0.98) // #FAFAFA

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
            bgCanvas.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Community")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(inkMain)

                        Spacer()

                        Button {
                            // Filter action
                        } label: {
                            Text("Filter")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(coralPrimary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CommunityFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 8)
                }
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(height: 1),
                    alignment: .bottom
                )

                // Feed content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Sample posts based on filter
                        ForEach(filteredPosts) { post in
                            CommunityPostCard(post: post)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, LayoutConstants.tabBarBottomPadding)
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(coralPrimary)
                            .clipShape(Circle())
                            .shadow(color: coralPrimary.opacity(0.4), radius: 12, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, LayoutConstants.tabBarBottomPadding)
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
    }

    // Filtered posts based on selected filter
    private var filteredPosts: [CommunityPost] {
        // For now, return sample data. This would be replaced with actual data from managers
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

    // Sample data for demonstration
    private var samplePosts: [CommunityPost] {
        [
            CommunityPost(
                id: UUID(),
                type: .event,
                authorName: "Sarah Mitchell",
                authorAvatar: nil,
                timeAgo: "Just now",
                subtitle: "Nearby",
                title: "Morning Yoga Flow",
                content: "Anyone interested in a 30min flow tomorrow morning? I have extra mats!",
                imageUrl: nil,
                attendeeCount: 3,
                replyCount: nil
            ),
            CommunityPost(
                id: UUID(),
                type: .help,
                authorName: "Dave Builder",
                authorAvatar: nil,
                timeAgo: "1h ago",
                subtitle: "Electrical",
                title: "Inverter keeps tripping?",
                content: "I have a 2000W Renogy inverter that trips every time I turn on my blender. Battery bank is full. Anyone seen this?",
                imageUrl: nil,
                attendeeCount: nil,
                replyCount: 5
            ),
            CommunityPost(
                id: UUID(),
                type: .market,
                authorName: "Mike Seller",
                authorAvatar: nil,
                timeAgo: "2h ago",
                subtitle: "For Sale",
                title: "Dometic CFX3 55 Fridge",
                content: "Barely used, 55L capacity. Works great. Selling because I upgraded to a larger unit. $650 OBO",
                imageUrl: nil,
                attendeeCount: nil,
                replyCount: 8
            )
        ]
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: CommunityFilter
    let isSelected: Bool
    let onTap: () -> Void

    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if !filter.icon.isEmpty {
                    Image(systemName: filter.icon)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : filter.iconColor)
                }
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(isSelected ? .white : Color.gray.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? inkMain : Color.white
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Community Post Model

enum CommunityPostType {
    case event
    case help
    case market
}

struct CommunityPost: Identifiable {
    let id: UUID
    let type: CommunityPostType
    let authorName: String
    let authorAvatar: String?
    let timeAgo: String
    let subtitle: String
    let title: String
    let content: String
    let imageUrl: String?
    let attendeeCount: Int?
    let replyCount: Int?
}

// MARK: - Community Post Card

struct CommunityPostCard: View {
    let post: CommunityPost

    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)

    private var typeTag: (text: String, bgColor: Color, textColor: Color) {
        switch post.type {
        case .event:
            return ("EVENT", Color.purple.opacity(0.1), Color.purple)
        case .help:
            return ("HELP", Color.orange.opacity(0.1), Color.orange)
        case .market:
            return ("MARKET", Color.blue.opacity(0.1), Color.blue)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: Avatar, name, time, tag
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )

                // Name and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(inkMain)

                    Text("\(post.timeAgo) • \(post.subtitle)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Type tag
                Text(typeTag.text)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(typeTag.textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeTag.bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Image (if event type)
            if post.type == .event, let _ = post.imageUrl {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 160)
            }

            // Title
            Text(post.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(inkMain)

            // Body
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(Color.gray.opacity(0.8))
                .lineSpacing(4)

            // Footer actions
            HStack {
                if post.type == .event {
                    // Attendees indicator
                    if let count = post.attendeeCount {
                        HStack(spacing: -8) {
                            ForEach(0..<min(count, 3), id: \.self) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                            if count > 3 {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("+\(count - 3)")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.gray)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                        }
                    }

                    Spacer()

                    Button {
                        // Join action
                    } label: {
                        Text("Join In")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(inkMain)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if post.type == .help {
                    // Reply count
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 14))
                        Text("\(post.replyCount ?? 0) Replies")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Button {
                        // Help action
                    } label: {
                        Text("Help Out")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(coralPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(coralPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    // Market - replies
                    if let count = post.replyCount {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                            Text("\(count) Replies")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    Button {
                        // Contact action
                    } label: {
                        Text("Contact")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(inkMain)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Create Post Sheet

struct CreateCommunityPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: CommunityPostType = .event
    @State private var title: String = ""
    @State private var details: String = ""

    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Type selector
                HStack(spacing: 12) {
                    PostTypeButton(
                        type: .event,
                        isSelected: selectedType == .event,
                        onTap: { selectedType = .event }
                    )
                    PostTypeButton(
                        type: .help,
                        isSelected: selectedType == .help,
                        onTap: { selectedType = .help }
                    )
                    PostTypeButton(
                        type: .market,
                        isSelected: selectedType == .market,
                        onTap: { selectedType = .market }
                    )
                }
                .padding(.horizontal, 24)

                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    TextField("What's this about?", text: $title)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                // Body field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    TextField("Tell people more...", text: $details, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(5...10)
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                Spacer()

                // Post button
                Button {
                    // Create post
                    dismiss()
                } label: {
                    Text("Post")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(title.isEmpty ? Color.gray : coralPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.top, 24)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

struct PostTypeButton: View {
    let type: CommunityPostType
    let isSelected: Bool
    let onTap: () -> Void

    private var config: (icon: String, title: String, color: Color) {
        switch type {
        case .event:
            return ("tent", "Event", .purple)
        case .help:
            return ("wrench.and.screwdriver", "Help", .orange)
        case .market:
            return ("storefront", "Market", .blue)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: config.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : config.color)

                Text(config.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? config.color : Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    CommunityScreen()
}
