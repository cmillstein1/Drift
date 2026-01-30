//
//  DiscoverZoomablePhotoView.swift
//  Drift
//

import SwiftUI

struct DiscoverZoomablePhotoView: View {
    let imageURL: URL
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture { onDismiss() }

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(lastScale * value, minScale), maxScale)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                default:
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.4), radius: 4)
                    }
                    .padding(24)
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3)) {
                if scale > 1 {
                    scale = 1
                    offset = .zero
                    lastOffset = .zero
                    lastScale = 1
                } else {
                    scale = 2
                    lastScale = 1
                }
            }
        }
    }
}
