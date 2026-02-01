//
//  MyFriendsSheet.swift
//  Drift
//
//  Sheet showing connection requests (accept/deny) and all friends with search; tap a friend to start or open a message.
//

import SwiftUI
import DriftBackend
import Auth

struct MyFriendsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var messagingManager = MessagingManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared

    /// When set, selecting a friend dismisses the sheet and passes the conversation to the parent (e.g. Messages tab) to present the message.
    var onSelectConversation: ((Conversation) -> Void)? = nil

    @State private var searchText = ""
    @State private var isLoading = true
    @State private var selectedProfileToView: UserProfile?
    @State private var selectedRequestForProfile: Friend?

    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let burntOrange = Color("BurntOrange")

    private var currentUserId: UUID? {
        supabaseManager.currentUser?.id
    }

    private var pendingRequests: [Friend] {
        friendsManager.pendingRequests
    }

    private var filteredFriends: [Friend] {
        guard let currentUserId = currentUserId else { return [] }
        return friendsManager.friends.filter { friend in
            guard let profile = friend.otherProfile(currentUserId: currentUserId) else { return false }
            return searchText.isEmpty || profile.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                softGray.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar — matches FriendsGridScreen / app pattern
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(inkSub)
                            .font(.system(size: 16))

                        TextField("Search friends...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    // Connection requests — people who want to connect (accept/deny)
                    if !pendingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Connection requests")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                Text("\(pendingRequests.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(burntOrange)
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                ForEach(pendingRequests) { request in
                                    FriendRequestCard(
                                        friendRequest: request,
                                        onAccept: { handleAcceptRequest(request) },
                                        onDecline: { handleDeclineRequest(request) },
                                        onViewProfile: {
                                            selectedRequestForProfile = request
                                            selectedProfileToView = request.requesterProfile
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading friends...")
                            .font(.system(size: 14))
                            .foregroundColor(inkSub)
                            .padding(.top, 8)
                        Spacer()
                    } else if filteredFriends.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundColor(inkSub)
                            Text(searchText.isEmpty ? "No friends yet" : "No friends found")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(inkSub)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredFriends) { friend in
                                FriendRow(
                                    friend: friend,
                                    currentUserId: currentUserId
                                ) {
                                    selectFriendAndOpenMessage(friend)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        handleUnfriend(friend)
                                    } label: {
                                        Label("Unfriend", systemImage: "person.badge.minus")
                                    }
                                }
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
                        Text("My Friends")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        if !friendsManager.friends.isEmpty {
                            Text("\(friendsManager.friends.count) friend\(friendsManager.friends.count == 1 ? "" : "s")")
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
                loadFriends()
                Task {
                    try? await friendsManager.fetchPendingRequests(silent: true)
                }
            }
        }
        .fullScreenCover(item: $selectedProfileToView) { profile in
            ProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedProfileToView != nil },
                    set: { if !$0 { selectedProfileToView = nil; selectedRequestForProfile = nil } }
                ),
                onLike: {
                    if let request = selectedRequestForProfile {
                        handleAcceptRequest(request)
                    }
                    selectedProfileToView = nil
                    selectedRequestForProfile = nil
                },
                onPass: {
                    if let request = selectedRequestForProfile {
                        handleDeclineRequest(request)
                    }
                    selectedProfileToView = nil
                    selectedRequestForProfile = nil
                }
            )
        }
    }

    private func handleAcceptRequest(_ request: Friend) {
        Task {
            do {
                _ = try await friendsManager.respondToFriendRequest(request.id, accept: true)
            } catch {
                print("Failed to accept request: \(error)")
            }
        }
    }

    private func handleDeclineRequest(_ request: Friend) {
        Task {
            do {
                try await friendsManager.respondToFriendRequest(request.id, accept: false)
            } catch {
                print("Failed to decline request: \(error)")
            }
        }
    }

    private func handleUnfriend(_ friend: Friend) {
        Task {
            do {
                try await friendsManager.removeFriend(friend.id)
            } catch {
                print("Failed to unfriend: \(error)")
            }
        }
    }

    private func loadFriends() {
        isLoading = true
        Task {
            do {
                try await friendsManager.fetchFriends()
            } catch {
                print("Failed to load friends: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func selectFriendAndOpenMessage(_ friend: Friend) {
        guard let currentUserId = currentUserId else { return }
        let friendUserId = friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId

        Task {
            do {
                let conversation = try await messagingManager.fetchOrCreateConversation(
                    with: friendUserId,
                    type: .friends
                )
                try await messagingManager.fetchConversations()
                await MainActor.run {
                    if let onSelect = onSelectConversation {
                        onSelect(conversation)
                        dismiss()
                    }
                }
            } catch {
                print("Failed to create conversation: \(error)")
            }
        }
    }
}

#Preview {
    MyFriendsSheet()
}
