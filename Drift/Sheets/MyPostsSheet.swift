//
//  MyPostsSheet.swift
//  Drift
//
//  Sheet showing the current user's community posts with interaction indicators.
//

import SwiftUI
import DriftBackend

struct MyPostsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var communityManager = CommunityManager.shared

    @State private var isLoading = true
    @State private var selectedPost: CommunityPost? = nil

    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")

    var body: some View {
        NavigationStack {
            ZStack {
                softGray.ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your posts...")
                            .font(.system(size: 14))
                            .foregroundColor(inkSub)
                            .padding(.top, 8)
                        Spacer()
                    } else if communityManager.myPosts.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(inkSub)
                            Text("No posts yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(inkSub)
                            Text("Create your first event or help request in the Community tab!")
                                .font(.system(size: 14))
                                .foregroundColor(inkSub.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(communityManager.myPosts) { post in
                                MyPostCard(post: post)
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
                        Text("My Posts")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        if !communityManager.myPosts.isEmpty {
                            Text("\(communityManager.myPosts.count) post\(communityManager.myPosts.count == 1 ? "" : "s")")
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
                loadPosts()
                communityManager.markMyPostsAsViewed()
            }
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
    }

    private func loadPosts() {
        isLoading = true
        Task {
            do {
                try await communityManager.fetchMyPosts()
            } catch {
                print("Failed to load my posts: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - My Post Card

private struct MyPostCard: View {
    let post: CommunityPost

    private let charcoal = Color("Charcoal")
    private let softGray = Color("SoftGray")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")

    private var typeIcon: String {
        post.type == .event ? "calendar" : "wrench.and.screwdriver"
    }

    private var typeLabel: String {
        post.type == .event ? "EVENT" : "HELP"
    }

    private var typeColor: Color {
        post.type == .event ? Color.purple : burntOrange
    }

    private var hasNewInteractions: Bool {
        if post.type == .event {
            return (post.pendingRequestCount ?? 0) > 0
        } else {
            return post.replyCount > 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Type Badge
                HStack(spacing: 6) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 12))
                    Text(typeLabel)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(typeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(typeColor.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

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

            // Content preview
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(charcoal.opacity(0.7))
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Divider
            Rectangle()
                .fill(softGray)
                .frame(height: 1)

            // Footer with interaction indicators
            HStack {
                // Stats
                HStack(spacing: 16) {
                    // Replies
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                        Text("\(post.replyCount)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoal.opacity(0.5))

                    // Likes
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 14))
                        Text("\(post.likeCount)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoal.opacity(0.5))

                    // Event-specific: attendees
                    if post.type == .event {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 14))
                            Text("\(post.currentAttendees ?? 0)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(charcoal.opacity(0.5))
                    }
                }

                Spacer()

                // Interaction indicators
                if post.type == .event, let pendingCount = post.pendingRequestCount, pendingCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.clock")
                            .font(.system(size: 12))
                        Text("\(pendingCount) request\(pendingCount == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(burntOrange)
                    .clipShape(Capsule())
                } else if post.type == .help {
                    if post.isSolved == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Solved")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(forestGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(forestGreen.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoal.opacity(0.3))
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
    MyPostsSheet()
}
