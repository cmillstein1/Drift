//
//  SegmentToggle.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct SegmentOption {
    let id: Int
    let title: String
    let icon: String?
    let activeGradient: LinearGradient?
    let activeColor: Color?
    
    init(
        id: Int,
        title: String,
        icon: String? = nil,
        activeGradient: LinearGradient? = nil,
        activeColor: Color? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.activeGradient = activeGradient
        self.activeColor = activeColor
    }
}

struct SegmentToggle: View {
    let options: [SegmentOption]
    @Binding var selectedIndex: Int
    
    private let charcoalColor = Color("Charcoal")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Sliding Background
                if selectedIndex < options.count {
                    let option = options[selectedIndex]
                    let padding: CGFloat = 6
                    let innerSpacing: CGFloat = 12
                    let segmentWidth = (geometry.size.width - padding * 2 - CGFloat((options.count - 1) * Int(innerSpacing))) / CGFloat(options.count)
                    
                    Capsule()
                        .fill(
                            option.activeGradient ?? 
                            LinearGradient(
                                gradient: Gradient(colors: [option.activeColor ?? Color("BurntOrange"), option.activeColor ?? Color("BurntOrange")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: segmentWidth)
                        .offset(x: calculateOffset(for: selectedIndex, in: geometry.size.width))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                }
                
                HStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedIndex = index
                            }
                        }) {
                            HStack(spacing: option.icon != nil ? 8 : 0) {
                                if let icon = option.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 14))
                                }
                                
                                Text(option.title)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedIndex == index ? .white : charcoalColor.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(6)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .frame(height: 50)
    }
    
    private func calculateOffset(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        let padding: CGFloat = 6
        let innerSpacing: CGFloat = 12
        let segmentWidth = (totalWidth - padding * 2 - CGFloat((options.count - 1) * Int(innerSpacing))) / CGFloat(options.count)
        return padding + CGFloat(index) * (segmentWidth + innerSpacing)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Dating/Friends Toggle
        SegmentToggle(
            options: [
                SegmentOption(
                    id: 0,
                    title: "Dating",
                    icon: "heart.fill",
                    activeGradient: LinearGradient(
                        gradient: Gradient(colors: [Color("BurntOrange"), Color(red: 0.93, green: 0.36, blue: 0.51)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                ),
                SegmentOption(
                    id: 1,
                    title: "Friends",
                    icon: "person.2.fill",
                    activeGradient: LinearGradient(
                        gradient: Gradient(colors: [Color("SkyBlue"), Color("ForestGreen")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            ],
            selectedIndex: .constant(0)
        )
        .frame(maxWidth: 448)
        .padding()
        
        // List/Map Toggle
        SegmentToggle(
            options: [
                SegmentOption(
                    id: 0,
                    title: "List",
                    icon: "list.bullet",
                    activeColor: Color("BurntOrange")
                ),
                SegmentOption(
                    id: 1,
                    title: "Map",
                    icon: "map",
                    activeColor: Color("BurntOrange")
                )
            ],
            selectedIndex: .constant(1)
        )
        .padding()
    }
}
