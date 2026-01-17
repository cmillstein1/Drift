//
//  ActivityPreferenceScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct ActivityPreference: Identifiable {
    let id: String
    let label: String
    let icon: String
    let gradient: LinearGradient
}

struct ActivityPreferenceScreen: View {
    let onContinue: () -> Void
    
    @State private var selectedActivities: Set<String> = []
    
    private let softGray = Color("SoftGray")
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let desertSand = Color("DesertSand")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    private var activities: [ActivityPreference] {
        [
            ActivityPreference(
                id: "hiking",
                label: "Hiking",
                icon: "mountain.2.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "surfing",
                label: "Surfing",
                icon: "water.waves",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, forestGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "photography",
                label: "Photography",
                icon: "camera.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, desertSand]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "coffee",
                label: "Coffee Hangouts",
                icon: "cup.and.saucer.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [desertSand, burntOrange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "music",
                label: "Live Music",
                icon: "music.note",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "food",
                label: "Food Tours",
                icon: "fork.knife",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [sunsetRose, burntOrange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "fitness",
                label: "Fitness",
                icon: "figure.run",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [forestGreen, burntOrange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "art",
                label: "Arts & Culture",
                icon: "paintpalette.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [skyBlue, sunsetRose]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "reading",
                label: "Book Clubs",
                icon: "book.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [desertSand, skyBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "nightlife",
                label: "Nightlife",
                icon: "wineglass.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [burntOrange, forestGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "cycling",
                label: "Cycling",
                icon: "bicycle",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [forestGreen, desertSand]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            ActivityPreference(
                id: "camping",
                label: "Camping",
                icon: "tent.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [forestGreen, burntOrange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        ]
    }
    
    private var canContinue: Bool {
        selectedActivities.count >= 3
    }
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What activities interest you?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(charcoalColor)
                    
                    Text("Select at least 3 to help us match you with the right crew")
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    Text("\(selectedActivities.count) selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(burntOrange)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Activities Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(activities) { activity in
                            ActivityPreferenceCard(
                                activity: activity,
                                isSelected: selectedActivities.contains(activity.id),
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedActivities.contains(activity.id) {
                                            selectedActivities.remove(activity.id)
                                        } else {
                                            selectedActivities.insert(activity.id)
                                        }
                                    }
                                }
                            )
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

struct ActivityPreferenceCard: View {
    let activity: ActivityPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    private let charcoalColor = Color("Charcoal")
    private let forestGreen = Color("ForestGreen")
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: activity.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : charcoalColor)
                }
                
                Text(activity.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : charcoalColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if isSelected {
                        activity.gradient
                    } else {
                        Color.white.opacity(0.2)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 0 : 1
                    )
            )
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                    
                                    Circle()
                                        .fill(forestGreen)
                                        .frame(width: 12, height: 12)
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ActivityPreferenceScreen {
        print("Continue tapped")
    }
}
