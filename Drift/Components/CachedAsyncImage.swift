//
//  CachedAsyncImage.swift
//  Drift
//

import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    // Phase-based initializer (matches AsyncImage API)
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content

        // Check cache synchronously for immediate render
        if let url, let cached = ImageCache.shared.image(for: url) {
            _phase = State(initialValue: .success(Image(uiImage: cached)))
        }
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                // Already loaded from cache
                if case .success = phase { return }

                guard let url else {
                    phase = .empty
                    return
                }

                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard let uiImage = UIImage(data: data) else {
                        phase = .failure(URLError(.cannotDecodeContentData))
                        return
                    }
                    ImageCache.shared.insert(uiImage, for: url)
                    withAnimation(.easeIn(duration: 0.15)) {
                        phase = .success(Image(uiImage: uiImage))
                    }
                } catch {
                    phase = .failure(error)
                }
            }
    }
}

// Simple content + placeholder initializer
extension CachedAsyncImage {
    init<I: View, P: View>(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(url: url) { phase in
            if case .success(let image) = phase {
                content(image)
            } else {
                placeholder()
            }
        }
    }
}
