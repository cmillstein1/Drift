//
//  VanBuilderChannel.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct ChannelMessage: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userAvatar: String
    let message: String
    let timestamp: String
    let images: [String]?
    let replies: Int?
    let likes: Int
    let isExpert: Bool
    let isPinned: Bool
}

struct VanBuilderChannelView: View {
    let channel: Channel
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChannelMessage] = [
        ChannelMessage(
            id: "1",
            userId: "101",
            userName: "Mike Thompson",
            userAvatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100",
            message: "Just finished my 400W solar install! Happy to answer questions about wiring and panel mounting. Here are some photos of the setup:",
            timestamp: "2 hours ago",
            images: [
                "https://images.unsplash.com/photo-1509391366360-2e959784a276?w=600",
                "https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=600"
            ],
            replies: 12,
            likes: 24,
            isExpert: true,
            isPinned: true
        ),
        ChannelMessage(
            id: "2",
            userId: "102",
            userName: "Sarah Chen",
            userAvatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100",
            message: "What size wire did you use from the panels to the charge controller? I'm planning a similar setup.",
            timestamp: "1 hour ago",
            images: nil,
            replies: 3,
            likes: 5,
            isExpert: false,
            isPinned: false
        ),
        ChannelMessage(
            id: "3",
            userId: "103",
            userName: "Jake Morrison",
            userAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100",
            message: "Has anyone dealt with flexible panels vs rigid? Trying to decide for my Sprinter build.",
            timestamp: "45 min ago",
            images: nil,
            replies: 8,
            likes: 12,
            isExpert: false,
            isPinned: false
        ),
        ChannelMessage(
            id: "4",
            userId: "104",
            userName: "Emma Rodriguez",
            userAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100",
            message: "Pro tip: Don't cheap out on the charge controller! I learned the hard way. Victron is worth every penny.",
            timestamp: "30 min ago",
            images: nil,
            replies: nil,
            likes: 18,
            isExpert: true,
            isPinned: false
        ),
        ChannelMessage(
            id: "5",
            userId: "105",
            userName: "Chris Taylor",
            userAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100",
            message: "Looking for help with battery placement. Anyone have experience with lithium battery heating pads?",
            timestamp: "15 min ago",
            images: nil,
            replies: 2,
            likes: 3,
            isExpert: false,
            isPinned: false
        )
    ]
    
    @State private var newMessage: String = ""
    @State private var selectedImages: [String] = []
    @State private var activeThread: String? = nil
    @FocusState private var isInputFocused: Bool
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
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
                            .fill(channel.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: channel.icon)
                            .font(.system(size: 20))
                            .foregroundColor(channel.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        Text("\(channel.members.formatted()) members")
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
                Text(channel.description)
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
                    LazyVStack(spacing: 24) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, onLike: {
                                handleLike(messageId: message.id)
                            }, onReply: {
                                activeThread = message.id
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
                .background(warmWhite)
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
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
                                AsyncImage(url: URL(string: imageUrl)) { image in
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
    }
    
    private func handleSendMessage() {
        if canSend {
            let message = ChannelMessage(
                id: UUID().uuidString,
                userId: "current-user",
                userName: "You",
                userAvatar: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100",
                message: newMessage,
                timestamp: "Just now",
                images: selectedImages.isEmpty ? nil : selectedImages,
                replies: nil,
                likes: 0,
                isExpert: false,
                isPinned: false
            )
            
            messages.append(message)
            newMessage = ""
            selectedImages = []
        }
    }
    
    private func handleAddImage() {
        // Simulate image upload
        let mockImages = [
            "https://images.unsplash.com/photo-1464207687429-7505649dae38?w=600",
            "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600",
            "https://images.unsplash.com/photo-1533587851505-d119e13fa0d7?w=600"
        ]
        let randomImage = mockImages.randomElement() ?? mockImages[0]
        selectedImages.append(randomImage)
    }
    
    private func handleLike(messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            let currentMessage = messages[index]
            messages[index] = ChannelMessage(
                id: currentMessage.id,
                userId: currentMessage.userId,
                userName: currentMessage.userName,
                userAvatar: currentMessage.userAvatar,
                message: currentMessage.message,
                timestamp: currentMessage.timestamp,
                images: currentMessage.images,
                replies: currentMessage.replies,
                likes: currentMessage.likes + 1,
                isExpert: currentMessage.isExpert,
                isPinned: currentMessage.isPinned
            )
        }
    }
}

struct MessageBubble: View {
    let message: ChannelMessage
    let onLike: () -> Void
    let onReply: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
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
                AsyncImage(url: URL(string: message.userAvatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                // Message Content
                VStack(alignment: .leading, spacing: 8) {
                    // User Info
                    HStack(spacing: 8) {
                        Text(message.userName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        if message.isExpert {
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
                    Text(message.message)
                        .font(.system(size: 15))
                        .foregroundColor(charcoalColor.opacity(0.9))
                        .lineSpacing(4)
                    
                    // Images
                    if let images = message.images, !images.isEmpty {
                        if images.count == 1 {
                            AsyncImage(url: URL(string: images[0])) { image in
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
                                ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { image in
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
                        
                        if let replies = message.replies {
                            Button(action: onReply) {
                                HStack(spacing: 6) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    
                                    Text("\(replies) replies")
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
    let messageId: String
    let onClose: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Thread view would show all replies here")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
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
    }
}

#Preview {
    VanBuilderChannelView(
        channel: Channel(
            id: "electrical",
            name: "Electrical & Wiring",
            icon: "bolt.fill",
            color: Color(red: 0.80, green: 0.40, blue: 0.20),
            description: "Electrical systems, wiring, batteries, and power management",
            members: 3421,
            unreadCount: 12,
            trending: true
        )
    )
}
