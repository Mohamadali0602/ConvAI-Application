//
//  MainAuthenticationView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import SwiftUI
import AuthenticationServices

struct MainAuthenticationView: View {
    let onGoogleSignIn: () -> Void
    let onAppleSignIn: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            // ConvAI gradient background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App logo and title
                VStack(spacing: 16) {
                    Text("ConvAI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(localizationManager.getString("welcome_subtitle") ?? "Your AI Conversation Partner")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Authentication buttons
                VStack(spacing: 20) {
                    // Sign in with Google
                    AuthButton(
                        title: localizationManager.getString("auth_sign_in_google") ?? "Continue with Google",
                        backgroundColor: .white,
                        textColor: .black,
                        icon: "globe",
                        action: onGoogleSignIn
                    )
                    
                    // Sign in with Apple (Official Button)
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success:
                                onAppleSignIn()
                            case .failure(let error):
                                print("Apple Sign-In failed: \(error)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Terms and conditions
                Text(localizationManager.getString("terms_conditions") ?? "By connecting to ConvAI, you accept our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
    }
}

struct AuthButton: View {
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let icon: String?
    let borderColor: Color?
    let action: () -> Void
    
    init(title: String, backgroundColor: Color, textColor: Color, icon: String? = nil, borderColor: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.icon = icon
        self.borderColor = borderColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    if icon == "google_logo" {
                        Image(icon) // Custom Google logo
                            .resizable()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: icon)
                            .font(.title3)
                    }
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundColor(textColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor ?? Color.clear, lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}

#Preview {
    MainAuthenticationView(
        onGoogleSignIn: { print("Google sign-in tapped") },
        onAppleSignIn: { print("Apple sign-in tapped") }
    )
}
