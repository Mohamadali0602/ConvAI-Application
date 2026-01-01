//
//  DataSyncService.swift
//  ConvAI
//
//  Consolidated data synchronization: Cloud + Notifications + Push
//  Production-ready Firebase Firestore sync with notification management
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftData
import SwiftUI
import UserNotifications

// MARK: - Cloud Sync Error Types
enum CloudSyncError: Error, LocalizedError {
    case userNotAuthenticated
    case firestoreError(Error)
    case modelContextUnavailable
    case syncInProgress
    case accountVerificationFailed
    case inactiveAccount
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to sync data"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        case .modelContextUnavailable:
            return "Model context is not available"
        case .syncInProgress:
            return "Synchronization already in progress"
        case .accountVerificationFailed:
            return "Account verification failed"
        case .inactiveAccount:
            return "Account is inactive - access denied"
        }
    }
}

// MARK: - Main Data Sync Service
@MainActor
class DataSyncService: ObservableObject {
    static let shared = DataSyncService()
    
    // MARK: - Cloud Sync Properties
    @Published private(set) var isSignedIn = false
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: String?
    @Published private(set) var currentUser: User?
    
    // MARK: - Notification Properties
    @Published var notificationsEnabled = true
    @Published var lastNotificationScheduled: Date?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var modelContext: ModelContext?
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
        setupNotificationPermissions()
        scheduleAllNotifications()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Authentication State Management
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    private func handleAuthStateChange(user: User?) {
        currentUser = user
        isSignedIn = user != nil
        syncError = nil
        
        if let user = user {
            print("🔑 DataSyncService: User signed in: \(user.uid)")
            Task {
                await performInitialSync()
            }
        } else {
            print("🚪 DataSyncService: User signed out")
            lastSyncDate = nil
        }
    }
    
    // MARK: - Account Verification for Phase 3 Security
    
    private func verifyAccountAccess() async throws {
        guard let user = currentUser else {
            throw CloudSyncError.userNotAuthenticated
        }
        
        // Check if account is active and has proper access
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            if userDoc.exists, let data = userDoc.data() {
                let isActive = data["isActive"] as? Bool ?? false
                let accountStatus = data["accountStatus"] as? String ?? "inactive"
                
                if !isActive || accountStatus == "suspended" {
                    throw CloudSyncError.inactiveAccount
                }
                
                print("✅ DataSyncService: Account verification passed for user \(user.uid)")
            } else {
                // First time user - create user document
                try await createUserDocument(for: user)
            }
        } catch {
            print("❌ DataSyncService: Account verification failed: \(error)")
            throw CloudSyncError.accountVerificationFailed
        }
    }
    
    private func createUserDocument(for user: User) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "isActive": true,
            "accountStatus": "active",
            "createdAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
        print("✅ DataSyncService: Created user document for \(user.uid)")
    }
    
    // MARK: - Cloud Synchronization
    
    func performInitialSync() async {
        await performSync(isInitial: true)
    }
    
    func performSync(isInitial: Bool = false) async {
        guard !isSyncing else {
            print("⚠️ DataSyncService: Sync already in progress")
            return
        }
        
        guard let user = currentUser else {
            syncError = CloudSyncError.userNotAuthenticated.localizedDescription
            return
        }
        
        guard let modelContext = modelContext else {
            syncError = CloudSyncError.modelContextUnavailable.localizedDescription
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Verify account access first (Phase 3 security requirement)
            try await verifyAccountAccess()
            
            // Sync to Firestore
            try await syncToFirestore(user: user, modelContext: modelContext)
            
            // Update sync status
            lastSyncDate = Date()
            print("✅ DataSyncService: Sync completed successfully")
            
        } catch {
            syncError = error.localizedDescription
            print("❌ DataSyncService: Sync failed: \(error)")
        }
        
        isSyncing = false
    }
    
    private func syncToFirestore(user: User, modelContext: ModelContext) async throws {
        // Get user data from SwiftData
        let predicate = #Predicate<UserData> { $0.userId == user.uid }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let userData = try modelContext.fetch(descriptor)
            
            if let userProfile = userData.first {
                // Prepare data for Firestore
                let firestoreData = prepareUserDataForFirestore(userProfile)
                
                // Upload to Firestore with merge to preserve existing data
                try await db.collection("users").document(user.uid).setData(firestoreData, merge: true)
                
                print("✅ DataSyncService: User data synced to Firestore")
            } else {
                print("⚠️ DataSyncService: No user data found in SwiftData for user \(user.uid)")
            }
        } catch {
            throw CloudSyncError.firestoreError(error)
        }
    }
    
    private func prepareUserDataForFirestore(_ userData: UserData) -> [String: Any] {
        return [
            "userId": userData.userId,
            "name": userData.name,
            "preferredLanguage": userData.preferredLanguage,
            "languageLevel": userData.languageLevel,
            "preferredVoice": userData.preferredVoice,
            "isSetup": userData.isSetup,
            "hasCompletedOnboarding": userData.hasCompletedOnboarding,
            "notificationsEnabled": userData.notificationsEnabled,
            "audioQualityPreference": userData.audioQualityPreference,
            "activitySensitivity": userData.activitySensitivity,
            "learningGoals": userData.learningGoals,
            "practiceDays": userData.practiceDays,
            "dailyGoalMinutes": userData.dailyGoalMinutes,
            "totalConversationTime": userData.totalConversationTime,
            "conversationsCompleted": userData.conversationsCompleted,
            "currentStreak": userData.currentStreak,
            "longestStreak": userData.longestStreak,
            "totalXP": userData.totalXP,
            "currentLevel": userData.currentLevel,
            "totalConversations": userData.totalConversations,
            "rejectionScore": userData.rejectionScore,
            "dealsClosedCounter": userData.dealsClosedCounter,
            "confidenceMeter": userData.confidenceMeter,
            "powerMovesUsed": userData.powerMovesUsed,
            "vocabularyMastered": userData.vocabularyMastered,
            "conversationMinutesInTargetLanguage": userData.conversationMinutesInTargetLanguage,
            "accentConfidenceScore": userData.accentConfidenceScore,
            "grammarAccuracy": userData.grammarAccuracy,
            "storiesInRepertoire": userData.storiesInRepertoire,
            "simulationsCompleted": userData.simulationsCompleted,
            "simulationSuccessRate": userData.simulationSuccessRate,
            "moneyMasteryLevel": userData.moneyMasteryLevel,
            "loveCoachLevel": userData.loveCoachLevel,
            "powerPlayerLevel": userData.powerPlayerLevel,
            "languageMasteryLevel": userData.languageMasteryLevel,
            "storyMasteryLevel": userData.storyMasteryLevel,
            "lastPracticeDate": userData.lastPracticeDate?.timeIntervalSince1970 ?? 0,
            "practiceSessionsToday": userData.practiceSessionsToday,
            "lastSyncedAt": FieldValue.serverTimestamp(),
            "dataVersion": userData.dataVersion
        ]
    }
    
    // MARK: - Account Switching Support
    
    func handleAccountSwitch(newUserId: String) async {
        print("🔄 DataSyncService: Handling account switch to \(newUserId)")
        
        // Perform sync for new account
        if isSignedIn {
            await performSync()
        }
        
        // Reschedule notifications for new account
        scheduleAllNotifications()
    }
    
    // MARK: - Manual Sync Controls
    
    func triggerManualSync() async {
        await performSync()
    }
    
    func forceSyncNow() async {
        isSyncing = false // Reset sync state if stuck
        await performSync()
    }
    
    // MARK: - Notification Management
    
    private func setupNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ DataSyncService: Notification permission granted")
                    self?.notificationsEnabled = true
                    self?.scheduleAllNotifications()
                } else if let error = error {
                    print("❌ DataSyncService: Notification permission error: \(error)")
                    self?.notificationsEnabled = false
                }
            }
        }
    }
    
    func scheduleAllNotifications() {
        guard notificationsEnabled else { return }
        
        print("📱 DataSyncService: Scheduling all notifications...")
        
        // Clear existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule addiction loop notifications
        scheduleAddictionLoopNotifications()
        
        // Schedule practice reminders
        schedulePracticeReminders()
        
        // Schedule streak notifications
        scheduleStreakNotifications()
        
        lastNotificationScheduled = Date()
        print("✅ DataSyncService: All notifications scheduled")
    }
    
    private func scheduleAddictionLoopNotifications() {
        let notifications: [(hours: Int, title: String, body: String)] = [
            (1, "🎯 Your next level awaits!", "Just 5 minutes of practice can unlock new achievements"),
            (3, "⚡ Build unstoppable momentum", "Your speaking confidence grows with every conversation"),
            (6, "🔥 Keep your streak alive!", "Don't let yesterday's progress slip away"),
            (12, "💪 Your future self will thank you", "Every conversation brings you closer to fluency"),
            (24, "🌟 Ready to level up?", "Your language skills are waiting to be unleashed"),
            (48, "🚀 Come back stronger", "Great speakers practice consistently - that's you!"),
            (72, "💎 You're worth the investment", "Premium conversations unlock premium confidence")
        ]
        
        for (index, notification) in notifications.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            content.badge = NSNumber(value: index + 1)
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(notification.hours * 3600),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "addiction_loop_\(notification.hours)h",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule \(notification.hours)h notification: \(error)")
                }
            }
        }
    }
    
    private func schedulePracticeReminders() {
        // Daily practice reminders at optimal times
        let reminderTimes = [
            (hour: 9, minute: 0, title: "🌅 Morning boost", body: "Start your day with confident conversation"),
            (hour: 13, minute: 0, title: "☀️ Lunch break learning", body: "5 minutes now = fluency later"),
            (hour: 18, minute: 0, title: "🌆 Evening excellence", body: "End your day with language mastery"),
            (hour: 21, minute: 0, title: "🌙 Night time practice", body: "Tomorrow you'll be glad you practiced today")
        ]
        
        for (index, reminder) in reminderTimes.enumerated() {
            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute
            
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.categoryIdentifier = "PRACTICE_REMINDER"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "practice_reminder_\(index)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule practice reminder: \(error)")
                }
            }
        }
    }
    
    private func scheduleStreakNotifications() {
        // Streak milestone notifications
        let streakMilestones = [3, 7, 14, 30, 60, 100]
        
        for milestone in streakMilestones {
            let content = UNMutableNotificationContent()
            content.title = "🔥 \(milestone) Day Streak!"
            content.body = "You're on fire! Keep this amazing momentum going!"
            content.sound = .default
            content.categoryIdentifier = "STREAK_MILESTONE"
            
            // Schedule for when user reaches this streak
            let request = UNNotificationRequest(
                identifier: "streak_\(milestone)",
                content: content,
                trigger: nil // Will be triggered programmatically
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule streak notification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Push Notification Triggers
    
    func triggerStreakNotification(streakCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 \(streakCount) Day Streak!"
        content.body = "Incredible! You're building unstoppable habits!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "streak_achieved_\(streakCount)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to trigger streak notification: \(error)")
            } else {
                print("🔥 Triggered streak notification for \(streakCount) days")
            }
        }
    }
    
    func triggerAchievementNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to trigger achievement notification: \(error)")
            } else {
                print("🏆 Triggered achievement notification: \(title)")
            }
        }
    }
    
    // MARK: - Notification Controls
    
    func enableNotifications() {
        notificationsEnabled = true
        scheduleAllNotifications()
    }
    
    func disableNotifications() {
        notificationsEnabled = false
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Testing Methods
    
    func testNotificationSystem() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "DataSyncService notification system is working!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Test notification failed: \(error)")
            } else {
                print("✅ Test notification scheduled for 5 seconds")
            }
        }
    }
    
    func debugSyncState() {
        print("🔍 DataSyncService Debug State:")
        print("  Is Signed In: \(isSignedIn)")
        print("  Is Syncing: \(isSyncing)")
        print("  Last Sync: \(lastSyncDate?.formatted() ?? "Never")")
        print("  Current User: \(currentUser?.uid ?? "None")")
        print("  Sync Error: \(syncError ?? "None")")
        print("  Notifications Enabled: \(notificationsEnabled)")
        print("  Last Notification Scheduled: \(lastNotificationScheduled?.formatted() ?? "Never")")
    }
}
