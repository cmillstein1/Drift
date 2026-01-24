//
//  ContentView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend
import Combine

// Observable object for tab bar visibility
class TabBarVisibility: ObservableObject {
    static let shared = TabBarVisibility()
    @Published var isVisible: Bool = true
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
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
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

            // Custom floating tab bar
            floatingTabBar
                .offset(y: tabBarVisibility.isVisible ? 0 : LayoutConstants.tabBarHeight + 40)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarVisibility.isVisible)
                .allowsHitTesting(tabBarVisibility.isVisible)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var floatingTabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
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
