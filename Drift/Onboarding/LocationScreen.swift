//
//  LocationScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

struct LocationScreen: View {
    let onContinue: () -> Void
    
    @StateObject private var locationManager = LocationManager()
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var descriptionOpacity: Double = 0
    @State private var descriptionOffset: CGFloat = 20
    @State private var feature1Opacity: Double = 0
    @State private var feature1Offset: CGFloat = -20
    @State private var feature2Opacity: Double = 0
    @State private var feature2Offset: CGFloat = -20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var skipButtonOpacity: Double = 0
    @State private var skipButtonOffset: CGFloat = 20
    
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)
    
    var body: some View {
        ZStack {
            warmWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ProgressIndicator(currentStep: 4, totalSteps: 5)
                    .padding(.top, 32)
                    .padding(.bottom, 48)
                
                VStack(spacing: 0) {
                    VStack(spacing: 32) {
                        VStack(spacing: 24) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(skyBlue.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(skyBlue)
                                    .scaleEffect(iconScale)
                                    .rotationEffect(.degrees(iconRotation))
                            }
                            .opacity(iconOpacity)
                            
                            VStack(spacing: 12) {
                                Text("Enable location")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(charcoalColor)
                                    .opacity(titleOpacity)
                                    .offset(y: titleOffset)
                                
                                Text("Meet people where you are — or where you're headed next")
                                    .font(.system(size: 16))
                                    .foregroundColor(charcoalColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .opacity(descriptionOpacity)
                                    .offset(y: descriptionOffset)
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                LocationFeature(
                                    icon: "mappin.circle.fill",
                                    iconColor: forestGreen,
                                    title: "Find nearby nomads",
                                    description: "Connect with travelers in your current area",
                                    opacity: feature1Opacity,
                                    offset: feature1Offset
                                )
                                
                                LocationFeature(
                                    icon: "mappin.circle.fill",
                                    iconColor: burntOrange,
                                    title: "Share your route",
                                    description: "Let others know where you're traveling next",
                                    opacity: feature2Opacity,
                                    offset: feature2Offset
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 48)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            locationManager.requestLocationPermission()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onContinue()
                            }
                        }) {
                            Text("Enable Location")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(burntOrange)
                                .clipShape(Capsule())
                        }
                        .opacity(buttonOpacity)
                        .offset(y: buttonOffset)
                        
                        Button(action: {
                            onContinue()
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(charcoalColor.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .opacity(skipButtonOpacity)
                        .offset(y: skipButtonOffset)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                iconOpacity = 1
                iconScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                iconRotation = 10
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    iconRotation = -10
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    iconRotation = 10
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    iconRotation = 0
                }
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                descriptionOpacity = 1
                descriptionOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                feature1Opacity = 1
                feature1Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                feature2Opacity = 1
                feature2Offset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                skipButtonOpacity = 1
                skipButtonOffset = 0
            }
        }
    }
}

struct LocationFeature: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let opacity: Double
    let offset: CGFloat
    
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(charcoalColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(charcoalColor.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .opacity(opacity)
        .offset(x: offset)
    }
}

#Preview {
    LocationScreen {
        print("Continue tapped")
    }
}
