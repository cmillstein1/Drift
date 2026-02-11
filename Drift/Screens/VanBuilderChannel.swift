//
//  VanBuilderChannel.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct VanBuilderChannelView: View {
    let channel: VanBuilderChannel
    @Environment(\.dismiss) var dismiss
    @StateObject private var vanBuilderManager = VanBuilderManager.shared

    @State private var newMessage: String = ""
    @State private var selectedImages: [String] = []
    @State private var activeThread: UUID? = nil
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)

    private var channelColor: Color {
        Color(hex: channel.color) ?? burntOrange
    }

    private var canSend: Bool {
        !newMessage.trimmingCharacters(in: .whitespaces).isEmpty || !selectedImages.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(channelColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: channel.icon)
                            .font(.system(size: 20))
                            .foregroundColor(channelColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)

                        Text("\(channel.memberCount.formatted()) members")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Channel Description
                Text(channel.description ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(charcoalColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    if vanBuilderManager.isLoading && vanBuilderManager.currentChannelMessages.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading messages...")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .padding(.vertical, 48)
                    } else if vanBuilderManager.currentChannelMessages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(charcoalColor.opacity(0.2))
                            Text("No messages yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.6))
                            Text("Be the first to start a conversation!")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.4))
                        }
                        .padding(.vertical, 48)
                    } else {
                        LazyVStack(spacing: 24) {
                            ForEach(vanBuilderManager.currentChannelMessages) { message in
                                ChannelMessageBubble(message: message, onLike: {
                                    handleLike(messageId: message.id)
                                }, onReply: {
                                    activeThread = message.id
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                    }
                }
                .background(warmWhite)
                .onChange(of: vanBuilderManager.currentChannelMessages.count) { _, _ in
                    if let lastMessage = vanBuilderManager.currentChannelMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Image Preview
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, imageUrl in
                            ZStack(alignment: .topTrailing) {
                                CachedAsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(charcoalColor)
                                        .clipShape(Circle())
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .top
                )
            }
            
            // Message Input
            HStack(spacing: 8) {
                // Attachment Buttons
                HStack(spacing: 4) {
                    Button(action: handleAddImage) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 18))
                            .foregroundColor(charcoalColor.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
                // Text Input
                HStack {
                    TextField("Share your thoughts...", text: $newMessage, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(isInputFocused ? burntOrange : Color.gray.opacity(0.2), lineWidth: 2)
                        )
                )
                
                // Send Button
                Button(action: handleSendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSend ? burntOrange : Color.gray.opacity(0.3))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .top
            )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: Binding(
            get: { activeThread != nil },
            set: { if !$0 { activeThread = nil } }
        )) {
            if let threadId = activeThread {
                ThreadView(messageId: threadId) {
                    activeThread = nil
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await vanBuilderManager.fetchChannelMessages(channel.id)
                    await vanBuilderManager.subscribeToChannel(channel.id)
                } catch {
                }
            }
        }
        .onDisappear {
            Task {
                await vanBuilderManager.unsubscribeFromChannel()
            }
        }
    }

    private func handleSendMessage() {
        guard canSend else { return }
        isSending = true

        Task {
            do {
                try await vanBuilderManager.sendChannelMessage(
                    channelId: channel.id,
                    content: newMessage,
                    images: selectedImages
                )
                await MainActor.run {
                    newMessage = ""
                    selectedImages = []
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                }
            }
        }
    }

    private func handleAddImage() {
        // TODO: Implement image picker
    }

    private func handleLike(messageId: UUID) {
        Task {
            do {
                try await vanBuilderManager.toggleLike(messageId: messageId)
            } catch {
            }
        }
    }
}

struct ChannelMessageBubble: View {
    let message: ChannelMessage
    let onLike: () -> Void
    let onReply: () -> Void

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)

    private var userName: String {
        message.user?.displayName ?? "Unknown User"
    }

    private var userAvatar: String {
        message.user?.primaryDisplayPhotoUrl ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pinned Badge
            if message.isPinned {
                HStack(spacing: 6) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundColor(burntOrange)

                    Text("Pinned by moderators")
                        .font(.system(size: 12))
                        .foregroundColor(burntOrange)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                // Avatar
                CachedAsyncImage(url: URL(string: userAvatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        Text(String(userName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                // Message Content
                VStack(alignment: .leading, spacing: 8) {
                    // User Info
                    HStack(spacing: 8) {
                        Text(userName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoalColor)

                        if message.isExpertPost {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(forestGreen)

                                Text("Expert")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(forestGreen)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(forestGreen.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        Text(message.timestamp)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.4))
                    }

                    // Message Text
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(charcoalColor.opacity(0.9))
                        .lineSpacing(4)

                    // Images
                    if !message.images.isEmpty {
                        if message.images.count == 1 {
                            CachedAsyncImage(url: URL(string: message.images[0])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(height: 192)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(Array(message.images.enumerated()), id: \.offset) { index, imageUrl in
                                    CachedAsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(height: 192)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    // Actions
                    HStack(spacing: 16) {
                        Button(action: onLike) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                Text("\(message.likes)")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.05))
                            .clipShape(Capsule())
                        }

                        if message.replyCount > 0 {
                            Button(action: onReply) {
                                HStack(spacing: 6) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))

                                    Text("\(message.replyCount) replies")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.05))
                                .clipShape(Capsule())
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
    }
}

struct ThreadView: View {
    let messageId: UUID
    let onClose: () -> Void

    @StateObject private var vanBuilderManager = VanBuilderManager.shared
    @State private var replies: [ChannelMessage] = []
    @State private var isLoading = true

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else if replies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 32))
                            .foregroundColor(charcoalColor.opacity(0.3))
                        Text("No replies yet")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(replies) { reply in
                                ChannelMessageBubble(message: reply, onLike: {}, onReply: {})
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            Task {
                do {
                    replies = try await vanBuilderManager.fetchReplies(for: messageId)
                } catch {
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    VanBuilderChannelView(
        channel: VanBuilderChannel(
            id: "electrical",
            name: "Electrical & Wiring",
            description: "Electrical systems, wiring, batteries, and power management",
            icon: "bolt.fill",
            color: "#CC6633",
            memberCount: 3421,
            trending: true,
            sortOrder: 1
        )
    )
}
