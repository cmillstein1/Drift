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
    
    enum OnboardingStep: Int, CaseIterable {
        case orientation = 0
        case lookingFor = 1
        case lifestyle = 2
        case location = 3
        case safety = 4
        
        var view: AnyView {
            switch self {
            case .orientation:
                return AnyView(OrientationScreen {
                    // Handled by OnboardingFlow
                })
            case .lookingFor:
                return AnyView(LookingForScreen {
                    // Handled by OnboardingFlow
                })
            case .lifestyle:
                return AnyView(LifestyleScreen {
                    // Handled by OnboardingFlow
                })
            case .location:
                return AnyView(LocationScreen {
                    // Handled by OnboardingFlow
                })
            case .safety:
                return AnyView(SafetyScreen {
                    // Handled by OnboardingFlow
                })
            }
        }
    }
    
    func nextStep() {
        if currentStep < OnboardingStep.allCases.count - 1 {
            currentStep += 1
        }
    }
    
    func isLastStep() -> Bool {
        return currentStep == OnboardingStep.allCases.count - 1
    }
}

struct OnboardingFlow: View {
    @StateObject private var flowManager = OnboardingFlowManager()
    let onComplete: () -> Void
    
    var body: some View {
        Group {
            switch flowManager.currentStep {
            case 0:
                OrientationScreen {
                    flowManager.nextStep()
                }
            case 1:
                LookingForScreen {
                    flowManager.nextStep()
                }
            case 2:
                LifestyleScreen {
                    flowManager.nextStep()
                }
            case 3:
                LocationScreen {
                    flowManager.nextStep()
                }
            case 4:
                SafetyScreen {
                    onComplete()
                }
            default:
                OrientationScreen {
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
