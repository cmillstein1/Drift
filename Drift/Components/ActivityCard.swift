//
//  ActivityCard.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct ActivityCard: View {
    let activity: Activity
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let forestGreen = Color("ForestGreen")
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: activity.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                }
                .frame(height: 160)
                .clipped()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                
                Text(activity.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(charcoalColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    )
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(activity.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text(activity.location)
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text(activity.date)
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        
                        Text("\(activity.attendees)/\(activity.maxAttendees) going")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }
                
                HStack {
                    HStack(spacing: 0) {
                        Text("Hosted by ")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                        Text(activity.host)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(burntOrange)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Handle join
                    }) {
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(forestGreen)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ActivityCard(
        activity: Activity(
            id: 1,
            title: "Sunrise Hike",
            location: "Big Sur Trail",
            date: "Tomorrow, 6:00 AM",
            attendees: 4,
            maxAttendees: 8,
            host: "Sarah",
            category: "Outdoor",
            imageURL: "https://images.unsplash.com/photo-1603741614953-4187ed84cc50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3VudGFpbiUyMGhpa2luZyUyMGFkdmVudHVyZXxlbnwxfHx8fDE3NjgzODg4MDN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
        )
    )
    .padding()
}
