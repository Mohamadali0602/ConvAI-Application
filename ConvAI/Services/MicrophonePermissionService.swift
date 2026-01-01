//
//  MicrophonePermissionService.swift
//  ConvAI
//
//  Created on 04/08/2025.
//

import Foundation
import AVFoundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// Service to handle microphone permission requests and status
public class MicrophonePermissionService: ObservableObject {
    #if os(iOS)
    @Published public var permissionStatus: AVAudioSession.RecordPermission = .undetermined
    @Published public var showPermissionDeniedAlert = false
    
    public static let shared = MicrophonePermissionService()
    
    private init() {
        updatePermissionStatus()
    }
    
    /// Update the current permission status
    public func updatePermissionStatus() {
        DispatchQueue.main.async {
            self.permissionStatus = AVAudioSession.sharedInstance().recordPermission
        }
    }
    
    /// Request microphone permission
    public func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionStatus = AVAudioSession.sharedInstance().recordPermission
                    if !granted {
                        self.showPermissionDeniedAlert = true
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    /// Check if microphone permission is granted
    public var isMicrophonePermissionGranted: Bool {
        return permissionStatus == .granted
    }
    
    /// Check if permission was denied
    public var isMicrophonePermissionDenied: Bool {
        return permissionStatus == .denied
    }
    
    /// Open app settings for permission change
    public func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    #else
    // macOS fallback - always granted for development
    @Published public var permissionStatus: Int = 1 // Mock granted state
    @Published public var showPermissionDeniedAlert = false
    
    public static let shared = MicrophonePermissionService()
    
    private init() {}
    
    public func updatePermissionStatus() {}
    
    public func requestMicrophonePermission() async -> Bool {
        return true // Always granted on macOS for development
    }
    
    public var isMicrophonePermissionGranted: Bool { true }
    public var isMicrophonePermissionDenied: Bool { false }
    public func openAppSettings() {}
    #endif
}
