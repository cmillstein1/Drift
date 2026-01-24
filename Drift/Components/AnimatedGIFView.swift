//
//  AnimatedGIFView.swift
//  Drift
//
//  SwiftUI view for displaying animated GIFs that loop continuously
//

import SwiftUI
import UIKit

struct AnimatedGIFView: UIViewRepresentable {
    let name: String
    let contentMode: UIView.ContentMode
    
    init(name: String, contentMode: UIView.ContentMode = .scaleAspectFit) {
        self.name = name
        self.contentMode = contentMode
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        
        // Try to load GIF from asset catalog (imageset or dataset)
        // First, try loading as a named image asset (works for both PNG and GIF in imagesets)
        if let image = UIImage(named: name) {
            // Check if it's an animated image (GIF)
            if let images = image.images, images.count > 1 {
                // It's already an animated image
                imageView.image = image
            } else {
                // Try to load as GIF data from bundle
                if let gifPath = Bundle.main.path(forResource: name, ofType: "gif"),
                   let gifData = try? Data(contentsOf: URL(fileURLWithPath: gifPath)),
                   let source = CGImageSourceCreateWithData(gifData as CFData, nil) {
                    let images = (0..<CGImageSourceGetCount(source)).compactMap { index -> UIImage? in
                        guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { return nil }
                        return UIImage(cgImage: cgImage)
                    }
                    
                    let animatedImage = UIImage.animatedImage(with: images, duration: gifDuration(source: source))
                    imageView.image = animatedImage
                } else {
                    // Fallback to static image
                    imageView.image = image
                }
            }
        } else {
            // Try loading from bundle directly
            if let gifURL = Bundle.main.url(forResource: name, withExtension: "gif"),
               let gifData = try? Data(contentsOf: gifURL),
               let source = CGImageSourceCreateWithData(gifData as CFData, nil) {
                let images = (0..<CGImageSourceGetCount(source)).compactMap { index -> UIImage? in
                    guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { return nil }
                    return UIImage(cgImage: cgImage)
                }
                
                let animatedImage = UIImage.animatedImage(with: images, duration: gifDuration(source: source))
                imageView.image = animatedImage
            } else {
                // Final fallback: try as regular image
                imageView.image = UIImage(named: name)
            }
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // No updates needed - GIF loops automatically
    }
    
    private func gifDuration(source: CGImageSource) -> TimeInterval {
        let count = CGImageSourceGetCount(source)
        var duration: TimeInterval = 0
        
        for index in 0..<count {
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
               let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                if let delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval {
                    duration += delayTime
                } else if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                    duration += delayTime
                }
            }
        }
        
        // If duration is 0, default to 0.1 seconds per frame
        return duration > 0 ? duration : Double(count) * 0.1
    }
}
