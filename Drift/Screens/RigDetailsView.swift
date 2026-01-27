//
//  RigDetailsView.swift
//  Drift
//
//  The Rig — structured rig details with hero card, specs grid, and features.
//

import SwiftUI

// MARK: - Conversion & Build Status

private enum ConversionType: String, CaseIterable {
    case selfBuilt = "self"
    case professional = "professional"
    case partial = "partial"
    var displayName: String {
        switch self {
        case .selfBuilt: return "Self-Built"
        case .professional: return "Pro Build"
        case .partial: return "Partial"
        }
    }
    var profileLine: String {
        switch self {
        case .selfBuilt: return "Self-Converted"
        case .professional: return "Professional Build"
        case .partial: return "Partial Build"
        }
    }
}

private enum BuildStatus: String, CaseIterable {
    case complete = "complete"
    case inProgress = "in-progress"
    case planning = "planning"
    var displayName: String {
        switch self {
        case .complete: return "Complete"
        case .inProgress: return "Building"
        case .planning: return "Planning"
        }
    }
}

// MARK: - Feature Key (for persistence and UI)

private struct RigFeature: Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let systemImage: String
}

private let rigFeatures: [RigFeature] = [
    RigFeature(key: "solar", label: "Solar", systemImage: "bolt.fill"),
    RigFeature(key: "bed", label: "Bed", systemImage: "bed.double.fill"),
    RigFeature(key: "kitchen", label: "Kitchen", systemImage: "fork.knife"),
    RigFeature(key: "shower", label: "Shower", systemImage: "drop.fill"),
    RigFeature(key: "water", label: "Water", systemImage: "drop.fill"),
    RigFeature(key: "electricity", label: "Battery", systemImage: "battery.100.bolt"),
    RigFeature(key: "heater", label: "Heater", systemImage: "thermometer.medium"),
    RigFeature(key: "ac", label: "AC", systemImage: "snowflake"),
    RigFeature(key: "wifi", label: "WiFi", systemImage: "wifi"),
    RigFeature(key: "toilet", label: "Toilet", systemImage: "wind"),
]

// MARK: - Extended State Persistence (UserDefaults)

private let rigDetailsExtendedKey = "Drift.rigDetailsExtended"

private struct RigDetailsExtended: Codable {
    var buildStatus: String
    var features: [String]
}

// MARK: - View

struct RigDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rigInfo: String
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var isEditMode = false
    @State private var vanType = "Sprinter"
    @State private var year = "2019"
    @State private var length = "144\""
    @State private var conversionType: ConversionType = .selfBuilt
    @State private var buildStatus: BuildStatus = .complete
    @State private var features: [String: Bool] = {
        var d: [String: Bool] = [:]
        for f in rigFeatures { d[f.key] = false }
        d["solar"] = true
        d["bed"] = true
        d["kitchen"] = true
        d["heater"] = true
        d["wifi"] = true
        d["water"] = true
        d["electricity"] = true
        return d
    }()

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    private var conversionTypeDisplay: String {
        conversionType.profileLine
    }

    private var activeFeatureKeys: [String] {
        features.filter { $0.value }.map { $0.key }
    }

    private var displayFeatureChipKeys: [String] {
        Array(activeFeatureKeys.prefix(4))
    }

    private var remainingFeatureCount: Int {
        max(0, activeFeatureKeys.count - 4)
    }

    private var heroChipItems: [ChipItem] {
        let featureChips = displayFeatureChipKeys.map { key in
            ChipItem(id: key, label: featureLabel(key), showIcon: true)
        }
        if remainingFeatureCount > 0 {
            return featureChips + [ChipItem(id: "more", label: "+\(remainingFeatureCount) more", showIcon: false)]
        }
        return featureChips
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    heroCard
                    specsGrid
                    if isEditMode {
                        conversionTypeSection
                        buildStatusSection
                        vanTypeSection
                        yearLengthSection
                    }
                    featuresSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 32)
            }
            .background(softGray)
            header
        }
        .navigationBarHidden(true)
        .onAppear {
            parseRigInfo()
            loadExtendedState()
            tabBarVisibility.isVisible = false
        }
        .onDisappear {
            if !isEditMode {
                saveRigInfo()
            }
        }
    }

    // MARK: - Header (glass buttons, no bar)

    private var header: some View {
        HStack {
            Button {
                saveRigInfo()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
            }
            Spacer()
            Text("The Rig")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(charcoal)
            Spacer()
            Button {
                if isEditMode { saveRigInfo() }
                isEditMode.toggle()
            } label: {
                Text(isEditMode ? "Done" : "Edit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(burntOrange)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Hero Card (modern, no background icon)

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 16))
                Text("My Rig")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.85))
            Text("\(year) \(vanType)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text("\(length) • \(conversionTypeDisplay)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            FlowLayout(data: heroChipItems, spacing: 8) { item in
                HStack(spacing: 6) {
                    if item.showIcon, let f = rigFeatures.first(where: { $0.key == item.id }) {
                        Image(systemName: f.systemImage)
                            .font(.system(size: 14))
                    }
                    Text(item.label)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.22)))
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(
                colors: [burntOrange.opacity(0.92), sunsetRose.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
    }

    // MARK: - Specs Grid

    private var specsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            specCard(title: "Van Type", value: vanType)
            specCard(title: "Status", value: buildStatus.displayName)
            specCard(title: "Year", value: year)
            specCard(title: "Length", value: length)
        }
    }

    private func specCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoal.opacity(0.5))
                if isEditMode {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(charcoal.opacity(0.3))
                }
            }
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(charcoal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4)
    }

    // MARK: - Conversion Type (edit only)

    private var conversionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversion Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(charcoal)
            HStack(spacing: 8) {
                ForEach(ConversionType.allCases, id: \.self) { type in
                    Button {
                        conversionType = type
                    } label: {
                        VStack(spacing: 8) {
                            Text(type.emoji)
                                .font(.system(size: 24))
                            Text(type.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(conversionType == type ? burntOrange : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(conversionType == type ? burntOrange : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        )
                        .foregroundColor(conversionType == type ? .white : charcoal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Build Status (edit only)

    private var buildStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build Status")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(charcoal)
            HStack(spacing: 4) {
                ForEach(BuildStatus.allCases, id: \.self) { status in
                    Button {
                        buildStatus = status
                    } label: {
                        Text(status.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(buildStatus == status ? burntOrange : Color(white: 0.95))
                            )
                            .foregroundColor(buildStatus == status ? .white : charcoal.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Van Type (edit only)

    private var vanTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Van Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(charcoal)
            VStack(spacing: 8) {
                ForEach(["Sprinter", "Transit", "ProMaster", "Econoline", "Other"], id: \.self) { type in
                    Button {
                        vanType = type
                    } label: {
                        HStack {
                            Text(type)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(vanType == type ? .white : charcoal)
                            Spacer()
                            if vanType == type {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vanType == type ? burntOrange : Color.white)
                        )
                        .shadow(color: vanType == type ? burntOrange.opacity(0.3) : .black.opacity(0.05), radius: vanType == type ? 6 : 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Year & Length (edit only)

    private var yearLengthSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Year")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoal)
                TextField("2019", text: $year)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .keyboardType(.numberPad)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Length")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoal)
                TextField("144\"", text: $length)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .keyboardType(.numbersAndPunctuation)
            }
        }
    }

    // MARK: - Features & Amenities

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Features & Amenities")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)
                Spacer()
                if isEditMode {
                    Text("\(activeFeatureKeys.count)/10")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(burntOrange)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(rigFeatures) { feature in
                    let isActive = features[feature.key, default: false]
                    Button {
                        if isEditMode {
                            features[feature.key] = !isActive
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: feature.systemImage)
                                .font(.system(size: 18))
                                .foregroundColor(isActive ? .white : charcoal.opacity(0.5))
                            Text(feature.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isActive ? .white : charcoal)
                            Spacer()
                            if isActive {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isActive ? forestGreen : Color.gray.opacity(0.3), lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isActive ? forestGreen : Color.white)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isEditMode)
                }
            }
        }
    }

    // MARK: - Helpers

    private func featureLabel(_ key: String) -> String {
        rigFeatures.first(where: { $0.key == key })?.label ?? key
    }

    private func parseRigInfo() {
        guard !rigInfo.isEmpty else { return }
        let line = rigInfo.components(separatedBy: "\n").first ?? rigInfo
        let parts = line.components(separatedBy: " ")
        if let y = Int(parts.first ?? ""), y > 1900, y < 2100 {
            year = parts[0]
        }
        for v in ["Sprinter", "Transit", "ProMaster", "Econoline", "Other"] {
            if line.contains(v) {
                vanType = v
                break
            }
        }
        if let r = line.range(of: #"\d+\""#, options: .regularExpression) {
            length = String(line[r])
        }
        if line.contains("Self-Converted") { conversionType = .selfBuilt }
        else if line.contains("Professional Build") { conversionType = .professional }
        else if line.contains("Partial Build") { conversionType = .partial }
    }

    private func loadExtendedState() {
        guard let data = UserDefaults.standard.data(forKey: rigDetailsExtendedKey),
              let decoded = try? JSONDecoder().decode(RigDetailsExtended.self, from: data) else { return }
        if let status = BuildStatus(rawValue: decoded.buildStatus) {
            buildStatus = status
        }
        for key in decoded.features {
            features[key] = true
        }
    }

    private func saveRigInfo() {
        let displayLine = "\(year) \(vanType) \(length) • \(conversionTypeDisplay)"
        rigInfo = displayLine

        var extended = RigDetailsExtended(buildStatus: buildStatus.rawValue, features: activeFeatureKeys)
        if let data = try? JSONEncoder().encode(extended) {
            UserDefaults.standard.set(data, forKey: rigDetailsExtendedKey)
        }
    }
}

// MARK: - ConversionType emoji

private extension ConversionType {
    var emoji: String {
        switch self {
        case .selfBuilt: return "🛠"
        case .professional: return "🏗"
        case .partial: return "🔀"
        }
    }
}

// MARK: - Chip Item for FlowLayout

private struct ChipItem: Identifiable {
    let id: String
    let label: String
    var showIcon: Bool = true
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RigDetailsView(rigInfo: .constant("2019 Sprinter 144\" Self-Converted"))
    }
}
