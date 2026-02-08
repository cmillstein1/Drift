//
//  ImageCache.swift
//  Drift
//

import UIKit

final class ImageCache {
    static let shared = ImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        return cache
    }()

    private init() {}

    /// Returns a cache key that includes the target size when provided (e.g. "https://…_56x56").
    private func cacheKey(for url: URL, targetSize: CGSize?) -> NSString {
        if let size = targetSize {
            return "\(url.absoluteString)_\(Int(size.width))x\(Int(size.height))" as NSString
        }
        return url.absoluteString as NSString
    }

    func image(for url: URL, targetSize: CGSize? = nil) -> UIImage? {
        cache.object(forKey: cacheKey(for: url, targetSize: targetSize))
    }

    func insert(_ image: UIImage, for url: URL, targetSize: CGSize? = nil) {
        // Pixel-based cost estimate: width * height * scale^2 * 4 bytes per pixel
        // Avoids expensive JPEG re-encoding on every cache insert
        let cost = Int(image.size.width * image.scale * image.size.height * image.scale * 4)
        cache.setObject(image, forKey: cacheKey(for: url, targetSize: targetSize), cost: cost)
    }

    func remove(for url: URL) {
        cache.removeObject(forKey: url.absoluteString as NSString)
    }
}
