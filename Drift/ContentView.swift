//
//  ContentView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

enum AppTab: String, CaseIterable {
    case discover
    case activities
    case builder
    case messages
    case profile

    var title: String {
        switch self {
        case .discover: return "Discover"
        case .activities: return "Activities"
        case .builder: return "Builder"
        case .messages: return "Messages"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .discover: return "compass"
        case .activities: return "calendar"
        case .builder: return "wrench.and.screwdriver"
        case .messages: return "message"
        case .profile: return "person"
        }
    }
}

struct ContentView: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedTab: AppTab = .discover

    private let burntOrange = Color("BurntOrange")

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverScreen()
                .tabItem {
                    Label {
                        Text(AppTab.discover.title)
                    } icon: {
                        Image("discover_rv")
                            .renderingMode(.template)
                    }
                }
                .tag(AppTab.discover)

            ActivitiesScreen()
                .tabItem {
                    Label(AppTab.activities.title, systemImage: AppTab.activities.systemImage)
                }
                .tag(AppTab.activities)

            BuilderScreen()
                .tabItem {
                    Label(AppTab.builder.title, systemImage: AppTab.builder.systemImage)
                }
                .tag(AppTab.builder)

            MessagesScreen()
                .tabItem {
                    Label(AppTab.messages.title, systemImage: AppTab.messages.systemImage)
                }
                .tag(AppTab.messages)

            ProfileScreen()
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
                }
                .tag(AppTab.profile)
        }
        .tint(burntOrange)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}





#Preview {
    ContentView()
}
