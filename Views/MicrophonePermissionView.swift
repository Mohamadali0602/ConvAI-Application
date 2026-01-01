//
//  MicrophonePermissionView.swift
//  ConvAI
//
//  Created on 04/08/2025.
//

import SwiftUI
import AVFoundation

struct MicrophonePermissionView: View {
    @StateObject private var permissionService = MicrophonePermissionService.shared
    @State private var showingPermissionRequest = false
    @State private var isRequestingPermission = false
    
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [darkBackground, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Microphone Icon with Animation
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(primaryColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .stroke(primaryColor, lineWidth: 3)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isRequestingPermission ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRequestingPermission)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(primaryColor)
                    }
                }
                
                // Title and Description
                VStack(spacing: 16) {
                    Text("Microphone Access Needed")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("ConvAI needs access to your microphone to have voice conversations with AI coaches. Your audio is processed securely and never stored.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .lineSpacing(4)
                }
                
                // Permission Status
                permissionStatusView
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if permissionService.isMicrophonePermissionDenied {
                        // Settings Button for Denied State
                        Button(action: {
                            permissionService.openAppSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [primaryColor, secondaryColor], startPoint: .leading, endPoint: .trailing))
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        // Refresh Button
                        Button(action: {
                            permissionService.updatePermissionStatus()
                            checkPermissionAndProceed()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Check Again")
                            }
                            .font(.headline)
                            .foregroundColor(primaryColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(primaryColor, lineWidth: 2)
                                    .background(Color.clear)
                            )
                        }
                        .padding(.horizontal, 40)
                        
                    } else {
                        // Request Permission Button
                        Button(action: {
                            requestMicrophonePermission()
                        }) {
                            HStack {
                                if isRequestingPermission {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "mic")
                                }
                                Text(isRequestingPermission ? "Requesting..." : "Allow Microphone Access")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [primaryColor, secondaryColor], startPoint: .leading, endPoint: .trailing))
                            )
                        }
                        .disabled(isRequestingPermission)
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            permissionService.updatePermissionStatus()
            checkPermissionAndProceed()
        }
        .onChange(of: permissionService.permissionStatus) { status in
            #if os(iOS)
            if status == .granted {
                onPermissionGranted()
            }
            #endif
        }
        .alert("Microphone Access Denied", isPresented: $permissionService.showPermissionDeniedAlert) {
            Button("Open Settings") {
                permissionService.openAppSettings()
            }
            Button("Not Now", role: .cancel) {
                onPermissionDenied()
            }
        } message: {
            Text("To use voice conversations, please enable microphone access in Settings > Privacy & Security > Microphone > ConvAI.")
        }
    }
    
    // MARK: - Permission Status View
    private var permissionStatusView: some View {
        Group {
            #if os(iOS)
            switch permissionService.permissionStatus {
            case .granted:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Microphone access granted")
                        .foregroundColor(.green)
                }
                .font(.headline)
                
            case .denied:
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Microphone access denied")
                        .foregroundColor(.red)
                }
                .font(.headline)
                
            case .undetermined:
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Permission not requested")
                        .foregroundColor(.orange)
                }
                .font(.headline)
                
            @unknown default:
                EmptyView()
            }
            #else
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Microphone access available")
                    .foregroundColor(.green)
            }
            .font(.headline)
            #endif
        }
    }
    
    // MARK: - Permission Request
    private func requestMicrophonePermission() {
        isRequestingPermission = true
        
        Task {
            let granted = await permissionService.requestMicrophonePermission()
            
            DispatchQueue.main.async {
                isRequestingPermission = false
                
                if granted {
                    onPermissionGranted()
                } else {
                    onPermissionDenied()
                }
            }
        }
    }
    
    private func checkPermissionAndProceed() {
        if permissionService.isMicrophonePermissionGranted {
            onPermissionGranted()
        }
    }
}

// MARK: - Preview
struct MicrophonePermissionView_Previews: PreviewProvider {
    static var previews: some View {
        MicrophonePermissionView(
            onPermissionGranted: {
                print("Permission granted")
            },
            onPermissionDenied: {
                print("Permission denied")
            }
        )
    }
}
