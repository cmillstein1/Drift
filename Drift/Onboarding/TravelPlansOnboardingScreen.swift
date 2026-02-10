//
//  TravelPlansOnboardingScreen.swift
//  Drift
//
//  Onboarding screen for adding travel destinations
//

import SwiftUI
import DriftBackend

struct TravelPlansOnboardingScreen: View {
    let onContinue: () -> Void
    var backgroundColor: Color = Color(red: 0.98, green: 0.98, blue: 0.96)

    @StateObject private var profileManager = ProfileManager.shared
    @State private var travelStops: [DriftBackend.TravelStop] = []
    @State private var showAddStop = false
    @State private var isSaving = false

    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = -20
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20

    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color("ForestGreen")
    private let desertSand = Color("DesertSand")

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 24)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Where are you headed?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .opacity(titleOpacity)
                        .offset(x: titleOffset)
                        .padding(.top, 8)

                    Text("Add your upcoming travel destinations so others can find you along the way.")
                        .font(.system(size: 16))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .padding(.top, 8)
                        .opacity(subtitleOpacity)
                        .offset(x: subtitleOffset)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 16) {
                        // Added destinations
                        ForEach(travelStops) { stop in
                            TravelStopOnboardingRow(
                                stop: stop,
                                onDelete: { deleteStop(stop) }
                            )
                        }

                        // Add destination button
                        Button {
                            showAddStop = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(forestGreen.opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(forestGreen)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add a destination")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(charcoalColor)

                                    Text("Let others know where you'll be")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.5))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoalColor.opacity(0.3))
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(forestGreen.opacity(0.3), lineWidth: 1.5)
                            )
                        }

                        // Info card
                        if travelStops.isEmpty {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundColor(burntOrange)

                                Text("Adding travel plans helps you connect with others heading the same direction. You can always update this later.")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.7))
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .background(burntOrange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        saveAndContinue()
                    }) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text(travelStops.isEmpty ? "Skip for now" : "Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(travelStops.isEmpty ? charcoalColor.opacity(0.3) : burntOrange)
                    .clipShape(Capsule())
                    .disabled(isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                }
            }
        }
        .onAppear {
            loadExistingStops()
            animateIn()
        }
        .sheet(isPresented: $showAddStop) {
            TravelStopOnboardingSheet(
                onSave: { newStop in
                    travelStops.append(newStop)
                    travelStops.sort { $0.startDate < $1.startDate }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5)) {
            titleOpacity = 1
            titleOffset = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            subtitleOpacity = 1
            subtitleOffset = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            contentOpacity = 1
            contentOffset = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            buttonOpacity = 1
            buttonOffset = 0
        }
    }

    private func loadExistingStops() {
        Task {
            do {
                travelStops = try await profileManager.fetchTravelSchedule()
            } catch {
                print("Failed to load existing travel stops: \(error)")
            }
        }
    }

    private func deleteStop(_ stop: DriftBackend.TravelStop) {
        travelStops.removeAll { $0.id == stop.id }
    }

    private func saveAndContinue() {
        guard !travelStops.isEmpty else {
            onContinue()
            return
        }

        isSaving = true
        Task {
            do {
                try await profileManager.saveTravelSchedule(travelStops)
            } catch {
                print("Failed to save travel stops: \(error)")
            }
            await MainActor.run {
                isSaving = false
                onContinue()
            }
        }
    }
}

// MARK: - Travel Stop Row

private struct TravelStopOnboardingRow: View {
    let stop: DriftBackend.TravelStop
    let onDelete: () -> Void

    private let charcoal = Color("Charcoal")
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [burntOrange.opacity(0.15), sunsetRose.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "signpost.right.and.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(burntOrange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(stop.location)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(charcoal)
                Text(stop.dateRange)
                    .font(.system(size: 14))
                    .foregroundColor(charcoal.opacity(0.6))
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(charcoal.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Travel Stop Editor Sheet

private struct TravelStopOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (DriftBackend.TravelStop) -> Void

    @State private var location: String = ""
    @State private var locationLatitude: Double? = nil
    @State private var locationLongitude: Double? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var hasEndDate: Bool = true

    private let charcoal = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(charcoal.opacity(0.6))

                Spacer()

                Text("Add Destination")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(charcoal)

                Spacer()

                Button("Add") {
                    saveStop()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(forestGreen)
                .disabled(location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LOCATION")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(charcoal.opacity(0.6))
                            .tracking(0.5)

                        LocationSearchField(
                            locationName: $location,
                            latitude: $locationLatitude,
                            longitude: $locationLongitude
                        )
                    }

                    // Dates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DATES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(charcoal.opacity(0.6))
                            .tracking(0.5)

                        HStack {
                            Text("Start")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoal.opacity(0.6))

                            Spacer()

                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .tint(forestGreen)
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if hasEndDate {
                            HStack {
                                Text("End")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(charcoal.opacity(0.6))

                                Spacer()

                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(forestGreen)
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Toggle("I have an end date", isOn: $hasEndDate)
                            .font(.system(size: 15))
                            .foregroundColor(charcoal)
                            .tint(forestGreen)
                            .padding(.top, 4)
                    }
                }
                .padding(24)
            }
        }
        .background(softGray)
    }

    private func saveStop() {
        guard let userId = ProfileManager.shared.currentProfile?.id else { return }

        let newStop = DriftBackend.TravelStop(
            id: UUID(),
            userId: userId,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            latitude: locationLatitude,
            longitude: locationLongitude,
            createdAt: nil
        )

        onSave(newStop)
        dismiss()
    }
}

#Preview {
    TravelPlansOnboardingScreen {
        print("Continue tapped")
    }
}
