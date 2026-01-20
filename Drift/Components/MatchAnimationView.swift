//
//  MatchAnimationView.swift
//  Drift
//
//  "It's a Match!" animation overlay
//

import SwiftUI
import DriftBackend

struct MatchAnimationView: View {
    let matchedProfile: UserProfile
    let currentUserAvatarUrl: String?
    let onSendMessage: () -> Void
    let onKeepSwiping: () -> Void

    @State private var showContent = false
    @State private var showPhotos = false
    @State private var showButtons = false
    @State private var heartScale: CGFloat = 0.1
    @State private var photosOffset: CGFloat = 100

    private let burntOrange = Color("BurntOrange")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    burntOrange.opacity(0.95),
                    pink500.opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // "It's a Match!" text
                if showContent {
                    VStack(spacing: 8) {
                        Text("It's a Match!")
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundColor(.white)

                        Text("You and \(matchedProfile.displayName) liked each other")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Profile photos with heart
                if showPhotos {
                    ZStack {
                        HStack(spacing: -20) {
                            // Current user photo
                            AsyncImage(url: URL(string: currentUserAvatarUrl ?? "")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.3), radius: 10)
                            .offset(x: showPhotos ? 0 : -photosOffset)

                            // Matched user photo
                            AsyncImage(url: URL(string: matchedProfile.photos.first ?? matchedProfile.avatarUrl ?? "")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .overlay(
                                            Text(matchedProfile.initials)
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.3), radius: 10)
                            .offset(x: showPhotos ? 0 : photosOffset)
                        }

                        // Heart icon in center
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [pink500, burntOrange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.3), radius: 8)
                            .scaleEffect(heartScale)
                    }
                    .transition(.opacity)
                }

                Spacer()

                // Action buttons
                if showButtons {
                    VStack(spacing: 16) {
                        Button(action: onSendMessage) {
                            Text("Send a Message")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(burntOrange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button(action: onKeepSwiping) {
                            Text("Keep Swiping")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Animate in sequence
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showPhotos = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
                heartScale = 1.0
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
                showButtons = true
            }
        }
    }
}

#Preview {
    MatchAnimationView(
        matchedProfile: UserProfile(
            id: UUID(),
            name: "Sarah",
            age: 28
        ),
        currentUserAvatarUrl: nil,
        onSendMessage: {},
        onKeepSwiping: {}
    )
}
