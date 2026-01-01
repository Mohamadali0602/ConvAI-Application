//
//  HabitFormationView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import SwiftUI
import UserNotifications

struct HabitFormationView: View {
    @State private var hasRequestedNotifications = false
    @State private var showingNotificationPermissionAlert = false
    let onContinue: () -> Void
    let onEnableNotifications: () -> Void
    let onSkip: () -> Void
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
                Spacer()
                
                // Main content
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.17))
                    
                    // Title
                                    Text(localizationManager.getString("habit_subtitle"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    
                    // Description
                    Text(localizationManager.getString("habit_description") ?? "Daily practice is the fastest way to fluency. Let us remind you to keep your streak alive!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Tap anywhere instruction
                Text(localizationManager.getString("tap_anywhere") ?? "Tap anywhere to continue")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .onTapGesture {
            requestNotificationPermission()
        }
        .alert("Notification Permission", isPresented: $showingNotificationPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
                onContinue()
            }
            Button("Continue anyway") {
                onContinue()
            }
        } message: {
            Text("Enable notifications in Settings to get daily practice reminders. Go to Settings > ConvAI > Notifications and enable them.")
        }
    }
    
    private func requestNotificationPermission() {
        // Check current notification permission status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // First time - show system permission dialog
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        DispatchQueue.main.async {
                            if !granted {
                                // User denied permission, show alert to go to settings
                                showingNotificationPermissionAlert = true
                            } else {
                                onContinue()
                            }
                        }
                    }
                case .denied:
                    // Permission was denied, show alert to go to settings
                    showingNotificationPermissionAlert = true
                case .authorized, .provisional, .ephemeral:
                    // Permission already granted
                    onContinue()
                @unknown default:
                    // Unknown status, continue anyway
                    onContinue()
                }
            }
        }
    }
}

#Preview {
    HabitFormationView(
        onContinue: {
            print("Continue tapped")
        },
        onEnableNotifications: {
            print("Enable notifications tapped")
        },
        onSkip: {
            print("Skip tapped")
        }
    )
}
