//
//  OnboardingFlow.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import Combine
import DriftBackend

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
        return currentStep == 13 // 14 screens total (0-13)
    }
}

struct OnboardingFlow: View {
    @StateObject private var flowManager = OnboardingFlowManager()
    @StateObject private var profileManager = ProfileManager.shared
    let onComplete: () -> Void
    
    private var startStep: Int? {
        // Check if there's a stored start step for partial onboarding
        if UserDefaults.standard.object(forKey: "datingOnboardingStartStep") != nil {
            let storedStep = UserDefaults.standard.integer(forKey: "datingOnboardingStartStep")
            return storedStep >= 0 ? storedStep : nil
        }
        return nil
    }

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
                // Back button - show on all screens except the first
                if flowManager.currentStep > 0 {
                    HStack {
                        OnboardingBackButton {
                            flowManager.previousStep()
                        }
                        .padding(.leading, 24)
                        .padding(.top, 16)
                        Spacer()
                    }
                }
                
                // Fixed Progress Indicator - only show for steps that need it
                if shouldShowProgressIndicator {
                    ProgressIndicator(currentStep: currentProgressStep, totalSteps: 11)
                        .padding(.horizontal, 24)
                        .padding(.top, flowManager.currentStep > 0 ? 8 : 32)
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
        .onAppear {
            // If startStep is provided, jump to that step for partial onboarding
            if let startStep = startStep {
                flowManager.currentStep = startStep
                UserDefaults.standard.removeObject(forKey: "datingOnboardingStartStep")
            }
            // Sign in with Apple: skip name step — use Apple-provided name only (Guideline 4.0)
            else if UserDefaults.standard.bool(forKey: "last_sign_in_was_apple") {
                flowManager.currentStep = 1
                UserDefaults.standard.removeObject(forKey: "last_sign_in_was_apple")
            }
        }
    }
    
    private var shouldShowProgressIndicator: Bool {
        // Don't show for Location (10), Push Notifications (11), Safety (13)
        return flowManager.currentStep != 10 && flowManager.currentStep != 11 && flowManager.currentStep != 13
    }

    private var currentProgressStep: Int {
        // Map onboarding steps to progress steps (accounting for skipped steps)
        // Total progress steps: 11
        switch flowManager.currentStep {
        case 0: return 1   // NameScreen
        case 1: return 2   // BirthdayScreen
        case 2: return 3   // OrientationScreen
        case 3: return 4   // LookingForScreen
        case 4: return 5   // PhotoUploadScreen
        case 5: return 6   // InterestsScreen
        case 6: return 7   // AboutMeScreen
        case 7: return 8   // ProfilePromptsScreen
        case 8: return 9   // TravelPlansOnboardingScreen
        case 9: return 10  // LifestyleOnboardingScreen
        case 10: return 10 // LocationScreen - no indicator shown
        case 11: return 11 // PushNotificationsScreen - no indicator shown
        case 12: return 11 // HometownScreen
        case 13: return 11 // SafetyScreen - no indicator shown
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
            ProfilePromptsScreen {
                flowManager.nextStep()
            }
        case 8:
            TravelPlansOnboardingScreen {
                flowManager.nextStep()
            }
        case 9:
            LifestyleOnboardingScreen {
                flowManager.nextStep()
            }
        case 10:
            LocationScreen {
                flowManager.nextStep()
            }
        case 11:
            PushNotificationsScreen {
                flowManager.nextStep()
            }
        case 12:
            HometownScreen {
                flowManager.nextStep()
            }
        case 13:
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
