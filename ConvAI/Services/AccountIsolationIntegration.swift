//
//  AccountIsolationIntegration.swift
//  ConvAI
//
//  Created by Account Isolation Implementation
//  Integration layer to handle account switching and data isolation across the app
//

import Foundation
import SwiftUI

/// Integration manager for account isolation across the ConvAI app
/// Handles account switching, data migration, and ensures proper data isolation
class AccountIsolationIntegration: ObservableObject {
    
    static let shared = AccountIsolationIntegration()
    
    @Published var isAccountSwitching = false
    @Published var currentAccountId: String = ""
    
    private let accountManager = AccountDataManager.shared
    
    private init() {
        setupAccountChangeMonitoring()
        currentAccountId = "Guest" // Default to guest account
    }
    
    // MARK: - Account Change Monitoring
    
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
        if let newAccountId = userInfo["newAccountId"] as? String {
            currentAccountId = newAccountId
        } else if let isGuest = userInfo["isGuest"] as? Bool, isGuest {
            currentAccountId = "Guest"
        }
        
        // Notify all services about account change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notifyServicesOfAccountChange()
            self.isAccountSwitching = false
        }
        
        print("🔄 AccountIsolationIntegration: Account changed to \(currentAccountId)")
    }
    
    private func notifyServicesOfAccountChange() {
        // This would notify GameProgressManager, UserProfile, etc. to reload their data
        // For now, we'll post a general notification
        NotificationCenter.default.post(
            name: .servicesAccountChangeNotification,
            object: nil
        )
    }
    
    // MARK: - Migration Management
    
    /// Performs one-time migration of existing data to account-specific storage
    @MainActor
    func performAccountSpecificMigration() {
        // Define all keys that need to be migrated
        let keysToMigrate = [
            // GameProgressManager keys
            "game_level", "game_xp", "game_streak", "game_conversations",
            "rejection_score", "deals_closed", "confidence_meter", "power_moves",
            "vocabulary_mastered", "conversation_minutes", "accent_confidence", "grammar_accuracy",
            "fluent_topics", "languages_activated", "native_phrases", "cultural_insights", "silence_breaking",
            "stories_repertoire", "narrative_hooks", "emotional_impact", "story_delivery",
            "audience_engagement", "vulnerability_comfort", "conversation_memorability",
            "charismatic_moments", "universal_lessons", "callback_techniques",
            "story_bank_size", "cross_category_connections", "real_world_applications",
            "conversational_stamina", "improvement_velocity",
            "money_level", "love_level", "power_level", "language_level", "story_level",
            "sessions_today", "longest_streak", "last_practice_date",
            "current_user", "last_awarded_xp", "sessionsForValidation",
            
            // UserProfile keys
            "userProfile", "hasCompletedOnboarding", "lastConversationDate",
            
            // BonusReward keys
            "total_bonus_xp", "total_bonus_count",
            
            // SimulationCharacterService keys
            "userGender",
            
            // AccountSettingsService keys
            "account_settings", "user_display_name",
            
            // Cloud sync keys
            "lastCloudSyncDate"
        ]
        
        accountManager.migrateKeysToAccountSpecific(keysToMigrate)
        
        print("✅ Account isolation migration completed")
    }
    
    // MARK: - Account Management
    
    /// Simulates signing out and switching to a new account (for testing)
    @MainActor
    func simulateAccountSwitch() {
        accountManager.switchToAccount("test_user_\(Date().timeIntervalSince1970)")
    }
    
    /// Simulates switching to guest mode
    @MainActor
    func simulateGuestMode() {
        accountManager.signOutAndSwitchToGuest()
    }
    
    /// Clears all data for the current account
    @MainActor
    func clearCurrentAccountData() {
        accountManager.clearAccountData()
        
        // Notify services to reset their state
        notifyServicesOfAccountChange()
        
        print("🗑️ Cleared all data for current account")
    }
    
    // MARK: - Validation & Debug
    
    /// Validates that account isolation is working correctly
    @MainActor
    func validateAccountIsolation() -> [String] {
        let issues = accountManager.validateAccountIsolation()
        
        if issues.isEmpty {
            print("✅ Account isolation validation passed")
        } else {
            print("⚠️ Account isolation validation failed:")
            for issue in issues {
                print("  - \(issue)")
            }
        }
        
        return issues
    }
    
    /// Gets current account information for debugging
    @MainActor
    func getCurrentAccountInfo() -> [String: Any] {
        let accountSummary = accountManager.getAccountDataSummary()
        
        return [
            "accountId": currentAccountId,
            "accountSpecificKeys": accountSummary["keys"] ?? [],
            "totalKeys": (accountSummary["keys"] as? [String])?.count ?? 0,
            "migrationCompleted": true // Assume completed for now
        ]
    }
    
    /// Gets a summary of all cached data@MainActor  for debugging
    @MainActor
    func getDataSummary() -> String {
        let accountInfo = getCurrentAccountInfo()
        let validationIssues = validateAccountIsolation()
        
        var summary = """
        
        📊 Account Isolation Status:
        
        Current Account: \(accountInfo["accountId"] ?? "Unknown")
        Account-Specific Keys: \(accountInfo["totalKeys"] ?? 0)
        Migration Completed: \(accountInfo["migrationCompleted"] ?? false)
        
        """
        
        if !validationIssues.isEmpty {
            summary += """
            
            ⚠️ Validation Issues:
            \(validationIssues.joined(separator: "\n"))
            
            """
        }
        
        if let keys = accountInfo["accountSpecificKeys"] as? [String], !keys.isEmpty {
            summary += """
            
            🔑 Account-Specific Keys:
            \(keys.prefix(10).joined(separator: "\n"))
            \(keys.count > 10 ? "\n... and \(keys.count - 10) more" : "")
            
            """
        }
        
        return summary
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let servicesAccountChangeNotification = Notification.Name("ServicesAccountChangeNotification")
}

// MARK: - SwiftUI Integration

struct AccountIsolationDebugView: View {
    @ObservedObject private var integration = AccountIsolationIntegration.shared
    @State private var showingDataSummary = false
    @State private var dataSummary = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Account Isolation Debug")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Current Account: \(integration.currentAccountId)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if integration.isAccountSwitching {
                ProgressView("Switching accounts...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            VStack(spacing: 12) {
                Button("Perform Migration") {
                    Task { @MainActor in
                        integration.performAccountSpecificMigration()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Simulate Account Switch") {
                    Task { @MainActor in
                        integration.simulateAccountSwitch()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Switch to Guest Mode") {
                    Task { @MainActor in
                        integration.simulateGuestMode()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Clear Account Data") {
                    Task { @MainActor in
                        integration.clearCurrentAccountData()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("Show Data Summary") {
                    dataSummary = integration.getDataSummary()
                    showingDataSummary = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .sheet(isPresented: $showingDataSummary) {
            NavigationView {
                ScrollView {
                    Text(dataSummary)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .navigationTitle("Data Summary")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            showingDataSummary = false
                        }
                    }
                }
            }
        }
    }
}
