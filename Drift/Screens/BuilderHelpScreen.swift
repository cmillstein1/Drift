//
//  BuilderHelpScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct Expert: Identifiable {
    let id: Int
    let name: String
    let specialty: String
    let rating: Double
    let reviews: Int
    let hourlyRate: Int
    let verified: Bool
    let description: String
    let badges: [String]
}

struct ExpertCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct BuilderHelpScreen: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var experts: [Expert] = [
        Expert(
            id: 1,
            name: "Mike Johnson",
            specialty: "Electrical & Solar",
            rating: 4.9,
            reviews: 127,
            hourlyRate: 75,
            verified: true,
            description: "Specialized in off-grid solar systems and electrical wiring for van conversions",
            badges: ["Solar Expert", "10+ Years", "Fast Response"]
        ),
        Expert(
            id: 2,
            name: "Sarah Chen",
            specialty: "Plumbing & Water Systems",
            rating: 4.8,
            reviews: 94,
            hourlyRate: 65,
            verified: true,
            description: "Expert in water tanks, pumps, and complete plumbing solutions for mobile living",
            badges: ["Certified", "Remote Help", "500+ Installs"]
        ),
        Expert(
            id: 3,
            name: "Tom Rodriguez",
            specialty: "Complete Van Builds",
            rating: 5.0,
            reviews: 203,
            hourlyRate: 95,
            verified: true,
            description: "Full-service van conversions from design to completion",
            badges: ["Master Builder", "Premium", "In-Person Available"]
        )
    ]
    
    private let categories: [ExpertCategory] = [
        ExpertCategory(name: "Electrical", icon: "bolt.fill", color: Color(red: 0.80, green: 0.40, blue: 0.20)),
        ExpertCategory(name: "Plumbing", icon: "drop.fill", color: Color(red: 0.53, green: 0.81, blue: 0.92)),
        ExpertCategory(name: "General", icon: "wrench.and.screwdriver.fill", color: Color(red: 0.13, green: 0.55, blue: 0.13))
    ]
    
    private let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Builder Help")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            Text("Connect with verified experts")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(charcoalColor)
                                .frame(width: 36, height: 36)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Badge
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Premium Feature")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Get expert help with your van build. Pay only for the time you need.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("All experts are verified and reviewed")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [burntOrange, forestGreen]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Categories")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            HStack(spacing: 12) {
                                ForEach(categories) { category in
                                    Button(action: {}) {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(category.color.opacity(0.2))
                                                    .frame(width: 48, height: 48)
                                                
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 24))
                                                    .foregroundColor(category.color)
                                            }
                                            
                                            Text(category.name)
                                                .font(.system(size: 13))
                                                .foregroundColor(charcoalColor)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Top Experts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Top Experts")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            ForEach(experts) { expert in
                                ExpertCard(expert: expert)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // How it works
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How it works")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(charcoalColor)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HowItWorksStep(
                                    number: "1",
                                    title: "Choose your expert",
                                    description: "Browse verified professionals by specialty"
                                )
                                
                                HowItWorksStep(
                                    number: "2",
                                    title: "Book a consultation",
                                    description: "Video call or in-person help available"
                                )
                                
                                HowItWorksStep(
                                    number: "3",
                                    title: "Get your build done right",
                                    description: "Expert guidance every step of the way"
                                )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }
}

struct ExpertCard: View {
    let expert: Expert
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let desertSand = Color(red: 0.96, green: 0.87, blue: 0.73)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Expert Header
            HStack(alignment: .top, spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [burntOrange, forestGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(expert.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(charcoalColor)
                        
                        if expert.verified {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(forestGreen)
                        }
                    }
                    
                    Text(expert.specialty)
                        .font(.system(size: 14))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(burntOrange)
                            
                            Text("\(expert.rating, specifier: "%.1f")")
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor)
                        }
                        
                        Text("(\(expert.reviews) reviews)")
                            .font(.system(size: 14))
                            .foregroundColor(charcoalColor.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(expert.description)
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.7))
                .lineSpacing(4)
            
            // Badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(expert.badges, id: \.self) { badge in
                        Text(badge)
                            .font(.system(size: 12))
                            .foregroundColor(charcoalColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(desertSand)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // Footer with pricing and button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starting at")
                        .font(.system(size: 13))
                        .foregroundColor(charcoalColor.opacity(0.6))
                    
                    Text("$\(expert.hourlyRate)/hr")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(charcoalColor)
                }
                
                Spacer()
                
                Button(action: {
                    // Handle book call
                }) {
                    Text("Book Call")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(burntOrange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(number). \(title)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(charcoalColor)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(charcoalColor.opacity(0.6))
        }
    }
}

#Preview {
    BuilderHelpScreen()
}
