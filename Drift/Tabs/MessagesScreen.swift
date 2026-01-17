//
//  MessagesScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

enum ConversationType {
    case dating
    case friends
}

struct Conversation: Identifiable {
    let id: Int
    let name: String
    let lastMessage: String
    let time: String
    let unread: Bool
    let type: ConversationType
    let avatar: String
}

struct MessagesScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var conversations: [Conversation] = [
        Conversation(id: 1, name: "Sarah", lastMessage: "That sunrise hike sounds perfect! See you tomorrow", time: "2m ago", unread: true, type: .dating, avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop"),
        Conversation(id: 2, name: "Marcus", lastMessage: "Thanks for the coworking spot recommendation!", time: "1h ago", unread: false, type: .friends, avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop"),
        Conversation(id: 3, name: "Luna", lastMessage: "Would love to join the campfire tonight", time: "3h ago", unread: false, type: .friends, avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop"),
        Conversation(id: 4, name: "Jake", lastMessage: "The surf conditions look great this weekend", time: "1d ago", unread: false, type: .dating, avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop"),
        Conversation(id: 5, name: "Emma", lastMessage: "Hope you enjoy Portland!", time: "2d ago", unread: false, type: .friends, avatar: "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=100&h=100&fit=crop")
    ]
    
    @State private var searchText: String = ""
    @State private var selectedMode: ConversationType = .friends
    @State private var selectedConversation: Conversation? = nil
    @State private var segmentIndex: Int = 1 // Default to friends (index 1)
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private var isDatingEnabled: Bool {
        !supabaseManager.isFriendsOnly()
    }
    
    private var segmentOptions: [SegmentOption] {
        [
            SegmentOption(
                id: 0,
                title: "Dating",
                icon: "heart.fill",
                activeGradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, pink500]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ),
            SegmentOption(
                id: 1,
                title: "Friends",
                icon: "person.2.fill",
                activeGradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        ]
    }
    
    private var filteredConversations: [Conversation] {
        conversations.filter { $0.type == selectedMode }
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Messages")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(charcoalColor)
                        
                        Text("Your conversations")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Dating/Friends Toggle - only show if dating is enabled
                    if isDatingEnabled {
                        SegmentToggle(
                            options: segmentOptions,
                            selectedIndex: Binding(
                                get: { segmentIndex },
                                set: { newIndex in
                                    segmentIndex = newIndex
                                    selectedMode = newIndex == 0 ? .dating : .friends
                                }
                            )
                        )
                        .frame(maxWidth: 448)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(charcoalColor.opacity(0.4))
                        
                        TextField("Search messages", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(charcoalColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 8) {
                        ForEach(filteredConversations) { conversation in
                            ConversationRow(conversation: conversation) {
                                selectedConversation = conversation
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    // Empty State
                    if filteredConversations.isEmpty {
                        VStack(spacing: 8) {
                            Text("No \(selectedMode == .dating ? "dating" : "friends") messages yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            Text(selectedMode == .dating
                                 ? "Match with someone to start a conversation"
                                 : "Connect with friends to start chatting")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            // Default to friends if dating is not enabled
            if !isDatingEnabled {
                selectedMode = .friends
                segmentIndex = 1
            }
        }
        .fullScreenCover(item: $selectedConversation) { conversation in
            MessageDetailScreen(
                conversation: conversation,
                onClose: {
                    selectedConversation = nil
                }
            )
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let onTap: () -> Void
    
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
        case .friends:
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
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    AsyncImage(url: URL(string: conversation.avatar)) { phase in
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
                        Text(conversation.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)
                        
                        Spacer()
                        
                        Text(conversation.time)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    Text(conversation.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(conversation.unread ? charcoalColor : charcoalColor.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if conversation.unread {
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
    }
}

#Preview {
    MessagesScreen()
}
