//
//  CommunityPostDetailSheet.swift
//  Drift
//
//  Unified detail sheet for community posts (Events & Help)
//

import SwiftUI
import DriftBackend
import Auth

struct CommunityPostDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let initialPost: CommunityPost

    @StateObject private var communityManager = CommunityManager.shared
    @State private var replyText: String = ""
    @State private var showingCalendarAdded: Bool = false
    @State private var showReportSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @FocusState private var isReplyFocused: Bool
    @State private var zoomedPhotoIndex: Int? = nil

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

    // Check if current user is the post owner
    private var isCurrentUserOwner: Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }
        return post.authorId == currentUserId
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            scrollableContent
            replyInputSection
        }
        .background(softGray)
        .onTapGesture {
            isReplyFocused = false
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
        .alert("Delete Post?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                isDeleting = true
                Task {
                    do {
                        try await communityManager.deletePost(post.id)
                        dismiss()
                    } catch {
                        print("Failed to delete post: \(error)")
                    }
                    isDeleting = false
                }
            }
        } message: {
            Text("This post will be permanently deleted. This action cannot be undone.")
        }
        .fullScreenCover(isPresented: Binding(
            get: { zoomedPhotoIndex != nil },
            set: { if !$0 { zoomedPhotoIndex = nil } }
        )) {
            let urls = post.images.compactMap { URL(string: $0) }
            DiscoverZoomablePhotoView(
                imageURLs: urls,
                initialIndex: min(zoomedPhotoIndex ?? 0, max(urls.count - 1, 0)),
                onDismiss: { zoomedPhotoIndex = nil }
            )
        }
        .onAppear {
            Task {
                try? await communityManager.fetchReplies(for: initialPost.id)
            }
        }
    }

    // MARK: - Header Section (category tag + close, then title)

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                typeBadge
                Spacer()

                // 3-dot menu
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }

                    if isCurrentUserOwner {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(charcoal)
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                }

                closeButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text(post.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(charcoal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .background(softGray)
    }

    private var typeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: post.type == .event ? "calendar" : (post.helpCategory?.icon ?? "wrench.and.screwdriver"))
                .font(.system(size: 12))

            if post.type == .help, let category = post.helpCategory {
                Text(category.displayName)
                    .font(.system(size: 12, weight: .semibold))
            } else if post.type == .event {
                Text("Event")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(typeBadgeBackgroundColor)
        .clipShape(Capsule())
    }

    private var typeBadgeBackgroundColor: Color {
        if post.type == .event { return .purple }
        guard let category = post.helpCategory else { return burntOrange }
        if case .solar = category {
            return Color(red: 0.82, green: 0.48, blue: 0.08)
        }
        return (Color(category.color) ?? burntOrange)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(charcoal)
                .frame(width: 36, height: 36)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = post.author?.primaryDisplayPhotoUrl, let url = URL(string: avatarUrl) {
            CachedAsyncImage(url: url) { image in
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

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                originalPostCard

                if post.type == .event {
                    eventInfoSection
                }

                repliesSection
            }
            .padding(.bottom, 100)
        }
        .background(softGray)
    }

    /// Light gray rounded card: author row, divider, Details + content, then Like + Replies pills
    private var originalPostCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                avatarView
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author?.name ?? "Anonymous")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(charcoal)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(post.timeAgo)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(charcoal.opacity(0.5))
                }
                Spacer()
            }
            .padding(20)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 8) {
                Text("Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)
                Text(post.content)
                    .font(.system(size: 15))
                    .foregroundColor(charcoal.opacity(0.8))
                    .lineSpacing(4)

                if !post.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(post.images.enumerated()), id: \.offset) { index, imageUrl in
                                if let url = URL(string: imageUrl) {
                                    CachedAsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.15)
                                    }
                                    .frame(width: 200, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .onTapGesture { zoomedPhotoIndex = index }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)

            HStack(spacing: 12) {
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
                    .foregroundColor(post.isLikedByCurrentUser == true ? forestGreen : charcoal.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                    Text("\(post.replyCount) replies")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

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
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var eventInfoSection: some View {
        VStack(spacing: 12) {
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
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replies (\(communityManager.currentReplies.count))")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(charcoal)
                .padding(.horizontal, 20)

            if communityManager.currentReplies.isEmpty {
                Text("No replies yet. Be the first to respond!")
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(communityManager.currentReplies.sorted { $0.likeCount > $1.likeCount }) { reply in
                    CommunityReplyCard(reply: reply, postAuthorId: post.authorId)
                }
                .padding(.horizontal, 20)
            }
        }
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
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(softGray.ignoresSafeArea(edges: .bottom))
    }

    private var replyTextField: some View {
        TextField("Add your reply...", text: $replyText)
            .font(.system(size: 15))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
            .focused($isReplyFocused)
    }

    private var sendButton: some View {
        Button {
            handleSendReply()
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 18))
                .foregroundColor(replyText.trimmingCharacters(in: .whitespaces).isEmpty ? charcoal.opacity(0.4) : .white)
                .frame(width: 48, height: 48)
                .background(sendButtonBackground)
                .clipShape(Circle())
        }
        .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @ViewBuilder
    private var sendButtonBackground: some View {
        if replyText.trimmingCharacters(in: .whitespaces).isEmpty {
            Color.gray.opacity(0.2)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                avatarView
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(reply.author?.name ?? "Anonymous")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(charcoal)
                        if reply.isExpertReply {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Expert")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(forestGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(forestGreen.opacity(0.12))
                            .clipShape(Capsule())
                        }
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
                Spacer()
            }

            Text(reply.content)
                .font(.system(size: 14))
                .foregroundColor(charcoal.opacity(0.85))
                .lineSpacing(4)
                .padding(.top, 10)

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
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 12)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = reply.author?.primaryDisplayPhotoUrl, let url = URL(string: avatarUrl) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderCircle
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            placeholderCircle
        }
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 40, height: 40)
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
