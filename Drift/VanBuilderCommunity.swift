//
//  VanBuilderCommunity.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct Channel: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let description: String
    let members: Int
    let unreadCount: Int?
    let trending: Bool
}

struct Resource: Identifiable {
    let id: Int
    let title: String
    let category: String
    let views: Int
    let saves: Int
}

struct VanBuilderCommunity: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedChannel: Channel? = nil
    @State private var searchQuery: String = ""
    @State private var activeTab: ActiveTab = .channels
    
    enum ActiveTab {
        case channels
        case resources
    }
    
    private let channels: [Channel] = [
        Channel(
            id: "electrical",
            name: "Electrical & Wiring",
            icon: "bolt.fill",
            color: Color(red: 0.80, green: 0.40, blue: 0.20),
            description: "Electrical systems, wiring, batteries, and power management",
            members: 3421,
            unreadCount: 12,
            trending: true
        ),
        Channel(
            id: "solar",
            name: "Solar & Off-Grid",
            icon: "sun.max.fill",
            color: Color(red: 0.96, green: 0.62, blue: 0.04),
            description: "Solar panels, charge controllers, and off-grid power solutions",
            members: 2890,
            unreadCount: 5,
            trending: true
        ),
        Channel(
            id: "plumbing",
            name: "Plumbing & Water",
            icon: "drop.fill",
            color: Color(red: 0.53, green: 0.81, blue: 0.92),
            description: "Water tanks, pumps, filtration, and plumbing systems",
            members: 2156,
            unreadCount: nil,
            trending: false
        ),
        Channel(
            id: "hvac",
            name: "Heating & Cooling",
            icon: "thermometer",
            color: Color(red: 0.86, green: 0.15, blue: 0.15),
            description: "Heaters, AC units, ventilation, and insulation",
            members: 1834,
            unreadCount: 3,
            trending: false
        ),
        Channel(
            id: "interior",
            name: "Interior Design",
            icon: "sofa.fill",
            color: Color(red: 0.13, green: 0.55, blue: 0.13),
            description: "Layout planning, furniture building, and space optimization",
            members: 4102,
            unreadCount: nil,
            trending: true
        ),
        Channel(
            id: "finishes",
            name: "Walls & Finishes",
            icon: "paintbrush.fill",
            color: Color(red: 0.55, green: 0.36, blue: 0.96),
            description: "Wall panels, flooring, paint, and finishing touches",
            members: 1923,
            unreadCount: nil,
            trending: false
        ),
        Channel(
            id: "internet",
            name: "Internet & Tech",
            icon: "wifi",
            color: Color(red: 0.02, green: 0.71, blue: 0.83),
            description: "WiFi boosters, cellular routers, and connectivity solutions",
            members: 2567,
            unreadCount: 8,
            trending: false
        ),
        Channel(
            id: "general",
            name: "General Build Help",
            icon: "wrench.and.screwdriver.fill",
            color: Color(red: 0.2, green: 0.2, blue: 0.2),
            description: "General questions, build progress, and troubleshooting",
            members: 5234,
            unreadCount: 15,
            trending: false
        )
    ]
    
    private let resources: [Resource] = [
        Resource(id: 1, title: "Complete Electrical Wiring Guide", category: "Electrical", views: 12453, saves: 892),
        Resource(id: 2, title: "Solar System Sizing Calculator", category: "Solar", views: 8721, saves: 1205),
        Resource(id: 3, title: "Insulation Best Practices", category: "HVAC", views: 6543, saves: 734),
        Resource(id: 4, title: "Water System Diagram Templates", category: "Plumbing", views: 5892, saves: 621)
    ]
    
    private var filteredChannels: [Channel] {
        if searchQuery.isEmpty {
            return channels
        }
        return channels.filter { channel in
            channel.name.localizedCaseInsensitiveContains(searchQuery) ||
            channel.description.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        NavigationView {
            ZStack {
                warmWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor.opacity(0.4))
                            
                            TextField("Search channels and topics...", text: $searchQuery)
                                .font(.system(size: 16))
                                .foregroundColor(charcoalColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(searchQuery.isEmpty ? Color.gray.opacity(0.2) : burntOrange, lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 16)
                        
                        // Tabs
                        HStack(spacing: 8) {
                            TabButton(
                                title: "Channels",
                                icon: "number",
                                isSelected: activeTab == .channels,
                                onTap: { activeTab = .channels }
                            )
                            
                            TabButton(
                                title: "Resources",
                                icon: "book.fill",
                                isSelected: activeTab == .resources,
                                onTap: { activeTab = .resources }
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .background(Color.white)
                    
                    // Content
                    ScrollView {
                        if activeTab == .channels {
                            channelsContent
                        } else {
                            resourcesContent
                        }
                    }
                }
            }
            .navigationTitle("Van Builder Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            VanBuilderChannel(channel: channel)
        }
    }
    
    private var channelsContent: some View {
        VStack(spacing: 16) {
            // Featured Banner
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Text("Trending This Week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("Common Electrical Mistakes to Avoid")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Join the discussion in #electrical-wiring with 200+ active builders")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Button(action: {}) {
                    Text("Join Discussion")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [burntOrange, forestGreen]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Channels List
            if filteredChannels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(charcoalColor.opacity(0.2))
                    
                    Text("No channels found matching \"\(searchQuery)\"")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                .padding(.vertical, 48)
            } else {
                ForEach(filteredChannels) { channel in
                    ChannelCard(channel: channel) {
                        selectedChannel = channel
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()
                .frame(height: 100)
        }
    }
    
    private var resourcesContent: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Popular Resources")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 14))
                        .foregroundColor(burntOrange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            ForEach(resources) { resource in
                ResourceCard(resource: resource)
                    .padding(.horizontal, 16)
            }
            
            // Upload Resource CTA
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .foregroundColor(charcoalColor.opacity(0.4))
                
                Text("Share Your Knowledge")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                Text("Help the community by uploading guides, templates, or diagrams")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Button(action: {}) {
                    Text("Upload Resource")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(burntOrange)
                        .clipShape(Capsule())
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(Color.gray.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.05))
                    )
            )
            .padding(.horizontal, 16)
            
            Spacer()
                .frame(height: 100)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : charcoalColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? burntOrange : Color.gray.opacity(0.1))
            )
        }
    }
}

struct ChannelCard: View {
    let channel: Channel
    let onTap: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Channel Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(channel.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: channel.icon)
                        .font(.system(size: 24))
                        .foregroundColor(channel.color)
                }
                
                // Channel Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(channel.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                        
                        if channel.trending {
                            Text("Hot")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(burntOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(burntOrange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(channel.description)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.5))
                        
                        Text("\(channel.members.formatted()) members")
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Unread Badge
                if let unreadCount = channel.unreadCount {
                    ZStack {
                        Circle()
                            .fill(burntOrange)
                            .frame(width: 24, height: 24)
                        
                        Text("\(unreadCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResourceCard: View {
    let resource: Resource
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                    
                    Text(resource.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(desertSand)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(charcoalColor.opacity(0.4))
            }
            
            HStack(spacing: 8) {
                Text("\(resource.views.formatted()) views")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.5))
                
                Text("•")
                    .foregroundColor(charcoalColor.opacity(0.5))
                
                Text("\(resource.saves.formatted()) saves")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.5))
            }
            
            Button(action: {}) {
                Text("View Resource")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(burntOrange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(burntOrange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    VanBuilderCommunity()
}
