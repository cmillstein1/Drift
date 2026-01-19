//
//  CampgroundDetailSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/19/26.
//

import SwiftUI
import UIKit
import DriftBackend

struct CampgroundDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let campground: Campground
    @State private var isBooking: Bool = false
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    // Computed properties for campground data
    private var displayAddress: String {
        if let address = campground.location.address {
            return address.full ?? "\(address.city ?? ""), \(address.stateCode ?? "")"
        }
        return "Location not available"
    }
    
    private var isOpen: Bool {
        campground.status == "open"
    }
    
    private var pricePerNight: Int? {
        if let price = campground.price, let min = price.minimum {
            return Int(min)
        }
        return nil
    }
    
    private var priceRange: String? {
        if let price = campground.price {
            if let min = price.minimum, let max = price.maximum {
                if min == max {
                    return "$\(Int(min))"
                } else {
                    return "$\(Int(min)) - $\(Int(max))"
                }
            }
        }
        return nil
    }
    
    private var heroImageUrl: String? {
        campground.photos?.first?.largeUrl ?? campground.photos?.first?.mediumUrl ?? campground.photos?.first?.originalUrl
    }
    
    private var description: String {
        campground.longDescription ?? campground.mediumDescription ?? campground.shortDescription ?? "No description available."
    }
    
    private var amenityList: [(icon: String, name: String)] {
        var list: [(String, String)] = []
        if let amenities = campground.amenities {
            if amenities.toilets == true {
                list.append(("toilet", "Toilets"))
            }
            if amenities.showers == true {
                list.append(("drop.fill", "Showers"))
            }
            if amenities.water == true {
                list.append(("drop.circle.fill", "Water"))
            }
            if amenities.petsAllowed == true {
                list.append(("pawprint.fill", "Pets Allowed"))
            }
            if amenities.wifi == true {
                list.append(("wifi", "WiFi"))
            }
            if amenities.electricHookups == true {
                list.append(("bolt.fill", "Electric Hookups"))
            }
            if amenities.waterHookups == true {
                list.append(("hose.fill", "Water Hookups"))
            }
            if amenities.sewerHookups == true {
                list.append(("pipe.and.drop.fill", "Sewer Hookups"))
            }
            if amenities.firesAllowed == true {
                list.append(("flame.fill", "Fire Pits"))
            }
            if amenities.dumpStation == true {
                list.append(("arrow.down.circle.fill", "Dump Station"))
            }
            if amenities.campStore == true {
                list.append(("bag.fill", "Camp Store"))
            }
        }
        return list
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Hero Image Section
                ZStack(alignment: .topLeading) {
                    // Hero Image
                    if let imageUrl = heroImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    ProgressView()
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                defaultHeroImage
                            @unknown default:
                                defaultHeroImage
                            }
                        }
                        .frame(height: 224)
                        .clipped()
                    } else {
                        defaultHeroImage
                    }
                    
                    // Gradient Overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            Color.clear,
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 224)
                    
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(charcoalColor)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Open Status Badge
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                
                                Text(isOpen ? "Open Now" : "Closed")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                isOpen ? forestGreen.opacity(0.9) : Color.red.opacity(0.9)
                            )
                            .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(height: 224)
                
                // Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title & Location Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(campground.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                                    .padding(.top, 2)
                                
                                Text(displayAddress)
                                    .font(.system(size: 14))
                                    .foregroundColor(charcoalColor.opacity(0.6))
                            }
                            
                            // Price Info
                            if let priceRange = priceRange {
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(forestGreen)
                                    
                                    Text(priceRange)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(charcoalColor)
                                    
                                    Text("per night")
                                        .font(.system(size: 14))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Quick Actions
                        HStack(spacing: 12) {
                            Button(action: {
                                openDirections()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(burntOrange)
                                    
                                    Text("Directions")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(charcoalColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(softGray)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            if let phone = campground.contact?.primaryPhone {
                                Button(action: {
                                    callPhone(phone)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(forestGreen)
                                        
                                        Text("Call")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(charcoalColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(softGray)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            Text(description)
                                .font(.system(size: 15))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        
                        // Amenities Section
                        if !amenityList.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Amenities")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(amenityList, id: \.name) { amenity in
                                        AmenityCard(icon: amenity.icon, name: amenity.name)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Contact Section
                        if campground.contact != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Contact")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                
                                VStack(spacing: 12) {
                                    if let phone = campground.contact?.primaryPhone {
                                        Button(action: {
                                            callPhone(phone)
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "phone.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(burntOrange)
                                                
                                                Text(phone)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(charcoalColor)
                                                
                                                Spacer()
                                            }
                                            .padding(16)
                                            .background(softGray)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                    
                                    if let email = campground.contact?.primaryEmail {
                                        Button(action: {
                                            sendEmail(email)
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "envelope.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(burntOrange)
                                                
                                                Text(email)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(charcoalColor)
                                                
                                                Spacer()
                                            }
                                            .padding(16)
                                            .background(softGray)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Bottom padding for the sticky button
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            
            // Sticky Bottom Button
            if let reservationUrl = campground.reservationUrl {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    Button(action: {
                        handleBookNow()
                    }) {
                        HStack(spacing: 8) {
                            if isBooking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Processing...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "tent.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                
                                if let price = pricePerNight {
                                    Text("Book Now - $\(price)/night")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("Book Now")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isBooking)
                    .opacity(isBooking ? 0.7 : 1.0)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(
                    Color.white.opacity(0.95)
                        .background(.ultraThinMaterial)
                )
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Helper Views
    
    private var defaultHeroImage: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [forestGreen.opacity(0.3), forestGreen.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "tent.fill")
                    .font(.system(size: 48))
                    .foregroundColor(forestGreen.opacity(0.5))
                
                Text("No Image Available")
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.5))
            }
        }
        .frame(height: 224)
    }
    
    // MARK: - Actions
    
    private func handleBookNow() {
        guard let reservationUrl = campground.reservationUrl,
              let url = URL(string: reservationUrl) else { return }
        
        isBooking = true
        
        // Open the reservation URL
        UIApplication.shared.open(url) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isBooking = false
            }
        }
    }
    
    private func openDirections() {
        let lat = campground.location.latitude
        let lon = campground.location.longitude
        let name = campground.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Try to open in Apple Maps
        if let url = URL(string: "maps://?daddr=\(lat),\(lon)&q=\(name)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Amenity Card Component

struct AmenityCard: View {
    let icon: String
    let name: String
    
    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(forestGreen)
            }
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(12)
        .background(softGray)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    CampgroundDetailSheet(
        campground: Campground(
            id: "preview-1",
            name: "Oleta River State Park Campground",
            status: "open",
            statusDescription: "Open for camping",
            kind: "campground",
            shortDescription: "A beautiful campground",
            mediumDescription: "A beautiful campground with great amenities",
            longDescription: "Oleta River State Park encompasses over 1,000 acres on Biscayne Bay, making it Florida's largest urban park despite being just 30 minutes from downtown Miami. The park offers 14 rustic air-conditioned cabins for overnight guests, though these do not include kitchens or private bathrooms. A centrally located bathhouse provides hot showers and restroom facilities.\n\nThe park is renowned for its 15 miles of off-road mountain biking trails, considered some of the best wilderness bike trails in the region.",
            location: CampgroundLocation(
                latitude: 25.9203,
                longitude: -80.1404,
                address: Address(
                    street1: "2701 NE 151st St",
                    city: "North Miami Beach",
                    zipcode: "33160",
                    country: "United States",
                    countryCode: "US",
                    state: "Florida",
                    stateCode: "FL",
                    full: "2701 NE 151st St, North Miami Beach, FL 33160"
                )
            ),
            amenities: CampgroundAmenities(
                toilets: true,
                toiletKind: "flush",
                trash: true,
                campStore: true,
                dumpStation: true,
                wifi: true,
                petsAllowed: true,
                showers: true,
                firesAllowed: true,
                water: true
            ),
            reservationUrl: "https://example.com/book",
            price: CampgroundPrice(minimum: 55, maximum: 85, currency: "USD"),
            contact: Contact(primaryPhone: "+1 (786) 756-2327", primaryEmail: "info@oletariver.com")
        )
    )
}
