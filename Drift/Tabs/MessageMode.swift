//
//  MessageMode.swift
//  Drift
//

import Foundation

enum MessageMode {
    case dating
    case friends
}

// Convert MessageMode to DiscoverMode for the switcher
extension MessageMode {
    var discoverMode: DiscoverMode {
        switch self {
        case .dating: return .dating
        case .friends: return .friends
        }
    }

    init(_ discoverMode: DiscoverMode) {
        switch discoverMode {
        case .dating: self = .dating
        case .friends: self = .friends
        }
    }
}
