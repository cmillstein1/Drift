//
//  MessageDetailScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Auth


struct MessageDetailScreen: View {
    let conversation: Conversation
    let onClose: () -> Void

    @StateObject private var messagingManager = MessagingManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var typingDebounceTask: Task<Void, Never>?
    @State private var lastTypingSentAt: Date?
    @State private var profileToShowFromMessage: UserProfile?
    @State private var isLoadingProfileForMessage: Bool = false
    @State private var pollingTask: Task<Void, Never>?
    @State private var messageToReport: Message?
    @State private var showMessageReportSheet = false

    private var currentUserId: UUID? {
        supabaseManager.currentUser?.id
    }

    /// The other participant's user ID (for block/report).
    private var otherUserId: UUID? {
        conversation.otherUser?.id
            ?? conversation.participants?.first(where: { $0.userId != currentUserId })?.userId
    }
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private var messageBubbleGradient: LinearGradient {
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

    private var sendButtonGradient: LinearGradient {
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
        case .friends:
            return "person.fill"
        case .activity:
            return "calendar"
        }
    }

    private var typeLabel: String {
        switch conversation.type {
        case .dating:
            return "Match"
        case .friends:
            return "Friend"
        case .activity:
            return "Activity"
        }
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(charcoalColor)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        if let other = conversation.otherUser {
                            profileToShowFromMessage = other
                        } else if let id = otherUserId {
                            isLoadingProfileForMessage = true
                            Task {
                                do {
                                    let p = try await profileManager.fetchProfile(by: id)
                                    await MainActor.run {
                                        profileToShowFromMessage = p
                                        isLoadingProfileForMessage = false
                                    }
                                } catch {
                                    await MainActor.run { isLoadingProfileForMessage = false }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                // Avatar
                                CachedAsyncImage(url: URL(string: conversation.avatarUrl ?? "")) { phase in
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
                                            .frame(width: 40, height: 40)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
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
                                            .frame(width: 40, height: 40)
                                    @unknown default:
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [burntOrange, forestGreen]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                
                                // Match/Friend Badge
                                ZStack {
                                    Circle()
                                        .fill(badgeBackground)
                                        .frame(width: 16, height: 16)
                                    
                                    Image(systemName: badgeIcon)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .offset(x: -2, y: -2)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conversation.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                Text(typeLabel)
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingProfileForMessage)
                    
                    Spacer()
                    
                    ReportBlockMenu(
                        userId: otherUserId,
                        displayName: conversation.displayName,
                        profile: conversation.otherUser,
                        onBlockComplete: onClose
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Date Divider
                            if !messagingManager.currentMessages.isEmpty {
                                Text("Today")
                                    .font(.system(size: 12))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                    .padding(.top, 16)
                            }

                            ForEach(messagingManager.currentMessages) { message in
                                ChatMessageBubble(
                                    message: message,
                                    isSent: message.senderId == currentUserId,
                                    gradient: messageBubbleGradient,
                                    conversationType: conversation.type
                                )
                                .id(message.id)
                                .contextMenu {
                                    // Only show report option for messages from other users
                                    if message.senderId != currentUserId {
                                        Button {
                                            messageToReport = message
                                            showMessageReportSheet = true
                                        } label: {
                                            Label("Report Message", systemImage: "exclamationmark.triangle")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 60)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                // Dismiss keyboard when scrolling down (fallback for older iOS)
                                if value.translation.height > 0 {
                                    isInputFocused = false
                                }
                            }
                    )
                    .onChange(of: messagingManager.currentMessages.count) { _ in
                        if let lastMessage = messagingManager.currentMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Typing indicator in a chat bubble (iMessage-style: light grey, tail on bottom-left)
                if messagingManager.typingUserId != nil {
                    HStack(alignment: .bottom, spacing: 0) {
                        TypingIndicatorView(color: charcoalColor.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight]))
                            .overlay(
                                RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight])
                                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(charcoalColor)
                        .focused($isInputFocused)
                        .lineLimit(1...5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(softGray)
                        )

                    Button(action: handleSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Group {
                                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Color.gray.opacity(0.3)
                                    } else {
                                        sendButtonGradient
                                    }
                                }
                            )
                            .clipShape(Circle())
                            .shadow(color: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.ignoresSafeArea(edges: .bottom))
            }
        }
        .onAppear {
            loadMessages()
            Task {
                try? await messagingManager.markAsRead(conversationId: conversation.id)
            }
        }
        .onDisappear {
            stopPolling()
            messagingManager.sendStoppedTypingIndicator()
            Task {
                await messagingManager.unsubscribeFromMessages()
            }
        }
        .fullScreenCover(item: $profileToShowFromMessage) { profile in
            MessageProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { profileToShowFromMessage != nil },
                    set: { if !$0 { profileToShowFromMessage = nil } }
                )
            )
        }
        .sheet(isPresented: $showMessageReportSheet) {
            if let message = messageToReport {
                ReportSheet(
                    targetName: conversation.displayName,
                    targetUserId: message.senderId,
                    message: message,
                    senderProfile: conversation.otherUser,
                    onComplete: { didBlock in
                        messageToReport = nil
                        if didBlock {
                            onClose()
                        }
                    }
                )
            }
        }
        .onChange(of: messageText) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messagingManager.sendStoppedTypingIndicator()
                lastTypingSentAt = nil
                return
            }
            typingDebounceTask?.cancel()
            // Throttle typing to at most once per second
            let now = Date()
            if lastTypingSentAt == nil || now.timeIntervalSince(lastTypingSentAt!) > 1 {
                messagingManager.sendTypingIndicator()
                lastTypingSentAt = now
            }
            typingDebounceTask = Task {
                try? await Task.sleep(for: .seconds(2))
                if !Task.isCancelled {
                    messagingManager.sendStoppedTypingIndicator()
                }
            }
        }
    }

    private func loadMessages() {
        Task {
            do {
                try await messagingManager.fetchMessages(for: conversation.id)
                await messagingManager.subscribeToMessages(conversationId: conversation.id)
                // Start polling as fallback for realtime (quota exceeded workaround)
                startPolling()
            } catch {
                print("Failed to load messages: \(error)")
            }
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                try? await messagingManager.fetchMessages(for: conversation.id)
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func handleSend() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let textToSend = trimmedText
        messageText = ""
        typingDebounceTask?.cancel()
        messagingManager.sendStoppedTypingIndicator()

        Task {
            do {
                try await messagingManager.sendMessage(to: conversation.id, content: textToSend)
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Typing Indicator (native iOS-style three bouncing dots)
private struct TypingIndicatorView: View {
    let color: Color
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

struct ChatMessageBubble: View {
    let message: Message
    let isSent: Bool
    let gradient: LinearGradient
    let conversationType: ConversationType

    private let charcoalColor = Color("Charcoal")

    private var timeString: String {
        guard let createdAt = message.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: createdAt)
    }

    var body: some View {
        HStack {
            if isSent {
                Spacer()
            }

            VStack(alignment: isSent ? .trailing : .leading, spacing: 4) {
                if isSent {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(gradient)
                        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomLeft]))
                } else {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight]))
                }

                Text(timeString)
                    .font(.system(size: 11))
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isSent ? .trailing : .leading)

            if !isSent {
                Spacer()
            }
        }
    }
}
