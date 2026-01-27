//
//  FriendDetailSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct FriendDetailView: View {
    let profile: UserProfile
    let mutualInterests: [String]
    let requestSent: Bool
    let showConnectButton: Bool
    let onConnect: ((UUID) -> Void)?
    let onMessage: ((UUID) -> Void)?
    
    init(profile: UserProfile, mutualInterests: [String], requestSent: Bool, showConnectButton: Bool = true, isFromFriendsGrid: Bool = false, onConnect: ((UUID) -> Void)? = nil, onMessage: ((UUID) -> Void)? = nil) {
        self.profile = profile
        self.mutualInterests = mutualInterests
        self.requestSent = requestSent
        self.showConnectButton = showConnectButton
        self.isFromFriendsGrid = isFromFriendsGrid
        self.onConnect = onConnect
        self.onMessage = onMessage
    }
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    
    // For navigation from friends grid, we don't want to dismiss all the way back
    var isFromFriendsGrid: Bool = false
    
    @State private var imageIndex: Int = 0
    
    // Colors
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let softGray = Color("SoftGray")
    
    // Mock additional images (in a real app, profile would have multiple images)
    private var images: [String] {
        var imageList = [String]()
        if let firstPhoto = profile.photos.first {
            imageList.append(firstPhoto)
        } else if let avatarUrl = profile.avatarUrl {
            imageList.append(avatarUrl)
        }
        // Add placeholder images if we have less than 4
        while imageList.count < 4 {
            imageList.append("")
        }
        return imageList
    }
    
    private var hasMultipleImages: Bool {
        images.count > 1 && !images[1].isEmpty
    }
    
    private var imageHeight: CGFloat {
        UIScreen.main.bounds.height * 0.5 // 50vh
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea(.all)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 0) {
                    // Image Carousel - 50vh
                    ZStack(alignment: .bottom) {
                        if hasMultipleImages {
                            TabView(selection: $imageIndex) {
                                ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                                    if !imageUrl.isEmpty {
                                        AsyncImage(url: URL(string: imageUrl)) { phase in
                                            switch phase {
                                            case .empty:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            case .failure:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .overlay(
                                                        Image(systemName: "person.fill")
                                                            .font(.system(size: 48))
                                                            .foregroundColor(.gray)
                                                    )
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                                        .clipped()
                                        .tag(index)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                                            .tag(index)
                                    }
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: imageHeight)
                        } else {
                            // Single image
                            AsyncImage(url: URL(string: images.first ?? "")) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 48))
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                            .clipped()
                        }
                        
                        // Gradient Overlay
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.2),
                                Color.clear,
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: imageHeight)
                        .allowsHitTesting(false)
                        
                        // Image Indicators
                        if hasMultipleImages {
                            VStack {
                                HStack(spacing: 4) {
                                    ForEach(0..<min(images.count, 4), id: \.self) { index in
                                        Capsule()
                                            .fill(index == imageIndex ? Color.white : Color.white.opacity(0.3))
                                            .frame(height: 2)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                
                                Spacer()
                            }
                        }
                        
                        // Verified Badge
                        if profile.verified {
                            VStack {
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(forestGreen)
                                        Text("Verified")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.trailing, 16)
                                    .padding(.bottom, 16)
                                }
                            }
                        }
                    }
                    .frame(height: imageHeight)
                    
                    // Profile Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Name, Age, Distance
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text(profile.displayName)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                
                                if profile.displayAge > 0 {
                                    Text(", \(profile.displayAge)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(charcoalColor)
                                }
                            }
                            
                            if let location = profile.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.north.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                    Text(location)
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                            }
                            
                            // Mutual Interests - directly under location
                            if !mutualInterests.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 20))
                                            .foregroundColor(burntOrange)
                                        
                                        Text("\(mutualInterests.count) shared interest\(mutualInterests.count > 1 ? "s" : "")")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    
                                    Text(mutualInterests.joined(separator: ", "))
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.7))
                                }
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            burntOrange.opacity(0.1),
                                            desertSand.opacity(0.3)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.top, 8)
                            }
                        }
                        
                        // Bio
                        if let bio = profile.bio {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                
                                Text(bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(charcoalColor.opacity(0.7))
                                    .lineSpacing(4)
                            }
                        }
                        
                        // Travel Plans
                        if profile.nextDestination != nil || profile.travelDates != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Travel Plans")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                
                                VStack(spacing: 12) {
                                    if let nextDestination = profile.nextDestination {
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin")
                                                .font(.system(size: 16))
                                                .foregroundColor(skyBlue)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Next Destination")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(charcoalColor.opacity(0.6))
                                                Text(nextDestination)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(charcoalColor)
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    if let travelDates = profile.travelDates {
                                        HStack(spacing: 12) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 16))
                                                .foregroundColor(skyBlue)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Travel Dates")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(charcoalColor.opacity(0.6))
                                                Text(travelDates)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(charcoalColor)
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(skyBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Lifestyle & Interests Tags
                        if !profile.interests.isEmpty || profile.lifestyle != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Interests")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                
                                FlowLayout(data: profile.interests.map { InterestItem($0) }, spacing: 8) { item in
                                    let isLifestyle = profile.lifestyle?.displayName == item.name
                                    HStack(spacing: 4) {
                                        if let emoji = DriftUI.emoji(for: item.name) {
                                            Text(emoji)
                                                .font(.system(size: 12))
                                        }
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(isLifestyle ? forestGreen : charcoalColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Group {
                                            if isLifestyle {
                                                Capsule()
                                                    .fill(forestGreen.opacity(0.1))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(forestGreen, lineWidth: 2)
                                                    )
                                            } else {
                                                Capsule()
                                                    .fill(desertSand)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Potential Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Would be great for...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                FriendActivityCard(emoji: "☕", title: "Coffee Meetup")
                                FriendActivityCard(emoji: "⛰️", title: "Outdoor Adventure")
                                FriendActivityCard(emoji: "💻", title: "Coworking")
                                FriendActivityCard(emoji: "🏕️", title: "Camping Trip")
                            }
                        }
                        
                        // Bottom padding for action buttons
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(24)
                }
            }
            
            // Fixed Action Buttons
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Top border
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                    
                    if showConnectButton {
                        // Connect button view (for non-friends)
                        HStack(spacing: 12) {
                            if requestSent {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Request Sent")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(forestGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(forestGreen.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(forestGreen, lineWidth: 2)
                                )
                                .clipShape(Capsule())
                            } else {
                                Button(action: {
                                    if let onConnect = onConnect {
                                        onConnect(profile.id)
                                    }
                                    dismiss()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Connect")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [skyBlue, forestGreen]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                }
                            }
                            
                            Button(action: {
                                if let onMessage = onMessage {
                                    onMessage(profile.id)
                                }
                                dismiss()
                            }) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(charcoalColor)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                    )
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    } else {
                        // Beautiful chat button for friends
                        Button(action: {
                            if let onMessage = onMessage {
                                onMessage(profile.id)
                            }
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Message \(profile.displayName)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                }
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.95))
                        .background(.ultraThinMaterial)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarBackButtonHidden(false)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation {
                tabBarVisibility.isVisible = false
            }
        }
        .onDisappear {
            withAnimation {
                tabBarVisibility.isVisible = true
            }
        }
    }
}

private struct InterestItem: Identifiable {
    let id: String
    let name: String
    
    init(_ name: String) {
        self.id = name
        self.name = name
    }
}

struct FriendActivityCard: View {
    let emoji: String
    let title: String
    
    private let charcoalColor = Color("Charcoal")
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 24))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(charcoalColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(gray100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    FriendDetailView(
        profile: UserProfile(
            id: UUID(),
            name: "Sarah",
            age: 28,
            bio: "Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.",
            avatarUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55?w=800",
            location: "Big Sur, CA",
            verified: true,
            lifestyle: .vanLife,
            nextDestination: "Portland, OR",
            travelDates: "March 15 - April 20",
            interests: ["Van Life", "Photography", "Surf", "Early Riser"],
            lookingFor: .friends
        ),
        mutualInterests: ["Photography", "Surf"],
        requestSent: false,
        showConnectButton: true,
        isFromFriendsGrid: false,
        onConnect: { _ in },
        onMessage: { _ in }
    )
}
