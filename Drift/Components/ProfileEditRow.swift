//
//  ProfileEditRow.swift
//  Drift
//

import SwiftUI

struct ProfileEditRow: View {
    let title: String
    let value: String
    var isMultiline: Bool = false
    let onTap: (() -> Void)?

    private let charcoalColor = Color("Charcoal")

    init(title: String, value: String, isMultiline: Bool = false, onTap: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.isMultiline = isMultiline
        self.onTap = onTap
    }

    var body: some View {
        let content = HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)

                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(value.contains("Add") ? charcoalColor.opacity(0.4) : charcoalColor.opacity(0.6))
                    .lineLimit(isMultiline ? 2 : 1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(charcoalColor.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())

        if let onTap = onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }
}
