//
//  Interests.Drift.swift
//  Drift
//
//  Interest data and utilities for Drift design system
//

import SwiftUI

extension DriftUI {
    /// Emoji lookup for interests
    public static let interestEmojis: [String: String] = [
        // Food & drink
        "Beer": "🍺", "Boba tea": "🧋", "Coffee": "☕", "Foodie": "🍝",
        "Gin": "🍸", "Pizza": "🍕", "Sushi": "🍣", "Sweet tooth": "🍭",
        "Tacos": "🌮", "Tea": "🍵", "Vegan": "🌱", "Vegetarian": "🥗",
        "Whisky": "🥃", "Wine": "🍷",
        // Traveling
        "Backpacking": "🎒", "Beaches": "🏖️", "Camping": "🏕️",
        "Exploring new cities": "🏙️", "Fishing trips": "🎣", "Hiking trips": "⛰️",
        "Road trips": "🚗", "Spa weekends": "🧖", "Staycations": "🏡", "Winter sports": "❄️",
        // Creative
        "Art": "🎨", "Photography": "📸", "Writing": "✍️",
        "Theater": "🎭", "Music": "🎸", "Dancing": "💃",
        // Active
        "Running": "🏃", "Cycling": "🚴", "Yoga": "🧘",
        "Gym": "🏋️", "Swimming": "🏊", "Skiing": "⛷️",
        // Additional common ones
        "Coding": "💻", "Dogs": "🐕", "Cats": "🐱", "National Parks": "🏞️",
        "Stargazing": "⭐", "Van Building": "🚐", "Desert Life": "🏜️",
        "Meditation": "🧘", "Hiking": "🥾", "Travel": "✈️"
    ]

    /// Get emoji for an interest, returns nil if not found
    public static func emoji(for interest: String) -> String? {
        interestEmojis[interest]
    }
}
