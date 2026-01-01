//
//  GoogleSignInButtonWrapper.swift
//  ConvAI
//
//  Created by GitHub Copilot on 02/08/2025.
//

import SwiftUI
import UIKit

struct GoogleSignInButtonWrapper: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("🔵 DEBUG: Google Sign-In button TAPPED")
            print("🔵 DEBUG: Button frame - height: 60, maxWidth: infinity")
            print("🔵 DEBUG: Button corner radius: 12")
            print("🔵 DEBUG: Button scale effect: 1.05")
            print("🔵 DEBUG: About to call Google Sign-In action...")
            action()
            print("🔵 DEBUG: Google Sign-In action completed")
        }) {
            HStack(spacing: 0) {
                // Google logo - positioned exactly like Apple's logo
                if let googleLogo = UIImage(named: "googleLogo") {
                    // DEBUG: Image found successfully
                    let _ = print("🖼️ DEBUG: googleLogo image found successfully - size: \(googleLogo.size)")
                    let _ = print("🖼️ DEBUG: googleLogo frame - width: 20, height: 20, aspect: fit")
                    let _ = print("🖼️ DEBUG: googleLogo color: original (not inverted)")
                    Image(uiImage: googleLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    // DEBUG: Image not found, using fallback
                    let _ = print("⚠️ DEBUG: googleLogo image NOT found - using fallback SVG logo")
                    let _ = print("🖼️ DEBUG: Fallback Google G - frame: 20x20, colors: official Google palette")
                    
                    // Fallback: Improved Google G logo with official colors
                    ZStack {
                        // Google G with official colors
                        Circle()
                            .stroke(Color.clear, lineWidth: 0)
                            .frame(width: 20, height: 20)
                            .overlay(
                                ZStack {
                                    // Blue quarter (top right)
                                    Circle()
                                        .trim(from: 0.625, to: 0.875)
                                        .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 2.5)
                                        .rotationEffect(.degrees(0))
                                    
                                    // Red quarter (top left)  
                                    Circle()
                                        .trim(from: 0.875, to: 1.125)
                                        .stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: 2.5)
                                        .rotationEffect(.degrees(0))
                                    
                                    // Yellow quarter (bottom left)
                                    Circle()
                                        .trim(from: 0.125, to: 0.375)
                                        .stroke(Color(red: 1.0, green: 0.73, blue: 0.0), lineWidth: 2.5)
                                        .rotationEffect(.degrees(0))
                                    
                                    // Green quarter (bottom right with gap)
                                    Circle()
                                        .trim(from: 0.375, to: 0.6)
                                        .stroke(Color(red: 0.0, green: 0.66, blue: 0.31), lineWidth: 2.5)
                                        .rotationEffect(.degrees(0))
                                    
                                    // Blue horizontal line
                                    Rectangle()
                                        .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                                        .frame(width: 6, height: 2.5)
                                        .offset(x: 4, y: 0)
                                }
                            )
                    }
                }
                
                Spacer()
                
                Text("Sign in with Google")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
        }
        .scaleEffect(1.05) // Match Apple button scale effect
        .onAppear {
            print("🔵 DEBUG: Google button appeared - Background: white, Border: black 0.2 opacity, Padding: 16px horizontal")
            print("🔵 DEBUG: Google button text - Font: 18pt semibold, Color: black, Alignment: center")
            print("🔵 DEBUG: Google button layout - HStack spacing: 0, Logo→Spacer→Text→Spacer")
            print("🔵 DEBUG: Google button border - RoundedRectangle(cornerRadius: 12), stroke width: 1px")
        }
    }
}

// Custom Google G Logo recreated with SwiftUI
struct GoogleGLogo: View {
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
            
            // Google G segments
            ZStack {
                // Blue segment (top right)
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color.blue, lineWidth: 3)
                    .rotationEffect(.degrees(-45))
                
                // Red segment (top left)
                Circle()
                    .trim(from: 0.25, to: 0.5)
                    .stroke(Color.red, lineWidth: 3)
                    .rotationEffect(.degrees(-45))
                
                // Yellow segment (bottom left)
                Circle()
                    .trim(from: 0.5, to: 0.75)
                    .stroke(Color.yellow, lineWidth: 3)
                    .rotationEffect(.degrees(-45))
                
                // Green segment (bottom right with gap)
                Circle()
                    .trim(from: 0.75, to: 0.95)
                    .stroke(Color.green, lineWidth: 3)
                    .rotationEffect(.degrees(-45))
                
                // Inner blue horizontal line
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 2)
                    .offset(x: 3, y: 0)
            }
            .frame(width: 14, height: 14)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GoogleSignInButtonWrapper {
            print("Google Sign-In tapped")
        }
        
        // For comparison with Google button styling
        AppleSignInButtonWrapper {
            print("Apple Sign-In tapped")
        }
    }
    .padding()
    .background(Color.black)
}
