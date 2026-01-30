//
//  TravelPlansCard.swift
//  Drift
//
//  Travel plans display card for profile views
//

import SwiftUI
import DriftBackend

struct TravelPlansCard: View {
    let travelStops: [DriftBackend.TravelStop]

    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let burntOrange = Color("BurntOrange")

    // Location emoji mapping based on keywords
    private func locationEmoji(for location: String) -> String {
        let lowercased = location.lowercased()
        if lowercased.contains("beach") || lowercased.contains("coast") || lowercased.contains("ocean") {
            return "🌊"
        } else if lowercased.contains("mountain") || lowercased.contains("peak") || lowercased.contains("alpine") {
            return "⛰️"
        } else if lowercased.contains("desert") || lowercased.contains("canyon") {
            return "🏜️"
        } else if lowercased.contains("forest") || lowercased.contains("woods") || lowercased.contains("park") {
            return "🌲"
        } else if lowercased.contains("lake") || lowercased.contains("river") {
            return "🏞️"
        } else if lowercased.contains("city") || lowercased.contains("downtown") {
            return "🏙️"
        }
        return "📍"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(burntOrange)
                Text("Travel Plans")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(charcoal)
            }

            // Travel stops list
            VStack(spacing: 12) {
                ForEach(travelStops) { stop in
                    HStack(spacing: 12) {
                        // Emoji circle
                        Text(locationEmoji(for: stop.location))
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(desertSand)
                            .clipShape(Circle())

                        // Location and dates
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.location)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(charcoal)
                            Text(stop.dateRange)
                                .font(.system(size: 14))
                                .foregroundColor(charcoal.opacity(0.6))
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack {
        TravelPlansCard(travelStops: [
            DriftBackend.TravelStop(
                id: UUID(),
                userId: UUID(),
                location: "Olympic National Park",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            ),
            DriftBackend.TravelStop(
                id: UUID(),
                userId: UUID(),
                location: "Bend, Oregon",
                startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
                endDate: Calendar.current.date(byAdding: .day, value: 24, to: Date())
            ),
            DriftBackend.TravelStop(
                id: UUID(),
                userId: UUID(),
                location: "Oregon Coast",
                startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
                endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date())
            )
        ])
    }
    .padding()
    .background(Color("SoftGray"))
}
