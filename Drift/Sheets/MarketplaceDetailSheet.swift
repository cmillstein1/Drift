//
//  MarketplaceDetailSheet.swift
//  Drift
//
//  Detail sheet for Marketplace posts in the community
//

import SwiftUI

struct MarketplaceDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let post: CommunityPost
    
    @State private var currentImageIndex: Int = 0
    @State private var isSaved: Bool = false
    
    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    
    // Mock data
    private let mockImages = [
        "https://images.unsplash.com/photo-1585659722983-3a675dabf23d?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1565084888279-aca607ecce2c?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1571950672577-5a3ce6d79ceb?w=800&h=600&fit=crop",
    ]
    
    private let mockSellerInfo = (
        rating: 4.8,
        reviewCount: 24,
        responseTime: "< 1 hour",
        verified: true,
        sales: 18,
        responseRate: 98
    )
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Image Gallery
                    imageGallery
                    
                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title & Badges
                        titleSection
                        
                        // Quick Info Grid
                        quickInfoGrid
                        
                        // Description
                        descriptionSection
                        
                        // Seller Info
                        sellerSection
                        
                        // Safety Notice
                        safetyNotice
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 120) // Space for bottom buttons
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Bottom Actions
            bottomActions
        }
        .background(Color.white)
    }
    
    // MARK: - Image Gallery
    
    private var imageGallery: some View {
        ZStack(alignment: .top) {
            // Image
            TabView(selection: $currentImageIndex) {
                ForEach(0..<mockImages.count, id: \.self) { index in
                    AsyncImage(url: URL(string: mockImages[index])) { phase in
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
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)
            
            // Header Controls
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoal)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Save button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSaved.toggle()
                    }
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSaved ? .red : charcoal)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                // Share button
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoal)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            
            // Price Badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(post.price ?? "$0")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(forestGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, -20)
            }
            .frame(height: 300)
            
            // Image Dots
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<mockImages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.6))
                            .frame(width: index == currentImageIndex ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentImageIndex)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(height: 300)
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Badges
            HStack(spacing: 8) {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: "bag")
                        .font(.system(size: 12))
                    Text(post.category ?? "For Sale")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(skyBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(skyBlue.opacity(0.1))
                .clipShape(Capsule())
                
                // Condition badge
                if let condition = extractCondition() {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text(condition)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(forestGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(forestGreen.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Title
            Text(post.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(charcoal)
        }
    }
    
    // MARK: - Quick Info Grid
    
    private var quickInfoGrid: some View {
        HStack(spacing: 12) {
            // Condition
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 14))
                    Text("Condition")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.6))
                
                Text(extractCondition() ?? "Like New")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(softGray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Location
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 14))
                    Text("Location")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(charcoal.opacity(0.6))
                
                Text(post.location ?? "Santa Monica, CA")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(softGray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
            
            Text(post.content)
                .font(.system(size: 15))
                .foregroundColor(charcoal.opacity(0.7))
                .lineSpacing(6)
        }
    }
    
    // MARK: - Seller Section
    
    private var sellerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Seller")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(charcoal)
                
                Spacer()
                
                if mockSellerInfo.verified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Verified")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(forestGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(forestGreen.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Seller Info
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [skyBlue, forestGreen]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.authorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoal)
                    
                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text("\(String(format: "%.1f", mockSellerInfo.rating)) (\(mockSellerInfo.reviewCount) reviews)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        
                        Text("•")
                        
                        Text("Responds in \(mockSellerInfo.responseTime)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(charcoal.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Stats Grid
            HStack(spacing: 8) {
                statItem(label: "Listed", value: post.timeAgo)
                statItem(label: "Sales", value: "\(mockSellerInfo.sales)")
                statItem(label: "Response", value: "\(mockSellerInfo.responseRate)%")
            }
        }
        .padding(16)
        .background(softGray)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(charcoal.opacity(0.6))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(charcoal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Safety Notice
    
    private var safetyNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                Text("Safety Tips")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(burntOrange)
            
            VStack(alignment: .leading, spacing: 4) {
                safetyTip("Meet in a public place for the exchange")
                safetyTip("Inspect the item before payment")
                safetyTip("Never share sensitive personal information")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(burntOrange.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(burntOrange.opacity(0.2), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func safetyTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.system(size: 12))
        .foregroundColor(charcoal.opacity(0.7))
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            HStack(spacing: 12) {
                // Message button
                Button {
                    // Message seller
                } label: {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(skyBlue)
                        .frame(width: 48, height: 48)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(skyBlue, lineWidth: 2)
                        )
                }
                
                // Make Offer / Message Seller button
                Button {
                    // Make offer
                } label: {
                    Text("Message Seller")
                        .font(.system(size: 16, weight: .semibold))
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
                        .shadow(color: skyBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
    
    // MARK: - Helpers
    
    private func extractCondition() -> String? {
        // Try to extract condition from content or use a default
        if post.content.lowercased().contains("new") {
            return "Like New"
        } else if post.content.lowercased().contains("good") {
            return "Good"
        } else if post.content.lowercased().contains("fair") {
            return "Fair"
        }
        return "Good"
    }
}

#Preview {
    MarketplaceDetailSheet(
        post: CommunityPost(
            id: UUID(),
            type: .market,
            authorName: "Sarah Builder",
            authorAvatar: nil,
            timeAgo: "2h ago",
            location: "Santa Monica, CA",
            category: "Solar Panels",
            title: "200W Portable Solar Panel",
            content: "Barely used 200W portable solar panel. Perfect for van life or camping. Includes carrying case and MC4 connectors. Works great, selling because I upgraded to a larger system.",
            likes: nil,
            replies: nil,
            price: "$150"
        )
    )
}
