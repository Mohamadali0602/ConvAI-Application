//
//  StreakWarningView.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import SwiftUI

// 🚨 Loss Aversion Warning View - Creates FOMO about losing streaks
struct StreakWarningView: View {
    @ObservedObject private var progressService = GameProgressManager.shared
    @State private var warnings: [AccessWarning] = []
    @State private var showWarning = false
    @State private var pulseAnimation = false
    
    var body: some View {
        if !warnings.isEmpty && showWarning {
            VStack(spacing: 0) {
                ForEach(warnings.indices, id: \.self) { index in
                    let warning = warnings[index]
                    warningCard(warning: warning)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showWarning)
            .onAppear {
                loadWarnings()
                startPulseAnimation()
            }
        }
    }
    
    private func warningCard(warning: AccessWarning) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with urgency indicator
            HStack {
                Image(systemName: warningIcon(for: warning.type))
                    .font(.title2.bold())
                    .foregroundColor(warningColor(for: warning.type))
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(warningTitle(for: warning.type))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text("\(warning.timeRemaining) hours left")
                        .font(.caption.bold())
                        .foregroundColor(warningColor(for: warning.type))
                        .tracking(1)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: { dismissWarning() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Warning message
            Text(warning.message)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            // Action button
            actionButton(for: warning.type)
        }
        .padding(16)
        .background(warningBackground(for: warning.type))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(warningColor(for: warning.type), lineWidth: 2)
        )
        .shadow(color: warningColor(for: warning.type).opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func actionButton(for type: AccessWarning.WarningType) -> some View {
        Button(action: { handleAction(for: type) }) {
            HStack {
                Image(systemName: actionIcon(for: type))
                    .font(.headline.bold())
                
                Text(actionText(for: type))
                    .font(.headline.bold())
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helper Methods
    private func warningIcon(for type: AccessWarning.WarningType) -> String {
        switch type {
        case .streakRisk: return "flame.fill"
        case .challengeExpiration: return "clock.fill"
        }
    }
    
    private func warningColor(for type: AccessWarning.WarningType) -> Color {
        switch type {
        case .streakRisk: return .red
        case .challengeExpiration: return .orange
        }
    }
    
    private func warningTitle(for type: AccessWarning.WarningType) -> String {
        switch type {
        case .streakRisk: return "STREAK AT RISK"
        case .challengeExpiration: return "CHALLENGE EXPIRES SOON"
        }
    }
    
    private func warningBackground(for type: AccessWarning.WarningType) -> some View {
        LinearGradient(
            colors: [
                warningColor(for: type).opacity(0.2),
                Color.black.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func actionIcon(for type: AccessWarning.WarningType) -> String {
        switch type {
        case .streakRisk: return "play.circle.fill"
        case .challengeExpiration: return "star.circle.fill"
        }
    }
    
    private func actionText(for type: AccessWarning.WarningType) -> String {
        switch type {
        case .streakRisk: return "Practice Now & Save Streak"
        case .challengeExpiration: return "Start Challenge Now"
        }
    }
    
    private func handleAction(for type: AccessWarning.WarningType) {
        switch type {
        case .streakRisk:
            // Navigate to practice to save streak
            NotificationCenter.default.post(name: .saveStreak, object: nil)
        case .challengeExpiration:
            // Navigate to daily challenge
            NotificationCenter.default.post(name: .startDailyChallenge, object: nil)
        }
        
        dismissWarning()
    }
    
    private func loadWarnings() {
        warnings = progressService.getAccessWarnings()
        showWarning = !warnings.isEmpty
    }
    
    private func dismissWarning() {
        showWarning = false
        
        // Hide for 24 hours
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_warning_dismissed")
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let saveStreak = Notification.Name("saveStreak")
}

// MARK: - Preview
#Preview {
    VStack {
        StreakWarningView()
            .padding()
        
        Spacer()
    }
    .background(Color.black)
}
