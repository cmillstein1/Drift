//
//  ProfileDetailView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import DriftBackend

struct ProfileDetailView: View {
    let profile: UserProfile
    @Binding var isOpen: Bool
    let onLike: () -> Void
    let onPass: () -> Void
    
    @State private var imageIndex: Int = 0
    @Environment(\.dismiss) var dismiss
    
    // Profile images - use photos array with avatar as fallback
    private var images: [String] {
        if profile.photos.isEmpty {
            return [profile.avatarUrl ?? ""]
        }
        return profile.photos
    }
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let pink500 = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private var lookingForText: String {
        switch profile.lookingFor {
        case .dating:
            return "Looking for Dating"
        case .friends:
            return "Looking for Friends"
        case .both:
            return "Looking for Dating & Friends"
        }
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Detail View
            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Image Carousel
                        ZStack(alignment: .top) {
                            GeometryReader { geometry in
                                AsyncImage(url: URL(string: images[imageIndex])) { phase in
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
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .clipped()
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
                            }
                            .frame(height: UIScreen.main.bounds.height * 0.5)
                            .frame(maxWidth: .infinity)
                            
                            // Gradient Overlay
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: UIScreen.main.bounds.height * 0.5)
                            
                            // Image Indicators
                            VStack {
                                HStack(spacing: 4) {
                                    ForEach(0..<images.count, id: \.self) { index in
                                        Button(action: {
                                            withAnimation {
                                                imageIndex = index
                                            }
                                        }) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(index == imageIndex ? Color.white : Color.white.opacity(0.3))
                                                .frame(height: 4)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                
                                Spacer()
                            }
                            
                            // Close Button
                            HStack {
                                Spacer()
                                Button(action: {
                                    dismiss()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                            .frame(width: 40, height: 40)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 20))
                                            .foregroundColor(charcoalColor)
                                    }
                                }
                                .padding(.trailing, 16)
                                .padding(.top, 16)
                            }
                            
                            // Verified Badge
                            if profile.verified {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(forestGreen)
                                    
                                    Text("Verified")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Capsule())
                                .padding(.leading, 16)
                                .padding(.top, 64)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .clipped()
                        
                        // Profile Info
                        VStack(alignment: .leading, spacing: 24) {
                                // Name & Age
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 0) {
                                        Text(profile.displayName)
                                        if let age = profile.age {
                                            Text(", \(age)")
                                        }
                                    }
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(charcoalColor)

                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor.opacity(0.6))

                                        Text(profile.location ?? "Unknown")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor.opacity(0.6))
                                    }
                                }
                                
                                // Looking For Badge
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    Text(lookingForText)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, pink500]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                
                                // Bio
                                if let bio = profile.bio {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("About")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(charcoalColor)

                                        Text(bio)
                                            .font(.system(size: 15))
                                            .foregroundColor(charcoalColor.opacity(0.7))
                                            .lineSpacing(4)
                                    }
                                }

                                // Interests
                                if !profile.interests.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Interests")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(charcoalColor)

                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
                                            ForEach(profile.interests, id: \.self) { interest in
                                                Text(interest)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(desertSand)
                                                    .clipShape(Capsule())
                                                    .fixedSize()
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }

                                // Travel Info
                                VStack(spacing: 16) {
                                    if let nextDestination = profile.nextDestination {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor.opacity(0.6))

                                                Text("Next Destination")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor.opacity(0.6))
                                            }

                                            Text(nextDestination)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(burntOrange)
                                        }
                                    }

                                    if let lifestyle = profile.lifestyle {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor.opacity(0.6))

                                                Text("Lifestyle")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor.opacity(0.6))
                                            }

                                            Text(lifestyle.displayName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(charcoalColor)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                // Safety Tips
                                VStack(spacing: 0) {
                                    Text("💡 Always meet in public places and tell a friend where you're going")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundColor(Color.gray.opacity(0.2))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.gray.opacity(0.05))
                                        )
                                )
                                .padding(.bottom, 100)
                        }
                        .padding(24)
                    }
                    
                    // Fixed Action Buttons
                    VStack(spacing: 0) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.white.opacity(0)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 20)
                        
                        HStack(spacing: 16) {
                            // Pass Button
                            Button(action: {
                                onPass()
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 56, height: 56)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Like Button
                            Button(action: {
                                onLike()
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [burntOrange, pink500]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                                    
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .background(Color.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)
                .padding(.top, UIScreen.main.bounds.height * 0.05)
                .padding(.bottom, UIScreen.main.bounds.height * 0.10)
            }
        }
    }
}

#Preview {
    ProfileDetailView(
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
            lookingFor: .dating
        ),
        isOpen: .constant(true),
        onLike: {},
        onPass: {}
    )
}
