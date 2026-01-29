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

// Convert MessageMode to DiscoverMode for the switcher
extension MessageMode {
    var discoverMode: DiscoverMode {
        switch self {
        case .dating: return .dating
        case .friends: return .friends
        }
    }
    
    init(_ discoverMode: DiscoverMode) {
        switch discoverMode {
        case .dating: self = .dating
        case .friends: self = .friends
        }
    }
}

// MARK: - Messages Empty State (no messages / only hidden — full-bleed like dating Discover empty)

struct MessagesEmptyStateView: View {
    let mode: MessageMode
    let onFindFriends: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image("Message_Empty_State")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 280)

                VStack(spacing: 10) {
                    Text("No messages right now")
                        //.font(.system(size: 24, weight: .bold))
                        .font(.campfire(.regular, size: 24))
                        .foregroundColor(charcoalColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(mode == .dating
                         ? "Matches are more intentional on Drift. Discover someone new to get the conversation started."
                         : "Start a conversation with a friend, or discover other travelers nearby.")
                        //.font(.system(size: 16))
                        .font(.campfire(.regular, size: 16))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    Button(action: onFindFriends) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Find friends")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(burntOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

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

    // Friends who don't have a conversation yet (only count visible conversations)
    private var friendsWithoutConversation: [Friend] {
        let conversationUserIds = Set(
            visibleConversations.compactMap { $0.otherUser?.id }
        )
        return acceptedFriends.filter { friend in
            guard let currentUserId = supabaseManager.currentUser?.id else { return false }
            let friendUserId = friend.requesterId == currentUserId ? friend.addresseeId : friend.requesterId
            return !conversationUserIds.contains(friendUserId)
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
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    
                    // Search bar — hidden in empty state to match dating Discover empty layout
                    if !visibleConversations.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(charcoalColor.opacity(0.4))

                            TextField("Search messages", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
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

                            List {
                                ForEach(visibleConversations) { conversation in
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
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(true)
                            .frame(minHeight: CGFloat(visibleConversations.count) * 96)
                        }
                        .padding(.bottom, 24)
                    }

                    // Empty state: no visible messages (or only hidden) — full-bleed like dating Discover empty
                    if visibleConversations.isEmpty {
                        MessagesEmptyStateView(
                            mode: selectedMode,
                            onFindFriends: {
                                tabBarVisibility.switchToDiscoverInFriendsMode = true
                                if !supabaseManager.isFriendsOnly() {
                                    tabBarVisibility.discoverStartInFriendsMode = true
                                }
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
                                List {
                                    ForEach(hiddenConversations) { conversation in
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
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(minHeight: CGFloat(hiddenConversations.count) * 96)
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
            // Default to friends if dating is not enabled
            if !isDatingEnabled {
                selectedMode = .friends
                segmentIndex = 1
            }
            // Load conversations first so the list appears; then friends/likes/matches
            loadConversations()
            loadFriendRequests()
            loadFriends()
            if isDatingEnabled {
                loadLikesYou()
                loadMatches()
            }

            // Subscribe to real-time updates (single subscription path)
            Task {
                await MessagingManager.shared.subscribeToConversations()
                await FriendsManager.shared.subscribeToFriendRequests()
                await FriendsManager.shared.subscribeToSwipes()
                await FriendsManager.shared.subscribeToMatches()
            }
        }
        .onChange(of: selectedMode) { _, newMode in
            let uid = supabaseManager.currentUser?.id
            let afterMode = messagingManager.conversations.filter { conv in
                switch newMode {
                case .dating: return conv.type == .dating
                case .friends: return conv.type == .friends
                }
            }
            let vis = (uid == nil ? 0 : afterMode.filter { !$0.hasLeft(for: uid!) && !$0.isHidden(for: uid!) }.count)
            let hid = (uid == nil ? 0 : afterMode.filter { !$0.hasLeft(for: uid!) && $0.isHidden(for: uid!) }.count)
            print("[Messages] selectedMode changed → \(newMode) | afterModeFilter: \(afterMode.count) | visible: \(vis), hidden: \(hid)")
        }
        .onChange(of: messagingManager.conversations.count) { _, newCount in
            let uid = supabaseManager.currentUser?.id
            let afterModeFilter: [Conversation] = messagingManager.conversations.filter { conv in
                switch selectedMode {
                case .dating: return conv.type == .dating
                case .friends: return conv.type == .friends
                }
            }
            let vis = (uid == nil ? 0 : afterModeFilter.filter { !$0.hasLeft(for: uid!) && !$0.isHidden(for: uid!) }.count)
            let hid = (uid == nil ? 0 : afterModeFilter.filter { !$0.hasLeft(for: uid!) && $0.isHidden(for: uid!) }.count)
            let typeBreakdown = Dictionary(grouping: messagingManager.conversations, by: { $0.type.rawValue }).mapValues(\.count)
            print("[Messages] conversations.count changed → total: \(newCount) | selectedMode: \(selectedMode) | afterModeFilter: \(afterModeFilter.count) | visible: \(vis), hidden: \(hid) | types in list: \(typeBreakdown) | currentUser: \(uid != nil ? "yes" : "no")")
        }
        .onDisappear {
            Task {
                await MessagingManager.shared.unsubscribe()
                await FriendsManager.shared.unsubscribe()
            }
        }
        .sheet(isPresented: $showLikesYouScreen) {
            LikesYouScreen()
        }
        .sheet(isPresented: $showLikesYouPaywall) {
            PaywallScreen(isOpen: $showLikesYouPaywall, source: .likesYou)
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
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: UUID?
    let onTap: () -> Void
    var onHide: (() -> Void)? = nil
    var onUnhide: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

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

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.content)
                            .font(.system(size: 14))
                            .foregroundColor(hasUnread ? charcoalColor : charcoalColor.opacity(0.6))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Send the first message")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(burntOrange.opacity(0.12))
                            .clipShape(Capsule())
                    }
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            if let onHide {
                Button(action: onHide) {
                    Label("Hide", systemImage: "eye.slash")
                }
                .tint(charcoalColor)
            }
            if let onUnhide {
                Button(action: onUnhide) {
                    Label("Unhide", systemImage: "eye")
                }
                .tint(forestGreen)
            }
        }
        .contextMenu {
            if let onHide {
                Button(action: onHide) {
                    Label("Hide", systemImage: "eye.slash")
                }
            }
            if let onUnhide {
                Button(action: onUnhide) {
                    Label("Unhide", systemImage: "eye")
                }
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
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
    let hasProAccess: Bool
    let onTap: () -> Void

    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoalColor = Color("Charcoal")

    /// Single avatar: profile photo (blurred when !hasProAccess) or neutral gray placeholder so we never show "glowing rings".
    @ViewBuilder
    private func avatarView(urlString: String, profile: UserProfile, hasProAccess: Bool) -> some View {
        let url = URL(string: urlString)
        let showBlur = !hasProAccess

        Group {
            if let url = url, !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipped()
                            .blur(radius: showBlur ? 12 : 0)
                    case .failure, .empty:
                        neutralPlaceholder(profile: profile)
                            .blur(radius: showBlur ? 12 : 0)
                    @unknown default:
                        neutralPlaceholder(profile: profile)
                            .blur(radius: showBlur ? 12 : 0)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                neutralPlaceholder(profile: profile)
                    .frame(width: 44, height: 44)
                    .blur(radius: showBlur ? 12 : 0)
                    .clipShape(Circle())
            }
        }
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private func neutralPlaceholder(profile: UserProfile) -> some View {
        Color(white: 0.75)
            .overlay(
                Text(profile.initials)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Stacked avatars: show actual profile photo, blurred when user doesn't have Drift Pro
                HStack(spacing: -12) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        let photoURL = profile.photos.first ?? profile.avatarUrl ?? ""
                        avatarView(urlString: photoURL, profile: profile, hasProAccess: hasProAccess)
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

                    Text(hasProAccess ? "Tap to see who" : "Upgrade to Drift Pro to see who")
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
