//
//  TravelPaceEditorSheet.swift
//  Drift
//

import SwiftUI

struct TravelPaceEditorSheet: View {
    @Binding var travelPace: EditProfileScreen.TravelPaceOption
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")

    var body: some View {
        NavigationView {
            ZStack {
                softGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(EditProfileScreen.TravelPaceOption.allCases, id: \.self) { pace in
                            Button(action: {
                                travelPace = pace
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pace.displayName.components(separatedBy: " - ").first ?? "")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(travelPace == pace ? .white : charcoalColor)

                                        Text(pace.displayName.components(separatedBy: " - ").last ?? "")
                                            .font(.system(size: 14))
                                            .foregroundColor(travelPace == pace ? .white.opacity(0.8) : charcoalColor.opacity(0.6))
                                    }

                                    Spacer()

                                    if travelPace == pace {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(20)
                                .background(travelPace == pace ? burntOrange : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Travel Pace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(charcoalColor)
                }
            }
        }
    }
}
