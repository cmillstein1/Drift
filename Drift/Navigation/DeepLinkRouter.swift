//
//  DeepLinkRouter.swift
//  Drift
//

import Foundation
import Combine

@MainActor
class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    enum Destination: Equatable {
        case conversation(id: UUID)
        case matchedUser(id: UUID)
        case eventPost(id: UUID)
        case communityPost(id: UUID)
    }

    @Published var pending: Destination?
}
