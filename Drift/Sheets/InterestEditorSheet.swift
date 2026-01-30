//
//  InterestEditorSheet.swift
//  Drift
//

import SwiftUI

struct InterestEditorSheet: View {
    @Binding var selectedInterests: [String]
    @Binding var isPresented: Bool

    @State private var selectedInterestsSet: Set<String>
    @State private var categories: [InterestCategory] = [
        InterestCategory(
            title: "Food & drink",
            interests: [
                Interest(emoji: "🍺", label: "Beer"),
                Interest(emoji: "🧋", label: "Boba tea"),
                Interest(emoji: "☕", label: "Coffee"),
                Interest(emoji: "🍝", label: "Foodie"),
                Interest(emoji: "🍸", label: "Gin"),
                Interest(emoji: "🍕", label: "Pizza"),
                Interest(emoji: "🍣", label: "Sushi"),
                Interest(emoji: "🍭", label: "Sweet tooth"),
                Interest(emoji: "🌮", label: "Tacos"),
                Interest(emoji: "🍵", label: "Tea"),
                Interest(emoji: "🌱", label: "Vegan"),
                Interest(emoji: "🥗", label: "Vegetarian"),
                Interest(emoji: "🥃", label: "Whisky"),
                Interest(emoji: "🍷", label: "Wine")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Traveling",
            interests: [
                Interest(emoji: "🎒", label: "Backpacking"),
                Interest(emoji: "🏖️", label: "Beaches"),
                Interest(emoji: "🏕️", label: "Camping"),
                Interest(emoji: "🏙️", label: "Exploring new cities"),
                Interest(emoji: "🎣", label: "Fishing trips"),
                Interest(emoji: "⛰️", label: "Hiking trips"),
                Interest(emoji: "🚗", label: "Road trips"),
                Interest(emoji: "🧖", label: "Spa weekends"),
                Interest(emoji: "🏡", label: "Staycations"),
                Interest(emoji: "❄️", label: "Winter sports")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Creative",
            interests: [
                Interest(emoji: "🎨", label: "Art"),
                Interest(emoji: "📸", label: "Photography"),
                Interest(emoji: "✍️", label: "Writing"),
                Interest(emoji: "🎭", label: "Theater"),
                Interest(emoji: "🎸", label: "Music"),
                Interest(emoji: "💃", label: "Dancing")
            ],
            expanded: true
        ),
        InterestCategory(
            title: "Active",
            interests: [
                Interest(emoji: "🏃", label: "Running"),
                Interest(emoji: "🚴", label: "Cycling"),
                Interest(emoji: "🧘", label: "Yoga"),
                Interest(emoji: "🏋️", label: "Gym"),
                Interest(emoji: "🏊", label: "Swimming"),
                Interest(emoji: "⛷️", label: "Skiing")
            ],
            expanded: true
        )
    ]

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96)

    init(selectedInterests: Binding<[String]>, isPresented: Binding<Bool>) {
        self._selectedInterests = selectedInterests
        self._isPresented = isPresented
        _selectedInterestsSet = State(initialValue: Set(selectedInterests.wrappedValue))
    }

    var body: some View {
        NavigationView {
            ZStack {
                warmWhite.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(categories.indices), id: \.self) { index in
                            InterestCategorySection(
                                category: Binding(
                                    get: { categories[index] },
                                    set: { categories[index] = $0 }
                                ),
                                selectedInterests: $selectedInterestsSet
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(charcoalColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        selectedInterests = Array(selectedInterestsSet)
                        isPresented = false
                    }
                    .foregroundColor(burntOrange)
                }
            }
        }
    }
}
