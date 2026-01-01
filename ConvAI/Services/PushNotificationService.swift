//
//  PushNotificationService.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import Foundation
import UserNotifications
import UIKit

class PushNotificationService: NSObject, ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func requestPermission() {
        isLoading = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                
                self?.checkAuthorizationStatus()
                
                if granted {
                    self?.scheduleHabitFormationNotifications()
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func scheduleHabitFormationNotifications() {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule daily habit reminders
        let habitReminders = [
            HabitNotification(
                id: "daily_practice",
                title: "Time for your daily practice! 🗣️",
                body: "Just 5 minutes can improve your conversation skills.",
                hour: 19, // 7 PM
                minute: 0,
                weekday: nil // Daily notification
            ),
            HabitNotification(
                id: "weekly_review",
                title: "Weekly Progress Review 📊",
                body: "See how your conversation skills have improved this week!",
                hour: 10, // 10 AM
                minute: 0,
                weekday: 1 // Sunday
            ),
            HabitNotification(
                id: "streak_motivation",
                title: "Keep your streak alive! 🔥",
                body: "You're doing great! Don't break your learning streak.",
                hour: 20, // 8 PM
                minute: 0,
                weekday: nil // Daily notification
            )
        ]
        
        for notification in habitReminders {
            scheduleNotification(notification)
        }
    }
    
    private func scheduleNotification(_ notification: HabitNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = notification.hour
        dateComponents.minute = notification.minute
        
        if let weekday = notification.weekday {
            dateComponents.weekday = weekday
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleCustomReminder(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

struct HabitNotification {
    let id: String
    let title: String
    let body: String
    let hour: Int
    let minute: Int
    let weekday: Int? // Optional, for weekly notifications
}
