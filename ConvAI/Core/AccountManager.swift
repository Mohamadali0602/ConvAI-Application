//
//  AccountManager.swift
//  ConvAI
//
//  Consolidated account management: Data + Switching + Storage + Isolation
//  Complete account-specific data management with Firebase integration
//

import Foundation
import SwiftUI
// import FirebaseAuth // TODO: Enable when Firebase is properly configured

// MARK: - Account Notifications
extension Notification.Name {
    static let accountDidChange = Notification.Name("accountDidChange")
    static let accountSwitchStarted = Notification.Name("accountSwitchStarted")
    static let accountSwitchCompleted = Notification.Name("accountSwitchCompleted")
}

// MARK: - Main Account Manager
@MainActor
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    // MARK: - Published Properties
    @Published var currentAccount: String = "guest"
    @Published var isAccountSwitching: Bool = false
    @Published var availableAccounts: [String] = []
    @Published var currentAccountId: String = ""
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let accountPrefix = "account_"
    private let guestAccountId = "guest"
    
    private init() {
        setupCurrentAccount()
        updateAvailableAccounts()
        setupAuthListener()
        setupAccountChangeMonitoring()
        currentAccountId = "Guest" // Default to guest account
    }
    
    // MARK: - Firebase Auth Integration
    
    private func setupAuthListener() {
        // TODO: Enable when Firebase is properly integrated
        /*
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleFirebaseAuthChange(user: user)
            }
        }
        */
        print("🔗 AccountManager: Auth listener setup ready for Firebase integration")
    }
    
    private func handleFirebaseAuthChange(user: Any?) {
        // TODO: Replace with proper Firebase User type when available
        /*
        let newAccountId = user?.uid ?? guestAccountId
        
        if newAccountId != currentAccount {
            switchToAccount(newAccountId)
        }
        */
        print("🔄 AccountManager: Firebase auth change handler ready")
    }
    
    // MARK: - Account Switching
    
    func switchToAccount(_ accountId: String) {
        guard accountId != currentAccount else { return }
        
        let previousAccount = currentAccount
        
        // Notify that account switch is starting
        isAccountSwitching = true
        NotificationCenter.default.post(name: .accountSwitchStarted, object: nil, userInfo: [
            "previousAccount": previousAccount,
            "newAccount": accountId
        ])
        
        print("🔄 AccountManager: Switching from '\(previousAccount)' to '\(accountId)'")
        
        // Update current account
        currentAccount = accountId
        currentAccountId = accountId
        userDefaults.set(accountId, forKey: "currentAccount")
        
        // Update available accounts list
        updateAvailableAccounts()
        
        // Perform account-specific migration if needed
        performAccountSpecificMigration(for: accountId)
        
        // Notify that account has changed
        NotificationCenter.default.post(name: .accountDidChange, object: nil, userInfo: [
            "previousAccount": previousAccount,
            "newAccount": accountId
        ])
        
        // Complete the switch
        isAccountSwitching = false
        NotificationCenter.default.post(name: .accountSwitchCompleted, object: nil, userInfo: [
            "previousAccount": previousAccount,
            "newAccount": accountId
        ])
        
        print("✅ AccountManager: Successfully switched to account '\(accountId)'")
    }
    
    func signOutToGuestAccount() {
        // TODO: Enable when Firebase is integrated
        // do {
        //     try Auth.auth().signOut()
        //     print("👋 AccountManager: Signed out and switched to guest account")
        // } catch let signOutError as NSError {
        //     print("❌ AccountManager: Error signing out: \(signOutError)")
        // }
        
        switchToAccount(guestAccountId)
        print("👋 AccountManager: Switched to guest account")
    }
    
    // MARK: - Account Setup and Management
    
    private func setupCurrentAccount() {
        // Get current account from UserDefaults, default to guest
        if let savedAccount = userDefaults.string(forKey: "currentAccount") {
            currentAccount = savedAccount
        } else {
            currentAccount = guestAccountId
            userDefaults.set(guestAccountId, forKey: "currentAccount")
        }
        
        print("🏠 AccountManager: Current account set to '\(currentAccount)'")
    }
    
    private func updateAvailableAccounts() {
        // Get all account-specific keys from UserDefaults
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let accountKeys = allKeys.filter { $0.hasPrefix(accountPrefix) }
        
        // Extract account IDs from keys
        var accounts: Set<String> = []
        for key in accountKeys {
            let components = key.components(separatedBy: "_")
            if components.count >= 2 {
                let accountId = components[1]
                accounts.insert(accountId)
            }
        }
        
        // Always include guest account
        accounts.insert(guestAccountId)
        
        // Convert to sorted array
        availableAccounts = Array(accounts).sorted()
        
        print("📱 AccountManager: Available accounts: \(availableAccounts)")
    }
    
    // MARK: - Account-Specific Data Storage
    
    func setValue<T>(_ value: T, forKey key: String) {
        let accountKey = "\(accountPrefix)\(currentAccount)_\(key)"
        
        if let value = value as? String {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? Int {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? Double {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? Bool {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? Data {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? [String] {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? [Any] {
            userDefaults.set(value, forKey: accountKey)
        } else if let value = value as? [String: Any] {
            userDefaults.set(value, forKey: accountKey)
        } else {
            print("⚠️ AccountManager: Unsupported type for key '\(key)'")
            return
        }
        
        print("💾 AccountManager: Saved '\(key)' for account '\(currentAccount)'")
    }
    
    func getValue<T>(forKey key: String, type: T.Type) -> T? {
        let accountKey = "\(accountPrefix)\(currentAccount)_\(key)"
        
        if type == String.self {
            return userDefaults.string(forKey: accountKey) as? T
        } else if type == Int.self {
            return userDefaults.integer(forKey: accountKey) as? T
        } else if type == Double.self {
            return userDefaults.double(forKey: accountKey) as? T
        } else if type == Bool.self {
            return userDefaults.bool(forKey: accountKey) as? T
        } else if type == Data.self {
            return userDefaults.data(forKey: accountKey) as? T
        } else if type == [String].self {
            return userDefaults.stringArray(forKey: accountKey) as? T
        } else if type == [Any].self {
            return userDefaults.array(forKey: accountKey) as? T
        } else if type == [String: Any].self {
            return userDefaults.dictionary(forKey: accountKey) as? T
        }
        
        return nil
    }
    
    func removeValue(forKey key: String) {
        let accountKey = "\(accountPrefix)\(currentAccount)_\(key)"
        userDefaults.removeObject(forKey: accountKey)
        print("🗑️ AccountManager: Removed '\(key)' for account '\(currentAccount)'")
    }
    
    // MARK: - Account Migration
    
    private func performAccountSpecificMigration(for accountId: String) {
        let migrationKey = "\(accountPrefix)\(accountId)_migration_completed"
        
        guard !userDefaults.bool(forKey: migrationKey) else {
            // Migration already completed for this account
            return
        }
        
        // Migrate legacy UserDefaults keys to account-specific storage
        let legacyKeys = [
            "userProfile",
            "onboarding_completed",
            "user_display_name",
            "total_conversation_time",
            "conversations_completed",
            "current_streak",
            "longest_streak",
            "total_xp",
            "current_level",
            "preferred_language",
            "language_level",
            "preferred_voice",
            "notifications_enabled",
            "audio_quality_preference",
            "activity_sensitivity",
            "learning_goals",
            "practice_days",
            "daily_goal_minutes",
            "last_practice_date",
            "practice_sessions_today"
        ]
        
        for key in legacyKeys {
            if let value = userDefaults.object(forKey: key) {
                let accountKey = "\(accountPrefix)\(accountId)_\(key)"
                userDefaults.set(value, forKey: accountKey)
                // Don't remove legacy key immediately to prevent data loss
                print("📦 AccountManager: Migrated '\(key)' to account-specific storage")
            }
        }
        
        // Mark migration as completed
        userDefaults.set(true, forKey: migrationKey)
        print("✅ AccountManager: Migration completed for account '\(accountId)'")
    }
    
    // MARK: - Account Isolation
    
    private func setupAccountChangeMonitoring() {
        NotificationCenter.default.addObserver(
            forName: .accountDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAccountChange(notification: notification)
        }
    }
    
    private func handleAccountChange(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        isAccountSwitching = true
        
        // Update current account ID
        if let newAccountId = userInfo["newAccount"] as? String {
            currentAccountId = newAccountId
        } else if let isGuest = userInfo["isGuest"] as? Bool, isGuest {
            currentAccountId = "Guest"
        }
        
        // Perform data isolation tasks
        isolateAccountData()
        
        // Complete account switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAccountSwitching = false
        }
    }
    
    private func isolateAccountData() {
        // Ensure all app components are aware of account change
        print("🔒 AccountManager: Isolating data for account '\(currentAccountId)'")
        
        // Clear any cached data that shouldn't persist across accounts
        clearTransientCache()
        
        // Notify other services about account change
        NotificationCenter.default.post(
            name: Notification.Name("dataIsolationRequired"),
            object: nil,
            userInfo: ["accountId": currentAccountId]
        )
    }
    
    private func clearTransientCache() {
        // Clear any app-level cache that shouldn't persist across accounts
        // This includes temporary UI state, cached API responses, etc.
        
        // Clear notification center temporary data
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        print("🧹 AccountManager: Cleared transient cache for account switch")
    }
    
    // MARK: - Account Data Management
    
    func clearAccountData(for targetAccount: String) {
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let accountSpecificKeys = allKeys.filter { 
            $0.hasPrefix("\(accountPrefix)\(targetAccount)_") 
        }
        
        // Remove all keys for the specified account
        for key in accountSpecificKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        // Update available accounts
        updateAvailableAccounts()
        
        print("🗑️ AccountManager: Cleared all data for account '\(targetAccount)' (\(accountSpecificKeys.count) keys)")
    }
    
    func clearCurrentAccountData() {
        clearAccountData(for: currentAccount)
    }
    
    // MARK: - Testing and Simulation Methods
    
    @MainActor
    func performAccountSpecificMigration() async {
        performAccountSpecificMigration(for: currentAccount)
    }
    
    @MainActor
    func simulateAccountSwitch() async {
        let testAccount = "test_user_\(Date().timeIntervalSince1970)"
        switchToAccount(testAccount)
    }
    
    @MainActor
    func simulateGuestMode() async {
        switchToAccount(guestAccountId)
    }
    
    // MARK: - Account State Queries
    
    var isGuestAccount: Bool {
        return currentAccount == guestAccountId
    }
    
    var hasMultipleAccounts: Bool {
        return availableAccounts.count > 1
    }
    
    func getAccountDisplayName(_ accountId: String) -> String {
        if accountId == guestAccountId {
            return "Guest"
        }
        
        // Try to get display name from account data
        let previousAccount = currentAccount
        let tempSwitch = accountId != currentAccount
        
        if tempSwitch {
            currentAccount = accountId
        }
        
        let displayName = getValue(forKey: "user_display_name", type: String.self) ?? accountId
        
        if tempSwitch {
            currentAccount = previousAccount
        }
        
        return displayName
    }
    
    // MARK: - Debugging and Diagnostics
    
    func debugPrintAccountState() {
        print("🔍 AccountManager Debug State:")
        print("  Current Account: \(currentAccount)")
        print("  Available Accounts: \(availableAccounts)")
        print("  Is Switching: \(isAccountSwitching)")
        print("  Is Guest: \(isGuestAccount)")
        print("  Has Multiple: \(hasMultipleAccounts)")
        
        // Print some account-specific data for debugging
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let currentAccountKeys = allKeys.filter { 
            $0.hasPrefix("\(accountPrefix)\(currentAccount)_") 
        }
        print("  Account Keys: \(currentAccountKeys.count)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Convenience Extensions

extension AccountManager {
    
    /// Get user profile data for current account
    func getUserProfileData() -> Data? {
        return getValue(forKey: "userProfile", type: Data.self)
    }
    
    /// Set user profile data for current account
    func setUserProfileData(_ data: Data) {
        setValue(data, forKey: "userProfile")
    }
    
    /// Check if onboarding is completed for current account
    func hasCompletedOnboarding() -> Bool {
        return getValue(forKey: "onboarding_completed", type: Bool.self) ?? false
    }
    
    /// Mark onboarding as completed for current account
    func markOnboardingCompleted() {
        setValue(true, forKey: "onboarding_completed")
    }
    
    /// Get display name for current account
    func getCurrentAccountDisplayName() -> String? {
        return getValue(forKey: "user_display_name", type: String.self)
    }
    
    /// Set display name for current account
    func setCurrentAccountDisplayName(_ name: String) {
        setValue(name, forKey: "user_display_name")
    }
}
