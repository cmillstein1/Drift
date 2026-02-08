//
//  DiscoverZoomablePhotoView.swift
//  Drift
//

import SwiftUI

struct DiscoverZoomablePhotoView: View {
    let imageURLs: [URL]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int
    @State private var scales: [Int: CGFloat] = [:]
    @State private var lastScales: [Int: CGFloat] = [:]
    @State private var offsets: [Int: CGSize] = [:]
    @State private var lastOffsets: [Int: CGSize] = [:]

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    init(imageURLs: [URL], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    zoomablePhoto(url: url, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: currentIndex) { oldIndex, _ in
                // Reset zoom on the photo we swiped away from
                withAnimation(.easeOut(duration: 0.2)) {
                    scales[oldIndex] = 1.0
                    lastScales[oldIndex] = 1.0
                    offsets[oldIndex] = .zero
                    lastOffsets[oldIndex] = .zero
                }
            }

            // Close button + pagination overlay
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

                // Pagination dots
                if imageURLs.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<imageURLs.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentIndex ? 20 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .statusBar(hidden: true)
    }

    @ViewBuilder
    private func zoomablePhoto(url: URL, index: Int) -> some View {
        let scale = scales[index] ?? 1.0
        let offset = offsets[index] ?? .zero

        CachedAsyncImage(url: url) { phase in
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
                                let last = lastScales[index] ?? 1.0
                                scales[index] = min(max(last * value, minScale), maxScale)
                            }
                            .onEnded { _ in
                                lastScales[index] = scales[index] ?? 1.0
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if (scales[index] ?? 1.0) > 1 {
                                    let last = lastOffsets[index] ?? .zero
                                    offsets[index] = CGSize(
                                        width: last.width + value.translation.width,
                                        height: last.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffsets[index] = offsets[index] ?? .zero
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3)) {
                            if (scales[index] ?? 1.0) > 1 {
                                scales[index] = 1
                                offsets[index] = .zero
                                lastOffsets[index] = .zero
                                lastScales[index] = 1
                            } else {
                                scales[index] = 2
                                lastScales[index] = 2
                            }
                        }
                    }
                    .onTapGesture(count: 1) {
                        onDismiss()
                    }
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
    }
}
