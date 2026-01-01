//
//  HapticFeedbackManager.swift
//  ConvAI
//
//  Created by Assistant on 09/08/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Centralized haptic feedback manager for enhanced user experience
class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private init() {}
    
    // MARK: - Notification Haptics
    
    /// Standard notification received haptic
    func notificationReceived() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        print("🔄 Haptic: Notification received")
    }
    
    /// Critical notification with double tap for urgency
    func criticalNotification() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
        
        // Double tap for urgency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            feedback.notificationOccurred(.error)
        }
        print("🚨 Haptic: Critical notification")
    }
    
    /// Streak warning with triple pulse pattern for attention
    func streakWarning() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
        
        // Triple pulse for attention
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            feedback.notificationOccurred(.warning)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            feedback.notificationOccurred(.warning)
        }
        print("⚠️ Haptic: Streak warning")
    }
    
    // MARK: - Bonus Reward Haptics
    
    /// Bonus earned with intensity based on amount
    func bonusEarned(amount: Int) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch amount {
        case 0...50:
            style = .light
        case 51...150:
            style = .medium
        default:
            style = .heavy
        }
        
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
        
        // Major bonuses get celebration sequence
        if amount > 150 {
            celebrationSequence()
        }
        print("💰 Haptic: Bonus earned \(amount) XP (\(style))")
    }
    
    /// Perfect bonus celebration sequence
    func perfectBonus() {
        // Celebration sequence for perfect performance
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        
        heavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            medium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            heavy.impactOccurred()
        }
        print("⭐ Haptic: Perfect bonus celebration")
    }
    
    // MARK: - Achievement Haptics
    
    /// Achievement unlocked with celebration sequence
    func achievementUnlocked() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        // Follow with celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.celebrationSequence()
        }
        print("🏆 Haptic: Achievement unlocked")
    }
    
    // MARK: - Daily Challenge Haptics
    
    /// Challenge completed with success confirmation
    func challengeCompleted() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        // Success confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
        print("🎯 Haptic: Challenge completed")
    }
    
    /// Challenge expiring with urgent pulsing pattern
    func challengeExpiring() {
        // Urgent pulsing pattern
        let light = UIImpactFeedbackGenerator(style: .light)
        
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                light.impactOccurred()
            }
        }
        print("⏰ Haptic: Challenge expiring")
    }
    
    /// Challenge started
    func challengeStarted() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        print("🚀 Haptic: Challenge started")
    }
    
    // MARK: - Practice & Conversation Haptics
    
    /// Practice session started
    func practiceStarted() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        print("📚 Haptic: Practice started")
    }
    
    /// Practice session completed
    func practiceCompleted() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        print("✅ Haptic: Practice completed")
    }
    
    /// Level up celebration
    func levelUp() {
        celebrationSequence()
        print("🆙 Haptic: Level up!")
    }
    
    // MARK: - UI Interaction Haptics
    
    /// Button tap feedback
    func buttonTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Card selection feedback
    func cardSelected() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        print("🃏 Haptic: Card selected")
    }
    
    /// Error feedback
    func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
        print("❌ Haptic: Error")
    }
    
    // MARK: - Private Helper Methods
    
    /// Multi-stage celebration sequence
    private func celebrationSequence() {
        let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .medium, .light]
        
        for (index, style) in styles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                let impact = UIImpactFeedbackGenerator(style: style)
                impact.impactOccurred()
            }
        }
        print("🎉 Haptic: Celebration sequence")
    }
}
