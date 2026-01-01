//
//  AccountSpecificStorage.swift
//  ConvAI
//
//  Created by Account Isolation Implementation
//  Provides account-specific data storage to prevent data leakage between user accounts
//

import Foundation
import FirebaseAuth

/// Utility class to handle account-specific storage, preventing data leakage between different user accounts on the same device
class AccountSpecificStorage {
    
    // MARK: - Private Properties
    
    private static let guestPrefix = "guest"
    private static let userPrefix = "user"
    private static let migrationKey = "account_storage_migration_completed"
    private static let currentAccountKey = "current_account_id"
    
    // MARK: - Account Management
    
    /// Gets the current account prefix for UserDefaults keys
    private static func getAccountPrefix() -> String {
        if let userId = Auth.auth().currentUser?.uid {
            return "\(userPrefix)_\(userId)"
        } else {
            // For guest users, create a persistent guest ID or use existing one
            return getOrCreateGuestPrefix()
        }
    }
    
    /// Gets or creates a persistent guest ID for non-authenticated users
    private static func getOrCreateGuestPrefix() -> String {
        let guestIdKey = "persistent_guest_id"
        
        if let existingGuestId = UserDefaults.standard.string(forKey: guestIdKey) {
            return "\(guestPrefix)_\(existingGuestId)"
        } else {
            let newGuestId = UUID().uuidString
            UserDefaults.standard.set(newGuestId, forKey: guestIdKey)
            return "\(guestPrefix)_\(newGuestId)"
        }
    }
    
    /// Gets the current account ID for comparison
    static func getCurrentAccountId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Checks if the current account has changed since last access
    static func hasAccountChanged() -> Bool {
        let currentId = getCurrentAccountId()
        let storedId = UserDefaults.standard.string(forKey: currentAccountKey)
        return currentId != storedId
    }
    
    /// Updates the stored account ID
    static func updateCurrentAccountId() {
        let currentId = getCurrentAccountId()
        UserDefaults.standard.set(currentId, forKey: currentAccountKey)
    }
    
    // MARK: - Storage Operations
    
    /// Sets a value for an account-specific key
    static func setAccountSpecific<T>(_ value: T, forKey key: String) {
        let accountKey = getAccountPrefix() + "_" + key
        UserDefaults.standard.set(value, forKey: accountKey)
        
        #if DEBUG
        print("AccountSpecificStorage: Set \(accountKey) = \(value)")
        #endif
    }
    
    /// Gets a value for an account-specific key with a default value
    static func getAccountSpecific<T>(forKey key: String, defaultValue: T) -> T {
        let accountKey = getAccountPrefix() + "_" + key
        let value = UserDefaults.standard.object(forKey: accountKey) as? T ?? defaultValue
        
        #if DEBUG
        print("AccountSpecificStorage: Get \(accountKey) = \(value)")
        #endif
        
        return value
    }
    
    /// Gets a value for an account-specific key without a default (returns nil if not found)
    static func getAccountSpecific<T>(forKey key: String, type: T.Type) -> T? {
        let accountKey = getAccountPrefix() + "_" + key
        return UserDefaults.standard.object(forKey: accountKey) as? T
    }
    
    /// Removes a value for an account-specific key
    static func removeAccountSpecific(forKey key: String) {
        let accountKey = getAccountPrefix() + "_" + key
        UserDefaults.standard.removeObject(forKey: accountKey)
        
        #if DEBUG
        print("AccountSpecificStorage: Removed \(accountKey)")
        #endif
    }
    
    /// Checks if an account-specific key exists
    static func hasAccountSpecific(forKey key: String) -> Bool {
        let accountKey = getAccountPrefix() + "_" + key
        return UserDefaults.standard.object(forKey: accountKey) != nil
    }
    
    // MARK: - Bulk Operations
    
    /// Clears all data for the current account
    static func clearCurrentAccountData() {
        let prefix = getAccountPrefix() + "_"
        clearDataWithPrefix(prefix)
    }
    
    /// Clears all data for a specific account ID
    static func clearAccountData(for accountId: String?) {
        guard let accountId = accountId else {
            // Clear guest data
            clearAllGuestData()
            return
        }
        
        let prefix = "\(userPrefix)_\(accountId)_"
        clearDataWithPrefix(prefix)
    }
    
    /// Clears all guest account data
    static func clearAllGuestData() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix("\(guestPrefix)_") {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    /// Clears all account-specific data (dangerous - use with caution)
    static func clearAllAccountData() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix("\(userPrefix)_") || key.hasPrefix("\(guestPrefix)_") {
                defaults.removeObject(forKey: key)
            }
        }
        
        #if DEBUG
        print("AccountSpecificStorage: Cleared all account data")
        #endif
    }
    
    /// Helper method to clear data with a specific prefix
    private static func clearDataWithPrefix(_ prefix: String) {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix(prefix) {
                defaults.removeObject(forKey: key)
            }
        }
        
        #if DEBUG
        print("AccountSpecificStorage: Cleared data with prefix: \(prefix)")
        #endif
    }
    
    // MARK: - Migration Support
    
    /// Migrates existing UserDefaults keys to account-specific format
    static func migrateExistingDataToAccountSpecific(keys: [String]) {
        guard !hasMigrationCompleted() else {
            #if DEBUG
            print("AccountSpecificStorage: Migration already completed")
            #endif
            return
        }
        
        let defaults = UserDefaults.standard
        
        for key in keys {
            if let value = defaults.object(forKey: key) {
                // Save to account-specific key
                setAccountSpecific(value, forKey: key)
                
                // Keep original key for safety during migration period
                // TODO: Remove original keys after successful migration validation
                
                #if DEBUG
                print("AccountSpecificStorage: Migrated \(key) to account-specific storage")
                #endif
            }
        }
        
        markMigrationCompleted()
    }
    
    /// Checks if migration has been completed
    static func hasMigrationCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    /// Marks migration as completed
    static func markMigrationCompleted() {
        UserDefaults.standard.set(true, forKey: migrationKey)
        
        #if DEBUG
        print("AccountSpecificStorage: Migration marked as completed")
        #endif
    }
    
    /// Resets migration state (for testing purposes)
    static func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
    }
    
    // MARK: - Debug & Utility
    
    /// Gets all account-specific keys for the current account (debug purposes)
    static func getAllCurrentAccountKeys() -> [String] {
        let prefix = getAccountPrefix() + "_"
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        return keys.filter { $0.hasPrefix(prefix) }
    }
    
    /// Gets all account-specific data for the current account (debug purposes)
    static func getAllCurrentAccountData() -> [String: Any] {
        let prefix = getAccountPrefix() + "_"
        let defaults = UserDefaults.standard
        let allData = defaults.dictionaryRepresentation()
        
        return allData.filter { $0.key.hasPrefix(prefix) }
    }
    
    /// Validates that no data leakage exists between accounts
    static func validateDataIsolation() -> [String] {
        var issues: [String] = []
        
        let currentPrefix = getAccountPrefix() + "_"
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        // Check for old non-account-specific keys that should have been migrated
        let legacyKeys = [
            "game_level", "game_xp", "game_streak", "userProfile", 
            "total_bonus_xp", "account_settings", "userGender"
        ]
        
        for legacyKey in legacyKeys {
            if keys.contains(legacyKey) {
                issues.append("Legacy key '\(legacyKey)' still exists - potential data leakage")
            }
        }
        
        return issues
    }
}

// MARK: - Account Change Notification

extension AccountSpecificStorage {
    
    /// Notification posted when account changes are detected
    static let accountDidChangeNotification = Notification.Name("AccountSpecificStorageAccountDidChange")
    
    /// Posts notification when account change is detected
    static func notifyAccountChange(from oldAccountId: String?, to newAccountId: String?) {
        let userInfo: [String: Any?] = [
            "oldAccountId": oldAccountId,
            "newAccountId": newAccountId
        ]
        
        NotificationCenter.default.post(
            name: accountDidChangeNotification,
            object: nil,
            userInfo: userInfo as [AnyHashable: Any]
        )
        
        #if DEBUG
        print("AccountSpecificStorage: Account changed from \(oldAccountId ?? "nil") to \(newAccountId ?? "nil")")
        #endif
    }
    
    /// Checks for account changes and posts notification if needed
    static func checkAndNotifyAccountChange() {
        let currentId = getCurrentAccountId()
        let storedId = UserDefaults.standard.string(forKey: currentAccountKey)
        
        if currentId != storedId {
            notifyAccountChange(from: storedId, to: currentId)
            updateCurrentAccountId()
        }
    }
}
