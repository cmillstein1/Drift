//
//  ContentView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import UIKit
import DriftBackend
import Combine
import Auth

// Observable object for tab bar visibility and cross-tab navigation
class TabBarVisibility: ObservableObject {
    static let shared = TabBarVisibility()
    @Published var isVisible: Bool = true
    /// When true, Messages "Find friends" requested switch to Discover tab.
    @Published var switchToDiscoverInFriendsMode: Bool = false
    /// When true, Discover should open in Friends mode (cleared after consumed).
    @Published var discoverStartInFriendsMode: Bool = false
}

enum AppTab: String, CaseIterable {
    case discover
    case community
    case map
    case messages
    case profile

    var title: String {
        switch self {
        case .discover: return "Discover"
        case .community: return "Community"
        case .map: return "Map"
        case .messages: return "Messages"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .discover: return "compass"
        case .community: return "person.3.fill"
        case .map: return "map.fill"
        case .messages: return "message.fill"
        case .profile: return "person.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @ObservedObject private var messagingManager = MessagingManager.shared
    @ObservedObject private var appDataManager = AppDataManager.shared
    @State private var selectedTab: AppTab = .discover

    private let burntOrange = Color("BurntOrange")
    private let charcoal = Color("Charcoal")

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content — extend into bottom safe area so no visible bar above tab bar (Discover soft gray fills it)
            Group {
                switch selectedTab {
                case .discover:
                    DiscoverScreen()
                case .community:
                    CommunityScreen()
                case .map:
                    MapScreen()
                case .messages:
                    MessagesScreen()
                case .profile:
                    ProfileScreen()
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Tab bar: slide away when user scrolls down, show when near top (or when full-screen context hides it)
            floatingTabBar
                .offset(y: tabBarVisibility.isVisible ? 0 : LayoutConstants.tabBarHeight)
                .opacity(tabBarVisibility.isVisible ? 1 : 0)
                .allowsHitTesting(tabBarVisibility.isVisible)
                .animation(.easeInOut(duration: 0.25), value: tabBarVisibility.isVisible)
        }
        .ignoresSafeArea(.keyboard)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offsetY in
            // Slide tab bar away when scrolling down, show when near top (hysteresis to avoid flicker)
            let hideThreshold: CGFloat = -50
            let showThreshold: CGFloat = -20
            let shouldHide = offsetY < hideThreshold
            let shouldShow = offsetY > showThreshold
            if shouldHide, tabBarVisibility.isVisible {
                withAnimation(.easeInOut(duration: 0.25)) {
                    tabBarVisibility.isVisible = false
                }
            } else if shouldShow, !tabBarVisibility.isVisible {
                withAnimation(.easeInOut(duration: 0.25)) {
                    tabBarVisibility.isVisible = true
                }
            }
        }
        .task(id: supabaseManager.currentUser?.id) {
            guard supabaseManager.currentUser != nil else { return }
            // Initialize all app data (conversations, friends, matches, etc.)
            await appDataManager.initializeAppData()
        }
        .onDisappear {
            Task {
                await FriendsManager.shared.unsubscribe()
                await MessagingManager.shared.unsubscribe()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    // Refresh data when app becomes active
                    try? await MessagingManager.shared.fetchConversations()
                    try? await FriendsManager.shared.fetchPendingRequests(silent: true)
                    await NotificationsManager.shared.fetchNotifications()
                }
            }
        }
        .onChange(of: tabBarVisibility.switchToDiscoverInFriendsMode) { _, requested in
            if requested {
                selectedTab = .discover
                tabBarVisibility.switchToDiscoverInFriendsMode = false
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // Tabs that don’t report scroll offset (Map, Community, Messages) should show tab bar when selected
            switch newTab {
            case .map, .community, .messages:
                if !tabBarVisibility.isVisible {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        tabBarVisibility.isVisible = true
                    }
                }
            case .discover, .profile:
                break
            }
        }
    }

    private var floatingTabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        // Mark messages as read when tapping Messages tab
                        if tab == .messages {
                            Task {
                                await messagingManager.markAllAsRead()
                            }
                        }
                    }                     label: {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Group {
                                    if tab == .discover {
                                        Image("discover_rv")
                                            .resizable()
                                            .renderingMode(.template)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: tab.systemImage)
                                            .font(.system(size: 20))
                                    }
                                }
                                .foregroundColor(selectedTab == tab ? burntOrange : charcoal.opacity(0.5))

                                if tab == .messages && messagingManager.unreadCount > 0 {
                                    Circle()
                                        .fill(burntOrange)
                                        .frame(width: 8, height: 8)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                        .offset(x: 6, y: -6)
                                }
                            }

                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? burntOrange : charcoal.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Spacer()
        }
        .frame(height: LayoutConstants.tabBarHeight)
        .background(
            TabBarRoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Rounded Corner Shape
private struct TabBarRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}





#Preview {
    ContentView()
}
