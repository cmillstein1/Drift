//
//  EditProfileSheetWrapper.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct EditProfileSheetWrapper: View {
    @Binding var isPresented: Bool
    @State private var hasExpandedSection = false
    
    var body: some View {
        EditProfileSheet(isPresented: $isPresented)
            .presentationDetents(hasExpandedSection ? [.large] : [.height(550), .large])
            .presentationDragIndicator(.visible)
            .onPreferenceChange(ExpandedSectionPreferenceKey.self) { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    hasExpandedSection = value
                }
            }
    }
}
