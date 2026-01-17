//
//  EditProfileSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct TravelStop: Identifiable {
    var id: String
    var location: String
    var startDate: String
    var endDate: String
}

struct EditProfileSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = "Alex Turner"
    @State private var currentLocation: String = "Big Sur, California"
    @State private var about: String = "Van-lifer and photographer exploring the West Coast. I love early morning hikes, good coffee, and meeting fellow adventurers on the road."
    @State private var travelPace: TravelPace = .slow
    @State private var travelSchedule: [TravelStop] = [
        TravelStop(id: "1", location: "Portland, OR", startDate: "2026-02-01", endDate: "2026-02-15"),
        TravelStop(id: "2", location: "Seattle, WA", startDate: "2026-02-16", endDate: "2026-03-01")
    ]
    
    @State private var showDatePicker = false
    @State private var selectedDateStopId: String = ""
    @State private var selectedDateField: DateFieldType?
    @State private var selectedDate: Date = Date()
    
    enum DateFieldType {
        case startDate
        case endDate
    }
    
    enum TravelPace: String, CaseIterable {
        case slow = "slow"
        case moderate = "moderate"
        case fast = "fast"
        
        var label: String {
            switch self {
            case .slow: return "Slow Traveler"
            case .moderate: return "Moderate Pace"
            case .fast: return "Fast Mover"
            }
        }
        
        var description: String {
            switch self {
            case .slow: return "Months in each location"
            case .moderate: return "Weeks in each location"
            case .fast: return "Days in each location"
            }
        }
    }
    
    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")
    private let softGray = Color("SoftGray")
    private let forestGreen = Color("ForestGreen")
    private let skyBlue = Color("SkyBlue")
    private let sunsetRose = Color(red: 0.93, green: 0.36, blue: 0.51)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(charcoalColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(charcoalColor)
                        .frame(width: 32, height: 32)
                        .background(softGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
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
                        VStack(spacing: 0) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                TextField("Your name", text: $name)
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(softGray)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // Current Location
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Location")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                HStack {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor.opacity(0.4))
                                    
                                    TextField("City, State/Country", text: $currentLocation)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(softGray)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // About
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                ZStack(alignment: .topLeading) {
                                    if about.isEmpty {
                                        Text("Tell people about yourself...")
                                            .font(.system(size: 16))
                                            .foregroundColor(charcoalColor.opacity(0.4))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    
                                    TextEditor(text: Binding(
                                        get: { about },
                                        set: { newValue in
                                            if newValue.count <= 500 {
                                                about = newValue
                                            }
                                        }
                                    ))
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                        .frame(minHeight: 100)
                                        .scrollContentBackground(.hidden)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(softGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                
                                HStack {
                                    Spacer()
                                    Text("\(about.count)/500")
                                        .font(.system(size: 12))
                                        .foregroundColor(charcoalColor.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // Travel Pace
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Travel Pace")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(charcoalColor)
                                
                                VStack(spacing: 8) {
                                    ForEach(TravelPace.allCases, id: \.self) { pace in
                                        Button(action: {
                                            travelPace = pace
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(pace.label)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(travelPace == pace ? .white : charcoalColor)
                                                
                                                Text(pace.description)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(travelPace == pace ? .white.opacity(0.8) : charcoalColor.opacity(0.6))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(16)
                                            .background(
                                                travelPace == pace ?
                                                LinearGradient(
                                                    gradient: Gradient(colors: [forestGreen, skyBlue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ) :
                                                LinearGradient(
                                                    gradient: Gradient(colors: [softGray, softGray]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color.gray.opacity(0.2)),
                                alignment: .bottom
                            )
                            
                            // Travel Schedule
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Travel Schedule")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(charcoalColor)
                                        
                                        Text("Where are you headed next?")
                                            .font(.system(size: 12))
                                            .foregroundColor(charcoalColor.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        travelSchedule.append(
                                            TravelStop(
                                                id: UUID().uuidString,
                                                location: "",
                                                startDate: "",
                                                endDate: ""
                                            )
                                        )
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Add")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                if travelSchedule.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("No travel plans yet. Add your next destination!")
                                            .font(.system(size: 14))
                                            .foregroundColor(charcoalColor.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                            .foregroundColor(Color.gray.opacity(0.3))
                                    )
                                } else {
                                    VStack(spacing: 16) {
                                        ForEach(Array(travelSchedule.enumerated()), id: \.element.id) { index, stop in
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text("Stop \(index + 1)")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(charcoalColor.opacity(0.6))
                                                    
                                                    Spacer()
                                                    
                                                    Button(action: {
                                                        travelSchedule.removeAll { $0.id == stop.id }
                                                    }) {
                                                        Image(systemName: "trash")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.red)
                                                            .frame(width: 24, height: 24)
                                                            .background(Color.red.opacity(0.1))
                                                            .clipShape(Circle())
                                                    }
                                                }
                                                
                                                HStack {
                                                    Image(systemName: "mappin")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(charcoalColor.opacity(0.4))
                                                    
                                                    TextField("Location", text: Binding(
                                                        get: { stop.location },
                                                        set: { newValue in
                                                            if let idx = travelSchedule.firstIndex(where: { $0.id == stop.id }) {
                                                                travelSchedule[idx].location = newValue
                                                            }
                                                        }
                                                    ))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(charcoalColor)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                
                                                HStack(spacing: 8) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("Start Date")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(charcoalColor.opacity(0.6))
                                                        
                                                        Button(action: {
                                                            selectedDateStopId = stop.id
                                                            selectedDateField = .startDate
                                                            // Parse existing date or use today
                                                            let formatter = DateFormatter()
                                                            formatter.dateFormat = "yyyy-MM-dd"
                                                            if let date = formatter.date(from: stop.startDate) {
                                                                selectedDate = date
                                                            } else {
                                                                selectedDate = Date()
                                                            }
                                                            showDatePicker = true
                                                        }) {
                                                            HStack {
                                                                Image(systemName: "calendar")
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(charcoalColor.opacity(0.4))
                                                                
                                                                Text(stop.startDate.isEmpty ? "Select date" : stop.startDate)
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(stop.startDate.isEmpty ? charcoalColor.opacity(0.4) : charcoalColor)
                                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                            }
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 8)
                                                            .background(Color.white)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        }
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("End Date")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(charcoalColor.opacity(0.6))
                                                        
                                                        Button(action: {
                                                            selectedDateStopId = stop.id
                                                            selectedDateField = .endDate
                                                            // Parse existing date or use today
                                                            let formatter = DateFormatter()
                                                            formatter.dateFormat = "yyyy-MM-dd"
                                                            if let date = formatter.date(from: stop.endDate) {
                                                                selectedDate = date
                                                            } else {
                                                                selectedDate = Date()
                                                            }
                                                            showDatePicker = true
                                                        }) {
                                                            HStack {
                                                                Image(systemName: "calendar")
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(charcoalColor.opacity(0.4))
                                                                
                                                                Text(stop.endDate.isEmpty ? "Select date" : stop.endDate)
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(stop.endDate.isEmpty ? charcoalColor.opacity(0.4) : charcoalColor)
                                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                            }
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 8)
                                                            .background(Color.white)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(16)
                                            .background(softGray)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            
                            // Save Button
                            VStack(spacing: 0) {
                                Button(action: {
                                    // TODO: Save changes
                                    dismiss()
                                }) {
                                    Text("Save Changes")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [burntOrange, sunsetRose]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .padding(.bottom, 32)
                            }
                            .background(Color.white)
                        }
                    }
                    .background(Color.white)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                VStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let dateString = formatter.string(from: selectedDate)
                            
                            if let idx = travelSchedule.firstIndex(where: { $0.id == selectedDateStopId }),
                               let field = selectedDateField {
                                if field == .startDate {
                                    travelSchedule[idx].startDate = dateString
                                } else {
                                    travelSchedule[idx].endDate = dateString
                                }
                            }
                            
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    EditProfileSheet(isPresented: .constant(true))
}
