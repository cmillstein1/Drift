//
//  ConversationRow.swift
//  Drift
//

import SwiftUI
import DriftBackend

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: UUID?
    let onTap: () -> Void
    var onHide: (() -> Void)? = nil
    var onUnhide: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

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
        case .friends, .activity:
            return "person.fill"
        }
    }

    private var hasUnread: Bool {
        guard let userId = currentUserId else { return false }
        return conversation.hasUnreadMessages(for: userId)
    }

    private var displayTime: String {
        guard let updatedAt = conversation.updatedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
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
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(conversation.otherUser?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
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
                                .overlay(
                                    Text(conversation.otherUser?.initials ?? "?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
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
                        Text(conversation.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(charcoalColor)

                        Spacer()

                        Text(displayTime)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.content)
                            .font(.system(size: 14))
                            .foregroundColor(hasUnread ? charcoalColor : charcoalColor.opacity(0.6))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Send the first message")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(burntOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(burntOrange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if hasUnread {
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
        .contextMenu {
            if let onHide {
                Button(action: onHide) {
                    Label("Hide", systemImage: "eye.slash")
                }
            }
            if let onUnhide {
                Button(action: onUnhide) {
                    Label("Unhide", systemImage: "eye")
                }
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
