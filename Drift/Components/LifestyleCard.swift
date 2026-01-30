//
//  LifestyleCard.swift
//  Drift
//
//  Lifestyle info display card for profile views (2x2 grid)
//

import SwiftUI
import DriftBackend

struct LifestyleCard: View {
    let lifestyle: Lifestyle?
    let workStyle: WorkStyle?
    let homeBase: String?
    let morningPerson: Bool?

    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let forestGreen = Color("ForestGreen")

    private var hasContent: Bool {
        lifestyle != nil || workStyle != nil || homeBase != nil || morningPerson != nil
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Lifestyle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(charcoal)

                // 2x2 Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    // Van Life / Lifestyle
                    if let lifestyle = lifestyle {
                        LifestyleGridItem(
                            icon: lifestyleIcon(for: lifestyle),
                            label: "Van Life",
                            value: lifestyle.displayName
                        )
                    }

                    // Work Style
                    if let workStyle = workStyle {
                        LifestyleGridItem(
                            icon: "briefcase",
                            label: "Work Style",
                            value: workStyle.displayName
                        )
                    }

                    // Home Base
                    if let homeBase = homeBase, !homeBase.isEmpty {
                        LifestyleGridItem(
                            icon: "house",
                            label: "Home Base",
                            value: homeBase
                        )
                    }

                    // Morning Person
                    if let morningPerson = morningPerson {
                        LifestyleGridItem(
                            icon: morningPerson ? "sun.max" : "moon.stars",
                            label: "Morning Person",
                            value: morningPerson ? "Yes" : "No"
                        )
                    }
                }
            }
            .padding(20)
            .background(Color.white)
        }
    }

    private func lifestyleIcon(for lifestyle: Lifestyle) -> String {
        switch lifestyle {
        case .vanLife:
            return "car.side"
        case .rvLife:
            return "bus"
        case .digitalNomad:
            return "laptopcomputer"
        case .traveler:
            return "airplane"
        }
    }
}

private struct LifestyleGridItem: View {
    let icon: String
    let label: String
    let value: String

    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let forestGreen = Color("ForestGreen")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(forestGreen)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(charcoal.opacity(0.6))

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoal)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(desertSand.opacity(0.5))
    }
}

#Preview {
    VStack {
        LifestyleCard(
            lifestyle: .vanLife,
            workStyle: .remote,
            homeBase: "Portland, OR",
            morningPerson: true
        )
    }
    .padding()
    .background(Color("SoftGray"))
}
