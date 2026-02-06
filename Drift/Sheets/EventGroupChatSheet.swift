//
//  EventGroupChatSheet.swift
//  Drift
//
//  Group chat for event attendees
//

import SwiftUI
import DriftBackend
import Auth

struct EventGroupChatSheet: View {
    @Environment(\.dismiss) var dismiss
    let post: CommunityPost

    @StateObject private var communityManager = CommunityManager.shared
    @State private var messageText: String = ""
    @State private var messages: [EventMessage] = []
    @State private var attendees: [UserProfile] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @FocusState private var isInputFocused: Bool

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private var currentUserId: UUID? {
        SupabaseManager.shared.currentUser?.id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Messages
            messagesSection

            // Input Area
            inputSection
        }
        .background(Color.white)
        .onAppear {
            loadMessages()
            loadAttendees()
            subscribeToMessages()
        }
        .onDisappear {
            Task {
                await communityManager.unsubscribeFromEventMessages()
            }
        }
    }

    private func subscribeToMessages() {
        // Set up callback for new messages
        communityManager.onNewEventMessage = { newMessage in
            // Only add if not already present
            if !messages.contains(where: { $0.id == newMessage.id }) {
                messages.append(newMessage)
            }
        }

        // Subscribe to realtime
        Task {
            await communityManager.subscribeToEventMessages(eventId: post.id)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(post.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(charcoal)
                            .lineLimit(1)

                        // Attendee count badge
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(post.currentAttendees ?? 0)")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(forestGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(forestGreen.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    // Location
                    if let location = post.eventLocation {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 12))
                            Text(location)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(charcoal.opacity(0.5))
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    // More options
                    Button {
                        // Show options menu
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoal)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }

                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(charcoal)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Attendees row
            attendeesRow
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [softGray, Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var attendeesRow: some View {
        HStack(spacing: 8) {
            // Stacked avatars from fetched attendees
            HStack(spacing: -8) {
                // Show up to 4 attendee avatars
                ForEach(Array(attendees.prefix(4).enumerated()), id: \.element.id) { index, attendee in
                    if let avatarUrl = attendee.avatarUrl, let url = URL(string: avatarUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            avatarPlaceholder
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .zIndex(Double(4 - index))
                    } else {
                        avatarPlaceholder
                            .zIndex(Double(4 - index))
                    }
                }
            }

            // Member count text
            let count = attendees.count
            Text("\(count) \(count == 1 ? "member" : "members")")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(charcoal.opacity(0.6))

            Spacer()
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }

    // MARK: - Messages

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Error message if any
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 16)
                    }

                    // Welcome message
                    welcomeMessage
                        .padding(.top, errorMessage == nil ? 16 : 8)

                    // Messages
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isCurrentUser: message.userId == currentUserId
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(softGray.opacity(0.3))
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var welcomeMessage: some View {
        Text("Welcome to the group chat!")
            .font(.system(size: 13))
            .foregroundColor(charcoal.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)

            HStack(spacing: 12) {
                // Text input
                TextField("Type a message...", text: $messageText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(softGray)
                    .clipShape(Capsule())
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }

                // Send button
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(sendButtonBackground)
                        .clipShape(Circle())
                        .shadow(
                            color: messageText.isEmpty ? .clear : burntOrange.opacity(0.3),
                            radius: 6, x: 0, y: 3
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }

    @ViewBuilder
    private var sendButtonBackground: some View {
        if messageText.trimmingCharacters(in: .whitespaces).isEmpty {
            Color.gray.opacity(0.3)
        } else {
            LinearGradient(
                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Actions

    private func loadMessages() {
        Task {
            isLoading = true
            do {
                messages = try await communityManager.fetchEventMessages(for: post.id)
            } catch {
                print("Failed to load messages: \(error)")
            }
            isLoading = false
        }
    }

    private func loadAttendees() {
        Task {
            do {
                attendees = try await communityManager.fetchEventAttendees(post.id)
            } catch {
                print("Failed to load attendees: \(error)")
            }
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let content = messageText
        messageText = ""
        isInputFocused = false
        errorMessage = nil

        Task {
            do {
                let newMessage = try await communityManager.sendEventMessage(
                    eventId: post.id,
                    content: content
                )
                messages.append(newMessage)
            } catch {
                print("Failed to send message: \(error)")
                errorMessage = "Failed to send: \(error.localizedDescription)"
                // Restore the message text so user can retry
                messageText = content
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: EventMessage
    let isCurrentUser: Bool

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 60)
            } else {
                // Avatar
                if let avatarUrl = message.author?.avatarUrl, let url = URL(string: avatarUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (for others only)
                if !isCurrentUser {
                    Text(message.author?.name ?? "Unknown")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(charcoal.opacity(0.6))
                        .padding(.leading, 8)
                }

                // Message bubble
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isCurrentUser ? .white : charcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(messageBubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // Timestamp
                Text(message.formattedTime)
                    .font(.system(size: 11))
                    .foregroundColor(charcoal.opacity(0.4))
                    .padding(.horizontal, 8)
            }

            if !isCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    @ViewBuilder
    private var messageBubbleBackground: some View {
        if isCurrentUser {
            LinearGradient(
                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            )
    }
}

// EventMessage model is defined in DriftBackend
