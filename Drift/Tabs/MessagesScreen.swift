//
//  MessagesScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct Conversation: Identifiable {
    let id: Int
    let name: String
    let lastMessage: String
    let time: String
    let unread: Bool
    let online: Bool
}

struct MessagesScreen: View {
    @State private var conversations: [Conversation] = [
        Conversation(id: 1, name: "Sarah", lastMessage: "That sunrise hike sounds perfect! See you tomorrow", time: "2m ago", unread: true, online: true),
        Conversation(id: 2, name: "Marcus", lastMessage: "Thanks for the coworking spot recommendation!", time: "1h ago", unread: false, online: true),
        Conversation(id: 3, name: "Luna", lastMessage: "Would love to join the campfire tonight", time: "3h ago", unread: false, online: false),
        Conversation(id: 4, name: "Jake", lastMessage: "The surf conditions look great this weekend", time: "1d ago", unread: false, online: false),
        Conversation(id: 5, name: "Emma", lastMessage: "Hope you enjoy Portland!", time: "2d ago", unread: false, online: false)
    ]
    
    @State private var searchText: String = ""
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
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
                        ForEach(conversations) { conversation in
                            ConversationRow(conversation: conversation)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 8) {
                        Text("Start connecting")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        Text("Match with travelers to start a conversation")
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
}

struct ConversationRow: View {
    let conversation: Conversation
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        Button(action: {
            // Handle conversation tap
        }) {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, forestGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    if conversation.online {
                        Circle()
                            .fill(forestGreen)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: -2, y: -2)
                    }
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
