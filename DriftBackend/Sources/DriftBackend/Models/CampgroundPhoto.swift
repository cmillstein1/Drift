import Foundation

/// A photo of a campground or campsite.
///
/// Contains URLs for various image sizes and attribution information.
public struct CampgroundPhoto: Codable, Sendable {
    /// URL of the original full-resolution image.
    public let originalUrl: String?
    /// Whether attribution is required when displaying the photo.
    public let attributionNeeded: Bool?
    /// URL of the large-sized image.
    public let largeUrl: String?
    /// URL of the medium-sized image.
    public let mediumUrl: String?
    /// URL of the small-sized image (thumbnail).
    public let smallUrl: String?
    /// Attribution text for the photo source.
    public let attribution: String?
    /// Name or caption for the photo.
    public let name: String?

    /// Creates a new campground photo.
    ///
    /// - Parameters:
    ///   - originalUrl: URL of the original image.
    ///   - attributionNeeded: Whether attribution is required.
    ///   - largeUrl: URL of the large image.
    ///   - mediumUrl: URL of the medium image.
    ///   - smallUrl: URL of the small image.
    ///   - attribution: Attribution text.
    ///   - name: Photo name or caption.
    public init(
        originalUrl: String? = nil,
        attributionNeeded: Bool? = nil,
        largeUrl: String? = nil,
        mediumUrl: String? = nil,
        smallUrl: String? = nil,
        attribution: String? = nil,
        name: String? = nil
    ) {
        self.originalUrl = originalUrl
        self.attributionNeeded = attributionNeeded
        self.largeUrl = largeUrl
        self.mediumUrl = mediumUrl
        self.smallUrl = smallUrl
        self.attribution = attribution
        self.name = name
    }
}
