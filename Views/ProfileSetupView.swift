//
//  ProfileSetupView.swift
//  ConvAI
//
//  Created by GitHub Copilot on 02/08/2025.
//

import SwiftUI
import Foundation

struct ProfileSetupView: View {
    let userAge: Int
    let onComplete: (String, String?) -> Void
    let onSkip: () -> Void
    
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
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
                
                // Title
                VStack(spacing: 12) {
                    Text(localizationManager.getString("choose_username_icon"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    // Informational note below the title (localized)
                    Text(localizationManager.getString("agents_call_username"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                // Username Input
                VStack(spacing: 20) {
                    TextField("Username", text: $username)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 32)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Next button
                    Button(action: {
                        completeProfile()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(localizationManager.getString("next"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color(red: 0.78, green: 0.36, blue: 0.17) : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .disabled(!isFormValid || isLoading)
                    
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        username.count >= 2 && 
        username.count <= 20
    }
    
    // MARK: - Actions
    
    private func completeProfile() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isFormValid else {
            errorMessage = "Please enter a valid username (2-20 characters)"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Complete the profile setup with just the username
        isLoading = false
        
        #if DEBUG
        print("🔧 ProfileSetup: Completing profile with username: \(trimmedUsername)")
        #endif
        
        // Pass nil for profile identifier since we're not using images
        onComplete(trimmedUsername, nil)
    }

}

// MARK: - Preview

#Preview {
    ProfileSetupView(
        userAge: 25,
        onComplete: { username, profileImageUrl in 
            print("Profile complete: \(username), image: \(profileImageUrl ?? "none")")
        },
        onSkip: { 
            print("Profile setup skipped") 
        }
    )
}
