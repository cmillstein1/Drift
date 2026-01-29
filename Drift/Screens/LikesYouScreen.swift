//
//  LikesYouScreen.swift
//  Drift
//
//  Grid view showing people who have liked you
//

import SwiftUI
import DriftBackend

struct LikesYouScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var messagingManager = MessagingManager.shared

    @State private var selectedProfile: UserProfile? = nil
    @State private var matchedProfile: UserProfile? = nil

    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let charcoal = Color("Charcoal")

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color("SoftGray").ignoresSafeArea()

                if friendsManager.peopleLikedMe.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(friendsManager.peopleLikedMe) { profile in
                                LikeYouCard(profile: profile) {
                                    selectedProfile = profile
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, LayoutConstants.tabBarBottomPadding)
                    }
                }

            }
            .navigationTitle("Likes You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoal)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedProfile) { profile in
            ProfileDetailView(
                profile: profile,
                isOpen: Binding(
                    get: { selectedProfile != nil },
                    set: { if !$0 { selectedProfile = nil } }
                ),
                onLike: {
                    handleLikeBack(profile: profile)
                },
                onPass: {
                    handlePass(profile: profile)
                },
                showBackButton: true,
                showLikeAndPassButtons: true
            )
        }
        .fullScreenCover(item: $matchedProfile) { matched in
            MatchAnimationView(
                matchedProfile: matched,
                currentUserAvatarUrl: profileManager.currentProfile?.avatarUrl,
                onSendMessage: { messageText in
                    matchedProfile = nil
                    // Send the message if not empty
                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Task {
                            do {
                                let conversation = try await MessagingManager.shared.fetchOrCreateConversation(
                                    with: matched.id,
                                    type: .dating
                                )
                                try await MessagingManager.shared.sendMessage(
                                    to: conversation.id,
                                    content: messageText
                                )
                            } catch {
                                print("Failed to send match message: \(error)")
                            }
                        }
                    }
                    dismiss()
                },
                onKeepSwiping: {
                    matchedProfile = nil
                }
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.5))

            Text("No likes yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(charcoal)

            Text("When someone likes you, they'll appear here")
                .font(.system(size: 14))
                .foregroundColor(charcoal.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private func handleLikeBack(profile: UserProfile) {
        // Optimistically remove from list and dismiss so they disappear immediately
        friendsManager.removeFromPeopleLikedMe(id: profile.id)
        selectedProfile = nil

        Task {
            do {
                let match = try await friendsManager.swipe(on: profile.id, direction: .right)
                await MainActor.run {
                    if match != nil {
                        matchedProfile = profile
                    }
                }
            } catch {
                print("Failed to like back: \(error)")
                try? await friendsManager.fetchPeopleLikedMe()
            }
        }
    }

    private func handlePass(profile: UserProfile) {
        // Optimistically remove from list and dismiss so they disappear immediately
        friendsManager.removeFromPeopleLikedMe(id: profile.id)
        selectedProfile = nil

        Task {
            do {
                _ = try await friendsManager.swipe(on: profile.id, direction: .left)
            } catch {
                print("Failed to pass: \(error)")
                try? await friendsManager.fetchPeopleLikedMe()
            }
        }
    }
}

// MARK: - Like You Card

struct LikeYouCard: View {
    let profile: UserProfile
    let onTap: () -> Void

    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)

    var body: some View {
        Button(action: onTap) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Profile image
                    AsyncImage(url: URL(string: profile.photos.first ?? profile.avatarUrl ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            LinearGradient(
                                colors: [burntOrange, pink500],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                Text(profile.initials)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.width * 1.3)
                    .clipped()

                    // Gradient overlay
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.7), location: 0.0),
                            .init(color: .clear, location: 0.5)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )

                    // Name and age
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(profile.displayName)
                                .font(.system(size: 16, weight: .bold))

                            if profile.displayAge > 0 {
                                Text(", \(profile.displayAge)")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)

                        if let location = profile.location {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 10))
                                Text(location)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)

                    // Heart badge
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    LinearGradient(
                                        colors: [burntOrange, pink500],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(0.77, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LikesYouScreen()
}
