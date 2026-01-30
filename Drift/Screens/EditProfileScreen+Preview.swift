//
//  EditProfileScreen+Preview.swift
//  Drift
//
//  Profile preview view for EditProfileScreen
//

import SwiftUI
import DriftBackend

extension EditProfileScreen {

    // MARK: - Profile Preview View

    var profilePreviewView: some View {
        ScrollView {
            VStack(spacing: 12) {
                mainPhotoCard

                if !travelStops.isEmpty {
                    TravelPlansCard(travelStops: travelStops)
                }

                if profileManager.currentProfile?.lifestyle != nil || workStyle != nil || !homeBase.isEmpty || morningPerson != nil {
                    LifestyleCard(
                        lifestyle: profileManager.currentProfile?.lifestyle,
                        workStyle: workStyle,
                        homeBase: homeBase.isEmpty ? nil : homeBase,
                        morningPerson: morningPerson
                    )
                }

                if !interests.isEmpty {
                    InterestsCard(interests: interests)
                }

                aboutCard
                promptsCard
                rigCard
                additionalPhotos

                Text("This is how your profile appears to others")
                    .font(.system(size: 13))
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .padding(.vertical, 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Preview Components

    private var mainPhotoCard: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            let cardHeight = cardWidth * 4 / 3

            ZStack(alignment: .bottom) {
                if let firstPhoto = photos.first, !firstPhoto.isEmpty,
                   let url = URL(string: firstPhoto) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipped()
                        } else {
                            previewPlaceholderGradient
                                .frame(width: cardWidth, height: cardHeight)
                        }
                    }
                } else {
                    previewPlaceholderGradient
                        .frame(width: cardWidth, height: cardHeight)
                }

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.7), location: 0.0),
                        .init(color: .clear, location: 0.5)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(name.isEmpty ? "Your Name" : name), \(age.isEmpty ? "25" : age)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            if !currentLocation.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin").font(.system(size: 14))
                                    Text(currentLocation).font(.system(size: 14))
                                }
                                .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        Spacer()
                    }
                }
                .padding(20)
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .aspectRatio(3/4, contentMode: .fit)
    }

    @ViewBuilder
    private var aboutCard: some View {
        if !about.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("About me")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(charcoalColor)
                Text(about)
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor)
                    .lineSpacing(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var promptsCard: some View {
        if !promptAnswers.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(promptAnswers.enumerated()), id: \.offset) { index, prompt in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(prompt.prompt)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(burntOrange)
                        Text(prompt.answer)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(charcoalColor)
                            .lineSpacing(4)
                    }
                    if index < promptAnswers.count - 1 {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var rigCard: some View {
        if !rigInfo.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("The Rig")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(charcoalColor)
                Text(rigInfo)
                    .font(.system(size: 16))
                    .foregroundColor(charcoalColor)
                    .lineSpacing(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var additionalPhotos: some View {
        if photos.count > 1 {
            ForEach(1..<min(photos.count, 4), id: \.self) { index in
                if let photoUrl = photos[safe: index], !photoUrl.isEmpty,
                   let url = URL(string: photoUrl) {
                    GeometryReader { geometry in
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            } else {
                                previewPlaceholderGradient
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    var previewPlaceholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview Wrapping HStack Layout

struct PreviewWrappingHStack: Layout {
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
