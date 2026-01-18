import Foundation

/// Contact information for a campground.
///
/// Contains phone and email details for reaching campground staff.
public struct Contact: Codable, Sendable {
    /// Primary phone number.
    public let primaryPhone: String?
    /// Primary email address.
    public let primaryEmail: String?

    /// Creates a new contact instance.
    ///
    /// - Parameters:
    ///   - primaryPhone: Primary phone number.
    ///   - primaryEmail: Primary email address.
    public init(
        primaryPhone: String? = nil,
        primaryEmail: String? = nil
    ) {
        self.primaryPhone = primaryPhone
        self.primaryEmail = primaryEmail
    }
}
