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
    private var typingBroadcastSubscriptions: [RealtimeSubscription] = []
    private var typingClearTask: Task<Void, Never>?

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Conversations

    /// Fetches all conversations for the current user.
    public func fetchConversations() async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch conversations with participants
            let conversations: [Conversation] = try await client
                .from("conversations")
                .select("""
                    *,
                    participants:conversation_participants(*, profile:profiles(*))
                """)
                .order("updated_at", ascending: false)
                .execute()
                .value

            // Enrich with other user data for 1:1 conversations
            var enrichedConversations: [Conversation] = []
            for var conv in conversations {
                if let participants = conv.participants {
                    conv.otherUser = participants
                        .first(where: { $0.userId != userId })?
                        .profile
                }

                // Fetch last message
                let messages: [Message] = try await client
                    .from("messages")
                    .select("*, sender:profiles!sender_id(*)")
                    .eq("conversation_id", value: conv.id)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value

                conv.lastMessage = messages.first
                enrichedConversations.append(conv)
            }

            self.conversations = enrichedConversations
            self.updateUnreadCount(userId: userId)
            isLoading = false
        } catch {
            isLoading = false
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

        // Check for existing conversation
        let existing: [Conversation] = try await client
            .from("conversations")
            .select("""
                *,
                participants:conversation_participants(*)
            """)
            .eq("type", value: type.rawValue)
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

    // MARK: - Messages

    /// Fetches messages for a conversation.
    ///
    /// - Parameter conversationId: The conversation's ID.
    public func fetchMessages(for conversationId: UUID) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let messages: [Message] = try await client
                .from("messages")
                .select("*, sender:profiles!sender_id(*)")
                .eq("conversation_id", value: conversationId)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: true)
                .execute()
                .value

            self.currentMessages = messages
            self.currentConversationId = conversationId
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
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

            // Re-sort conversations by updatedAt
            conversations.sort { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
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
            .update(["last_read_at": ISO8601DateFormatter().string(from: now)])
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

    /// Soft deletes a message.
    ///
    /// - Parameter messageId: The message's ID.
    public func deleteMessage(_ messageId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw MessagingError.notAuthenticated
        }

        try await client
            .from("messages")
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: messageId)
            .eq("sender_id", value: userId)
            .execute()

        // Remove from local state
        currentMessages.removeAll { $0.id == messageId }
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
        currentConversationId = conversationId
        typingUserId = nil
        typingClearTask?.cancel()
        typingClearTask = nil
        typingBroadcastSubscriptions = []

        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return }

        // Create channel and set up postgres change and broadcast BEFORE subscribing
        let channel = client.realtimeV2.channel("messages:\(conversationId)")

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
                let userIdString = json["user_id"]?.stringValue ?? (json["payload"]?.objectValue?["user_id"]?.stringValue)
                guard let uid = userIdString.flatMap({ UUID(uuidString: $0) }), uid != currentUserId else { return }
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
                let userIdString = json["user_id"]?.stringValue ?? (json["payload"]?.objectValue?["user_id"]?.stringValue)
                guard let uid = userIdString.flatMap({ UUID(uuidString: $0) }) else { return }
                if self.typingUserId == uid {
                    self.typingUserId = nil
                    self.typingClearTask?.cancel()
                }
            }
        }
        typingBroadcastSubscriptions = [subTyping, subStopped]

        // Subscribe first, then listen for changes
        await channel.subscribe()
        messageChannel = channel

        Task {
            for await insertion in insertions {
                // Fetch the new message with sender info
                let record = insertion.record
                if let idString = record["id"]?.stringValue,
                   let id = UUID(uuidString: idString) {
                    do {
                        let message: Message = try await self.client
                            .from("messages")
                            .select("*, sender:profiles!sender_id(*)")
                            .eq("id", value: id)
                            .single()
                            .execute()
                            .value

                        await MainActor.run {
                            // Avoid duplicates
                            if !self.currentMessages.contains(where: { $0.id == message.id }) {
                                self.currentMessages.append(message)
                            }
                        }
                    } catch {
                        print("Failed to fetch new message: \(error)")
                    }
                }
            }
        }
    }

    /// Unsubscribes from the current message channel.
    public func unsubscribeFromMessages() async {
        typingClearTask?.cancel()
        typingClearTask = nil
        typingBroadcastSubscriptions = []
        typingUserId = nil
        await messageChannel?.unsubscribe()
        messageChannel = nil
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
              let userId = SupabaseManager.shared.currentUser?.id else { return }
        Task {
            try? await channel.broadcast(event: "typing", message: TypingPayload(userId: userId.uuidString))
        }
    }

    /// Notifies other participants that this user stopped typing.
    /// Call when the user clears the field or sends a message.
    public func sendStoppedTypingIndicator() {
        guard let channel = messageChannel,
              let userId = SupabaseManager.shared.currentUser?.id else { return }
        Task {
            try? await channel.broadcast(event: "stopped_typing", message: TypingPayload(userId: userId.uuidString))
        }
    }

    /// Subscribes to conversation updates.
    public func subscribeToConversations() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        // Create channel and set up postgres change BEFORE subscribing
        let channel = client.realtimeV2.channel("conversations:\(userId)")

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "conversations"
        )

        // Subscribe first, then listen for changes
        await channel.subscribe()
        conversationsChannel = channel

        Task {
            for await _ in updates {
                try? await self.fetchConversations()
            }
        }
    }

    /// Unsubscribes from all channels.
    public func unsubscribe() async {
        await unsubscribeFromMessages()
        await conversationsChannel?.unsubscribe()
        conversationsChannel = nil
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
