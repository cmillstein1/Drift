//
//  NameEditorView.swift
//  Drift
//

import SwiftUI

struct NameEditorView: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    @State private var editedName: String = ""

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let sectionHeaderColor = Color(red: 0.29, green: 0.33, blue: 0.41)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 0.97)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Name label (eyebrow)
                    HStack {
                        Text("NAME")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(sectionHeaderColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Text field in a card
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter your name", text: $editedName)
                            .font(.system(size: 17))
                            .foregroundColor(charcoalColor)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
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
        .navigationTitle("Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    name = editedName
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(burntOrange)
                .disabled(editedName.isEmpty)
            }
        }
        .onAppear {
            editedName = name
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
