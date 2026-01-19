//
//  FlowLayout.swift
//  Drift
//
//  Created by Claude on 1/19/26.
//

import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    init(
        data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(data) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if item.id == data.last?.id as? Data.Element.ID {
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item.id == data.last?.id as? Data.Element.ID {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.frame(in: .local).size.height
            }
            return Color.clear
        }
    }
}

#Preview {
    struct PreviewInterest: Identifiable {
        let id = UUID()
        let emoji: String
        let label: String
    }

    let interests = [
        PreviewInterest(emoji: "🍺", label: "Beer"),
        PreviewInterest(emoji: "☕", label: "Coffee"),
        PreviewInterest(emoji: "🍕", label: "Pizza"),
        PreviewInterest(emoji: "🍣", label: "Sushi"),
        PreviewInterest(emoji: "🌮", label: "Tacos"),
        PreviewInterest(emoji: "🍷", label: "Wine"),
        PreviewInterest(emoji: "🧋", label: "Boba tea"),
        PreviewInterest(emoji: "🍭", label: "Sweet tooth"),
        PreviewInterest(emoji: "🌱", label: "Vegan"),
        PreviewInterest(emoji: "🥗", label: "Vegetarian")
    ]

    return FlowLayout(data: interests, spacing: 8) { interest in
        HStack(spacing: 8) {
            Text(interest.emoji)
            Text(interest.label)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 2))
    }
    .padding()
}
