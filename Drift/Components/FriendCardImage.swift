//
//  FriendCardImage.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

// Profile image with verified badge for friend cards
struct FriendCardImage: View {
    let imageUrl: String
    let verified: Bool
    
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Profile Image
            CachedAsyncImage(url: URL(string: imageUrl), targetSize: CGSize(width: 96, height: 96)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(softGray)
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Verified Badge
            if verified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(forestGreen)
                    .padding(2)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .offset(x: 4, y: -4)
            }
        }
        .frame(width: 96, height: 96)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Verified user
        FriendCardImage(
            imageUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55",
            verified: true
        )
        
        // Non-verified user
        FriendCardImage(
            imageUrl: "https://images.unsplash.com/photo-1682101525282-545b10c4bb55",
            verified: false
        )
    }
    .padding()
}
