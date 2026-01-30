//
//  FriendOnboardingFlow.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Combine

class FriendOnboardingFlowManager: ObservableObject {
    @Published var currentStep: Int = 0
    
    func nextStep() {
        currentStep += 1
    }
    
    func isLastStep() -> Bool {
        return currentStep == 11 // 12 screens total (0-11)
    }
}

struct FriendOnboardingFlow: View {
    @StateObject private var flowManager = FriendOnboardingFlowManager()
    let onComplete: () -> Void
    
    private let softGray = Color("SoftGray")
    
    var body: some View {
        ZStack {
            softGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button - show on all screens except the first
                if flowManager.currentStep > 0 {
                    HStack {
                        OnboardingBackButton {
                            flowManager.currentStep = max(0, flowManager.currentStep - 1)
                        }
                        .padding(.leading, 24)
                        .padding(.top, 16)
                        Spacer()
                    }
                }
                
                Group {
                    switch flowManager.currentStep {
            case 0:
                FriendWelcomeScreen {
                    flowManager.nextStep()
                }
            case 1:
                TravelStyleScreen {
                    flowManager.nextStep()
                }
            case 2:
                ActivityPreferenceScreen {
                    flowManager.nextStep()
                }
            case 3:
                FriendAvailabilityScreen {
                    flowManager.nextStep()
                }
            case 4:
                TravelPlansOnboardingScreen(backgroundColor: softGray) {
                    flowManager.nextStep()
                }
            case 5:
                NameScreen(backgroundColor: softGray) {
                    flowManager.nextStep()
                }
            case 6:
                PhotoUploadScreen(backgroundColor: softGray) {
                    flowManager.nextStep()
                }
            case 7:
                InterestsScreen {
                    flowManager.nextStep()
                }
            case 8:
                AboutMeScreen(backgroundColor: softGray) {
                    flowManager.nextStep()
                }
            case 9:
                LocationScreen(backgroundColor: softGray) {
                    flowManager.nextStep()
                }
            case 10:
                PushNotificationsScreen {
                    flowManager.nextStep()
                }
            case 11:
                SafetyScreen(backgroundColor: softGray) {
                    // SafetyScreen handles marking onboarding as complete internally
                    onComplete()
                }
            default:
                FriendWelcomeScreen {
                    flowManager.nextStep()
                }
                    }
                }
            }
        }
    }
}

#Preview {
    FriendOnboardingFlow {
        print("Friend onboarding complete")
    }
}
