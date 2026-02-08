//
//  EventsJoinedSheet.swift
//  Drift
//
//  Sheet showing events the current user has joined as an attendee.
//

import SwiftUI
import DriftBackend
import Auth

struct EventsJoinedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var communityManager = CommunityManager.shared

    @State private var isLoading = true
    @State private var selectedPost: CommunityPost? = nil

    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let burntOrange = Color("BurntOrange")

    var body: some View {
        NavigationStack {
            ZStack {
                softGray.ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading events...")
                            .font(.system(size: 14))
                            .foregroundColor(inkSub)
                            .padding(.top, 8)
                        Spacer()
                    } else if communityManager.joinedEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 48))
                                .foregroundColor(inkSub)
                            Text("No events joined yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(inkSub)
                            Text("Join events in the Community tab to see them here!")
                                .font(.system(size: 14))
                                .foregroundColor(inkSub.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(communityManager.joinedEvents) { post in
                                JoinedEventCard(post: post)
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Events Joined")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        if !communityManager.joinedEvents.isEmpty {
                            Text("\(communityManager.joinedEvents.count) event\(communityManager.joinedEvents.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundColor(inkSub)
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(charcoalColor)
                }
            }
            .onAppear {
                loadEvents()
            }
        }
        .sheet(item: $selectedPost) { post in
            EventDetailSheet(initialPost: post)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private func loadEvents() {
        isLoading = true
        Task {
            do {
                try await communityManager.fetchJoinedEvents()
            } catch {
                print("Failed to load joined events: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Joined Event Card

private struct JoinedEventCard: View {
    let post: CommunityPost

    @StateObject private var communityManager = CommunityManager.shared

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")

    private var hasUnread: Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return false }
        let key = "eventChatLastRead_\(userId.uuidString)_\(post.id.uuidString)"
        let lastRead = UserDefaults.standard.object(forKey: key) as? Date
        // If never read, consider unread
        return lastRead == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Type Badge
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("EVENT")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                // Unread dot
                if hasUnread {
                    Circle()
                        .fill(burntOrange)
                        .frame(width: 10, height: 10)
                }

                // Time ago
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(post.timeAgo)
                        .font(.system(size: 12))
                }
                .foregroundColor(charcoal.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Title
            Text(post.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(charcoal)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            // Event details (date & location)
            VStack(alignment: .leading, spacing: 4) {
                if let dateStr = post.formattedEventDate {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateStr)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(charcoal.opacity(0.6))
                }

                if let location = post.eventLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                        Text(location)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(charcoal.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Divider
            Rectangle()
                .fill(softGray)
                .frame(height: 1)

            // Footer
            HStack {
                // Attendees
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                    Text("\(post.currentAttendees ?? 0)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.5))

                Spacer()

                // Host name
                if let authorName = post.author?.name {
                    HStack(spacing: 4) {
                        Text("Hosted by")
                            .font(.system(size: 12))
                            .foregroundColor(charcoal.opacity(0.4))
                        Text(authorName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(charcoal.opacity(0.6))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoal.opacity(0.3))
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    EventsJoinedSheet()
}
