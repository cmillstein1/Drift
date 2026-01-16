//
//  OnboardingFlow.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Combine

class OnboardingFlowManager: ObservableObject {
    @Published var currentStep: Int = 0
    
    func nextStep() {
        currentStep += 1
    }
    
    func isLastStep() -> Bool {
        return currentStep == 7 // 8 screens total (0-7)
    }
}

struct OnboardingFlow: View {
    @StateObject private var flowManager = OnboardingFlowManager()
    let onComplete: () -> Void
    
    var body: some View {
        Group {
            switch flowManager.currentStep {
            case 0:
                NameScreen {
                    flowManager.nextStep()
                }
            case 1:
                BirthdayScreen {
                    flowManager.nextStep()
                }
            case 2:
                OrientationScreen {
                    flowManager.nextStep()
                }
            case 3:
                LookingForScreen {
                    flowManager.nextStep()
                }
            case 4:
                PhotoUploadScreen {
                    flowManager.nextStep()
                }
            case 5:
                InterestsScreen {
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
                NameScreen {
                    flowManager.nextStep()
                }
            }
        }
    }
}

#Preview {
    OnboardingFlow {
        print("Onboarding complete")
    }
}
