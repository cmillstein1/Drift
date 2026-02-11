//
//  AboutEditorView.swift
//  Drift
//

import SwiftUI
import DriftBackend

struct AboutEditorView: View {
    @Binding var about: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    @State private var editedAbout: String = ""
    @State private var isSaving = false
    @State private var saveError: String?

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.97)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // About label (eyebrow)
                Text("ABOUT")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.41))
                    .padding(.horizontal, 16)

                // Text editor - normal height (~5 lines)
                TextEditor(text: $editedAbout)
                    .font(.system(size: 17))
                    .foregroundColor(charcoalColor)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    .frame(height: 160)
                    .padding(.horizontal, 16)
                    .scrollContentBackground(.hidden)

                if let saveError {
                    Text(saveError)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveAbout()
                }
                .foregroundColor(burntOrange)
                .disabled(isSaving)
            }
        }
        .onAppear {
            editedAbout = about
        }
    }

    private func saveAbout() {
        saveError = nil
        isSaving = true

        Task {
            do {
                let newBio = editedAbout.trimmingCharacters(in: .whitespacesAndNewlines)
                try await profileManager.updateProfile(ProfileUpdateRequest(
                    bio: newBio.isEmpty ? nil : newBio
                ))
                await MainActor.run {
                    about = editedAbout
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            }
        }
    }
}
