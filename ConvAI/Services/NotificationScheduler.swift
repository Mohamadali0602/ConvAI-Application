//
//  NotificationScheduler.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import Foundation
import UserNotifications
import SwiftUI

// 🔔 Loss Aversion Notification Scheduler
@MainActor
class NotificationScheduler: ObservableObject {
    static let shared = NotificationScheduler()
    
    private var userProgressService: GameProgressManager {
        GameProgressManager.shared
    }
    private var notificationCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Permission Request
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                DispatchQueue.main.async {
                    self.scheduleAllNotifications()
                }
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Main Scheduling Function
    func scheduleAllNotifications() {
        print("📱 NotificationScheduler: Scheduling all notifications...")
        
        // Clear existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule daily addiction loop notifications
        scheduleAddictionLoopNotifications()
        
        // TODO: Re-enable after Phase 3 completion
        // Schedule streak risk notifications
        scheduleStreakRiskNotifications()
        
        // Schedule daily challenge notifications
        scheduleDailyChallengeNotifications()
        
        // Schedule weekend warrior notifications
        scheduleWeekendNotifications()
    }
    
    // MARK: - Addiction Loop Notifications (FOMO)
    private func scheduleAddictionLoopNotifications() {
        let notifications = [
            // Morning FOMO - exactly as specified in plan
            (
                hour: 8, minute: 30,
                title: "Your competition already practiced today",
                body: "Don't fall behind. 2-minute practice = confidence boost all day"
            ),
            // Lunch productivity - exactly as specified in plan
            (
                hour: 12, minute: 15,
                title: "Quick 2-min confidence booster?",
                body: "Perfect time for a power practice session"
            ),
            // Evening preparation - exactly as specified in plan
            (
                hour: 18, minute: 45,
                title: "Tomorrow's challenge is ready",
                body: "Preview tomorrow's challenge and get ahead"
            ),
            // Late night FOMO - exactly as specified in plan
            (
                hour: 22, minute: 30,
                title: "Can't sleep? Perfect time to practice",
                body: "Night owls have 23% higher success rates"
            )
        ]
        
        for (index, notification) in notifications.enumerated() {
            scheduleRepeatingNotification(
                identifier: "addiction_loop_\(index)",
                title: notification.title,
                body: notification.body,
                hour: notification.hour,
                minute: notification.minute
            )
        }
    }
    
    // MARK: - Streak Risk Notifications (Loss Aversion)
    private func scheduleStreakRiskNotifications() {
        // Check if user has a significant streak at risk
        let currentStreak = userProgressService.currentStreak
        
        if currentStreak >= 3 {
            // 16 hours after last practice
            scheduleStreakWarning(
                hours: 16,
                title: "🔥 \(currentStreak)-day streak at risk!",
                body: "Don't lose your momentum. Practice for 2 minutes to save it."
            )
            
            // 20 hours after last practice (critical)
            scheduleStreakWarning(
                hours: 20,
                title: "🚨 CRITICAL: About to lose your streak!",
                body: "Your \(currentStreak)-day streak ends in 4 hours. Act now!"
            )
        }
        
        if currentStreak >= 7 {
            // Elite features at risk
            scheduleStreakWarning(
                hours: 18,
                title: "⚠️ Elite features at risk!",
                body: "Your Elite Coach access expires if you don't practice today"
            )
        }
    }
    
    // MARK: - Daily Challenge Notifications (FOMO)
    private func scheduleDailyChallengeNotifications() {
        // Morning challenge available
        scheduleRepeatingNotification(
            identifier: "daily_challenge_morning",
            title: "🎯 New daily challenge unlocked!",
            body: "Today's challenge: High XP reward expires at midnight",
            hour: 9,
            minute: 0
        )
        
        // Afternoon reminder
        scheduleRepeatingNotification(
            identifier: "daily_challenge_afternoon",
            title: "⏰ Daily challenge expires in 6 hours",
            body: "Don't miss today's bonus XP! Complete now",
            hour: 18,
            minute: 0
        )
        
        // Final warning
        scheduleRepeatingNotification(
            identifier: "daily_challenge_final",
            title: "🚨 Last chance! Challenge expires in 1 hour",
            body: "Miss this and lose today's bonus XP forever",
            hour: 23,
            minute: 0
        )
    }
    
    // MARK: - Weekend Warrior Notifications
    private func scheduleWeekendNotifications() {
        // Saturday motivation
        scheduleWeeklyNotification(
            identifier: "weekend_saturday",
            title: "🏆 Weekend warriors get 2X XP!",
            body: "Practice today and tomorrow for double rewards",
            weekday: 7, // Saturday
            hour: 10,
            minute: 0
        )
        
        // Sunday final push
        scheduleWeeklyNotification(
            identifier: "weekend_sunday",
            title: "📈 Sunday success multiplier active",
            body: "End your week strong. Elite members practice on Sundays",
            weekday: 1, // Sunday
            hour: 16,
            minute: 0
        )
    }
    
    // MARK: - Immediate Streak Warning
    func scheduleImmediateStreakWarning() {
        let streak = userProgressService.currentStreak
        guard streak >= 3 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💔 Your \(streak)-day streak is about to break!"
        content.body = "Practice now or lose all your progress and Elite features"
        content.sound = .defaultCritical
        content.categoryIdentifier = "STREAK_CRITICAL"
        
        // Trigger in 1 hour
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_streak_warning",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule immediate streak warning: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func scheduleRepeatingNotification(
        identifier: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(identifier): \(error)")
            }
        }
    }
    
    private func scheduleWeeklyNotification(
        identifier: String,
        title: String,
        body: String,
        weekday: Int,
        hour: Int,
        minute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule weekly notification \(identifier): \(error)")
            }
        }
    }
    
    private func scheduleStreakWarning(hours: Int, title: String, body: String) {
        guard let lastPractice = userProgressService.lastPracticeDate else { return }
        
        let warningTime = lastPractice.addingTimeInterval(TimeInterval(hours * 3600))
        let now = Date()
        
        // Only schedule if warning time is in the future
        guard warningTime > now else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = hours >= 20 ? .defaultCritical : .default
        content.categoryIdentifier = "STREAK_WARNING"
        
        let timeInterval = warningTime.timeIntervalSince(now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "streak_warning_\(hours)h",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule streak warning: \(error)")
            }
        }
    }
    
    // MARK: - Public Interface
    func onPracticeCompleted() {
        // Reschedule streak warnings based on new practice time
        scheduleStreakRiskNotifications()
    }
    
    func onStreakBroken() {
        // Cancel streak warnings since streak is broken
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "streak_warning_16h",
            "streak_warning_20h"
        ])
    }
    
    func enableCriticalMode() {
        // User is at high risk of churning - increase notification frequency
        scheduleImmediateStreakWarning()
    }
}

// MARK: - Notification Categories
extension NotificationScheduler {
    func setupNotificationCategories() {
        // Streak warning actions
        let practiceAction = UNNotificationAction(
            identifier: "PRACTICE_NOW",
            title: "Practice Now",
            options: [.foreground]
        )
        
        let remindAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 hour",
            options: []
        )
        
        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_WARNING",
            actions: [practiceAction, remindAction],
            intentIdentifiers: [],
            options: []
        )
        
        let criticalCategory = UNNotificationCategory(
            identifier: "STREAK_CRITICAL",
            actions: [practiceAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([streakCategory, criticalCategory])
    }
}
