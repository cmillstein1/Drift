//
//  MyFriendsSheet.swift
//  Drift
//
//  Sheet showing all friends with search; tap a friend to start or open a message.
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

    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)

    private var currentUserId: UUID? {
        supabaseManager.currentUser?.id
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
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredFriends) { friend in
                                    FriendRow(
                                        friend: friend,
                                        currentUserId: currentUserId
                                    ) {
                                        selectFriendAndOpenMessage(friend)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 24)
                        }
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
