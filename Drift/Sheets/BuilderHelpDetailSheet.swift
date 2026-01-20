//
//  BuilderHelpDetailSheet.swift
//  Drift
//
//  Detail sheet for Build Help posts in the community
//

import SwiftUI

struct HelpReply: Identifiable {
    let id: UUID
    let user: String
    let avatar: String?
    let time: String
    let message: String
    let helpful: Int
    let isExpert: Bool
}

struct BuilderHelpDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let post: CommunityPost
    
    @State private var replyText: String = ""
    @State private var isHelpful: Bool = false
    @FocusState private var isReplyFocused: Bool
    
    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)
    
    // Mock replies for demonstration
    private let mockReplies: [HelpReply] = [
        HelpReply(
            id: UUID(),
            user: "Alex Turner",
            avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop",
            time: "30min ago",
            message: "I had the same issue! Turned out my inverter was undersized for the surge current. Blenders can pull 3-4x their rated power on startup. You might need a larger inverter or use a different appliance.",
            helpful: 12,
            isExpert: false
        ),
        HelpReply(
            id: UUID(),
            user: "Maria Santos",
            avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop",
            time: "15min ago",
            message: "Also check your battery cables! Make sure they're thick enough (at least 4 AWG for a 2000W setup). Voltage drop can cause inverters to trip even with a full battery.",
            helpful: 8,
            isExpert: true
        ),
        HelpReply(
            id: UUID(),
            user: "Jake Martinez",
            avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop",
            time: "5min ago",
            message: "Quick fix: try using your blender at a lower speed first, then ramp up. That helped me reduce the surge current!",
            helpful: 4,
            isExpert: false
        ),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            scrollableContent
            replyInputSection
        }
        .background(warmWhite)
        .onTapGesture {
            isReplyFocused = false
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            headerTopRow
            titleView
            userInfoRow
        }
        .background(warmWhite)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var headerTopRow: some View {
        HStack {
            categoryBadge
            Spacer()
            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    private var categoryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 12))
            Text(post.category ?? "Build Help")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(burntOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(burntOrange.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(charcoal)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    private var titleView: some View {
        Text(post.title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(charcoal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 12)
    }
    
    private var userInfoRow: some View {
        HStack(spacing: 12) {
            avatarGradient
            userDetails
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    private var avatarGradient: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 40, height: 40)
    }
    
    private var userDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(post.authorName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(post.timeAgo)
                    .font(.system(size: 12))
            }
            .foregroundColor(charcoal.opacity(0.5))
        }
    }
    
    // MARK: - Scrollable Content
    
    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                detailsSection
                engagementStats
                repliesSection
            }
        }
        .background(warmWhite)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
            
            Text(post.content)
                .font(.system(size: 15))
                .foregroundColor(charcoal.opacity(0.7))
                .lineSpacing(6)
        }
        .padding(24)
    }
    
    private var engagementStats: some View {
        HStack(spacing: 16) {
            helpfulButton
            repliesCount
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    private var helpfulButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHelpful.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 14))
                Text("\((post.likes ?? 0) + (isHelpful ? 1 : 0))")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isHelpful ? forestGreen : charcoal.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHelpful ? forestGreen.opacity(0.1) : Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private var repliesCount: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left")
                .font(.system(size: 14))
            Text("\(post.replies ?? 0) replies")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(charcoal.opacity(0.6))
    }
    
    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Answers (\(mockReplies.count))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            ForEach(mockReplies) { reply in
                ReplyCard(reply: reply, burntOrange: burntOrange, forestGreen: forestGreen, charcoal: charcoal)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Reply Input Section
    
    private var replyInputSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            HStack(spacing: 12) {
                replyTextField
                sendButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
    
    private var replyTextField: some View {
        TextField("Share your advice...", text: $replyText)
            .font(.system(size: 15))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(softGray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isReplyFocused ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .focused($isReplyFocused)
    }
    
    private var sendButton: some View {
        Button {
            handleSendReply()
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(sendButtonBackground)
                .clipShape(Circle())
        }
        .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    @ViewBuilder
    private var sendButtonBackground: some View {
        if replyText.trimmingCharacters(in: .whitespaces).isEmpty {
            Color.gray.opacity(0.3)
        } else {
            LinearGradient(
                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func handleSendReply() {
        guard !replyText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        print("Sending reply: \(replyText)")
        replyText = ""
        isReplyFocused = false
    }
}

// MARK: - Reply Card

struct ReplyCard: View {
    let reply: HelpReply
    let burntOrange: Color
    let forestGreen: Color
    let charcoal: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            replyHeader
            messageText
            actionButtons
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var replyHeader: some View {
        HStack(spacing: 12) {
            avatarView
            userInfoView
            Spacer()
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = reply.avatar, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderCircle
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                case .failure:
                    placeholderCircle
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            placeholderCircle
        }
    }
    
    private var placeholderCircle: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 36, height: 36)
    }
    
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(reply.user)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)
                
                if reply.isExpert {
                    expertBadge
                }
            }
            
            Text(reply.time)
                .font(.system(size: 12))
                .foregroundColor(charcoal.opacity(0.5))
        }
    }
    
    private var expertBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
            Text("Expert")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(forestGreen)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(forestGreen.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var messageText: some View {
        Text(reply.message)
            .font(.system(size: 14))
            .foregroundColor(charcoal.opacity(0.7))
            .lineSpacing(4)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                // Mark as helpful
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 12))
                    Text("Helpful (\(reply.helpful))")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Button {
                // Reply to this
            } label: {
                Text("Reply")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(burntOrange)
            }
        }
    }
}

#Preview {
    BuilderHelpDetailSheet(
        post: CommunityPost(
            id: UUID(),
            type: .help,
            authorName: "Dave Builder",
            authorAvatar: nil,
            timeAgo: "1h ago",
            location: nil,
            category: "Electrical",
            title: "Inverter keeps tripping?",
            content: "I have a 2000W Renogy inverter that trips every time I turn on my blender. Battery bank is full. Anyone seen this?",
            likes: nil,
            replies: 5,
            price: nil
        )
    )
}
