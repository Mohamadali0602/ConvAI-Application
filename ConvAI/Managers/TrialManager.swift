//
//  TrialManager.swift
//  ConvAI
//
//  Created by Implementation on 30/08/2025.
//

import Foundation
import Combine
import UserNotifications

@MainActor
class TrialManager: ObservableObject {
    @Published var isInTrial = false
    @Published var trialEndDate: Date?
    @Published var daysRemaining = 0
    @Published var hoursRemaining = 0
    
    private var timer: Timer?
    private let notificationManager = NotificationManager.shared
    
    init() {
        Task {
            await notificationManager.requestPermission()
            notificationManager.setupNotificationCategories()
        }
        startTrialMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Trial Monitoring
    private func startTrialMonitoring() {
        // Update trial status every hour
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await self.updateTrialStatus()
            }
        }
        
        // Initial update
        Task {
            await updateTrialStatus()
        }
    }
    
    func updateTrialStatus() async {
        if let endDate = trialEndDate {
            let now = Date()
            let timeInterval = endDate.timeIntervalSince(now)
            
            if timeInterval > 0 {
                isInTrial = true
                daysRemaining = Int(timeInterval / 86400) // seconds in a day
                hoursRemaining = Int((timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
            } else {
                isInTrial = false
                daysRemaining = 0
                hoursRemaining = 0
            }
        }
    }
    
    func startTrial() {
        let startDate = Date()
        trialEndDate = Calendar.current.date(byAdding: .day, value: 3, to: startDate)
        
        Task {
            await updateTrialStatus()
            if let endDate = trialEndDate {
                notificationManager.scheduleTrialReminders(trialEndDate: endDate)
            }
        }
    }
    
    func endTrial() {
        isInTrial = false
        trialEndDate = nil
        daysRemaining = 0
        hoursRemaining = 0
        
        // Clear trial notifications
        notificationManager.clearTrialNotifications()
    }
    
    // MARK: - Utility Methods
    func getFormattedTimeRemaining() -> String {
        if daysRemaining > 0 {
            return "\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining"
        } else if hoursRemaining > 0 {
            return "\(hoursRemaining) hour\(hoursRemaining == 1 ? "" : "s") remaining"
        } else {
            return "Trial ended"
        }
    }
    
    func getTrialProgress() -> Double {
        guard let trialEndDate = trialEndDate else { return 0.0 }
        
        let totalTrialDuration: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
        let elapsed = Date().timeIntervalSince(trialEndDate.addingTimeInterval(-totalTrialDuration))
        
        return min(1.0, max(0.0, elapsed / totalTrialDuration))
    }
}
