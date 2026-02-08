//
//  EnterInviteCodeScreen.swift
//  Drift
//
//  Full-screen "Enter Invite Code" shown after sign-in when the user hasn't yet redeemed a code.
//

import SwiftUI
import DriftBackend
import Auth

struct EnterInviteCodeScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var inviteManager = InviteManager.shared
    
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var showCheckmark = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var isRedeeming = false
    @State private var isSigningOut = false
    @State private var addedToWaitlist = false
    @State private var waitlistCheckmarkScale: CGFloat = 0
    @FocusState private var focusedField: Int?
    
    private let textMuted = Color(red: 0.55, green: 0.55, blue: 0.58)
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top bar: Sign out only
                    HStack {
                        Spacer()
                        Button(action: { signOut() }) {
                            if isSigningOut {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Sign out")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isSigningOut)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Title: "You've been" + animated "invited"
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You've been")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        AnimatedGradientText(text: "invited", fontSize: 28)
                            .frame(height: 36)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
                    
                    Text("Enter your code to join the community.")
                        .font(.system(size: 14))
                        .foregroundColor(textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 42)
                    
                    // INVITE CODE label with dividers (glass feel)
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.1), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                        Text("INVITE CODE")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.1), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    .padding(.bottom, 10)
                    
                    // Six glassmorphic code fields
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            InviteCodeDigitField(
                                text: $digits[index],
                                index: index,
                                isFocused: focusedField == index,
                                onDigitChange: handleDigitInput,
                                focusBinding: $focusedField
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    
                    if let message = errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                    }
                    
                    Spacer(minLength: 28)
                    
                    // Continue button (gradient, glass feel)
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            if isRedeeming {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.1)
                            } else if showCheckmark {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                            } else if showError {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .bold))
                            } else {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if isRedeeming {
                                Color(hexInvite: "2A2A2A").opacity(0.8)
                            } else if showCheckmark {
                                Color(red: 0.13, green: 0.55, blue: 0.13)
                            } else if showError {
                                Color.red.opacity(0.9)
                            } else {
                                LinearGradient(
                                    colors: [Color(hexInvite: "D97845"), Color(hexInvite: "E07A89")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color(hexInvite: "D97845").opacity(showError ? 0 : 0.4), radius: 16, y: 8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                    .disabled(isRedeeming)
                    
                    // Join waitlist button (glass) → success state with animation
                    Button(action: {
                        guard !addedToWaitlist else { return }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            addedToWaitlist = true
                        }
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
                            waitlistCheckmarkScale = 1
                        }
                    }) {
                        if addedToWaitlist {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hexInvite: "547756").opacity(0.3))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hexInvite: "547756"))
                                }
                                .scaleEffect(waitlistCheckmarkScale)
                                Text("You have been added to the waitlist!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color(hexInvite: "547756").opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color(hexInvite: "547756").opacity(0.4), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        } else {
                            Text("Join waitlist")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(addedToWaitlist)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
                .onTapGesture {
                    focusedField = nil
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            digits = Array(repeating: "", count: 6)
            showCheckmark = false
            showError = false
            errorMessage = nil
            isRedeeming = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = 0
            }
        }
    }
    
    private func handleDigitInput(index: Int, oldValue: String, newValue: String) {
        if showError {
            showError = false
            errorMessage = nil
        }
        
        let filtered = newValue.filter { $0.isNumber }
        
        if filtered.isEmpty && !oldValue.isEmpty {
            if index > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField = index - 1
                }
            }
            return
        }
        
        if filtered.count > 1 {
            let codeArray = Array(filtered.prefix(6))
            for i in 0..<min(6, codeArray.count) {
                digits[i] = String(codeArray[i])
            }
            if codeArray.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    validateAndRedeemCode()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = min(5, codeArray.count)
                }
            }
            return
        }
        
        if let digitChar = filtered.first, filtered.count == 1 {
            digits[index] = String(digitChar)
            if index < 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField = index + 1
                }
            } else if index == 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    validateAndRedeemCode()
                }
            }
        } else if filtered.isEmpty {
            digits[index] = ""
        }
    }
    
    private func getCodeString() -> String {
        digits.joined()
    }
    
    private func signOut() {
        isSigningOut = true
        Task {
            await PushNotificationManager.shared.clearFCMToken()
            do {
                try await supabaseManager.signOut()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
    
    /// Validate then redeem the code for the current user and mark invite as redeemed.
    private func validateAndRedeemCode() {
        let code = getCodeString()
        guard code.count == 6,
              let userId = supabaseManager.currentUser?.id else { return }
        
        isRedeeming = true
        showError = false
        showCheckmark = false
        errorMessage = nil
        
        Task {
            let isValid = await inviteManager.validateInviteCode(code)
            
            await MainActor.run {
                guard isValid else {
                    isRedeeming = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showError = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        digits = Array(repeating: "", count: 6)
                        showError = false
                        focusedField = nil
                        DispatchQueue.main.async {
                            focusedField = 0
                        }
                    }
                    return
                }
                
                // Redeem the code for this user
                Task {
                    do {
                        try await inviteManager.redeemInviteCode(code, userId: userId)
                        await MainActor.run {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCheckmark = true
                            }
                            supabaseManager.hasRedeemedInvite = true
                        }
                    } catch {
                        await MainActor.run {
                            isRedeeming = false
                            errorMessage = error.localizedDescription
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showError = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                digits = Array(repeating: "", count: 6)
                                showError = false
                                errorMessage = nil
                                focusedField = nil
                                DispatchQueue.main.async {
                                    focusedField = 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    EnterInviteCodeScreen()
}
