//
//  UsernameInputView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import SwiftUI

struct UsernameInputView: View {
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let userAge: Int
    let userEmail: String
    let onCompleteProfile: (String) -> Void
    let onBack: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
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
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Title
                Text(localizationManager.getString("choose_username") ?? "Choose Your Username")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text(localizationManager.getString("username_subtitle") ?? "This is how other learners will see you")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Username input
                VStack(spacing: 16) {
                    TextField(localizationManager.getString("username_placeholder") ?? "Enter username", text: $username)
                        .convAITextFieldStyle()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Complete profile button
                Button(action: {
                    completeProfile()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(localizationManager.getString("complete_profile") ?? "Complete Profile")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidUsername ? Color(red: 0.78, green: 0.36, blue: 0.17) : Color.gray)
                .cornerRadius(12)
                .disabled(!isValidUsername || isLoading)
                .padding(.horizontal, 20)
                
                // User info display
                VStack(spacing: 8) {
                    Text(localizationManager.getString("signed_in_as") ?? "Signed in as:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(userEmail)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Age: \(userAge) years")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var isValidUsername: Bool {
        username.count >= 3 && username.count <= 20 && username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    
    private func completeProfile() {
        guard isValidUsername else {
            errorMessage = localizationManager.getString("username_error") ?? "Username must be 3-20 characters (letters, numbers, underscore only)"
            return
        }
        
        isLoading = true
        onCompleteProfile(username)
    }
}

#Preview {
    UsernameInputView(
        userAge: 25,
        userEmail: "user@gmail.com",
        onCompleteProfile: { username in
            print("Complete profile with username: \(username)")
        },
        onBack: {
            print("Back pressed")
        }
    )
}
