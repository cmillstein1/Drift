//
//  RigDetailsView.swift
//  Drift
//
//  Created for rig details editing
//

import SwiftUI

struct RigDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rigInfo: String
    @ObservedObject private var tabBarVisibility = TabBarVisibility.shared
    
    @State private var selectedVanType = "Sprinter"
    @State private var year = "2019"
    @State private var length = "144\""
    @State private var selectedConversionType = "Self-Converted"
    @State private var selectedAmenities: Set<String> = ["Solar Power", "Kitchen", "Fresh Water", "Heater", "WiFi/Hotspot", "Bed", "House Battery"]
    
    let vanTypes = ["Sprinter", "Transit", "ProMaster", "Econoline", "Other"]
    let conversionTypes = ["Self-Converted", "Professional Build", "Factory Camper", "DIY Partial"]
    let amenities = ["Solar Power", "Kitchen", "Fresh Water", "Heater", "WiFi/Hotspot", "Bed", "House Battery", "Shower", "AC", "Toilet"]
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let sectionHeaderColor = Color(red: 0.29, green: 0.33, blue: 0.41) // #4A5568
    private let textColor = Color(red: 0.18, green: 0.22, blue: 0.28) // #2D3748
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 0.97) // #F7F7F7
    private let warmWhite = Color(red: 0.99, green: 0.98, blue: 0.96) // #FDF8F5
    private let darkGreen = Color(red: 0.31, green: 0.47, blue: 0.27) // #4F7744
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Card
                heroCard
                
                // Van Type Section
                vanTypeSection
                
                // Year & Length Section
                yearLengthSection
                
                // Conversion Type Section
                conversionTypeSection
                
                // Amenities Section
                amenitiesSection
            }
            .padding(.bottom, 32)
        }
        .background(backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("The Rig")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(charcoalColor)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveRigInfo()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(burntOrange)
                }
            }
        }
        .onAppear {
            parseRigInfo()
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
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("My Rig")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("\(year) \(selectedVanType)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(length) • \(selectedConversionType)")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            // Amenity Tags
            FlowLayout(data: Array(selectedAmenities.sorted()).map { AmenityItem(id: $0, name: $0) }, spacing: 8) { item in
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.25))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(burntOrange)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var vanTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VAN TYPE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(sectionHeaderColor)
                .padding(.horizontal, 16)
            
            VStack(spacing: 10) {
                ForEach(vanTypes, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedVanType = type
                        }
                    } label: {
                        HStack {
                            Text(type)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(selectedVanType == type ? .white : textColor)
                            
                            Spacer()
                            
                            if selectedVanType == type {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedVanType == type ? burntOrange : .white)
                                .shadow(color: selectedVanType == type ? burntOrange.opacity(0.3) : Color.black.opacity(0.05), radius: selectedVanType == type ? 8 : 2, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var yearLengthSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("YEAR")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(sectionHeaderColor)
                
                TextField("Year", text: $year)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(textColor)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    )
                    .keyboardType(.numberPad)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("LENGTH")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(sectionHeaderColor)
                
                TextField("Length", text: $length)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(textColor)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    )
                    .keyboardType(.numbersAndPunctuation)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var conversionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONVERSION TYPE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(sectionHeaderColor)
                .padding(.horizontal, 16)
            
            VStack(spacing: 10) {
                ForEach(conversionTypes, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedConversionType = type
                        }
                    } label: {
                        HStack {
                            Text(type)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(selectedConversionType == type ? .white : textColor)
                            
                            Spacer()
                            
                            if selectedConversionType == type {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedConversionType == type ? burntOrange : .white)
                                .shadow(color: selectedConversionType == type ? burntOrange.opacity(0.3) : Color.black.opacity(0.05), radius: selectedConversionType == type ? 8 : 2, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FEATURES & AMENITIES")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(sectionHeaderColor)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(amenities, id: \.self) { amenity in
                        Button {
                            if selectedAmenities.contains(amenity) {
                                selectedAmenities.remove(amenity)
                            } else {
                                selectedAmenities.insert(amenity)
                            }
                        } label: {
                            HStack {
                                Text(amenity)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(selectedAmenities.contains(amenity) ? .white : textColor)
                                
                                Spacer()
                                
                                if selectedAmenities.contains(amenity) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(selectedAmenities.contains(amenity) ? darkGreen : .white)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(warmWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }
    
    private func parseRigInfo() {
        // Parse existing rigInfo string if available
        // Format could be: "2019 Sprinter 144\" Self-Converted" or similar
        if !rigInfo.isEmpty {
            let components = rigInfo.components(separatedBy: " ")
            if components.count >= 2 {
                // Try to extract year (first component if it's a number)
                if let firstYear = Int(components[0]), firstYear > 1900 && firstYear < 2100 {
                    year = components[0]
                }
                
                // Try to find van type
                for vanType in vanTypes {
                    if rigInfo.contains(vanType) {
                        selectedVanType = vanType
                        break
                    }
                }
                
                // Try to find length (contains ")
                if let lengthRange = rigInfo.range(of: #"\d+\""#, options: .regularExpression) {
                    length = String(rigInfo[lengthRange])
                }
                
                // Try to find conversion type
                for convType in conversionTypes {
                    if rigInfo.contains(convType) {
                        selectedConversionType = convType
                        break
                    }
                }
            }
        }
        
        // Map old amenity names to new ones if needed
        let oldToNewMapping: [String: String] = [
            "Solar": "Solar Power",
            "WiFi": "WiFi/Hotspot",
            "Water": "Fresh Water",
            "Battery": "House Battery"
        ]
        
        // Update selected amenities to use new names
        var updatedAmenities = Set<String>()
        for amenity in selectedAmenities {
            if let newName = oldToNewMapping[amenity] {
                updatedAmenities.insert(newName)
            } else if amenities.contains(amenity) {
                updatedAmenities.insert(amenity)
            }
        }
        selectedAmenities = updatedAmenities
    }
    
    private func saveRigInfo() {
        // Format: "2019 Sprinter 144\" Self-Converted"
        rigInfo = "\(year) \(selectedVanType) \(length) • \(selectedConversionType)"
    }
}

// Helper struct for FlowLayout
private struct AmenityItem: Identifiable {
    let id: String
    let name: String
}

#Preview {
    NavigationStack {
        RigDetailsView(rigInfo: .constant("2019 Sprinter 144\" Self-Converted"))
    }
}
