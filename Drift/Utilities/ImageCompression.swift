//
//  ImageCompression.swift
//  Drift
//

import UIKit

enum ImageCompression {
    /// Resizes an image so its longest edge is at most `maxDimension` points.
    /// Returns the original image if already within bounds.
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)

        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Compresses an image to JPEG data under `maxFileSizeMB`.
    /// First resizes to 1200px max, then progressively lowers quality.
    static func compressImage(_ image: UIImage, maxFileSizeMB: Double) -> Data? {
        let resized = resizeImage(image, maxDimension: 1200)

        let maxFileSizeBytes = Int(maxFileSizeMB * 1024 * 1024)
        var compressionQuality: CGFloat = 0.8
        var imageData = resized.jpegData(compressionQuality: compressionQuality)

        while let data = imageData, data.count > maxFileSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resized.jpegData(compressionQuality: compressionQuality)
        }

        return imageData
    }
}
