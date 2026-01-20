//
//  MessagesScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Auth

enum MessageMode {
    case dating
    case friends
}

struct MessagesScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var messagingManager = MessagingManager.shared
    @StateObject private var friendsManager = FriendsManager.shared

    @State private var searchText: String = ""
    @State private var selectedMode: MessageMode = .dating
    @State private var selectedConversation: Conversation? = nil
    @State private var segmentIndex: Int = 0 // Default to dating (index 0)
    @State private var selectedProfileToView: UserProfile? = nil
    @State private var showLikesYouScreen = false

    private var conversations: [Conversation] {
        messagingManager.conversations
    }

    private var pendingFriendRequests: [Friend] {
        friendsManager.pendingRequests
    }

    private var acceptedFriends: [Friend] {
        friendsManager.friends
    }

    // Friends who don't have a conversation yet
    private var friendsWithoutConversation: [Friend] {
        let conversationUserIds = Set(
            filteredConversations.compactMap { $0.otherUser?.id }
        )
        return acceptedFriends.filter { friend in
            guard let currentUserId = supabaseManager.currentUser?.id else { return false }
            let friendUserId = friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId
            return !conversationUserIds.contains(friendUserId)
        }
    }

    private func loadConversations() {
        Task {
            do {
                try await messagingManager.fetchConversations()
                await messagingManager.subscribeToConversations()
            } catch {
                print("Failed to load conversations: \(error)")
            }
        }
    }

    private func loadFriendRequests() {
        Task {
            do {
                try await friendsManager.fetchPendingRequests()
            } catch {
                print("Failed to load friend requests: \(error)")
            }
        }
    }

    private func loadFriends() {
        Task {
            do {
                try await friendsManager.fetchFriends()
            } catch {
                print("Failed to load friends: \(error)")
            }
        }
    }

    private func loadLikesYou() {
        Task {
            do {
                try await friendsManager.fetchPeopleLikedMe()
            } catch {
                print("Failed to load likes: \(error)")
            }
        }
    }

    private func startConversationWithFriend(_ friend: Friend) {
        guard let currentUserId = supabaseManager.currentUser?.id else { return }
        let friendUserId = friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId

        Task {
            do {
                let conversation = try await messagingManager.fetchOrCreateConversation(
                    with: friendUserId,
                    type: .friends
                )
                // Refresh conversations list first
                try await messagingManager.fetchConversations()
                // Then open the conversation
                await MainActor.run {
                    selectedConversation = conversation
                }
            } catch {
                print("Failed to create conversation: \(error)")
            }
        }
    }

    private func handleAcceptRequest(_ request: Friend) {
        Task {
            do {
                _ = try await friendsManager.respondToFriendRequest(request.id, accept: true)
                // Conversations are refreshed inside respondToFriendRequest
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
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private var isDatingEnabled: Bool {
        !supabaseManager.isFriendsOnly()
    }
    
    private var segmentOptions: [SegmentOption] {
        [
            SegmentOption(
                id: 0,
                title: "Dating",
                icon: "heart.fill",
                activeGradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, pink500]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ),
            SegmentOption(
                id: 1,
                title: "Friends",
                icon: "person.2.fill",
                activeGradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        ]
    }
    
    private var filteredConversations: [Conversation] {
        conversations.filter { conv in
            switch selectedMode {
            case .dating:
                return conv.type == .dating
            case .friends:
                return conv.type == .friends
            }
        }
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Dating/Friends Toggle - only show if dating is enabled
                    if isDatingEnabled {
                        SegmentToggle(
                            options: segmentOptions,
                            selectedIndex: Binding(
                                get: { segmentIndex },
                                set: { newIndex in
                                    segmentIndex = newIndex
                                    selectedMode = newIndex == 0 ? .dating : .friends
                                    if newIndex == 0 {
                                        loadLikesYou()
                                    }
                                }
                            )
                        )
                        .frame(maxWidth: 448)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(charcoalColor.opacity(0.4))

                        TextField("Search messages", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // "X people like you" banner (only show in dating mode)
                    if selectedMode == .dating && !friendsManager.peopleLikedMe.isEmpty {
                        LikesYouBanner(
                            count: friendsManager.peopleLikedMe.count,
                            profiles: Array(friendsManager.peopleLikedMe.prefix(3)),
                            onTap: {
                                showLikesYouScreen = true
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else if selectedMode == .dating {
                        Spacer().frame(height: 8)
                    } else {
                        Spacer().frame(height: 8)
                    }

                    // Friend Requests Section (only show in friends mode)
                    if selectedMode == .friends && !pendingFriendRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Friend Requests")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)

                                Text("\(pendingFriendRequests.count)")
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
                                ForEach(pendingFriendRequests) { request in
                                    FriendRequestCard(
                                        friendRequest: request,
                                        onAccept: { handleAcceptRequest(request) },
                                        onDecline: { handleDeclineRequest(request) },
                                        onViewProfile: {
                                            selectedProfileToView = request.requesterProfile
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // Friends without conversation (only in friends mode)
                    if selectedMode == .friends && !friendsWithoutConversation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Friends")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(charcoalColor)
                                .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                ForEach(friendsWithoutConversation) { friend in
                                    FriendRow(
                                        friend: friend,
                                        currentUserId: supabaseManager.currentUser?.id
                                    ) {
                                        startConversationWithFriend(friend)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // Conversations
                    if !filteredConversations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if selectedMode == .friends && (!pendingFriendRequests.isEmpty || !friendsWithoutConversation.isEmpty) {
                                Text("Conversations")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                    .padding(.horizontal, 16)
                            }

                            VStack(spacing: 8) {
                                ForEach(filteredConversations) { conversation in
                                    ConversationRow(
                                        conversation: conversation,
                                        currentUserId: supabaseManager.currentUser?.id
                                    ) {
                                        selectedConversation = conversation
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // Empty State
                    if filteredConversations.isEmpty && friendsWithoutConversation.isEmpty && (selectedMode == .dating || pendingFriendRequests.isEmpty) {
                        VStack(spacing: 8) {
                            Text("No \(selectedMode == .dating ? "dating" : "friends") messages yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor)

                            Text(selectedMode == .dating
                                 ? "Match with someone to start a conversation"
                                 : "Connect with friends to start chatting")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            // Default to friends if dating is not enabled
            if !isDatingEnabled {
                selectedMode = .friends
                segmentIndex = 1
            } else {
                // Load likes when dating is enabled
                loadLikesYou()
            }
            loadConversations()
            loadFriendRequests()
            loadFriends()
        }
        .sheet(isPresented: $showLikesYouScreen) {
            LikesYouScreen()
        }
        .fullScreenCover(item: $selectedConversation) { conversation in
            MessageDetailScreen(
                conversation: conversation,
                onClose: {
                    selectedConversation = nil
                }
            )
        }
        .fullScreenCover(item: $selectedProfileToView) { profile in
            ProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedProfileToView != nil },
                    set: { if !$0 { selectedProfileToView = nil } }
                ),
                onLike: {
                    // Find the request for this profile and accept it
                    if let request = pendingFriendRequests.first(where: { $0.requesterProfile?.id == profile.id }) {
                        handleAcceptRequest(request)
                    }
                    selectedProfileToView = nil
                },
                onPass: {
                    // Find the request for this profile and decline it
                    if let request = pendingFriendRequests.first(where: { $0.requesterProfile?.id == profile.id }) {
                        handleDeclineRequest(request)
                    }
                    selectedProfileToView = nil
                }
            )
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: UUID?
    let onTap: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)

    private var badgeBackground: LinearGradient {
        switch conversation.type {
        case .dating:
            return LinearGradient(
                gradient: Gradient(colors: [burntOrange, pink500]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .friends, .activity:
            return LinearGradient(
                gradient: Gradient(colors: [Color("SkyBlue"), forestGreen]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var badgeIcon: String {
        switch conversation.type {
        case .dating:
            return "heart.fill"
        case .friends, .activity:
            return "person.fill"
        }
    }

    private var hasUnread: Bool {
        guard let userId = currentUserId else { return false }
        return conversation.hasUnreadMessages(for: userId)
    }

    private var displayTime: String {
        guard let updatedAt = conversation.updatedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    AsyncImage(url: URL(string: conversation.avatarUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(conversation.otherUser?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(conversation.otherUser?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                        }
                    }

                    // Match/Friend Badge
                    ZStack {
                        Circle()
                            .fill(badgeBackground)
                            .frame(width: 20, height: 20)

                        Image(systemName: badgeIcon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: -2, y: -2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)

                        Spacer()

                        Text(displayTime)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }

                    Text(conversation.lastMessage?.content ?? "Start a conversation")
                        .font(.system(size: 14))
                        .foregroundColor(hasUnread ? charcoalColor : charcoalColor.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if hasUnread {
                    Circle()
                        .fill(burntOrange)
                        .frame(width: 12, height: 12)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Friend Row (for friends without conversation)

struct FriendRow: View {
    let friend: Friend
    let currentUserId: UUID?
    let onTap: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")

    private var friendProfile: UserProfile? {
        guard let currentUserId = currentUserId else { return nil }
        if friend.requesterId == currentUserId {
            return friend.addresseeProfile
        } else {
            return friend.requesterProfile
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    AsyncImage(url: URL(string: friendProfile?.photos.first ?? friendProfile?.avatarUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [skyBlue, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(friendProfile?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [skyBlue, forestGreen]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(friendProfile?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 56, height: 56)
                        }
                    }

                    // Friend Badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 20, height: 20)

                        Image(systemName: "person.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: -2, y: -2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(friendProfile?.displayName ?? "Friend")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoalColor)

                    Text("Tap to start chatting")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(forestGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Likes You Banner

struct LikesYouBanner: View {
    let count: Int
    let profiles: [UserProfile]
    let onTap: () -> Void

    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoalColor = Color("Charcoal")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Stacked avatars
                HStack(spacing: -12) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        AsyncImage(url: URL(string: profile.photos.first ?? profile.avatarUrl ?? "")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                LinearGradient(
                                    colors: [burntOrange, pink500],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .overlay(
                                    Text(profile.initials)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            }
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .zIndex(Double(profiles.count - index))
                    }

                    if count > 3 {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [burntOrange, pink500],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text("+\(count - 3)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 1 ? "1 person likes you" : "\(count) people like you")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(charcoalColor)

                    Text("Tap to see who")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(burntOrange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [burntOrange.opacity(0.5), pink500.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MessagesScreen()
}
