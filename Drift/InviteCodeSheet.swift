//
//  InviteCodeSheet.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI

struct InviteCodeSheet: View {
    @Binding var isOpen: Bool
    let onSubmit: (String) -> Void
    
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var showCheckmark = false
    @State private var showError = false
    @FocusState private var focusedField: Int?
    
    // Master invite code
    private let masterCode = "000000"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Enter Invite Code")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Button(action: {
                        isOpen = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                VStack(spacing: 20) {
                    // Key Icon
                    Image(systemName: "key.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Color(red: 0.80, green: 0.40, blue: 0.20)) // burnt-orange
                        .padding(.bottom, 4)
                    
                    Text("Join the community of wanderers")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                    
                    // 6 Individual Input Squares
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            TextField("", text: $digits[index])
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .frame(width: 48, height: 56)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .focused($focusedField, equals: index)
                                .onChange(of: digits[index]) { oldValue, newValue in
                                    handleDigitInput(index: index, oldValue: oldValue, newValue: newValue)
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 20)
                    
                    // Continue Button
                    Button(action: {
                        // Button is disabled, validation happens automatically
                    }) {
                        ZStack {
                            if showCheckmark {
                                // Show checkmark when code is valid
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            } else if showError {
                                // Show X when code is invalid
                                Image(systemName: "xmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(
                        showCheckmark ? Color(red: 0.13, green: 0.55, blue: 0.13) : // green when valid
                        showError ? Color.red : // red when invalid
                        Color(red: 0.80, green: 0.40, blue: 0.20) // burnt-orange otherwise
                    )
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    // Footer - Waitlist link
                    HStack(spacing: 4) {
                        Text("Don't have an invite code?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // Handle waitlist action
                            print("Join waitlist tapped")
                        }) {
                            Text("Join the waitlist")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.80, green: 0.40, blue: 0.20)) // burnt-orange
                                .underline()
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Reset state when sheet appears
            digits = Array(repeating: "", count: 6)
            showCheckmark = false
            showError = false
            // Focus first field when sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = 0
            }
        }
    }
    
    private func handleDigitInput(index: Int, oldValue: String, newValue: String) {
        // Clear error state when user starts typing
        if showError {
            showError = false
        }
        
        // Filter to only numbers
        let filtered = newValue.filter { $0.isNumber }
        
        // Handle backspace - move to previous field
        if filtered.isEmpty && !oldValue.isEmpty {
            if index > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField = index - 1
                }
            }
            return
        }
        
        // Handle paste - if multiple digits pasted, fill all fields
        if filtered.count > 1 {
            let codeArray = Array(filtered.prefix(6))
            for i in 0..<min(6, codeArray.count) {
                digits[i] = String(codeArray[i])
            }
            
            // If 6 digits pasted, validate immediately
            if codeArray.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    validateCode()
                }
            } else {
                // Focus next empty field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = min(5, codeArray.count)
                }
            }
            return
        }
        
        // Single digit input - only update if it's actually a digit
        if let digitChar = filtered.first, filtered.count == 1 {
            digits[index] = String(digitChar)
            
            // Auto-advance to next field if digit entered
            if index < 5 {
                // Move to next field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField = index + 1
                }
            } else if index == 5 {
                // Last digit entered, validate automatically
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    validateCode()
                }
            }
        } else if filtered.isEmpty {
            // Clear the field
            digits[index] = ""
        }
    }
    
    private func isCodeComplete() -> Bool {
        return digits.allSatisfy { !$0.isEmpty }
    }
    
    private func getCodeString() -> String {
        return digits.joined()
    }
    
    private func validateCode() {
        let code = getCodeString()
        
        guard code.count == 6 else {
            return
        }
        
        // Small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if code == masterCode {
                // Valid code - show checkmark
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showCheckmark = true
                    showError = false
                }
                
                // Dismiss sheet after showing checkmark briefly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onSubmit(code)
                    isOpen = false
                }
            } else {
                // Invalid code - show X
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showError = true
                    showCheckmark = false
                }
                
                // Clear all digits after showing error
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    digits = Array(repeating: "", count: 6)
                    showError = false
                    focusedField = 0
                }
            }
        }
    }
}

#Preview {
    InviteCodeSheet(isOpen: .constant(true)) { code in
        print("Code submitted: \(code)")
    }
}
