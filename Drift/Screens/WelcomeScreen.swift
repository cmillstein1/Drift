//
//  WelcomeScreen.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import SwiftUI
import AuthenticationServices
import DriftBackend

struct WelcomeScreen: View {
    @ObservedObject private var supabaseManager = SupabaseManager.shared
    
    @State private var showEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 40
    
    // Charcoal color matching the design
    private let charcoalColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20)
    private let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    
    var body: some View {
        ZStack {
            // Background Image
            GeometryReader { geometry in
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1637690244677-320c56d21de2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx2YW4lMjBsaWZlJTIwc3Vuc2V0fGVufDF8fHx8MTc2ODUwNjA1Mnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(charcoalColor)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .opacity(0.7)
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        charcoalColor.opacity(0.5),
                        charcoalColor
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            
            // Content
            VStack {
                // Title Section
                VStack(spacing: 12) {
                    Text("Drift")
                        .font(.system(size: 60, weight: .bold, design: .default))
                        .tracking(-2)
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                    
                    Text("Where wanderers connect")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Buttons Section – Sign in with Apple / Google / Email
                VStack(spacing: 16) {
                    if !showEmailLogin {
                        Text("For van-lifers, digital nomads, and those who choose the open road")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.bottom, 32)
                            .opacity(buttonsOpacity)
                            .offset(y: buttonsOffset)
                        
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
                        .frame(height: 56)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .opacity(buttonsOpacity)
                        .offset(y: buttonsOffset)
                        
                        // Sign in with Google
                        Button(action: {
                            Task {
                                await handleGoogleSignIn()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image("google_icon")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundColor(charcoalColor)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .opacity(buttonsOpacity)
                        .offset(y: buttonsOffset)
                        
                        // Divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        .opacity(buttonsOpacity)
                        .offset(y: buttonsOffset)

                        // Email option
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmailLogin = true
                            }
                        }) {
                            Text("Continue with email")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .opacity(buttonsOpacity)
                        .offset(y: buttonsOffset)

                        // Terms
                        Text("By continuing, you agree to Drift's Terms of Service\nand Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.top, 8)
                            .opacity(buttonsOpacity)
                            .offset(y: buttonsOffset)
                    }

                    if showEmailLogin {
                            // Email Login Form
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                    TextField("Enter your email", text: $email)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                        .padding(.horizontal, 20)
                                        .frame(height: 56)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                    SecureField("Enter your password", text: $password)
                                        .font(.system(size: 16))
                                        .foregroundColor(charcoalColor)
                                        .padding(.horizontal, 20)
                                        .frame(height: 56)
                                        .background(Color.white)
                                        .clipShape(Capsule())
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
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundColor(.white)
                                .background(charcoalColor)
                                .clipShape(Capsule())
                                .disabled(isLoading)

                                Button(action: {
                                    isSignUp.toggle()
                                    errorMessage = nil
                                }) {
                                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.top, 4)

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showEmailLogin = false
                                        errorMessage = nil
                                        email = ""
                                        password = ""
                                    }
                                }) {
                                    Text("Back")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.top, 4)
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 64)
            }
        }
        .onAppear {
            // Animate title
            withAnimation(.easeOut(duration: 0.8)) {
                titleOpacity = 1
                titleOffset = 0
            }
            
            // Animate buttons with delay
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                buttonsOpacity = 1
                buttonsOffset = 0
            }
        }
    }
    
    // MARK: - Authentication Handlers
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
            print("Apple Sign In successful")
        } catch {
            print("Apple Sign In error: \(error)")
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
        
        print("🔑 handleEmailAuth called - isSignUp: \(isSignUp)")
        
        do {
            if isSignUp {
                print("📝 Calling signUpWithEmail...")
                try await supabaseManager.signUpWithEmail(email: email, password: password)
            } else {
                print("🔐 Calling signInWithEmail...")
                try await supabaseManager.signInWithEmail(email: email, password: password)
            }
        } catch {
            print("❌ Auth error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    WelcomeScreen()
}
