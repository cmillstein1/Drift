//
//  WorkStyleEditorSheet.swift
//  Drift
//

import SwiftUI
import DriftBackend

struct WorkStyleEditorSheet: View {
    @Binding var workStyle: WorkStyle?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")

    private func description(for style: WorkStyle) -> String {
        switch style {
        case .remote: return "Work from anywhere with internet"
        case .hybrid: return "Mix of remote and in-person work"
        case .locationBased: return "Work requires physical presence"
        case .retired: return "No longer working"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                softGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(WorkStyle.allCases, id: \.self) { style in
                            Button(action: {
                                workStyle = style
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(style.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(workStyle == style ? .white : charcoalColor)

                                        Text(description(for: style))
                                            .font(.system(size: 14))
                                            .foregroundColor(workStyle == style ? .white.opacity(0.8) : charcoalColor.opacity(0.6))
                                    }

                                    Spacer()

                                    if workStyle == style {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(20)
                                .background(workStyle == style ? burntOrange : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Work Style")
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
