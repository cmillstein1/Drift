//
//  BuilderScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct PopularChannel: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let members: Int
    let color: Color
}

struct TopExpert: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let rating: Double
    let reviews: Int
}

struct RecentActivity: Identifiable {
    let id = UUID()
    let user: String
    let action: String
    let time: String
}

struct BuilderScreen: View {
    @State private var showCommunity = false
    @State private var showExpertHelp = false
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    private let amber500 = Color(red: 0.96, green: 0.62, blue: 0.04)
    
    private var popularChannels: [PopularChannel] {
        [
            PopularChannel(name: "Electrical & Wiring", icon: "bolt.fill", members: 3421, color: burntOrange),
            PopularChannel(name: "Solar & Off-Grid", icon: "sun.max.fill", members: 2890, color: amber500),
            PopularChannel(name: "Plumbing & Water", icon: "drop.fill", members: 2156, color: skyBlue)
        ]
    }
    
    private let topExperts: [TopExpert] = [
        TopExpert(name: "Mike Johnson", specialty: "Electrical & Solar", rating: 4.9, reviews: 127),
        TopExpert(name: "Sarah Chen", specialty: "Plumbing Systems", rating: 4.8, reviews: 94),
        TopExpert(name: "Tom Rodriguez", specialty: "Complete Builds", rating: 5.0, reviews: 203)
    ]
    
    private let recentActivity: [RecentActivity] = [
        RecentActivity(user: "Alex M.", action: "shared a solar wiring diagram", time: "5m ago"),
        RecentActivity(user: "Jamie K.", action: "asked about battery placement", time: "12m ago"),
        RecentActivity(user: "Chris P.", action: "completed electrical consultation", time: "1h ago")
    ]
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
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
                    
                    // Main Actions
                    HStack(spacing: 12) {
                        // Community Card
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
                        
                        // Expert Help Card
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    // Stats Row
                    HStack(spacing: 12) {
                        StatCard(value: "12.3K", label: "Builders")
                        StatCard(value: "850+", label: "Resources")
                        StatCard(value: "45", label: "Experts")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    // Popular Channels
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
                            ForEach(popularChannels) { channel in
                                Button(action: {
                                    showCommunity = true
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(channel.color.opacity(0.2))
                                                .frame(width: 48, height: 48)
                                            
                                            Image(systemName: channel.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(channel.color)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(channel.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(charcoalColor)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.2.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(charcoalColor.opacity(0.6))
                                                
                                                Text("\(channel.members.formatted()) members")
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
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                    
                    // Top Experts
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Top Rated Experts")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            Spacer()
                            
                            Button(action: {
                                showExpertHelp = true
                            }) {
                                Text("View All")
                                    .font(.system(size: 14))
                                    .foregroundColor(burntOrange)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(topExperts) { expert in
                                Button(action: {
                                    showExpertHelp = true
                                }) {
                                    HStack(spacing: 16) {
                                        // Avatar
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [burntOrange, forestGreen]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 6) {
                                                Text(expert.name)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(charcoalColor)
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(forestGreen)
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
                                                
                                                Text("\(expert.reviews) reviews")
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
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                    
                    // Recent Activity
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
                            ForEach(recentActivity) { activity in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(forestGreen)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(activity.user) \(activity.action)")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor)
                                        
                                        Text(activity.time)
                                            .font(.system(size: 12))
                                            .foregroundColor(charcoalColor.opacity(0.4))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    // Resource Library CTA
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
            }
        }
        .fullScreenCover(isPresented: $showCommunity) {
            VanBuilderCommunity()
        }
        .fullScreenCover(isPresented: $showExpertHelp) {
            BuilderHelpScreen()
        }
    }
}

#Preview {
    BuilderScreen()
}
