//
//  BuilderScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct BuilderScreen: View {
    @State private var showCommunity = false
    @State private var showExpertHelp = false
    @State private var showPaywall = false
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @StateObject private var vanBuilderManager = VanBuilderManager.shared

    private var channels: [VanBuilderChannel] {
        vanBuilderManager.channels
    }

    private var experts: [VanBuilderExpert] {
        vanBuilderManager.experts
    }

    private func loadData() {
        Task {
            do {
                try await vanBuilderManager.fetchChannels()
                try await vanBuilderManager.fetchExperts()
            } catch {
                print("Failed to load builder data: \(error)")
            }
        }
    }

    private func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let amber500 = Color(red: 0.96, green: 0.62, blue: 0.04)

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Van Builder")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(charcoalColor)

            Text("Community support & expert help for your build")
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Community Card
    private var communityCard: some View {
        Button(action: {
            showCommunity = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "message")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                Text("Community")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Chat with 12K+ builders")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))

                    Text("145 active now")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Expert Help Card
    private var expertHelpCard: some View {
        Button(action: {
            showExpertHelp = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "wrench")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                Text("Expert Help")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Book 1-on-1 sessions")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Verified pros")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [burntOrange, pink500]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Main Actions View
    private var mainActionsView: some View {
        HStack(spacing: 12) {
            communityCard
            expertHelpCard
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Popular Channels View
    private var popularChannelsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Channels")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)

                Spacer()

                Button(action: {
                    showCommunity = true
                }) {
                    Text("View All")
                        .font(.system(size: 14))
                        .foregroundColor(burntOrange)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(Array(channels.prefix(3))) { channel in
                    channelRow(channel: channel)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Channel Row
    private func channelRow(channel: VanBuilderChannel) -> some View {
        Button(action: {
            showCommunity = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorFromHex(channel.color).opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: channel.icon)
                        .font(.system(size: 24))
                        .foregroundColor(colorFromHex(channel.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))

                        Text("\(channel.memberCount.formatted()) members")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Top Experts View
    private var topExpertsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Rated Experts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)

                Spacer()

                Button(action: {
                    if revenueCatManager.hasProAccess {
                        showExpertHelp = true
                    } else {
                        showPaywall = true
                    }
                }) {
                    Text("View All")
                        .font(.system(size: 14))
                        .foregroundColor(burntOrange)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(Array(experts.prefix(3))) { expert in
                    expertRow(expert: expert)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Expert Row
    private func expertRow(expert: VanBuilderExpert) -> some View {
        Button(action: {
            if revenueCatManager.hasProAccess {
                showExpertHelp = true
            } else {
                showPaywall = true
            }
        }) {
            HStack(spacing: 16) {
                expertAvatar(expert: expert)
                expertInfo(expert: expert)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Expert Avatar
    @ViewBuilder
    private func expertAvatar(expert: VanBuilderExpert) -> some View {
        if let avatarUrl = expert.profile?.primaryDisplayPhotoUrl, let url = URL(string: avatarUrl) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, forestGreen]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [burntOrange, forestGreen]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
        }
    }

    // MARK: - Expert Info
    private func expertInfo(expert: VanBuilderExpert) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(expert.profile?.displayName ?? "Expert")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)

                if expert.verified {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(forestGreen)
                }
            }

            Text(expert.specialty)
                .font(.system(size: 13))
                .foregroundColor(charcoalColor.opacity(0.6))

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(burntOrange)

                    Text("\(expert.rating, specifier: "%.1f")")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor)
                }

                Text("•")
                    .foregroundColor(charcoalColor.opacity(0.4))

                Text("\(expert.reviewCount) reviews")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
        }
    }

    // MARK: - Recent Activity View
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundColor(burntOrange)

                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            VStack(spacing: 12) {
                Text("Join the community to see recent activity")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .padding(.horizontal, 20)

                Button(action: {
                    showCommunity = true
                }) {
                    Text("View Community")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(burntOrange)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Resource Library View
    private var resourceLibraryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 48))
                .foregroundColor(charcoalColor.opacity(0.4))

            Text("Resource Library")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(charcoalColor)

            Text("Guides, diagrams, and templates for every build phase")
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.6))
                .multilineTextAlignment(.center)

            Button(action: {
                showCommunity = true
            }) {
                Text("Browse Resources")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(burntOrange)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(Color.gray.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.05))
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
    }

    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    mainActionsView
                    statsRowView
                    popularChannelsView
                    topExpertsView
                    recentActivityView
                    resourceLibraryView
                }
            }
        }
        .fullScreenCover(isPresented: $showCommunity) {
            VanBuilderCommunity()
        }
        .fullScreenCover(isPresented: $showExpertHelp) {
            BuilderHelpScreen()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallScreen(isOpen: $showPaywall, source: .expertHelp)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Stats Row View
    private var statsRowView: some View {
        HStack(spacing: 12) {
            StatCard(value: "12.3K", label: "Builders")
            StatCard(value: "850+", label: "Resources")
            StatCard(value: "45", label: "Experts")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

#Preview {
    BuilderScreen()
}
