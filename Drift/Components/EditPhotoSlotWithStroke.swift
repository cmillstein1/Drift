//
//  EditPhotoSlotWithStroke.swift
//  Drift
//

import SwiftUI

struct EditPhotoSlotWithStroke: View {
    let index: Int
    let photoUrl: String?
    let previewImage: Image?
    let isUploading: Bool
    let isMainPhoto: Bool
    var showMainBadge: Bool = true
    let onSelect: () -> Void
    let onRemove: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")

    private static let cornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            if isUploading {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(softGray)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: burntOrange))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Self.cornerRadius)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else if let previewImage = previewImage {
                GeometryReader { geometry in
                    previewImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(photoOverlay)
            } else if let url = photoUrl, !url.isEmpty {
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure, .empty:
                            RoundedRectangle(cornerRadius: Self.cornerRadius)
                                .fill(softGray)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: charcoalColor.opacity(0.4)))
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: Self.cornerRadius)
                                .fill(softGray)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(photoOverlay)
            } else {
                Button(action: onSelect) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Self.cornerRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(Color.gray.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: Self.cornerRadius)
                                    .fill(softGray)
                            )

                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(burntOrange)
                                    .frame(width: 40, height: 40)

                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            if isMainPhoto {
                                Text("Main")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .overlay(alignment: .topLeading) {
            if isMainPhoto, showMainBadge {
                mainBadge
            }
        }
    }

    /// Inset so the badge sits fully inside the rounded corner (radius 16).
    private static let mainBadgeInset: CGFloat = cornerRadius + 14

    private var mainBadge: some View {
        Text("MAIN")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(burntOrange)
            .clipShape(Capsule())
            .padding(.top, Self.mainBadgeInset)
            .padding(.leading, Self.mainBadgeInset)
    }

    private var photoOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(6)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
        }
    }
}
