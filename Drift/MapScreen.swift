//
//  MapScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct NearbyUser: Identifiable {
    let id: Int
    let name: String
    let age: Int
    let distance: String
    let lifestyle: String
    let lat: Double
    let lng: Double
}

struct MapScreen: View {
    @State private var nearbyUsers: [NearbyUser] = [
        NearbyUser(id: 1, name: "Sarah", age: 28, distance: "2 mi", lifestyle: "Van Life", lat: 36.27, lng: -121.81),
        NearbyUser(id: 2, name: "Marcus", age: 31, distance: "5 mi", lifestyle: "Digital Nomad", lat: 36.29, lng: -121.83),
        NearbyUser(id: 3, name: "Luna", age: 26, distance: "8 mi", lifestyle: "Van Life", lat: 36.25, lng: -121.79),
        NearbyUser(id: 4, name: "Jake", age: 29, distance: "12 mi", lifestyle: "Backpacker", lat: 36.32, lng: -121.85)
    ]
    
    @State private var selectedUser: NearbyUser? = nil
    @State private var pulseScale: CGFloat = 1.0
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    MapBackgroundView()
                    
                    ForEach(Array(nearbyUsers.enumerated()), id: \.element.id) { index, user in
                        MapMarker(
                            user: user,
                            isSelected: selectedUser?.id == user.id,
                            position: CGPoint(
                                x: geometry.size.width * (0.35 + Double(index) * 0.10),
                                y: geometry.size.height * (0.30 + Double(index) * 0.15)
                            ),
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedUser = user
                                }
                            }
                        )
                    }
                    
                    CurrentLocationMarker(pulseScale: pulseScale)
                        .position(
                            x: geometry.size.width * 0.5,
                            y: geometry.size.height * 0.5
                        )
                    
                    VStack {
                        HStack {
                            StatsCard(count: nearbyUsers.count)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                            
                            Spacer()
                            
                            FilterButton()
                                .padding(.trailing, 16)
                                .padding(.top, 16)
                        }
                        
                        Spacer()
                        
                        if let selectedUser = selectedUser {
                            UserCard(user: selectedUser) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.selectedUser = nil
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}

struct MapBackgroundView: View {
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    skyBlue.opacity(0.2),
                    forestGreen.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            GridPattern()
                .opacity(0.1)
        }
    }
}

struct GridPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 40
                
                for x in stride(from: 0, through: geometry.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                for y in stride(from: 0, through: geometry.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }
}

struct MapMarker: View {
    let user: NearbyUser
    let isSelected: Bool
    let position: CGPoint
    let onTap: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
            onTap()
        }) {
            ZStack {
                Circle()
                    .fill(burntOrange)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Circle()
                    .fill(forestGreen)
                    .frame(width: 16, height: 16)
                    .offset(x: 18, y: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
        .scaleEffect(scale)
        .position(position)
    }
}

struct CurrentLocationMarker: View {
    let pulseScale: CGFloat
    
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    
    var body: some View {
        ZStack {
            Circle()
                .fill(skyBlue.opacity(0.2))
                .frame(width: 80, height: 80)
                .scaleEffect(pulseScale)
            
            ZStack {
                Circle()
                    .fill(skyBlue)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: "location.north.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
    }
}

struct StatsCard: View {
    let count: Int
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nearby")
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.6))
            
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(charcoalColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct FilterButton: View {
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        Button(action: {
            // Handle filter action
        }) {
            Text("Filters")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
        }
    }
}

struct UserCard: View {
    let user: NearbyUser
    let onView: () -> Void
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(user.name), \(user.age)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    Text("\(user.distance) away")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Text(user.lifestyle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(desertSand)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: onView) {
                Text("View")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(burntOrange)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}

#Preview {
    MapScreen()
}
