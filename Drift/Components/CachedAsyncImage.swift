//
//  CachedAsyncImage.swift
//  Drift
//

import SwiftUI
import ImageIO

/// Coordinates in-flight image downloads so the same URL is only fetched once,
/// even when multiple views request it simultaneously.
private actor ImageDownloadCoordinator {
    static let shared = ImageDownloadCoordinator()

    private var inFlight: [URL: Task<Data, Error>] = [:]

    func data(for url: URL) async throws -> Data {
        if let existing = inFlight[url] {
            return try await existing.value
        }

        let task = Task<Data, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        inFlight[url] = task

        do {
            let result = try await task.value
            inFlight[url] = nil
            return result
        } catch {
            inFlight[url] = nil
            throw error
        }
    }
}

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let targetSize: CGSize?
    private let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    /// Phase-based initializer with optional downsampling.
    /// - Parameters:
    ///   - url: The image URL.
    ///   - targetSize: Point size to downsample to (e.g. CGSize(width: 56, height: 56)).
    ///     `nil` loads at full resolution (backward compatible).
    ///   - content: ViewBuilder receiving the async image phase.
    init(url: URL?, targetSize: CGSize? = nil, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.targetSize = targetSize
        self.content = content

        // Check cache synchronously for immediate render
        if let url, let cached = ImageCache.shared.image(for: url, targetSize: targetSize) {
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
                    let data = try await ImageDownloadCoordinator.shared.data(for: url)

                    let uiImage: UIImage?
                    if let targetSize {
                        uiImage = Self.downsample(data: data, to: targetSize)
                    } else {
                        uiImage = UIImage(data: data)
                    }

                    guard let uiImage else {
                        phase = .failure(URLError(.cannotDecodeContentData))
                        return
                    }
                    ImageCache.shared.insert(uiImage, for: url, targetSize: targetSize)
                    withAnimation(.easeIn(duration: 0.15)) {
                        phase = .success(Image(uiImage: uiImage))
                    }
                } catch {
                    phase = .failure(error)
                }
            }
    }

    /// Decodes image data directly at the target pixel size using ImageIO,
    /// avoiding a full-resolution decode. A 1200x1200 image downsampled to
    /// 56x56@3x uses ~110 KB instead of ~5.5 MB.
    private static func downsample(data: Data, to pointSize: CGSize) -> UIImage? {
        let scale = UIScreen.main.scale
        let maxPixel = max(pointSize.width, pointSize.height) * scale

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}

// Simple content + placeholder initializer
extension CachedAsyncImage {
    init<I: View, P: View>(
        url: URL?,
        targetSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(url: url, targetSize: targetSize) { phase in
            if case .success(let image) = phase {
                content(image)
            } else {
                placeholder()
            }
        }
    }
}
