//
//  AuthGateView.swift
//  ConvAI
//

import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject var auth: EnhancedAuthenticationService
    
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
                    
                    Text("Your AI Conversation Partner")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 16)
                } else {
                    // Authentication buttons
                    VStack(spacing: 20) {
                        // Custom Google Sign-In Button (matching Apple button style)
                        GoogleSignInButtonWrapper {
                            auth.signInWithGoogle()
                        }
                        
                        // Custom Apple Sign-In Button (matching Google button style)
                        AppleSignInButtonWrapper {
                            auth.signInWithApple()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Error message
                if !auth.errorMessage.isEmpty {
                    Text(auth.errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                }
                
                // Terms and conditions
                Text("By connecting to ConvAI, you accept our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
    }
}


