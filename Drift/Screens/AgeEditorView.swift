//
//  AgeEditorView.swift
//  Drift
//

import SwiftUI

struct AgeEditorView: View {
    @Binding var age: String
    @Binding var birthday: Date?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @State private var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sectionHeaderColor = Color(red: 0.29, green: 0.33, blue: 0.41)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 0.97)

    private var calculatedAge: Int {
        calendar.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
    }

    private var isDateValid: Bool {
        let maxDate = calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        return selectedDate <= maxDate
    }

    private var minDate: Date {
        calendar.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }

    private var maxDate: Date {
        calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Age label (eyebrow)
                    HStack {
                        Text("AGE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(sectionHeaderColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Date picker in a card
                    VStack(spacing: 12) {
                        DatePicker(
                            "Birthday",
                            selection: $selectedDate,
                            in: minDate...maxDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()

                        if !isDateValid {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text("You must be 18 or older")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .padding(.top, 8)
                        } else {
                            Text("Age: \(calculatedAge)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.6))
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Age")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    age = "\(calculatedAge)"
                    birthday = selectedDate
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(burntOrange)
                .disabled(!isDateValid)
            }
        }
        .onAppear {
            // Initialize date picker from current birthday or age
            if let existingBirthday = birthday {
                selectedDate = existingBirthday
            } else if let ageInt = Int(age), ageInt >= 18 {
                // Calculate birthday from age (approximate - use Jan 1st of that year)
                if let birthday = calendar.date(byAdding: .year, value: -ageInt, to: Date()) {
                    selectedDate = birthday
                } else {
                    selectedDate = maxDate
                }
            } else {
                // Default to 18 years ago
                selectedDate = maxDate
            }
            // Immediately hide tab bar and keep it hidden
            tabBarVisibility.isVisible = false
            // Also set it with animation after a brief delay to override any other changes
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    tabBarVisibility.isVisible = false
                }
            }
        }
        .onDisappear {
            // Don't show tab bar here - let EditProfileScreen handle it
        }
    }
}
