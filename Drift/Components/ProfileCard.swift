//
//  ProfileCard.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct ProfileCard: View {
    let profile: UserProfile
    let isTop: Bool
    let mode: DiscoverMode
    let scale: Double
    let offset: Double
    let onSwipe: (SwipeDirection) -> Void
    let onTap: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let desertSand = Color("DesertSand")
    private let skyBlue = Color("SkyBlue")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51) // Keep pink500 as is since it's not in assets
    
    private var shouldShowDatingBadge: Bool {
        let lookingFor = profile.lookingFor
        return lookingFor == .dating || (lookingFor == .both && mode == .dating)
    }

    private var shouldShowFriendsBadge: Bool {
        let lookingFor = profile.lookingFor
        return lookingFor == .friends || (lookingFor == .both && mode == .friends)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 0) {
                    // Image section - 60% height
                    ZStack(alignment: .topLeading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.black.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)
                        
                        // Badges - positioned to avoid overlap
                        HStack {
                            // Looking For Badge (top left)
                            if shouldShowDatingBadge {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    Text("Dating")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, pink500]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                            } else if shouldShowFriendsBadge {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    Text("Friends")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [skyBlue, forestGreen]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            // Verified Badge (top right)
                            if profile.verified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(forestGreen)
                                    
                                    Text("Verified")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                    .background(
                        AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    ProgressView()
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .allowsHitTesting(false)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: RectangleCornerRadii(
                                topLeading: 24,
                                bottomLeading: 0,
                                bottomTrailing: 0,
                                topTrailing: 24
                            )
                        )
                    )
                    
                    // Content section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text(profile.displayName)
                                if let age = profile.age {
                                    Text(", \(age)")
                                }
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(charcoalColor)

                            HStack(spacing: 4) {
                                Image("map_pin")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                Text(profile.location ?? "Unknown")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }

                        if let bio = profile.bio {
                            Text(bio)
                                .font(.system(size: 15))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Tags (interests)
                        HStack(spacing: 8) {
                            ForEach(profile.interests.prefix(4), id: \.self) { interest in
                                Text(interest)
                                    .font(.system(size: 13))
                                    .foregroundColor(charcoalColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(desertSand)
                                    .clipShape(Capsule())
                            }
                        }

                        if let nextDestination = profile.nextDestination {
                            HStack(spacing: 4) {
                                Text("Next:")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))

                                Text(nextDestination)
                                    .font(.system(size: 14))
                                    .foregroundColor(burntOrange)
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scaleEffect(scale)
            .offset(x: isTop ? dragOffset.width : 0, y: offset + (isTop ? dragOffset.height : 0))
            .rotationEffect(.degrees(isTop ? dragRotation : 0))
            .opacity(isTop ? (1.0 - abs(dragOffset.width) / 500.0) : 0.95)
            .gesture(
                isTop ? DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        dragRotation = Double(value.translation.width / 20)
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > 100 {
                            onSwipe(value.translation.width > 0 ? .right : .left)
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                                dragRotation = 0
                            }
                        }
                    }
                : nil
            )
            .onTapGesture {
                if isTop {
                    onTap()
                }
            }
        }
    }
}

#Preview {
    ProfileCard(
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
            interests: ["Van Life", "Photography", "Surf", "Early Riser"],
            lookingFor: .both
        ),
        isTop: true,
        mode: .friends,
        scale: 1.0,
        offset: 0,
        onSwipe: { _ in },
        onTap: { }
    )
    .frame(height: 600)
    .padding()
}
