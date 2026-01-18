import Foundation

/// Equipment type allowed at a campsite.
///
/// Represents a specific type of camping equipment that can be used at a site.
public struct CampsiteEquipment: Codable, Sendable {
    /// Equipment category (e.g., "tent", "rv", "trailer").
    public let kind: String
    /// Human-readable equipment name.
    public let name: String

    /// Creates a new equipment type.
    ///
    /// - Parameters:
    ///   - kind: Equipment category.
    ///   - name: Human-readable name.
    public init(kind: String, name: String) {
        self.kind = kind
        self.name = name
    }
}
