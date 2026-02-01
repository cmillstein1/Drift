//
//  NearbyFriendsFilterSheet.swift
//  Drift
//
//  Filter sheet for Nearby Friends: distance, age, interests, lifestyle.
//

import SwiftUI
import DriftBackend

// MARK: - Filter Preferences

struct NearbyFriendsFilterPreferences: Equatable {
    var maxDistanceMiles: Int
    var minAge: Int
    var maxAge: Int
    var sharedInterestsOnly: Bool
    var lifestyleFilter: Lifestyle?

    static let `default` = NearbyFriendsFilterPreferences(
        maxDistanceMiles: 50,
        minAge: 18,
        maxAge: 80,
        sharedInterestsOnly: false,
        lifestyleFilter: nil
    )

    var hasActiveFilters: Bool {
        maxDistanceMiles != 50 || minAge != 18 || maxAge != 80 || sharedInterestsOnly || lifestyleFilter != nil
    }

    /// Single source of truth: returns whether a profile passes all active filters.
    /// - Parameters:
    ///   - profile: The profile to test.
    ///   - currentUserInterests: The current user's interests (for "shared interests only").
    ///   - currentUserLat: Current user's latitude (for distance filter); nil = don't filter by distance.
    ///   - currentUserLon: Current user's longitude (for distance filter); nil = don't filter by distance.
    func matches(_ profile: UserProfile, currentUserInterests: [String], currentUserLat: Double?, currentUserLon: Double?) -> Bool {
        // Age: include if in range; if age unknown (0), include so we don't over-filter
        let ageOk: Bool = {
            let age = profile.displayAge
            if age == 0 { return true }
            return age >= minAge && age <= maxAge
        }()

        // Shared interests: if filter off, pass. If on but current user has no interests, show all.
        let sharedOk: Bool = {
            if !sharedInterestsOnly { return true }
            if currentUserInterests.isEmpty { return true }
            let mutual = Set(currentUserInterests).intersection(Set(profile.interests))
            return !mutual.isEmpty
        }()

        // Lifestyle: if no filter, pass; else must match
        let lifestyleOk = lifestyleFilter == nil || profile.lifestyle == lifestyleFilter

        // Distance: only filter when both user and profile have coordinates
        let distanceOk: Bool = {
            guard let ulat = currentUserLat, let ulon = currentUserLon,
                  let plat = profile.latitude, let plon = profile.longitude else { return true }
            let miles = Self.haversineMiles(lat1: ulat, lon1: ulon, lat2: plat, lon2: plon)
            return miles <= Double(maxDistanceMiles)
        }()

        return ageOk && sharedOk && lifestyleOk && distanceOk
    }

    /// Distance in miles between two points (Haversine formula).
    private static func haversineMiles(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3959.0 // Earth radius in miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

// MARK: - Sheet

struct NearbyFriendsFilterSheet: View {
    @Binding var isPresented: Bool
    @Binding var preferences: NearbyFriendsFilterPreferences
    @Environment(\.dismiss) private var dismiss

    @State private var maxDistanceMiles: Double
    @State private var minAge: Double
    @State private var maxAge: Double
    @State private var sharedInterestsOnly: Bool
    @State private var lifestyleFilter: Lifestyle?

    init(isPresented: Binding<Bool>, preferences: Binding<NearbyFriendsFilterPreferences>) {
        _isPresented = isPresented
        _preferences = preferences
        let p = preferences.wrappedValue
        _maxDistanceMiles = State(initialValue: Double(p.maxDistanceMiles))
        _minAge = State(initialValue: Double(p.minAge))
        _maxAge = State(initialValue: Double(p.maxAge))
        _sharedInterestsOnly = State(initialValue: p.sharedInterestsOnly)
        _lifestyleFilter = State(initialValue: p.lifestyleFilter)
    }

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")

    var body: some View {
        VStack(spacing: 0) {
            filterSheetHeader
            filterFormContent
            applyButtonSection
        }
        .background(softGray)
    }

    private var filterSheetHeader: some View {
        HStack {
            Text("Filters")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(charcoalColor)
                .padding(.top, 8)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .frame(width: 32, height: 32)
                    .background(softGray)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(softGray)
    }

    private var filterFormContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Narrow down who appears in Nearby Friends")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    distanceSection
                    ageRangeSection
                    sharedInterestsSection
                    lifestyleSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .background(softGray)
    }

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Maximum distance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                Spacer()
                Text("\(Int(maxDistanceMiles)) mi")
                    .font(.system(size: 13))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            Slider(value: $maxDistanceMiles, in: 5...200, step: 5)
                .tint(forestGreen)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var ageRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Age range")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                Spacer()
                Text("\(Int(minAge)) – \(Int(maxAge))")
                    .font(.system(size: 13))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            // Extra horizontal padding so slider thumbs aren’t flush with card edges
            VStack(alignment: .leading, spacing: 4) {
                AgeRangeSlider(
                    minValue: $minAge,
                    maxValue: $maxAge,
                    range: 18...80,
                    accentColor: forestGreen,
                    gradientColors: [skyBlue, forestGreen]
                )
                .frame(height: 24)
                .padding(.horizontal, 12)
                HStack {
                    Text("18")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.4))
                    Spacer()
                    Text("80")
                        .font(.system(size: 12))
                        .foregroundColor(charcoalColor.opacity(0.4))
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var sharedInterestsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Shared interests only")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                Text("Show people who share at least one interest with you")
                    .font(.system(size: 12))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $sharedInterestsOnly)
                .labelsHidden()
                .tint(forestGreen)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifestyle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)

            LifestyleFilterChipsView(selection: $lifestyleFilter)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var applyButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: applyAndDismiss) {
                Text("Apply filters")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [skyBlue, forestGreen]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(softGray)
    }

    private func applyAndDismiss() {
        preferences = NearbyFriendsFilterPreferences(
            maxDistanceMiles: Int(maxDistanceMiles),
            minAge: Int(minAge),
            maxAge: Int(maxAge),
            sharedInterestsOnly: sharedInterestsOnly,
            lifestyleFilter: lifestyleFilter
        )
        dismiss()
    }
}

// MARK: - Lifestyle filter chips (avoids FlowLayout name collision)

private struct LifestyleFilterChipsView: View {
    @Binding var selection: Lifestyle?

    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")

    private var options: [Lifestyle?] {
        [nil] + Lifestyle.allCases.map { Optional($0) }
    }

    var body: some View {
        // Fixed 3-column grid for consistent alignment
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, item in
                let isSelected = selection == item
                Button(action: {
                    selection = isSelected ? nil : item
                }) {
                    Text(item?.displayName ?? "Any")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? forestGreen : Color.gray.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    NearbyFriendsFilterSheet(
        isPresented: .constant(true),
        preferences: .constant(.default)
    )
}
