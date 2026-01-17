//
//  FriendAvailabilityScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct MeetupFrequency: Identifiable {
    let id: String
    let label: String
    let description: String
}

struct LocationStatus: Identifiable {
    let id: String
    let label: String
    let description: String
    let icon: String
}

struct FriendAvailabilityScreen: View {
    let onContinue: () -> Void
    
    @State private var selectedFrequency: String? = nil
    @State private var selectedLocation: String? = nil
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private let meetupFrequencies: [MeetupFrequency] = [
        MeetupFrequency(
            id: "daily",
            label: "Almost Daily",
            description: "I love meeting new people all the time"
        ),
        MeetupFrequency(
            id: "few-times-week",
            label: "Few Times a Week",
            description: "Regular hangouts work for me"
        ),
        MeetupFrequency(
            id: "weekly",
            label: "Weekly",
            description: "Once a week is my sweet spot"
        ),
        MeetupFrequency(
            id: "occasional",
            label: "Occasionally",
            description: "When the vibe is right"
        )
    ]
    
    private let locationStatuses: [LocationStatus] = [
        LocationStatus(
            id: "settled",
            label: "Settled for Now",
            description: "Staying in one place for a while",
            icon: "mappin.circle.fill"
        ),
        LocationStatus(
            id: "moving",
            label: "Always Moving",
            description: "New location every few weeks",
            icon: "mappin.circle.fill"
        ),
        LocationStatus(
            id: "seasonal",
            label: "Seasonal Nomad",
            description: "I follow the weather",
            icon: "mappin.circle.fill"
        )
    ]
    
    private var canContinue: Bool {
        selectedFrequency != nil && selectedLocation != nil
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How social are you?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(charcoalColor)
                    
                    Text("Let's understand your availability for meetups")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Meetup Frequency
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                Text("MEETUP FREQUENCY")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(charcoalColor.opacity(0.5))
                                    .tracking(1)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(meetupFrequencies) { freq in
                                    MeetupFrequencyCard(
                                        frequency: freq,
                                        isSelected: selectedFrequency == freq.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedFrequency = freq.id
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Travel Pace
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "mappin.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                Text("TRAVEL PACE")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(charcoalColor.opacity(0.5))
                                    .tracking(1)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(locationStatuses) { status in
                                    LocationStatusCard(
                                        status: status,
                                        isSelected: selectedLocation == status.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedLocation = status.id
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom CTA - Pinned to bottom with solid background
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                    
                    // Button - Make entire area clickable
                    Button(action: {
                        if canContinue {
                            onContinue()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 56)
                        .background(
                            canContinue ?
                            LinearGradient(
                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: canContinue ? .black.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canContinue)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 50)
                }
                .background(Color.white)
            }
        }
    }
}

struct MeetupFrequencyCard: View {
    let frequency: MeetupFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? burntOrange : charcoalColor)
                    
                    Text(frequency.description)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(burntOrange)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? burntOrange : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationStatusCard: View {
    let status: LocationStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let softGray = Color("SoftGray")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                gradient: Gradient(colors: [forestGreen, skyBlue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [softGray, softGray]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: status.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? forestGreen : charcoalColor)
                    
                    Text(status.description)
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(forestGreen)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? forestGreen : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FriendAvailabilityScreen {
        print("Continue tapped")
    }
}
