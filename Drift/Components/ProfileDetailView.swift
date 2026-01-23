//
//  ProfileDetailView.swift
//  Drift
//
//  Full profile view matching Discover page design
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

    // Colors from Discover
    private let coralPrimary = Color(red: 1.0, green: 0.37, blue: 0.37)
    private let inkMain = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let inkSub = Color(red: 0.42, green: 0.44, blue: 0.50)
    private let gray100 = Color(red: 0.95, green: 0.95, blue: 0.96)
    private let gray700 = Color(red: 0.37, green: 0.37, blue: 0.42)

    private var images: [String] {
        if profile.photos.isEmpty {
            return [profile.avatarUrl ?? ""]
        }
        return profile.photos
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Main scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        ZStack(alignment: .bottom) {
                            // Hero image
                            if let heroUrl = images.first,
                               let url = URL(string: heroUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geo.size.width, height: 500)
                                    } else if phase.error != nil {
                                        placeholderGradient
                                    } else {
                                        placeholderGradient
                                            .overlay(ProgressView().tint(.white))
                                    }
                                }
                                .frame(width: geo.size.width, height: 500)
                                .clipped()
                            } else {
                                placeholderGradient
                                    .frame(width: geo.size.width, height: 500)
                            }

                            // Gradient overlay
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.8), location: 0.0),
                                    .init(color: .clear, location: 0.4)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(width: geo.size.width, height: 500)

                            // Hero overlay content
                            HStack(alignment: .bottom, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(profile.displayName), \(profile.age ?? 0)")
                                        .font(.system(size: 36, weight: .heavy))
                                        .tracking(-0.5)
                                        .foregroundColor(.white)

                                    if let location = profile.location {
                                        HStack(spacing: 8) {
                                            Image(systemName: "mappin")
                                                .font(.system(size: 14))
                                            Text(location)
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    }
                                }

                                Spacer()

                                // Like button
                                Button {
                                    onLike()
                                    dismiss()
                                } label: {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                            .padding(24)
                        }
                    }
                    .frame(height: 500)

                    // ==========================================
                    // BIO SECTION
                    // ==========================================
                    VStack(alignment: .leading, spacing: 24) {
                        if let bio = profile.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 18))
                                .foregroundColor(inkMain)
                                .lineSpacing(6)
                        }

                        // Tags row (interests)
                        if !profile.interests.isEmpty {
                            WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(gray700)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(gray100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)

                    // ==========================================
                    // PROMPT SECTION 1 - "My simple pleasure"
                    // ==========================================
//                    if let simplePleasure = profile.simplePleasure, !simplePleasure.isEmpty {
//                        HStack(spacing: 0) {
//                            Rectangle()
//                                .fill(coralPrimary)
//                                .frame(width: 4)
//
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("MY SIMPLE PLEASURE")
//                                    .font(.system(size: 12, weight: .bold))
//                                    .tracking(1)
//                                    .foregroundColor(coralPrimary)
//
//                                Text(simplePleasure)
//                                    .font(.system(size: 20, weight: .medium))
//                                    .foregroundColor(inkMain)
//                            }
//                            .padding(.leading, 16)
//                            .padding(.vertical, 4)
//
//                            Spacer()
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.vertical, 8)
//                        .background(Color.white)
//                    }

                    // ==========================================
                    // RIG PHOTO SECTION
                    // ==========================================
                    if images.count > 1 {
                        GeometryReader { geo in
                            ZStack {
                                AsyncImage(url: URL(string: images[1])) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geo.size.width, height: 400)
                                    } else {
                                        placeholderGradient
                                    }
                                }
                                .frame(width: geo.size.width, height: 400)
                                .clipped()

                                // Like button top-right
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button {
                                            onLike()
                                            dismiss()
                                        } label: {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .frame(width: 48, height: 48)
                                                .background(Color.white.opacity(0.2))
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        }
                                        .padding(.trailing, 24)
                                        .padding(.top, 16)
                                    }
                                    Spacer()
                                }

                                // Rig info card bottom-left
                                if let rigInfo = profile.rigInfo, !rigInfo.isEmpty {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "box.truck.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(coralPrimary)
                                                    Text("The Rig")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(inkMain)
                                                }
                                                Text(rigInfo)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(inkSub)
                                            }
                                            .padding(12)
                                            .frame(maxWidth: 200, alignment: .leading)
                                            .background(Color.white.opacity(0.95))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                                            Spacer()
                                        }
                                        .padding(.leading, 24)
                                        .padding(.bottom, 24)
                                    }
                                }
                            }
                        }
                        .frame(height: 400)
                        .padding(.top, 24)
                    }

                    // ==========================================
                    // PROMPT SECTION 2 - "Dating me looks like"
                    // ==========================================
//                    if let datingLooksLike = profile.datingLooksLike, !datingLooksLike.isEmpty {
//                        VStack(spacing: 16) {
//                            Text("DATING ME LOOKS LIKE")
//                                .font(.system(size: 14, weight: .bold))
//                                .tracking(1)
//                                .foregroundColor(Color.gray)
//
//                            Text(datingLooksLike)
//                                .font(.system(size: 18))
//                                .foregroundColor(inkMain)
//                                .multilineTextAlignment(.center)
//                                .padding(20)
//                                .frame(maxWidth: .infinity)
//                                .background(Color.white)
//                                .clipShape(RoundedRectangle(cornerRadius: 16))
//                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 16)
//                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
//                                )
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.vertical, 32)
//                        .frame(maxWidth: .infinity)
//                        .background(Color.gray.opacity(0.05))
//                    }

                    // ==========================================
                    // ADDITIONAL PHOTOS
                    // ==========================================
                    ForEach(Array(images.dropFirst(2).enumerated()), id: \.offset) { index, photoUrl in
                        GeometryReader { geo in
                            ZStack {
                                AsyncImage(url: URL(string: photoUrl)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geo.size.width, height: 400)
                                    } else {
                                        placeholderGradient
                                    }
                                }
                                .frame(width: geo.size.width, height: 400)
                                .clipped()

                                // Like button top-right
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button {
                                            onLike()
                                            dismiss()
                                        } label: {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .frame(width: 48, height: 48)
                                                .background(Color.white.opacity(0.2))
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        }
                                        .padding(.trailing, 24)
                                        .padding(.top, 16)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(height: 400)
                    }

                    // Bottom padding for action buttons
                    Spacer().frame(height: 120)
                }
            }

            // ==========================================
            // FLOATING HEADER - close button
            // ==========================================
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()
            }

            // ==========================================
            // PASS BUTTON - bottom left
            // ==========================================
            VStack {
                Spacer()
                HStack {
                    Button {
                        onPass()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color.gray)
                            .frame(width: 64, height: 64)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
                    }

                    Spacer()
                }
                .padding(.leading, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Wrapping HStack for tags
    struct WrappingHStack: Layout {
        var alignment: HorizontalAlignment = .leading
        var horizontalSpacing: CGFloat = 8
        var verticalSpacing: CGFloat = 8

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let containerWidth = proposal.width ?? .infinity
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > containerWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }

            return CGSize(width: containerWidth, height: currentY + lineHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var currentX: CGFloat = bounds.minX
            var currentY: CGFloat = bounds.minY
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                    currentX = bounds.minX
                    currentY += lineHeight + verticalSpacing
                    lineHeight = 0
                }
                subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
                currentX += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
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
