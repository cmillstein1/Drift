import Foundation

/// An external link related to a campground.
///
/// Represents a URL with a descriptive title for additional campground information.
public struct CampgroundLink: Codable, Sendable {
    /// The URL of the external resource.
    public let url: String
    /// Display title for the link.
    public let title: String

    /// Creates a new campground link.
    ///
    /// - Parameters:
    ///   - url: The URL of the external resource.
    ///   - title: Display title for the link.
    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
