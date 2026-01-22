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
    @Published var direction: NavigationDirection = .forward

    enum NavigationDirection {
        case forward, backward
    }

    func nextStep() {
        direction = .forward
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep += 1
        }
    }

    func previousStep() {
        direction = .backward
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep -= 1
        }
    }

    func isLastStep() -> Bool {
        return currentStep == 9 // 10 screens total (0-9)
    }
}

struct OnboardingFlow: View {
    @StateObject private var flowManager = OnboardingFlowManager()
    let onComplete: () -> Void

    private var slideTransition: AnyTransition {
        let insertion: AnyTransition = .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        let removal: AnyTransition = .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
        return flowManager.direction == .forward ? insertion : removal
    }

    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)

    var body: some View {
        ZStack {
            // Background that extends into safe areas
            warmWhite
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed Progress Indicator - only show for steps that need it
                if shouldShowProgressIndicator {
                    ProgressIndicator(currentStep: currentProgressStep, totalSteps: 10)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
                
                ZStack {
                    currentScreen
                        .id(flowManager.currentStep)
                        .transition(slideTransition)
                }
                .clipped()
            }
        }
    }
    
    private var shouldShowProgressIndicator: Bool {
        // Don't show progress indicator for LocationScreen (step 7) and SafetyScreen (step 9)
        return flowManager.currentStep != 7 && flowManager.currentStep != 9
    }
    
    private var currentProgressStep: Int {
        // Map onboarding steps to progress steps (accounting for skipped steps)
        switch flowManager.currentStep {
        case 0: return 1  // NameScreen
        case 1: return 2  // BirthdayScreen
        case 2: return 3  // OrientationScreen
        case 3: return 4  // LookingForScreen
        case 4: return 5  // PhotoUploadScreen
        case 5: return 6  // InterestsScreen
        case 6: return 7  // AboutMeScreen
        case 7: return 7  // LocationScreen - no indicator shown
        case 8: return 8  // HometownScreen
        case 9: return 8  // SafetyScreen - no indicator shown
        default: return 1
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
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
            AboutMeScreen {
                flowManager.nextStep()
            }
        case 7:
            LocationScreen {
                flowManager.nextStep()
            }
        case 8:
            HometownScreen {
                flowManager.nextStep()
            }
        case 9:
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

#Preview {
    OnboardingFlow {
        print("Onboarding complete")
    }
}
