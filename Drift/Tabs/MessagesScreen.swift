//
//  MessagesScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Auth
import UserNotifications


struct MessagesScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var messagingManager = MessagingManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var searchText: String = ""
    @State private var selectedMode: MessageMode = .dating
    @State private var selectedConversation: Conversation? = nil
    @State private var segmentIndex: Int = 0 // Default to dating (index 0)
    @State private var selectedProfileToView: UserProfile? = nil
    @State private var showLikesYouScreen = false
    @State private var showLikesYouPaywall = false
    @State private var hiddenSectionExpanded = false
    @State private var showMyFriendsSheet = false
    @State private var pendingConversationToOpen: Conversation?

    private var conversations: [Conversation] {
        messagingManager.conversations
    }

    private var pendingFriendRequests: [Friend] {
        friendsManager.pendingRequests
    }

    private var acceptedFriends: [Friend] {
        friendsManager.friends
    }

    // Friends who don't have a conversation yet — match by participant user IDs so we
    // don't show "Tap to start chatting" when a conversation exists but otherUser (profile) is nil.
    private var friendsWithoutConversation: [Friend] {
        guard let currentUserId = supabaseManager.currentUser?.id else { return [] }
        let conversationOtherUserIds = Set(
            visibleConversations.compactMap { conv in
                conv.participants?.first(where: { $0.userId != currentUserId })?.userId
            }
        )
        return acceptedFriends.filter { friend in
            let friendUserId = friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId
            return !conversationOtherUserIds.contains(friendUserId)
        }
    }

    /// Loads conversation list only. Realtime subscription is done once in onAppear Task to avoid double-subscribe and "postgresChange after join".
    private func loadConversations() {
        print("[Messages] loadConversations() called")
        Task {
            do {
                try await messagingManager.fetchConversations()
                print("[Messages] loadConversations() completed OK, list count: \(messagingManager.conversations.count)")
            } catch {
                print("[Messages] loadConversations() failed: \(error)")
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

    private func loadMatches() {
        Task {
            do {
                // This will also create conversations for any matches that don't have one
                try await friendsManager.fetchMatches()
                // Refresh conversations after matches are processed
                try await messagingManager.fetchConversations()
            } catch {
                print("Failed to load matches: \(error)")
            }
        }
    }

    private func refreshData() async {
        do {
            try await messagingManager.fetchConversations()
            try await friendsManager.fetchPendingRequests()
            try await friendsManager.fetchFriends()
            if selectedMode == .dating {
                try await friendsManager.fetchPeopleLikedMe()
                try await friendsManager.fetchMatches()
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled {
                print("Failed to refresh: \(error)")
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

    /// Conversations to show in the main list (not left, not hidden).
    private var visibleConversations: [Conversation] {
        guard let userId = supabaseManager.currentUser?.id else { return [] }
        return filteredConversations.filter { !$0.hasLeft(for: userId) && !$0.isHidden(for: userId) }
    }

    /// Conversations in the Hidden section (not left, hidden).
    private var hiddenConversations: [Conversation] {
        guard let userId = supabaseManager.currentUser?.id else { return [] }
        return filteredConversations.filter { !$0.hasLeft(for: userId) && $0.isHidden(for: userId) }
    }

    /// Conversations matching search text.
    private var searchFilteredConversations: [Conversation] {
        guard !searchText.isEmpty else { return visibleConversations }
        let query = searchText.lowercased()
        return visibleConversations.filter { $0.displayName.lowercased().contains(query) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                softGray
                    .ignoresSafeArea()

                ScrollView {
                VStack(spacing: 0) {
                    // Dating/Friends Toggle - only show if dating is enabled
                    // Match exact positioning from DiscoverScreen
                    VStack(spacing: 0) {
                        // Mode switcher row + My Friends button (top right)
                        HStack {
                            if isDatingEnabled {
                                DiscoverModeSwitcher(
                                    mode: Binding(
                                        get: { selectedMode.discoverMode },
                                        set: { newMode in
                                            selectedMode = MessageMode(newMode)
                                            segmentIndex = newMode == .dating ? 0 : 1
                                            if newMode == .dating {
                                                loadLikesYou()
                                            }
                                        }
                                    ),
                                    style: .light
                                )
                            }
                            Spacer()
                            if selectedMode == .friends {
                                Button {
                                    showMyFriendsSheet = true
                                } label: {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "person.2.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(charcoalColor)
                                            .frame(width: 40, height: 40)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        if !pendingFriendRequests.isEmpty {
                                            Circle()
                                                .fill(burntOrange)
                                                .frame(width: 10, height: 10)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 1.5)
                                                )
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    
                    // Search bar — hidden in empty state to match dating Discover empty layout
                    if !visibleConversations.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor.opacity(0.4))
                            TextField("Search messages", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(searchText.isEmpty ? Color.gray.opacity(0.2) : Color("BurntOrange"), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }

                    // "X people like you" banner (only show in dating mode)
                    if selectedMode == .dating && !friendsManager.peopleLikedMe.isEmpty {
                        LikesYouBanner(
                            count: friendsManager.peopleLikedMe.count,
                            profiles: Array(friendsManager.peopleLikedMe.prefix(3)),
                            hasProAccess: revenueCatManager.hasProAccess,
                            onTap: {
                                if revenueCatManager.hasProAccess {
                                    showLikesYouScreen = true
                                } else {
                                    showLikesYouPaywall = true
                                }
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

                    // Friends without conversation — only show when there are visible messages (otherwise we show empty state)
                    if !visibleConversations.isEmpty && selectedMode == .friends && !friendsWithoutConversation.isEmpty {
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

                    // Main list: visible conversations (List with fixed height so it lays out inside ScrollView; swipe to Hide/Delete)
                    if !visibleConversations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Messages")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(charcoalColor)
                                .padding(.horizontal, 16)

                            LazyVStack(spacing: 8) {
                                ForEach(visibleConversations) { conversation in
                                    SwipeableRow(actions: [
                                        SwipeAction(label: "Hide", icon: "eye.slash", tint: charcoalColor) {
                                            Task {
                                                messagingManager.errorMessage = nil
                                                do {
                                                    try await messagingManager.hideConversation(conversation.id)
                                                } catch {
                                                    messagingManager.errorMessage = error.localizedDescription
                                                }
                                            }
                                        },
                                        SwipeAction(label: "Delete", icon: "trash", tint: .red) {
                                            Task {
                                                messagingManager.errorMessage = nil
                                                do {
                                                    try await messagingManager.leaveConversation(conversation.id)
                                                } catch {
                                                    messagingManager.errorMessage = error.localizedDescription
                                                }
                                            }
                                        }
                                    ]) {
                                        ConversationRow(
                                            conversation: conversation,
                                            currentUserId: supabaseManager.currentUser?.id,
                                            onTap: { selectedConversation = conversation },
                                            onHide: {
                                                Task {
                                                    messagingManager.errorMessage = nil
                                                    do {
                                                        try await messagingManager.hideConversation(conversation.id)
                                                    } catch {
                                                        messagingManager.errorMessage = error.localizedDescription
                                                    }
                                                }
                                            },
                                            onUnhide: nil,
                                            onDelete: {
                                                Task {
                                                    messagingManager.errorMessage = nil
                                                    do {
                                                        try await messagingManager.leaveConversation(conversation.id)
                                                    } catch {
                                                        messagingManager.errorMessage = error.localizedDescription
                                                    }
                                                }
                                            }
                                        )
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // Empty state: no visible messages (or only hidden) — full-bleed like dating Discover empty
                    if visibleConversations.isEmpty {
                        MessagesEmptyStateView(
                            mode: selectedMode,
                            onFindFriends: {
                                tabBarVisibility.switchToDiscoverInFriendsMode = true
                                // Find Matches (dating) → Discover dating; Find friends → Discover friends
                                tabBarVisibility.discoverStartInFriendsMode = (selectedMode == .friends)
                            }
                        )
                        .frame(minHeight: UIScreen.main.bounds.height - 320)
                        .padding(.bottom, hiddenConversations.isEmpty ? 100 : 16)
                    }

                    // Hidden section (collapsible dropdown) — below empty state when no visible messages
                    if !hiddenConversations.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hiddenSectionExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Hidden")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(charcoalColor)
                                    Text("(\(hiddenConversations.count))")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                    Spacer()
                                    Image(systemName: hiddenSectionExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if hiddenSectionExpanded {
                                LazyVStack(spacing: 8) {
                                    ForEach(hiddenConversations) { conversation in
                                        SwipeableRow(actions: [
                                            SwipeAction(label: "Unhide", icon: "eye", tint: Color("ForestGreen")) {
                                                Task {
                                                    messagingManager.errorMessage = nil
                                                    do {
                                                        try await messagingManager.unhideConversation(conversation.id)
                                                    } catch {
                                                        messagingManager.errorMessage = error.localizedDescription
                                                    }
                                                }
                                            },
                                            SwipeAction(label: "Delete", icon: "trash", tint: .red) {
                                                Task {
                                                    messagingManager.errorMessage = nil
                                                    do {
                                                        try await messagingManager.leaveConversation(conversation.id)
                                                    } catch {
                                                        messagingManager.errorMessage = error.localizedDescription
                                                    }
                                                }
                                            }
                                        ]) {
                                            ConversationRow(
                                                conversation: conversation,
                                                currentUserId: supabaseManager.currentUser?.id,
                                                onTap: { selectedConversation = conversation },
                                                onHide: nil,
                                                onUnhide: {
                                                    Task {
                                                        messagingManager.errorMessage = nil
                                                        do {
                                                            try await messagingManager.unhideConversation(conversation.id)
                                                        } catch {
                                                            messagingManager.errorMessage = error.localizedDescription
                                                        }
                                                    }
                                                },
                                                onDelete: {
                                                    Task {
                                                        messagingManager.errorMessage = nil
                                                        do {
                                                            try await messagingManager.leaveConversation(conversation.id)
                                                        } catch {
                                                            messagingManager.errorMessage = error.localizedDescription
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.bottom, 24)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        .padding(.bottom, LayoutConstants.tabBarBottomPadding + 24)
                    }

                    // Bottom spacer so last content (hidden list, etc.) scrolls clear of the tab bar
                    Color.clear
                        .frame(height: LayoutConstants.tabBarBottomPadding + 32)
                }
            }
            .refreshable {
                await refreshData()
            }

            // Error banner for hide/unhide/delete failures
            if let message = messagingManager.errorMessage {
                HStack {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        messagingManager.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(12)
                .background(charcoalColor)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .onAppear {
            print("[Messages] MessagesScreen onAppear | isDatingEnabled: \(isDatingEnabled), selectedMode: \(selectedMode)")
            // Clear app badge when opening Messages tab
            UNUserNotificationCenter.current().setBadgeCount(0)
            // Default to friends if dating is not enabled
            if !isDatingEnabled {
                selectedMode = .friends
                segmentIndex = 1
            }
            // AppDataManager handles initial data loading and realtime subscriptions.
            // Only fetch here if data hasn't been loaded yet (fallback).
            if messagingManager.conversations.isEmpty && !messagingManager.isLoading {
                loadConversations()
            }
        }
        .onChange(of: selectedMode) { _, newMode in
            print("[Messages] selectedMode changed → \(newMode) | visible: \(visibleConversations.count), hidden: \(hiddenConversations.count)")
        }
        .onChange(of: messagingManager.conversations.count) { _, newCount in
            print("[Messages] conversations.count changed → total: \(newCount) | visible: \(visibleConversations.count), hidden: \(hiddenConversations.count)")
        }
        // Note: Realtime subscriptions are managed by AppDataManager at the ContentView level
        .sheet(isPresented: $showLikesYouScreen) {
            LikesYouScreen()
        }
        .sheet(isPresented: $showLikesYouPaywall) {
            PaywallScreen(isOpen: $showLikesYouPaywall, source: .likesYou)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMyFriendsSheet, onDismiss: {
            if let conv = pendingConversationToOpen {
                selectedConversation = conv
                pendingConversationToOpen = nil
            }
        }) {
            MyFriendsSheet(onSelectConversation: { conversation in
                pendingConversationToOpen = conversation
                showMyFriendsSheet = false
            })
        }
        .navigationDestination(item: $selectedConversation) { conversation in
            MessageDetailScreen(
                conversation: conversation,
                onClose: {
                    selectedConversation = nil
                    tabBarVisibility.isVisible = true
                }
            )
            .navigationBarBackButtonHidden(true)
            .onAppear {
                tabBarVisibility.isVisible = false
            }
            .onDisappear {
                tabBarVisibility.isVisible = true
            }
        }
        .fullScreenCover(item: $selectedProfileToView) { profile in
            DatingProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedProfileToView != nil },
                    set: { if !$0 { selectedProfileToView = nil } }
                ),
                onLike: {
                    if let request = pendingFriendRequests.first(where: { $0.requesterProfile?.id == profile.id }) {
                        handleAcceptRequest(request)
                    }
                    selectedProfileToView = nil
                },
                onPass: {
                    if let request = pendingFriendRequests.first(where: { $0.requesterProfile?.id == profile.id }) {
                        handleDeclineRequest(request)
                    }
                    selectedProfileToView = nil
                },
                showBackButton: true,
                showLikeAndPassButtons: true
            )
        }
        }
    }
}

#Preview {
    MessagesScreen()
}
