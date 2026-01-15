//
//  LoginView.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    @State private var showEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                Text("Drift")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 40)
            
            if !showEmailLogin {
                // Social Sign In Buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    
                    // Sign in with Google
                    Button(action: {
                        Task {
                            await handleGoogleSignIn()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Sign in with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.primary)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Use email instead button
                    Button(action: {
                        withAnimation {
                            showEmailLogin = true
                        }
                    }) {
                        Text("Use email instead")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
            } else {
                // Email Login Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    Button(action: {
                        Task {
                            await handleEmailAuth()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .disabled(isLoading)
                    
                    Button(action: {
                        isSignUp.toggle()
                        errorMessage = nil
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    Button(action: {
                        withAnimation {
                            showEmailLogin = false
                            errorMessage = nil
                            email = ""
                            password = ""
                        }
                    }) {
                        Text("Back")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await performAppleSignIn(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
    }
    
    private func performAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            errorMessage = "Failed to get identity token from Apple"
            isLoading = false
            return
        }
        
        let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        
        do {
            try await supabaseManager.signInWithApple(
                identityToken: identityToken,
                authorizationCode: authorizationCode
            )
            // Success - the state should update automatically via @Published
            print("Apple Sign In successful")
        } catch {
            print("Apple Sign In error: \(error)")
            // Provide more user-friendly error message
            if error.localizedDescription.contains("Unacceptable audience") {
                errorMessage = "Apple Sign In configuration error. Please check Supabase dashboard settings."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    private func handleGoogleSignIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Note: Full Google Sign In integration requires additional setup
            // This is a placeholder - you'll need to implement the OAuth flow
            // with Supabase's OAuth provider
            try await supabaseManager.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func handleEmailAuth() async {
        isLoading = true
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            isLoading = false
            return
        }
        
        do {
            if isSignUp {
                try await supabaseManager.signUpWithEmail(email: email, password: password)
            } else {
                try await supabaseManager.signInWithEmail(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    LoginView()
}
