import Foundation
import Supabase
import Realtime

/// Manager for the Van Builder community.
///
/// Handles channels, messages, experts, and resources.
@MainActor
public class VanBuilderManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = VanBuilderManager()

    /// All available channels.
    @Published public var channels: [VanBuilderChannel] = []
    /// Messages in the current channel.
    @Published public var currentChannelMessages: [ChannelMessage] = []
    /// Verified experts.
    @Published public var experts: [VanBuilderExpert] = []
    /// Resources library.
    @Published public var resources: [VanBuilderResource] = []
    /// Whether data is currently loading.
    @Published public var isLoading = false
    /// The last error message, if any.
    @Published public var errorMessage: String?

    private var messageChannel: RealtimeChannelV2?
    private var currentChannelId: String?

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Channels

    /// Fetches all Van Builder channels.
    public func fetchChannels() async throws {
        isLoading = true
        errorMessage = nil

        do {
            let channels: [VanBuilderChannel] = try await client
                .from("van_builder_channels")
                .select()
                .order("sort_order")
                .execute()
                .value

            // Check memberships for current user
            if let userId = SupabaseManager.shared.currentUser?.id {
                let memberships: [ChannelMembership] = try await client
                    .from("channel_memberships")
                    .select("channel_id")
                    .eq("user_id", value: userId)
                    .execute()
                    .value

                let memberChannelIds = Set(memberships.map { $0.channelId })

                self.channels = channels.map { channel in
                    var mutableChannel = channel
                    mutableChannel.isMember = memberChannelIds.contains(channel.id)
                    return mutableChannel
                }
            } else {
                self.channels = channels
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches a single channel by ID.
    ///
    /// - Parameter channelId: The channel's ID.
    /// - Returns: The channel.
    public func fetchChannel(_ channelId: String) async throws -> VanBuilderChannel {
        return try await client
            .from("van_builder_channels")
            .select()
            .eq("id", value: channelId)
            .single()
            .execute()
            .value
    }

    /// Joins a channel.
    ///
    /// - Parameter channelId: The channel's ID.
    public func joinChannel(_ channelId: String) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw VanBuilderError.notAuthenticated
        }

        let request = ChannelMembershipCreateRequest(channelId: channelId, userId: userId)

        try await client
            .from("channel_memberships")
            .insert(request)
            .execute()

        // Update local state
        if let index = channels.firstIndex(where: { $0.id == channelId }) {
            channels[index].isMember = true
            channels[index].memberCount += 1
        }
    }

    /// Leaves a channel.
    ///
    /// - Parameter channelId: The channel's ID.
    public func leaveChannel(_ channelId: String) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw VanBuilderError.notAuthenticated
        }

        try await client
            .from("channel_memberships")
            .delete()
            .eq("channel_id", value: channelId)
            .eq("user_id", value: userId)
            .execute()

        // Update local state
        if let index = channels.firstIndex(where: { $0.id == channelId }) {
            channels[index].isMember = false
            channels[index].memberCount = max(0, channels[index].memberCount - 1)
        }
    }

    // MARK: - Messages

    /// Fetches messages for a channel.
    ///
    /// - Parameters:
    ///   - channelId: The channel's ID.
    ///   - limit: Maximum number of messages to fetch.
    public func fetchChannelMessages(_ channelId: String, limit: Int = 50) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let messages: [ChannelMessage] = try await client
                .from("channel_messages")
                .select("*, user:profiles!user_id(*)")
                .eq("channel_id", value: channelId)
                .is("parent_id", value: nil)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            self.currentChannelMessages = messages.reversed()
            self.currentChannelId = channelId
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Sends a message to a channel.
    ///
    /// - Parameters:
    ///   - channelId: The channel's ID.
    ///   - content: The message content.
    ///   - images: Optional array of image URLs.
    ///   - parentId: Optional parent message ID for replies.
    public func sendChannelMessage(
        channelId: String,
        content: String,
        images: [String] = [],
        parentId: UUID? = nil
    ) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw VanBuilderError.notAuthenticated
        }

        let request = ChannelMessageCreateRequest(
            channelId: channelId,
            userId: userId,
            content: content,
            images: images,
            parentId: parentId
        )

        try await client
            .from("channel_messages")
            .insert(request)
            .execute()
    }

    /// Likes or unlikes a message.
    ///
    /// - Parameter messageId: The message's ID.
    public func toggleLike(messageId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw VanBuilderError.notAuthenticated
        }

        // Fetch current message to get liked_by array
        let message: ChannelMessage = try await client
            .from("channel_messages")
            .select("liked_by, likes")
            .eq("id", value: messageId)
            .single()
            .execute()
            .value

        var likedBy = message.likedBy
        let alreadyLiked = likedBy.contains(userId)

        if alreadyLiked {
            likedBy.removeAll { $0 == userId }
        } else {
            likedBy.append(userId)
        }

        let updateData = MessageLikeUpdate(
            likedBy: likedBy.map { $0.uuidString },
            likes: likedBy.count
        )

        try await client
            .from("channel_messages")
            .update(updateData)
            .eq("id", value: messageId)
            .execute()

        // Update local state
        if let index = currentChannelMessages.firstIndex(where: { $0.id == messageId }) {
            currentChannelMessages[index].likedBy = likedBy
            currentChannelMessages[index].likes = likedBy.count
        }
    }

    /// Fetches replies for a message.
    ///
    /// - Parameter messageId: The parent message's ID.
    /// - Returns: Array of reply messages.
    public func fetchReplies(for messageId: UUID) async throws -> [ChannelMessage] {
        return try await client
            .from("channel_messages")
            .select("*, user:profiles!user_id(*)")
            .eq("parent_id", value: messageId)
            .is("deleted_at", value: nil)
            .order("created_at")
            .execute()
            .value
    }

    /// Deletes a message (soft delete).
    ///
    /// - Parameter messageId: The message's ID.
    public func deleteMessage(_ messageId: UUID) async throws {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            throw VanBuilderError.notAuthenticated
        }

        try await client
            .from("channel_messages")
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: messageId)
            .eq("user_id", value: userId)
            .execute()

        // Remove from local state
        currentChannelMessages.removeAll { $0.id == messageId }
    }

    // MARK: - Experts

    /// Fetches verified experts.
    ///
    /// - Parameter specialty: Optional specialty filter.
    public func fetchExperts(specialty: String? = nil) async throws {
        isLoading = true
        errorMessage = nil

        do {
            var filterQuery = client
                .from("van_builder_experts")
                .select("*, profile:profiles!user_id(*)")
                .eq("verified", value: true)

            if let specialty = specialty {
                filterQuery = filterQuery.eq("specialty", value: specialty)
            }

            let experts: [VanBuilderExpert] = try await filterQuery
                .order("rating", ascending: false)
                .execute()
                .value

            self.experts = experts
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Resources

    /// Fetches resources, optionally filtered by category.
    ///
    /// - Parameter category: Optional category filter.
    public func fetchResources(category: String? = nil) async throws {
        isLoading = true
        errorMessage = nil

        do {
            var filterQuery = client
                .from("van_builder_resources")
                .select("*")

            if let category = category {
                filterQuery = filterQuery.eq("category", value: category)
            }

            let resources: [VanBuilderResource] = try await filterQuery
                .order("views", ascending: false)
                .limit(20)
                .execute()
                .value

            self.resources = resources
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Image Upload

    /// Uploads an image for a channel message.
    ///
    /// - Parameter imageData: The image data.
    /// - Returns: The public URL of the uploaded image.
    public func uploadChannelImage(_ imageData: Data) async throws -> String {
        guard let channelId = currentChannelId else {
            throw VanBuilderError.noChannel
        }

        let imageId = UUID().uuidString
        let fileName = "\(channelId)/\(imageId).jpg"

        try await client.storage
            .from("channel-images")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try client.storage
            .from("channel-images")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    // MARK: - Realtime Subscriptions

    /// Subscribes to messages in a channel.
    ///
    /// - Parameter channelId: The channel's ID.
    public func subscribeToChannel(_ channelId: String) async {
        currentChannelId = channelId

        // Create channel and set up postgres change BEFORE subscribing
        let channel = client.realtimeV2.channel("channel_messages:\(channelId)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "channel_messages",
            filter: "channel_id=eq.\(channelId)"
        )

        // Subscribe first, then listen for changes
        await channel.subscribe()
        messageChannel = channel

        Task {
            for await insertion in insertions {
                // Only add top-level messages (not replies)
                let record = insertion.record
                if (record["parent_id"] == nil || record["parent_id"]?.isNull == true),
                   let idString = record["id"]?.stringValue,
                   let id = UUID(uuidString: idString) {
                    do {
                        let message: ChannelMessage = try await self.client
                            .from("channel_messages")
                            .select("*, user:profiles!user_id(*)")
                            .eq("id", value: id)
                            .single()
                            .execute()
                            .value

                        await MainActor.run {
                            // Avoid duplicates
                            if !self.currentChannelMessages.contains(where: { $0.id == message.id }) {
                                self.currentChannelMessages.append(message)
                            }
                        }
                    } catch {
                        print("Failed to fetch new channel message: \(error)")
                    }
                }
            }
        }
    }

    /// Unsubscribes from the current channel.
    public func unsubscribeFromChannel() async {
        await messageChannel?.unsubscribe()
        messageChannel = nil
        currentChannelId = nil
    }
}

// MARK: - Supporting Types

public enum VanBuilderError: LocalizedError {
    case notAuthenticated
    case channelNotFound
    case noChannel
    case messageFailed

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .channelNotFound:
            return "Channel not found."
        case .noChannel:
            return "No channel selected."
        case .messageFailed:
            return "Failed to send message."
        }
    }
}

// Helper struct for updating message likes
struct MessageLikeUpdate: Encodable {
    let likedBy: [String]
    let likes: Int

    enum CodingKeys: String, CodingKey {
        case likedBy = "liked_by"
        case likes
    }
}

// Helper extension
extension AnyJSON {
    var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }
}
