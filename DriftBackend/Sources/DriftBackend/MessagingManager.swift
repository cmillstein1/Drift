import Foundation
import Supabase
import Realtime

/// Manager for messaging and conversations.
///
/// Handles conversations, messages, and realtime subscriptions.
@MainActor
public class MessagingManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = MessagingManager()

    /// All conversations for the current user.
    @Published public var conversations: [Conversation] = []
    /// Messages in the current conversation.
    @Published public var currentMessages: [Message] = []
    /// Total unread message count.
    @Published public var unreadCount: Int = 0
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?
    /// User ID of the other participant who is currently typing (nil if no one typing).
    @Published public var typingUserId: UUID?

    private var messageChannel: RealtimeChannelV2?
    private var conversationsChannel: RealtimeChannelV2?
    private var currentConversationId: UUID?
    private var isSubscribingToConversations = false
    private var isSubscribingToMessages = false
    private var typingBroadcastSubscriptions: [RealtimeSubscription] = []
    private var typingClearTask: Task<Void, Never>?

    /// Local participant state we just set (hide/unhide/leave). Preserved across refetches for a short window so the list doesn't flip back.
    private var recentParticipantState: [UUID: (hiddenAt: Date?, leftAt: Date?, at: Date)] = [:]
    private let recentParticipantStateWindow: TimeInterval = 30

    // MARK: - Static Formatters (avoid re-creating per call)

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    private static let timeBubbleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Conversations

    /// Fetches all conversations for the current user.
    public func fetchConversations() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            #if DEBUG
            print("[Messages] fetchConversations skipped: no current user (not authenticated)")
            #endif
            throw MessagingError.notAuthenticated
        }
        guard !isLoading else { return }

        #if DEBUG
        print("[Messages] fetchConversations started (userId: \(userId.uuidString.prefix(8))...)")
        #endif
        isLoading = true

        do {
            // Fetch conversations with participants
            let conversations: [Conversation]
            do {
                conversations = try await client
                    .from("conversations")
                    .select("""
                        *,
                        participants:conversation_participants(*, profile:profiles(*))
                    """)
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
            } catch {
                let nsError = error as NSError
                let isCancelled = nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
                #if DEBUG
                if !isCancelled {
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("[Messages] Decode failed: keyNotFound '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) — \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("[Messages] Decode failed: typeMismatch \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) — \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("[Messages] Decode failed: valueNotFound \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) — \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("[Messages] Decode failed: dataCorrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) — \(context.debugDescription)")
                        @unknown default:
                            print("[Messages] Decode failed: \(decodingError)")
                        }
                    } else {
                        print("[Messages] fetchConversations request/parse error: \(error)")
                    }
                }
                #endif
                throw error
            }

            #if DEBUG
            print("[Messages] API returned \(conversations.count) conversation(s) | types: \(conversations.map { $0.type.rawValue })")
            #endif

            // Batch-fetch last message for all conversations in a single query
            let conversationIds = conversations.map { $0.id }
            var lastMessageByConv: [UUID: Message] = [:]
            if !conversationIds.isEmpty {
                // Fetch the most recent message per conversation using a single query
                // We fetch recent messages for all conversations and pick the latest per conv
                let allLastMessages: [Message] = try await client
                    .from("messages")
                    .select("*, sender:profiles!sender_id(*)")
                    .in("conversation_id", values: conversationIds)
                    .order("created_at", ascending: false)
                    .limit(conversationIds.count * 2)
                    .execute()
                    .value

                // Group by conversation and take the first (most recent) for each
                for msg in allLastMessages {
                    if lastMessageByConv[msg.conversationId] == nil {
                        lastMessageByConv[msg.conversationId] = msg
                    }
                }
            }

            // Enrich with other user data and last message
            var enrichedConversations: [Conversation] = []
            for (idx, var conv) in conversations.enumerated() {
                if let participants = conv.participants {
                    conv.otherUser = participants
                        .first(where: { $0.userId != userId })?
                        .profile
                }

                conv.lastMessage = lastMessageByConv[conv.id]
                enrichedConversations.append(conv)

                let myParticipant = conv.participants?.first(where: { $0.userId == userId })
                let hiddenAt = myParticipant?.hiddenAt
                let leftAt = myParticipant?.leftAt
                #if DEBUG
                if idx < 3 {
                    print("[Messages]   [\(idx)] conv \(conv.id.uuidString.prefix(8))... participants: \(conv.participants?.count ?? 0), hiddenAt: \(hiddenAt != nil ? "set" : "nil"), leftAt: \(leftAt != nil ? "set" : "nil"), otherUser: \(conv.otherUser != nil ? "yes" : "no")")
                }
                #endif
            }
            #if DEBUG
            if conversations.count > 3 {
                print("[Messages]   ... and \(conversations.count - 3) more")
            }
            #endif

            // Preserve recent hide/unhide/leave state so a refetch (realtime, onAppear) doesn't overwrite the UI
            let now = Date()
            for (convId, state) in recentParticipantState {
                guard now.timeIntervalSince(state.at) <= recentParticipantStateWindow else { continue }
                guard let idx = enrichedConversations.firstIndex(where: { $0.id == convId }) else { continue }
                var conv = enrichedConversations[idx]
                guard var participants = conv.participants,
                      let pIdx = participants.firstIndex(where: { $0.userId == userId }) else { continue }
                participants[pIdx].hiddenAt = state.hiddenAt
                participants[pIdx].leftAt = state.leftAt
                conv.participants = participants
                enrichedConversations[idx] = conv
            }
            // Prune stale entries
            recentParticipantState = recentParticipantState.filter { now.timeIntervalSince($0.value.at) <= recentParticipantStateWindow }

            // Exclude conversations the user has left so the list stays accurate
            var filtered = enrichedConversations.filter { !$0.hasLeft(for: userId) }
            // Exclude conversations with blocked users (blocker and blockee should not see each other)
            let blockedIds = (try? await FriendsManager.shared.fetchBlockedExclusionUserIds()) ?? []
            let blockedSet = Set(blockedIds)
            filtered = filtered.filter { conv in
                guard let otherId = conv.otherUser?.id else { return true }
                return !blockedSet.contains(otherId)
            }
            let visibleCount = filtered.filter { !$0.isHidden(for: userId) }.count
            let hiddenCount = filtered.filter { $0.isHidden(for: userId) }.count

            #if DEBUG
            print("[Messages] After filter (not left): \(filtered.count) | visible: \(visibleCount), hidden: \(hiddenCount) | current list had: \(self.conversations.count) | types: \(filtered.map { $0.type.rawValue })")
            #endif

            // Never overwrite the list with empty once we have data (avoids "message shows up then disappears" from a second refetch returning empty)
            let willAssign: Bool
            if !filtered.isEmpty {
                willAssign = true
            } else if self.conversations.isEmpty {
                willAssign = true
            } else {
                willAssign = false
            }
            #if DEBUG
            print("[Messages] Assign list? \(willAssign) (filtered.isEmpty=\(filtered.isEmpty), conversations.isEmpty=\(self.conversations.isEmpty))")
            #endif

            if willAssign {
                self.conversations = filtered
                #if DEBUG
                print("[Messages] conversations set to \(self.conversations.count) item(s)")
                #endif
            }

            self.updateUnreadCount(userId: userId)
            isLoading = false
        } catch {
            isLoading = false
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                #if DEBUG
                print("[Messages] fetchConversations cancelled (request cancelled)")
                #endif
                return
            }
            #if DEBUG
            print("[Messages] fetchConversations failed: \(error)")
            #endif
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Gets or creates a conversation with another user.
    ///
    /// - Parameters:
    ///   - userId: The other user's ID.
    ///   - type: The type of conversation.
    /// - Returns: The existing or newly created conversation.
    public func fetchOrCreateConversation(
        with userId: UUID,
        type: ConversationType
    ) async throws -> Conversation {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }

        // Check for existing conversation — filter to conversations the current user participates in
        // by using the conversation_participants join, rather than fetching ALL conversations of this type.
        let existing: [Conversation] = try await client
            .from("conversations")
            .select("""
                *,
                participants:conversation_participants(*)
            """)
            .eq("type", value: type.rawValue)
            .eq("conversation_participants.user_id", value: currentUserId)
            .limit(50)
            .execute()
            .value

        // Find conversation with both users
        for var conv in existing {
            let participantIds = conv.participants?.map { $0.userId } ?? []
            if participantIds.contains(currentUserId) && participantIds.contains(userId) {
                // Ensure otherUser is populated
                if conv.otherUser == nil {
                    conv.otherUser = try await ProfileManager.shared.fetchProfile(by: userId)
                }
                return conv
            }
        }

        // Create new conversation using RPC function (bypasses RLS)
        let conversationId: UUID = try await client
            .rpc("create_conversation_with_participants", params: [
                "p_type": type.rawValue,
                "p_user1_id": currentUserId.uuidString,
                "p_user2_id": userId.uuidString
            ])
            .execute()
            .value

        // Fetch the created conversation
        let newConv: Conversation = try await client
            .from("conversations")
            .select()
            .eq("id", value: conversationId)
            .single()
            .execute()
            .value

        // Fetch the other user's profile
        var conversationWithUser = newConv
        conversationWithUser.otherUser = try await ProfileManager.shared.fetchProfile(by: userId)

        return conversationWithUser
    }

    /// Whether there are older messages that can be loaded.
    @Published public var hasOlderMessages = true

    /// Page size for message pagination.
    private let messagePageSize = 50

    // MARK: - Messages

    /// Fetches the most recent page of messages for a conversation.
    ///
    /// - Parameter conversationId: The conversation's ID.
    public func fetchMessages(for conversationId: UUID) async throws {
        isLoading = true

        do {
            let messages: [Message] = try await client
                .from("messages")
                .select("*, sender:profiles!sender_id(*)")
                .eq("conversation_id", value: conversationId)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .limit(messagePageSize)
                .execute()
                .value

            self.currentMessages = messages.reversed()
            self.currentConversationId = conversationId
            self.hasOlderMessages = messages.count >= messagePageSize
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Loads older messages before the earliest currently loaded message.
    ///
    /// - Parameter conversationId: The conversation's ID.
    public func fetchOlderMessages(for conversationId: UUID) async throws {
        guard hasOlderMessages, let oldest = currentMessages.first,
              let oldestDate = oldest.createdAt else { return }

        let olderMessages: [Message] = try await client
            .from("messages")
            .select("*, sender:profiles!sender_id(*)")
            .eq("conversation_id", value: conversationId)
            .is("deleted_at", value: nil)
            .lt("created_at", value: Self.iso8601Formatter.string(from: oldestDate))
            .order("created_at", ascending: false)
            .limit(messagePageSize)
            .execute()
            .value

        hasOlderMessages = olderMessages.count >= messagePageSize
        currentMessages.insert(contentsOf: olderMessages.reversed(), at: 0)
    }

    /// Sends a message to a conversation.
    ///
    /// - Parameters:
    ///   - conversationId: The conversation's ID.
    ///   - content: The message content.
    ///   - images: Optional array of image URLs.
    public func sendMessage(
        to conversationId: UUID,
        content: String,
        images: [String] = []
    ) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }

        let request = MessageRequest(
            conversationId: conversationId,
            senderId: userId,
            content: content,
            images: images
        )

        try await client
            .from("messages")
            .insert(request)
            .execute()

        // Persist read status to database immediately so realtime refetches
        // pick up the updated lastReadAt before overwriting local state
        try? await client
            .from("conversation_participants")
            .update(["last_read_at": Self.iso8601Formatter.string(from: Date())])
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()

        // Update the local conversation's lastMessage for immediate UI feedback
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            let senderProfile = try? await ProfileManager.shared.fetchProfile(by: userId)
            let newMessage = Message(
                id: UUID(),
                conversationId: conversationId,
                senderId: userId,
                content: content,
                images: images,
                createdAt: Date(),
                deletedAt: nil,
                sender: senderProfile
            )
            conversations[index].lastMessage = newMessage
            conversations[index].updatedAt = Date()

            // Update sender's lastReadAt so their own message doesn't show as unread
            if var participants = conversations[index].participants,
               let pIdx = participants.firstIndex(where: { $0.userId == userId }) {
                participants[pIdx].lastReadAt = Date()
                conversations[index].participants = participants
            }

            // Re-sort conversations by updatedAt
            conversations.sort { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }

            updateUnreadCount(userId: userId)
        }
    }

    /// Marks a conversation as read.
    ///
    /// - Parameter conversationId: The conversation's ID.
    public func markAsRead(conversationId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }

        let now = Date()

        try await client
            .from("conversation_participants")
            .update(["last_read_at": Self.iso8601Formatter.string(from: now)])
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()

        // Update local conversation so the unread dot disappears immediately
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            var conv = conversations[idx]
            if var participants = conv.participants,
               let pIdx = participants.firstIndex(where: { $0.userId == userId }) {
                participants[pIdx].lastReadAt = now
                conv.participants = participants
                conversations[idx] = conv
            }
        }

        updateUnreadCount(userId: userId)
    }

    /// Marks all conversations as read.
    public func markAllAsRead() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        let now = Date()

        // Update all participant records for this user
        try? await client
            .from("conversation_participants")
            .update(["last_read_at": Self.iso8601Formatter.string(from: now)])
            .eq("user_id", value: userId)
            .execute()

        // Update local state
        for i in conversations.indices {
            if var participants = conversations[i].participants,
               let pIdx = participants.firstIndex(where: { $0.userId == userId }) {
                participants[pIdx].lastReadAt = now
                conversations[i].participants = participants
            }
        }

        unreadCount = 0
    }

    /// Soft deletes a message.
    ///
    /// - Parameter messageId: The message's ID.
    public func deleteMessage(_ messageId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }

        try await client
            .from("messages")
            .update(["deleted_at": Self.iso8601Formatter.string(from: Date())])
            .eq("id", value: messageId)
            .eq("sender_id", value: userId)
            .execute()

        // Remove from local state
        currentMessages.removeAll { $0.id == messageId }
    }

    // MARK: - Hide / Unhide / Leave

    /// Hides a conversation (moves to Hidden section). Reversible.
    public func hideConversation(_ conversationId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }
        let nowDate = Date()
        try await client
            .from("conversation_participants")
            .update(["hidden_at": Self.iso8601Formatter.string(from: nowDate)])
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
        updateParticipantFlag(conversationId: conversationId, userId: userId) { $0.hiddenAt = nowDate }
        recentParticipantState[conversationId] = (hiddenAt: nowDate, leftAt: nil, at: nowDate)
        updateUnreadCount(userId: userId)
    }

    /// Unhides a conversation (moves back to main list).
    public func unhideConversation(_ conversationId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }
        // Encode hidden_at as null explicitly — Swift's Encodable skips nil optionals by default,
        // so a plain Optional would produce {} and the column would never be cleared.
        struct UnhidePayload: Encodable {
            enum CodingKeys: String, CodingKey { case hidden_at }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeNil(forKey: .hidden_at)
            }
        }
        try await client
            .from("conversation_participants")
            .update(UnhidePayload())
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
        let now = Date()
        updateParticipantFlag(conversationId: conversationId, userId: userId) { $0.hiddenAt = nil }
        recentParticipantState[conversationId] = (hiddenAt: nil, leftAt: nil, at: now)
        updateUnreadCount(userId: userId)
    }

    /// Rejoins a conversation that was previously left or hidden, clearing both left_at and hidden_at.
    public func rejoinConversation(_ conversationId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }
        struct RejoinPayload: Encodable {
            enum CodingKeys: String, CodingKey { case left_at; case hidden_at }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeNil(forKey: .left_at)
                try container.encodeNil(forKey: .hidden_at)
            }
        }
        try await client
            .from("conversation_participants")
            .update(RejoinPayload())
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
        let now = Date()
        updateParticipantFlag(conversationId: conversationId, userId: userId) {
            $0.leftAt = nil
            $0.hiddenAt = nil
        }
        recentParticipantState[conversationId] = (hiddenAt: nil, leftAt: nil, at: now)
        updateUnreadCount(userId: userId)
    }

    /// Leaves (deletes) a conversation for the current user. Removes from list.
    public func leaveConversation(_ conversationId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }
        let nowDate = Date()
        try await client
            .from("conversation_participants")
            .update(["left_at": Self.iso8601Formatter.string(from: nowDate)])
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
        updateParticipantFlag(conversationId: conversationId, userId: userId) { $0.leftAt = nowDate }
        recentParticipantState[conversationId] = (hiddenAt: nil, leftAt: nowDate, at: nowDate)
        removeLeftConversationFromList(conversationId)
        updateUnreadCount(userId: userId)
    }

    private func updateParticipantFlag(conversationId: UUID, userId: UUID, update: (inout ConversationParticipant) -> Void) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        // Use explicit read → mutate → write-back so the @Published setter fires
        // (in-place subscript mutation can use _modify accessor, bypassing objectWillChange).
        var updated = conversations
        guard var participants = updated[idx].participants,
              let pIdx = participants.firstIndex(where: { $0.userId == userId }) else { return }
        update(&participants[pIdx])
        updated[idx].participants = participants
        conversations = updated
    }

    /// Removes a conversation from the in-memory list after the user has left (so it doesn't reappear until next full fetch).
    private func removeLeftConversationFromList(_ conversationId: UUID) {
        conversations.removeAll { $0.id == conversationId }
    }

    // MARK: - Image Upload

    /// Uploads an image for a message.
    ///
    /// - Parameters:
    ///   - imageData: The image data.
    ///   - conversationId: The conversation's ID.
    /// - Returns: The public URL of the uploaded image.
    public func uploadMessageImage(_ imageData: Data, for conversationId: UUID) async throws -> String {
        let imageId = UUID().uuidString
        let fileName = "\(conversationId.uuidString)/\(imageId).jpg"

        try await client.storage
            .from("message-images")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try client.storage
            .from("message-images")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    // MARK: - Realtime Subscriptions

    /// Subscribes to messages in a conversation.
    ///
    /// - Parameter conversationId: The conversation's ID.
    public func subscribeToMessages(conversationId: UUID) async {
        if messageChannel != nil, currentConversationId == conversationId { return }
        if isSubscribingToMessages { return }
        isSubscribingToMessages = true
        defer { isSubscribingToMessages = false }

        currentConversationId = conversationId
        typingUserId = nil
        typingClearTask?.cancel()
        typingClearTask = nil
        typingBroadcastSubscriptions = []

        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return }

        await messageChannel?.unsubscribe()
        messageChannel = nil

        // Ensure realtime client has the current auth token for RLS
        do {
            let accessToken = try await client.auth.session.accessToken
            await client.realtimeV2.setAuth(accessToken)
        } catch {
            #if DEBUG
            print("[Messages] Could not set realtime auth: \(error)")
            #endif
        }

        let channel = client.realtimeV2.channel("messages:\(conversationId)")
        messageChannel = channel

        // Listen for postgres INSERT changes
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversationId)"
        )

        // Listen for typing indicators (before subscribe)
        let subTyping = channel.onBroadcast(event: "typing") { [weak self] json in
            Task { @MainActor in
                guard let self else { return }
                // Try multiple paths to find user_id
                var userIdString: String?
                if case .string(let str) = json["user_id"] {
                    userIdString = str
                } else if case .object(let obj) = json["payload"],
                          case .string(let str) = obj["user_id"] {
                    userIdString = str
                }
                guard let uid = userIdString.flatMap({ UUID(uuidString: $0) }), uid != currentUserId else {
                    return
                }
                self.typingClearTask?.cancel()
                self.typingUserId = uid
                self.typingClearTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    if !Task.isCancelled {
                        self.typingUserId = nil
                    }
                }
            }
        }
        let subStopped = channel.onBroadcast(event: "stopped_typing") { [weak self] json in
            Task { @MainActor in
                guard let self else { return }
                var userIdString: String?
                if case .string(let str) = json["user_id"] {
                    userIdString = str
                } else if case .object(let obj) = json["payload"],
                          case .string(let str) = obj["user_id"] {
                    userIdString = str
                }
                guard let uid = userIdString.flatMap({ UUID(uuidString: $0) }) else { return }
                if self.typingUserId == uid {
                    self.typingUserId = nil
                    self.typingClearTask?.cancel()
                }
            }
        }
        typingBroadcastSubscriptions = [subTyping, subStopped]

        await channel.subscribe()

        Task { @MainActor in
            for await insertion in insertions {
                let record = insertion.record
                guard let idString = record["id"]?.stringValue,
                      let id = UUID(uuidString: idString) else { continue }
                do {
                    let message: Message = try await self.client
                        .from("messages")
                        .select("*, sender:profiles!sender_id(*)")
                        .eq("id", value: id)
                        .single()
                        .execute()
                        .value

                    if !self.currentMessages.contains(where: { $0.id == message.id }) {
                        self.currentMessages.append(message)
                        self.currentMessages.sort { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
                    }
                } catch {
                    #if DEBUG
                    print("[Messages] Failed to fetch new message: \(error)")
                    #endif
                }
            }
        }
    }

    /// Unsubscribes from the current message channel and removes it from the client.
    public func unsubscribeFromMessages() async {
        typingClearTask?.cancel()
        typingClearTask = nil
        typingBroadcastSubscriptions = []
        typingUserId = nil
        if let channel = messageChannel {
            await client.realtimeV2.removeChannel(channel)
            messageChannel = nil
        }
        currentConversationId = nil
    }

    // MARK: - Typing Indicator

    private struct TypingPayload: Codable {
        let userId: String
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
        }
    }

    /// Notifies other participants in the current conversation that this user is typing.
    /// Call this when the user is editing the message field (debounce in UI).
    public func sendTypingIndicator() {
        guard let channel = messageChannel,
              let userId = SupabaseManager.shared.currentUser?.id else {
            // Channel not ready yet - this is expected if user types before subscription completes
            return
        }
        Task {
            do {
                try await channel.httpSend(event: "typing", message: TypingPayload(userId: userId.uuidString))
            } catch {
                #if DEBUG
                print("[Typing] Broadcast failed: \(error)")
                #endif
            }
        }
    }

    /// Notifies other participants that this user stopped typing.
    /// Call when the user clears the field or sends a message.
    public func sendStoppedTypingIndicator() {
        guard let channel = messageChannel,
              let userId = SupabaseManager.shared.currentUser?.id else { return }
        Task {
            try? await channel.httpSend(event: "stopped_typing", message: TypingPayload(userId: userId.uuidString))
        }
    }

    /// Subscribes to conversation updates. Call once per session (e.g. in onAppear). If already subscribed, returns immediately so postgresChange is never registered after join.
    public func subscribeToConversations() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        if conversationsChannel != nil { return }
        if isSubscribingToConversations { return }
        isSubscribingToConversations = true
        defer { isSubscribingToConversations = false }

        do {
            let accessToken = try await client.auth.session.accessToken
            await client.realtimeV2.setAuth(accessToken)
        } catch {
            #if DEBUG
            print("[Conversations] Could not set realtime auth: \(error)")
            #endif
        }

        let channel = client.realtimeV2.channel("conversations:\(userId)")
        conversationsChannel = channel

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "conversations"
        )

        await channel.subscribe()

        Task {
            for await _ in updates {
                try? await self.fetchConversations()
            }
        }
    }

    /// Unsubscribes from all channels and removes them from the client so the next subscribe gets a fresh channel (avoids "postgresChange after join" warning).
    public func unsubscribe() async {
        await unsubscribeFromMessages()
        if let channel = conversationsChannel {
            await client.realtimeV2.removeChannel(channel)
            conversationsChannel = nil
        }
    }

    // MARK: - Private

    private func updateUnreadCount(userId: UUID) {
        var count = 0
        for conv in conversations {
            if conv.hasUnreadMessages(for: userId) {
                count += 1
            }
        }
        unreadCount = count
    }
}

// MARK: - Supporting Types

public enum MessagingError: LocalizedError {
    case notAuthenticated
    case conversationNotFound
    case messageFailed

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .conversationNotFound:
            return "Conversation not found."
        case .messageFailed:
            return "Failed to send message."
        }
    }
}

// Helper extension for AnyJSON
extension AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
}
