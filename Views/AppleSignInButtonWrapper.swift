//
//  AppleSignInButtonWrapper.swift
//  ConvAI
//
//  Created by GitHub Copilot on 03/08/2025.
//

import SwiftUI
import UIKit

struct AppleSignInButtonWrapper: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("🍎 DEBUG: Apple Sign-In button TAPPED")
            print("🍎 DEBUG: Button frame - height: 60, maxWidth: infinity")
            print("🍎 DEBUG: Button corner radius: 12")
            print("🍎 DEBUG: Button scale effect: 1.05")
            print("🍎 DEBUG: About to call Apple Sign-In action...")
            action()
            print("🍎 DEBUG: Apple Sign-In action completed")
        }) {
            HStack(spacing: 0) {
                // Apple logo - positioned exactly like Google's logo
                if let appleLogo = loadImageFromBundle(named: "AppleLogo") {
                    // DEBUG: Image found successfully
                    let _ = print("🖼️ DEBUG: AppleLogo image found successfully - size: \(appleLogo.size)")
                    let _ = print("🖼️ DEBUG: AppleLogo frame - width: 20, height: 20, aspect: fit")
                    let _ = print("🖼️ DEBUG: AppleLogo color inverted: true")
                    Image(uiImage: appleLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .colorInvert() // Inverse the Apple logo color to make it black on white
                } else {
                    // DEBUG: Image not found, using fallback
                    let _ = print("⚠️ DEBUG: AppleLogo image NOT found - using SF Symbol fallback")
                    let _ = print("🖼️ DEBUG: SF Symbol frame - width: 20, height: 20, font: 18pt medium")
                    
                    // Fallback: Apple SF Symbol
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 20, height: 20)
                }
                
                Spacer()
                
                Text("Sign in with Apple")
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
        .scaleEffect(1.05) // Match Google button scale effect
        .onAppear {
            print("🍎 DEBUG: Apple button appeared - Background: white, Border: black 0.2 opacity, Padding: 16px horizontal")
            print("🍎 DEBUG: Apple button text - Font: 18pt semibold, Color: black, Alignment: center")
            print("🍎 DEBUG: Apple button layout - HStack spacing: 0, Logo→Spacer→Text→Spacer")
            print("🍎 DEBUG: Apple button border - RoundedRectangle(cornerRadius: 12), stroke width: 1px")
        }
    }
}

// Helper function to load images from bundle
private func loadImageFromBundle(named imageName: String) -> UIImage? {
    // Try different common image extensions
    let extensions = ["png", "jpg", "jpeg"]
    
    for ext in extensions {
        if let path = Bundle.main.path(forResource: imageName, ofType: ext) {
            print("🖼️ DEBUG: Found image at path: \(path)")
            return UIImage(contentsOfFile: path)
        }
    }
    
    // Also try without extension (in case it's already included)
    if let path = Bundle.main.path(forResource: imageName, ofType: nil) {
        print("🖼️ DEBUG: Found image at path: \(path)")
        return UIImage(contentsOfFile: path)
    }
    
    print("⚠️ DEBUG: Could not find image named '\(imageName)' in bundle")
    return nil
}

#Preview {
    VStack(spacing: 20) {
        AppleSignInButtonWrapper {
            print("Apple Sign-In tapped")
        }
        
        GoogleSignInButtonWrapper {
            print("Google Sign-In tapped")
        }
    }
    .padding()
    .background(Color.black)
}
