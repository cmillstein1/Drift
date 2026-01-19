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
        return currentStep == 8 // 9 screens total (0-8)
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

            ZStack {
                currentScreen
                    .id(flowManager.currentStep)
                    .transition(slideTransition)
            }
            .clipped()
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
            LocationScreen {
                flowManager.nextStep()
            }
        case 7:
            HometownScreen {
                flowManager.nextStep()
            }
        case 8:
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
