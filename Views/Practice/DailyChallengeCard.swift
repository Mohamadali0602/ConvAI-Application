//
//  DailyChallengeCard.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import SwiftUI

// 🎯 FOMO-driven Daily Challenge Card with Loss Aversion
struct DailyChallengeCard: View {
    @ObservedObject private var progressService = GameProgressManager.shared
    @State private var todaysChallenge: DailyChallenge?
    @State private var timeRemaining: String = ""
    @State private var isCompleted: Bool = false
    @State private var showShareSheet = false
    @State private var pulseAnimation = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if let challenge = todaysChallenge {
            VStack(spacing: 0) {
                // Header with urgency
                headerSection(challenge: challenge)
                
                // Main content
                contentSection(challenge: challenge)
                
                // Action buttons
                actionSection(challenge: challenge)
            }
            .background(challengeBackground)
            .cornerRadius(20)
            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
            .onAppear {
                checkCompletion()
                startPulseAnimation()
            }
            .onReceive(timer) { _ in
                updateTimeRemaining()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [challenge.shareText])
            }
        } else {
            // No challenge available - already completed
            completedChallengeView
        }
    }
    
    // MARK: - Header Section with Countdown
    private func headerSection(challenge: DailyChallenge) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.yellow)
                        .font(.caption.bold())
                    
                    Text("DAILY CHALLENGE")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .tracking(1)
                }
                
                // 🚨 FOMO: Countdown timer
                Text("Expires in \(timeRemaining)")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // XP Reward with multiplier hint
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(challenge.xpReward) XP")
                    .font(.headline.bold())
                    .foregroundColor(.yellow)
                
                if progressService.currentStreak > 0 {
                    Text("+\(Int(Double(challenge.xpReward) * 0.1 * Double(progressService.currentStreak))) streak bonus")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Content Section
    private func contentSection(challenge: DailyChallenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundColor(categoryColor(challenge.category))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text(challenge.category.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(categoryColor(challenge.category))
                        .tracking(1)
                }
                
                Spacer()
            }
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
            
            // 🔥 LOSS AVERSION: Show what they'll miss
            if !isCompleted {
                lossAversionWarning(challenge: challenge)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loss Aversion Warning
    private func lossAversionWarning(challenge: DailyChallenge) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text("Miss this challenge and lose today's bonus XP forever!")
                .font(.caption.bold())
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Action Section
    private func actionSection(challenge: DailyChallenge) -> some View {
        HStack(spacing: 12) {
            // Primary action button
            Button(action: { startChallenge(challenge) }) {
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "play.circle.fill")
                        .font(.headline)
                    
                    Text(isCompleted ? "Completed" : "Start Challenge")
                        .font(.headline.bold())
                }
                .foregroundColor(isCompleted ? .green : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isCompleted ? Color.green.opacity(0.2) : Color.yellow)
                .cornerRadius(12)
            }
            .disabled(isCompleted)
            .buttonStyle(ScaleButtonStyle())
            
            // Share button (always available for viral growth)
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Completed Challenge View
    private var completedChallengeView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text("Daily Challenge Complete!")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text("Come back tomorrow for a new challenge")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // Tomorrow's preview
            Text("Tomorrow: Master the Perfect Pitch")
                .font(.caption)
                .foregroundColor(.yellow)
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
    
    // MARK: - Background Gradient
    private var challengeBackground: some View {
        LinearGradient(
            colors: [
                Color.orange.opacity(0.4),
                Color.red.opacity(0.4),
                Color.purple.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Animated sparkle effect
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -50...50))
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.5),
                            value: pulseAnimation
                        )
                }
            }
        )
    }
    
    // MARK: - Helper Methods
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Money": return .green
        case "Love": return .pink
        case "Power": return .yellow
        default: return .blue
        }
    }
    
    private func startChallenge(_ challenge: DailyChallenge) {
        // Trigger haptic feedback
        HapticFeedbackManager.shared.challengeStarted()
        
        // Navigate to practice with specific challenge context
        NotificationCenter.default.post(
            name: .startDailyChallenge,
            object: ["challenge": challenge]
        )
        
        print("🎯 Daily challenge started with haptic feedback: \(challenge.title)")
    }
    
    private func checkCompletion() {
        todaysChallenge = progressService.getTodaysChallenge()
        isCompleted = todaysChallenge == nil
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate time until end of day
        if let endOfDay = calendar.dateInterval(of: .day, for: now)?.end {
            let timeInterval = endOfDay.timeIntervalSince(now)
            
            if timeInterval > 0 {
                let hours = Int(timeInterval) / 3600
                let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
                
                if hours > 0 {
                    timeRemaining = "\(hours)h \(minutes)m"
                } else {
                    timeRemaining = "\(minutes)m"
                    
                    // Add urgent haptic when challenge is about to expire
                    if minutes <= 5 && !isCompleted {
                        HapticFeedbackManager.shared.challengeExpiring()
                    }
                }
            } else {
                timeRemaining = "Expired"
                // Reset for tomorrow
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    checkCompletion()
                }
            }
        }
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// ScaleButtonStyle is already defined in SharedButtonStyles.swift

// MARK: - Notification Extension
extension Notification.Name {
    static let startDailyChallenge = Notification.Name("startDailyChallenge")
}

// MARK: - Preview
#Preview {
    VStack {
        DailyChallengeCard()
            .padding()
        
        Spacer()
    }
    .background(Color.black)
}
