//
//  ContentView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
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
            // Tab content
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

            // Custom floating tab bar (always visible)
            floatingTabBar
        }
        .ignoresSafeArea(.keyboard)
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
            Rectangle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
                .ignoresSafeArea(.all, edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }
}





#Preview {
    ContentView()
}
