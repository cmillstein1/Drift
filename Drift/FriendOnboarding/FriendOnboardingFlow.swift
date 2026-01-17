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
        return currentStep == 7 // 8 screens total (0-7)
    }
}

struct FriendOnboardingFlow: View {
    @StateObject private var flowManager = FriendOnboardingFlowManager()
    let onComplete: () -> Void
    
    var body: some View {
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
                NameScreen {
                    flowManager.nextStep()
                }
            case 5:
                PhotoUploadScreen {
                    flowManager.nextStep()
                }
            case 6:
                LocationScreen {
                    flowManager.nextStep()
                }
            case 7:
                SafetyScreen {
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

#Preview {
    FriendOnboardingFlow {
        print("Friend onboarding complete")
    }
}
