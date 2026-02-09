//
//  TravelPlansEditorView.swift
//  Drift
//
//  Editor for managing travel plans/schedule
//

import SwiftUI
import DriftBackend

struct TravelPlansEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared

    @State private var travelStops: [DriftBackend.TravelStop] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showAddStop = false
    @State private var editingStop: DriftBackend.TravelStop?

    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")

    var body: some View {
        ZStack {
            softGray.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if travelStops.isEmpty {
                        emptyState
                    } else {
                        ForEach(travelStops) { stop in
                            TravelStopRow(
                                stop: stop,
                                onEdit: { editingStop = stop },
                                onDelete: { deleteStop(stop) }
                            )
                        }
                    }

                    // Add destination button
                    Button {
                        showAddStop = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add Destination")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(forestGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(forestGreen.opacity(0.3), lineWidth: 1.5)
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
        }
        .navigationTitle("Travel Plans")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(charcoal)
                }
            }
        }
        .onAppear {
            tabBarVisibility.isVisible = false
            loadTravelStops()
        }
        .sheet(isPresented: $showAddStop) {
            TravelStopEditorSheet(
                stop: nil,
                onSave: { newStop in
                    travelStops.append(newStop)
                    travelStops.sort { $0.startDate < $1.startDate }
                    saveTravelStops()
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $editingStop) { stop in
            TravelStopEditorSheet(
                stop: stop,
                onSave: { updatedStop in
                    if let index = travelStops.firstIndex(where: { $0.id == updatedStop.id }) {
                        travelStops[index] = updatedStop
                        travelStops.sort { $0.startDate < $1.startDate }
                        saveTravelStops()
                    }
                }
            )
            .presentationDetents([.medium])
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(charcoal.opacity(0.3))

            Text("No travel plans yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(charcoal)

            Text("Add your upcoming destinations to let others know where you'll be!")
                .font(.system(size: 14))
                .foregroundColor(charcoal.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }

    private func loadTravelStops() {
        Task {
            do {
                travelStops = try await profileManager.fetchTravelSchedule()
            } catch {
                print("Failed to load travel stops: \(error)")
            }
            isLoading = false
        }
    }

    private func saveTravelStops() {
        Task {
            do {
                try await profileManager.saveTravelSchedule(travelStops)
            } catch {
                print("Failed to save travel stops: \(error)")
            }
        }
    }

    private func deleteStop(_ stop: DriftBackend.TravelStop) {
        travelStops.removeAll { $0.id == stop.id }
        saveTravelStops()
    }
}

// MARK: - Travel Stop Row

private struct TravelStopRow: View {
    let stop: DriftBackend.TravelStop
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let charcoal = Color("Charcoal")
    private let desertSand = Color("DesertSand")
    private let burntOrange = Color("BurntOrange")

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

            // Edit button
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundColor(charcoal.opacity(0.5))
            }

            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Travel Stop Editor Sheet

private struct TravelStopEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let stop: DriftBackend.TravelStop?
    let onSave: (DriftBackend.TravelStop) -> Void

    @State private var location: String = ""
    @State private var locationLatitude: Double? = nil
    @State private var locationLongitude: Double? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var tripType: TripType = .roadTrip

    private let charcoal = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    private let skyBlue = Color("SkyBlue")

    enum TripType: String, CaseIterable {
        case vanLife = "Van Life"
        case flying = "Flying"
        case backpacking = "Backpacking"
        case roadTrip = "Road Trip"

        var emoji: String {
            switch self {
            case .vanLife: return "🚐"
            case .flying: return "✈️"
            case .backpacking: return "🎒"
            case .roadTrip: return "🚗"
            }
        }
    }

    init(stop: DriftBackend.TravelStop?, onSave: @escaping (DriftBackend.TravelStop) -> Void) {
        self.stop = stop
        self.onSave = onSave
        if let stop = stop {
            _location = State(initialValue: stop.location)
            _locationLatitude = State(initialValue: stop.latitude)
            _locationLongitude = State(initialValue: stop.longitude)
            _startDate = State(initialValue: stop.startDate)
            _endDate = State(initialValue: stop.endDate ?? Date())
            _hasEndDate = State(initialValue: stop.endDate != nil)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(charcoal.opacity(0.6))

                Spacer()

                Text(stop == nil ? "Add Destination" : "Edit Destination")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoal)

                Spacer()

                Button("Save") {
                    saveStop()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(forestGreen)
                .disabled(location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()
                .background(Color.gray.opacity(0.2))

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Location Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LOCATION")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(charcoal.opacity(0.6))
                            .tracking(0.5)

                        LocationSearchField(
                            locationName: $location,
                            latitude: $locationLatitude,
                            longitude: $locationLongitude
                        )
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }

                    // Dates Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DATES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(charcoal.opacity(0.6))
                            .tracking(0.5)

                        // Start Date
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 20))
                                    .foregroundColor(charcoal.opacity(0.4))

                                Text("Start Date")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoal.opacity(0.6))
                            }

                            Spacer()

                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(forestGreen)
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                        // Has End Date Toggle
                        HStack {
                            Text("Has End Date")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoal)

                            Spacer()

                            Toggle("", isOn: $hasEndDate)
                                .labelsHidden()
                                .tint(forestGreen)
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                        // End Date (conditional)
                        if hasEndDate {
                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 20))
                                        .foregroundColor(charcoal.opacity(0.4))

                                    Text("End Date")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(charcoal.opacity(0.6))
                                }

                                Spacer()

                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .tint(forestGreen)
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                        }
                    }

                    // Trip Type Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TRIP TYPE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(charcoal.opacity(0.6))
                            .tracking(0.5)

                        HStack(spacing: 8) {
                            ForEach(TripType.allCases, id: \.self) { type in
                                Button {
                                    tripType = type
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(type.emoji)
                                            .font(.system(size: 28))

                                        Text(type.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(tripType == type ? .white : charcoal.opacity(0.7))
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(tripType == type ? forestGreen : Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                    }

                    // Info Card
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(skyBlue)
                                .frame(width: 32, height: 32)

                            Image(systemName: "mappin.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }

                        Text("Adding destinations helps others find you and discover shared travel plans.")
                            .font(.system(size: 14))
                            .foregroundColor(charcoal.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(skyBlue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(skyBlue.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(24)
            }
        }
        .background(softGray)
    }

    private func saveStop() {
        guard let userId = ProfileManager.shared.currentProfile?.id else { return }

        let newStop = DriftBackend.TravelStop(
            id: stop?.id ?? UUID(),
            userId: userId,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            latitude: locationLatitude,
            longitude: locationLongitude,
            createdAt: stop?.createdAt
        )

        onSave(newStop)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TravelPlansEditorView()
    }
}
