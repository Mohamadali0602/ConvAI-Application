//

//  NotificationScheduler.swift
//  ConvAI
//
//  Simplified notification scheduler for Phase 3 implementation
//

import Foundation
import UserNotifications

// 🔔 Simplified Notification Scheduler 
class NotificationScheduler: ObservableObject {
    static let shared = NotificationScheduler()
    
    private var notificationCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Permission Request
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleAllNotifications()
                } else {
                    print("❌ Notification permission denied")
                }
                
                if let error = error {
                    print("❌ Notification permission error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Main Scheduling Function
    func scheduleAllNotifications() {
        print("📱 NotificationScheduler: Scheduling basic notifications...")
        
        // Clear existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule basic daily reminder
        scheduleDailyPracticeReminder()
    }
    
    // MARK: - Basic Daily Reminder
    private func scheduleDailyPracticeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Ready to practice?"
        content.body = "Build your conversation skills with a quick session"
        content.sound = .default
        content.badge = 1
        
        // Schedule for 7 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_practice_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily reminder: \(error)")
            } else {
                print("✅ Daily practice reminder scheduled for 7 PM")
            }
        }
    }
    
    // MARK: - Public Interface
    func scheduleImmediateStreakWarning() {
        // Placeholder for streak warning functionality
        print("📱 Streak warning functionality will be implemented after Phase 3")
    }
    
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ All notifications cleared")
    }
}
