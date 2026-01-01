//
//  NotificationManager.swift
//  ConvAI
//
//  Created by Implementation on 30/08/2025.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            self.isAuthorized = granted
            
            if granted {
                print("✅ Notification permissions granted")
                await registerForRemoteNotifications()
            } else {
                print("❌ Notification permissions denied")
            }
            
            return granted
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
            self.isAuthorized = false
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Trial Notifications
    func scheduleTrialReminders(trialEndDate: Date) {
        guard isAuthorized else {
            print("⚠️ Cannot schedule notifications - permission not granted")
            return
        }
        
        // Clear any existing trial reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "trial_reminder_24h",
            "trial_reminder_2h"
        ])
        
        let calendar = Calendar.current
        let now = Date()
        
        // 24 hours before trial ends
        if let reminderDate24h = calendar.date(byAdding: .hour, value: -24, to: trialEndDate),
           reminderDate24h > now {
            scheduleNotification(
                identifier: "trial_reminder_24h",
                title: "ConvAI Trial Ending Soon",
                body: "Your free trial ends tomorrow. Continue your conversation coaching journey!",
                date: reminderDate24h
            )
        }
        
        // 2 hours before trial ends
        if let reminderDate2h = calendar.date(byAdding: .hour, value: -2, to: trialEndDate),
           reminderDate2h > now {
            scheduleNotification(
                identifier: "trial_reminder_2h",
                title: "ConvAI Trial Ending in 2 Hours",
                body: "Don't lose access to premium features. Subscribe now to continue your progress.",
                date: reminderDate2h
            )
        }
        
        print("✅ Scheduled trial reminder notifications")
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add action buttons
        content.categoryIdentifier = "TRIAL_REMINDER"
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(identifier): \(error)")
            } else {
                print("✅ Scheduled notification: \(identifier) for \(date)")
            }
        }
    }
    
    // MARK: - Engagement Notifications
    func scheduleEngagementReminders() {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule daily practice reminders (if not already practicing)
        for dayOffset in 1...7 {
            if let reminderDate = calendar.date(byAdding: .day, value: dayOffset, to: now) {
                let hour = 19 // 7 PM
                if let practiceTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: reminderDate) {
                    scheduleNotification(
                        identifier: "daily_practice_\(dayOffset)",
                        title: "Time for Conversation Practice",
                        body: "Practice makes perfect! Continue your conversation skills with ConvAI.",
                        date: practiceTime
                    )
                }
            }
        }
    }
    
    // MARK: - Notification Categories
    func setupNotificationCategories() {
        let subscribeAction = UNNotificationAction(
            identifier: "SUBSCRIBE_ACTION",
            title: "Subscribe Now",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )
        
        let trialCategory = UNNotificationCategory(
            identifier: "TRIAL_REMINDER",
            actions: [subscribeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([trialCategory])
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Clean Up
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }
    
    func clearTrialNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "trial_reminder_24h",
            "trial_reminder_2h"
        ])
    }
}
