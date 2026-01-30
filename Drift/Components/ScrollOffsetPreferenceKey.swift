//
//  ScrollOffsetPreferenceKey.swift
//  Drift
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if abs(next) > abs(value) {
            value = next
        } else {
            value = next
        }
    }
}
