//
//  ContentView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct ContentView: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var activeTab: String = "discover"
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Group {
                    switch activeTab {
                    case "discover":
                        DiscoverScreen()
                    case "map":
                        MapScreen()
                    case "activities":
                        ActivitiesScreen()
                    case "builder":
                        BuilderScreen()
                    case "messages":
                        MessagesScreen()
                    case "profile":
                        ProfileScreen()
                    default:
                        DiscoverScreen()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                BottomNav(activeTab: $activeTab) { tab in
                    activeTab = tab
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}





#Preview {
    ContentView()
}
