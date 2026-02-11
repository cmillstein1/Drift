//
//  HomeBaseEditorView.swift
//  Drift
//

import SwiftUI

struct HomeBaseEditorView: View {
    @Binding var homeBase: String
    @Environment(\.dismiss) private var dismiss
    @State private var editedHomeBase: String = ""

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let sectionHeaderColor = Color(red: 0.29, green: 0.33, blue: 0.41)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 0.97)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Label
                    HStack {
                        Text("HOME BASE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(sectionHeaderColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Text field in a card
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("City, State (e.g., Portland, OR)", text: $editedHomeBase)
                            .font(.system(size: 17))
                            .foregroundColor(charcoalColor)
                            .autocapitalization(.words)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    // Helper text
                    Text("Where do you call home when you're not on the road?")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                        .padding(.horizontal, 16)

                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Home Base")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    homeBase = editedHomeBase
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(burntOrange)
            }
        }
        .onAppear {
            editedHomeBase = homeBase
        }
    }
}
