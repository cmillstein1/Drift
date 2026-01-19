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
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool

    private var currentUserId: UUID? {
        supabaseManager.currentUser?.id
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
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(charcoalColor)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
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
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
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
                
                // Input Area
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    HStack(spacing: 8) {
                        TextField("Message...", text: $messageText, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundColor(charcoalColor)
                            .focused($isInputFocused)
                            .lineLimit(1...5)
                        
                        Button(action: {}) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 18))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                    }
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
                .background(Color.white)
            }
        }
        .onAppear {
            loadMessages()
        }
        .onDisappear {
            Task {
                await messagingManager.unsubscribeFromMessages()
            }
        }
    }

    private func loadMessages() {
        Task {
            do {
                try await messagingManager.fetchMessages(for: conversation.id)
                await messagingManager.subscribeToMessages(conversationId: conversation.id)
            } catch {
                print("Failed to load messages: \(error)")
            }
        }
    }

    private func handleSend() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let textToSend = trimmedText
        messageText = ""

        Task {
            do {
                try await messagingManager.sendMessage(to: conversation.id, content: textToSend)
            } catch {
                print("Failed to send message: \(error)")
            }
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
