//
//  CommunityPostDetailSheet.swift
//  Drift
//
//  Unified detail sheet for community posts (Events & Help)
//

import SwiftUI
import DriftBackend

struct CommunityPostDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let initialPost: CommunityPost

    @StateObject private var communityManager = CommunityManager.shared
    @State private var replyText: String = ""
    @State private var showingCalendarAdded: Bool = false
    @FocusState private var isReplyFocused: Bool

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    // Get the current post from manager (for live updates) or fallback to initial
    private var post: CommunityPost {
        communityManager.posts.first(where: { $0.id == initialPost.id }) ?? initialPost
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            scrollableContent
            replyInputSection
        }
        .background(warmWhite)
        .onTapGesture {
            isReplyFocused = false
        }
        .onAppear {
            Task {
                try? await communityManager.fetchReplies(for: initialPost.id)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            headerTopRow
            titleView
            userInfoRow
        }
        .background(warmWhite)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var headerTopRow: some View {
        HStack {
            typeBadge
            Spacer()
            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var typeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: post.type == .event ? "calendar" : "wrench.and.screwdriver")
                .font(.system(size: 12))

            if post.type == .help, let category = post.helpCategory {
                Text(category.displayName)
                    .font(.system(size: 12, weight: .semibold))
            } else if post.type == .event {
                Text("Event")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundColor(post.type == .event ? .purple : burntOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background((post.type == .event ? Color.purple : burntOrange).opacity(0.1))
        .clipShape(Capsule())
    }

    private var closeButton: some View {
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

    private var titleView: some View {
        Text(post.title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(charcoal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 12)
    }

    private var userInfoRow: some View {
        HStack(spacing: 12) {
            avatarView
            userDetails
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = post.author?.avatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                avatarGradient
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            avatarGradient
        }
    }

    private var avatarGradient: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 40, height: 40)
    }

    private var userDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(post.author?.name ?? "Anonymous")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(post.timeAgo)
                    .font(.system(size: 12))
            }
            .foregroundColor(charcoal.opacity(0.5))
        }
    }

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                detailsSection

                // Event-specific info
                if post.type == .event {
                    eventInfoSection
                }

                engagementStats
                repliesSection
            }
        }
        .background(warmWhite)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)

            Text(post.content)
                .font(.system(size: 15))
                .foregroundColor(charcoal.opacity(0.7))
                .lineSpacing(6)
        }
        .padding(24)
    }

    @ViewBuilder
    private var eventInfoSection: some View {
        VStack(spacing: 12) {
            // Date/Time
            if let formattedDate = post.formattedEventDate {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("When")
                            .font(.system(size: 12))
                            .foregroundColor(charcoal.opacity(0.5))
                        Text(formattedDate)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoal)
                    }

                    Spacer()
                }
            }

            // Location
            if let location = post.eventLocation {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Where")
                            .font(.system(size: 12))
                            .foregroundColor(charcoal.opacity(0.5))
                        Text(location)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoal)
                    }

                    Spacer()
                }
            }

            // Attendees
            if let max = post.maxAttendees {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spots")
                            .font(.system(size: 12))
                            .foregroundColor(charcoal.opacity(0.5))
                        Text("\(post.currentAttendees ?? 0) / \(max) attending")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoal)
                    }

                    Spacer()

                    // Join button
                    Button {
                        Task {
                            if post.isAttendingEvent == true {
                                try? await communityManager.leaveEvent(post.id)
                                // Cancel the reminder notification
                                EventHelper.shared.cancelEventReminder(eventId: post.id)
                            } else {
                                try? await communityManager.joinEvent(post.id)
                                // Schedule a reminder 1 hour before
                                if let eventDate = post.eventDatetime {
                                    await EventHelper.shared.scheduleEventReminder(
                                        eventId: post.id,
                                        eventTitle: post.title,
                                        eventDate: eventDate
                                    )
                                }
                            }
                        }
                    } label: {
                        Text(post.isAttendingEvent == true ? "Leave" : "Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(post.isAttendingEvent == true ? charcoal : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(post.isAttendingEvent == true ? Color.clear : Color.purple)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(post.isAttendingEvent == true ? charcoal : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }

            // Add to Calendar button
            if let eventDate = post.eventDatetime, eventDate > Date() {
                Button {
                    Task {
                        let success = await EventHelper.shared.addToCalendar(
                            title: post.title,
                            notes: post.content,
                            startDate: eventDate,
                            location: post.eventLocation
                        )
                        if success {
                            showingCalendarAdded = true
                            // Hide the confirmation after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingCalendarAdded = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showingCalendarAdded ? "checkmark.circle.fill" : "calendar.badge.plus")
                            .font(.system(size: 16))
                        Text(showingCalendarAdded ? "Added to Calendar" : "Add to Calendar")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(showingCalendarAdded ? .green : .purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(showingCalendarAdded ? Color.green.opacity(0.1) : Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(showingCalendarAdded)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private var engagementStats: some View {
        HStack(spacing: 16) {
            // Like button
            Button {
                Task {
                    try? await communityManager.togglePostLike(post.id)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: post.isLikedByCurrentUser == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 14))
                    Text("\(post.likeCount)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(post.isLikedByCurrentUser == true ? forestGreen : charcoal.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(post.isLikedByCurrentUser == true ? forestGreen.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(Capsule())
            }

            // Replies count
            HStack(spacing: 8) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14))
                Text("\(post.replyCount) replies")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(charcoal.opacity(0.6))

            Spacer()

            // Solved badge for help posts
            if post.type == .help && post.isSolved == true {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Solved")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(forestGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(forestGreen.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Replies (\(communityManager.currentReplies.count))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            if communityManager.currentReplies.isEmpty {
                Text("No replies yet. Be the first to respond!")
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.5))
                    .padding(.horizontal, 24)
            } else {
                ForEach(communityManager.currentReplies.sorted { $0.likeCount > $1.likeCount }) { reply in
                    CommunityReplyCard(reply: reply, postAuthorId: post.authorId)
                        .padding(.horizontal, 24)
                }
            }
        }
        .padding(.bottom, 100)
    }

    // MARK: - Reply Input Section

    private var replyInputSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            HStack(spacing: 12) {
                replyTextField
                sendButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    private var replyTextField: some View {
        TextField("Add a reply...", text: $replyText)
            .font(.system(size: 15))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(softGray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isReplyFocused ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .focused($isReplyFocused)
    }

    private var sendButton: some View {
        Button {
            handleSendReply()
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(sendButtonBackground)
                .clipShape(Circle())
        }
        .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @ViewBuilder
    private var sendButtonBackground: some View {
        if replyText.trimmingCharacters(in: .whitespaces).isEmpty {
            Color.gray.opacity(0.3)
        } else {
            LinearGradient(
                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func handleSendReply() {
        guard !replyText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let content = replyText
        replyText = ""
        isReplyFocused = false

        Task {
            _ = try? await communityManager.createReply(postId: post.id, content: content)
        }
    }
}

// MARK: - Community Reply Card

struct CommunityReplyCard: View {
    let reply: PostReply
    let postAuthorId: UUID

    @StateObject private var communityManager = CommunityManager.shared

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            replyHeader
            messageText
            actionButtons
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var replyHeader: some View {
        HStack(spacing: 12) {
            avatarView
            userInfoView
            Spacer()
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = reply.author?.avatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderCircle
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            placeholderCircle
        }
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 36, height: 36)
    }

    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(reply.author?.name ?? "Anonymous")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)

                // Expert badge
                if reply.isExpertReply {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Expert")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(forestGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(forestGreen.opacity(0.1))
                    .clipShape(Capsule())
                }

                // OP badge if reply is from post author
                if reply.authorId == postAuthorId {
                    Text("OP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(burntOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(burntOrange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Text(reply.timeAgo)
                .font(.system(size: 12))
                .foregroundColor(charcoal.opacity(0.5))
        }
    }

    private var messageText: some View {
        Text(reply.content)
            .font(.system(size: 14))
            .foregroundColor(charcoal.opacity(0.7))
            .lineSpacing(4)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    try? await communityManager.toggleReplyLike(reply.id)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: reply.isLikedByCurrentUser == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 12))
                    Text("Helpful (\(reply.likeCount))")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(reply.isLikedByCurrentUser == true ? forestGreen : charcoal.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(reply.isLikedByCurrentUser == true ? forestGreen.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    CommunityPostDetailSheet(
        initialPost: CommunityPost(
            id: UUID(),
            authorId: UUID(),
            type: .help,
            title: "Inverter keeps tripping?",
            content: "I have a 2000W Renogy inverter that trips every time I turn on my blender. Battery bank is full. Anyone seen this?",
            helpCategory: .electrical
        )
    )
}
