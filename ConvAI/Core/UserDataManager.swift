//
//  UserDataManager.swift
//  ConvAI
//
//  Consolidated user data management: Profile + Account Settings + Settings Models
//  Unified SwiftData + Firebase + Local Storage integration
//

import Foundation
import SwiftUI
import SwiftData
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth Provider Enum
public enum AuthProvider: String, CaseIterable {
    case apple = "apple.com"
    case google = "google.com"
    case email = "password"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .apple: return "Apple ID"
        case .google: return "Google"
        case .email: return "Email"
        case .unknown: return "Unknown"
        }
    }
    
    public var iconName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "globe"
        case .email: return "envelope.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Subscription Tier Enum
public enum SubscriptionTier: String, CaseIterable {
    case trial = "trial"
    case developer = "developer"
    case betaTester = "betaTester"
    case monthly = "monthly"
    case yearly = "yearly"
    
    public var displayName: String {
        switch self {
        case .trial: return "Free Trial"
        case .developer: return "Developer Access"
        case .betaTester: return "Beta Tester"
        case .monthly: return "Premium Monthly"
        case .yearly: return "Premium Yearly"
        }
    }
    
    public var features: [String] {
        switch self {
        case .trial:
            return ["Limited trial access", "Basic AI models", "3-day trial period"]
        case .developer:
            return ["Unlimited access", "All AI models", "Development features", "No restrictions"]
        case .betaTester:
            return ["Beta access", "Testing features", "2-hour daily limit", "All AI models"]
        case .monthly:
            return ["180 minutes daily", "Advanced AI models", "Priority support"]
        case .yearly:
            return ["180 minutes daily", "Advanced AI models", "Priority support", "Early access to features"]
        }
    }
    
    public var iconName: String {
        switch self {
        case .trial: return "clock"
        case .developer: return "hammer.fill"
        case .betaTester: return "testtube.2"
        case .monthly: return "star.fill"
        case .yearly: return "crown.fill"
        }
    }
}

// MARK: - SwiftData User Model
@Model
final class UserData {
    // Use Firebase UID as unique identifier
    @Attribute(.unique) var userId: String
    
    // --- User Profile Properties ---
    var name: String = ""
    var preferredLanguage: String = "en-US"
    var languageLevel: String = "beginner"
    var preferredVoice: String = "Puck"
    var gender: String? = nil
    var isSetup: Bool = false
    var hasCompletedOnboarding: Bool = false
    
    // User preferences
    var notificationsEnabled: Bool = true
    var audioQualityPreference: String = "balanced"
    var activitySensitivity: String = "medium"
    
    // Learning preferences
    var learningGoals: [String] = []
    var practiceDays: [String] = []
    var dailyGoalMinutes: Int = 15
    
    // Statistics
    var totalConversationTime: TimeInterval = 0
    var conversationsCompleted: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalXP: Int = 0
    
    // --- Game Progress Properties ---
    var currentLevel: Int = 1
    var totalConversations: Int = 0
    
    // Psychological Metrics
    var rejectionScore: Int = 0
    var dealsClosedCounter: Int = 0
    var confidenceMeter: Double = 0.0
    var powerMovesUsed: Int = 0
    
    // Language Learning Metrics
    var vocabularyMastered: Int = 0
    var conversationMinutesInTargetLanguage: Int = 0
    var accentConfidenceScore: Double = 0.0
    var grammarAccuracy: Double = 0.0
    var fluentTopics: [String] = []
    var languagesActivated: [String] = []
    var nativePhrasesLearned: Int = 0
    var culturalInsightsGained: Int = 0
    var silenceBreakingTechniques: Int = 0
    
    // Storytelling & Narrative Metrics
    var storiesInRepertoire: Int = 0
    var narrativeHooksMastered: Int = 0
    var emotionalImpactScore: Double = 0.0
    var storyDeliveryConfidence: Double = 0.0
    var audienceEngagementLevel: Double = 0.0
    var vulnerabilityComfortZone: Double = 0.0
    var conversationMemorability: Int = 0
    var charismaticMomentsCaptured: Int = 0
    var universalLessonsExtracted: Int = 0
    var callbackTechniquesUsed: Int = 0
    
    // Cross-Category Integration Metrics
    var storyBankSize: Int = 0
    var crossCategoryConnections: Int = 0
    var realWorldApplications: Int = 0
    var conversationalStamina: TimeInterval = 0
    var improvementVelocity: Double = 0.0
    
    // Simulation Metrics
    var simulationsCompleted: Int = 0
    var simulationSuccessRate: Double = 0.0
    
    // Category-Specific Progress
    var moneyMasteryLevel: Int = 1
    var loveCoachLevel: Int = 1
    var powerPlayerLevel: Int = 1
    var languageMasteryLevel: Int = 1
    var storyMasteryLevel: Int = 1
    
    // Achievement & Milestone Tracking
    var lastPracticeDate: Date?
    var practiceSessionsToday: Int = 0
    var lastConversationDate: Date?
    
    // Migration tracking
    var dataVersion: Int = 1
    var migrationCompleted: Bool = false
    
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Computed Properties
    
    var levelProgress: Double {
        let xpForCurrentLevel = xpRequiredForLevel(currentLevel)
        let xpForNextLevel = xpRequiredForLevel(currentLevel + 1)
        let xpInCurrentLevel = totalXP - xpForCurrentLevel
        let xpNeededForNextLevel = xpForNextLevel - xpForCurrentLevel
        
        return Double(xpInCurrentLevel) / Double(xpNeededForNextLevel)
    }
    
    private func xpRequiredForLevel(_ level: Int) -> Int {
        return (level - 1) * 100
    }
    
    // MARK: - Game Logic Methods
    
    func addXP(_ points: Int) {
        totalXP += points
        checkForLevelUp()
    }
    
    func updateConversationStats(duration: TimeInterval) {
        totalConversationTime += duration
        conversationsCompleted += 1
        
        // Update streak logic
        let calendar = Calendar.current
        let today = Date()
        
        if let lastConversation = lastConversationDate {
            if calendar.isDate(lastConversation, inSameDayAs: today) {
                // Same day, don't update streak
            } else if calendar.isDate(lastConversation, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today) {
                // Yesterday, continue streak
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // Missed a day, reset streak
                currentStreak = 1
            }
        } else {
            // First conversation
            currentStreak = 1
            longestStreak = 1
        }
        
        lastConversationDate = today
    }
    
    private func checkForLevelUp() {
        let newLevel = (totalXP / 100) + 1
        if newLevel > currentLevel {
            currentLevel = newLevel
        }
    }
}

// MARK: - User Account Data Model
@MainActor
public class UserAccount: ObservableObject {
    @Published public var email: String = ""
    @Published public var displayName: String = ""
    @Published public var userID: String = ""
    @Published public var authProvider: AuthProvider = .unknown
    @Published public var isEmailVerified: Bool = false
    @Published public var accountCreationDate: Date?
    @Published public var lastSignInDate: Date?
    
    public init() {
        loadFromCurrentUser()
    }
    
    public func loadFromCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            resetUserData()
            return
        }
        
        self.userID = user.uid
        self.email = user.email ?? ""
        self.displayName = user.displayName ?? ""
        self.isEmailVerified = user.isEmailVerified
        self.accountCreationDate = user.metadata.creationDate
        self.lastSignInDate = user.metadata.lastSignInDate
        
        // Determine auth provider
        if let providerData = user.providerData.first {
            self.authProvider = AuthProvider(rawValue: providerData.providerID) ?? .unknown
        } else {
            self.authProvider = .unknown
        }
    }
    
    private func resetUserData() {
        self.email = ""
        self.displayName = ""
        self.userID = ""
        self.authProvider = .unknown
        self.isEmailVerified = false
        self.accountCreationDate = nil
        self.lastSignInDate = nil
    }
    
    public func updateDisplayName(_ newName: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw UserDataError.noCurrentUser
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        
        try await changeRequest.commitChanges()
        
        // Update local state
        self.displayName = newName
        
        // Save to UserDefaults for offline access
        UserDefaults.standard.set(newName, forKey: "user_display_name")
    }
}

// MARK: - Subscription Status Model
@MainActor
public class SubscriptionStatus: ObservableObject {
    @Published public var isActive: Bool = false
    @Published public var tier: SubscriptionTier = .trial
    @Published public var expirationDate: Date?
    @Published public var isBillable: Bool = false
    @Published public var environment: String = "unknown"
    @Published public var autoRenewalStatus: Bool = false
    @Published public var lastUpdated: Date = Date()
    
    public func updateFromStoreKit(
        isActive: Bool,
        tier: String?,
        expirationDate: Date?,
        isBillable: Bool,
        environment: String,
        autoRenewal: Bool = false
    ) {
        self.isActive = isActive
        self.tier = SubscriptionTier(rawValue: tier ?? "trial") ?? .trial
        self.expirationDate = expirationDate
        self.isBillable = isBillable
        self.environment = environment
        self.autoRenewalStatus = autoRenewal
        self.lastUpdated = Date()
    }
    
    public var statusText: String {
        switch tier {
        case .trial:
            return isActive ? "Free Trial Active" : "Free Trial Expired"
        case .developer:
            return "Developer Access"
        case .betaTester:
            return "Beta Tester Access"
        case .monthly, .yearly:
            if !isActive {
                return "Subscription Expired"
            }
            
            var text = tier.displayName
            
            if !isBillable {
                text += environment == "sandbox" ? " (TestFlight)" : " (Beta)"
            }
            
            return text
        }
    }
    
    public var expirationText: String? {
        guard let expirationDate = expirationDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if expirationDate > Date() {
            return "Expires \(formatter.string(from: expirationDate))"
        } else {
            return "Expired \(formatter.string(from: expirationDate))"
        }
    }
}

// MARK: - Account Settings Model
public struct AccountSettings: Codable {
    public var allowDataExport: Bool = true
    public var dataRetentionDays: Int = 30
    public var analyticsEnabled: Bool = true
    public var crashReportingEnabled: Bool = true
    public var marketingEmailsEnabled: Bool = false
    public var productUpdatesEnabled: Bool = true
    
    public init() {}
}

// MARK: - Main UserDataManager Class
@MainActor
public class UserDataManager: ObservableObject {
    // MARK: - Subcomponents
    @Published public var userAccount = UserAccount()
    @Published public var subscriptionStatus = SubscriptionStatus()
    @Published public var accountSettings = AccountSettings()
    
    // MARK: - User Profile Properties (Published for SwiftUI)
    @Published public var currentUserData: UserData?
    @Published public var name: String = ""
    @Published public var preferredLanguage: String = "en-US"
    @Published public var languageLevel: String = "beginner"
    @Published public var preferredVoice: String = "Puck"
    @Published public var gender: String? = nil
    @Published public var isSetup: Bool = false
    @Published public var hasCompletedOnboarding: Bool = false
    @Published public var notificationsEnabled: Bool = true
    @Published public var audioQualityPreference: String = "balanced"
    @Published public var activitySensitivity: String = "medium"
    @Published public var learningGoals: [String] = []
    @Published public var practiceDays: [String] = []
    @Published public var dailyGoalMinutes: Int = 15
    @Published public var totalConversationTime: TimeInterval = 0
    @Published public var conversationsCompleted: Int = 0
    @Published public var currentStreak: Int = 0
    @Published public var longestStreak: Int = 0
    @Published public var totalXP: Int = 0
    
    // MARK: - State Properties
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var storeKitManager: StoreKit2PurchaseManager?
    private var modelContext: ModelContext?
    private var currentUserId: String = "guest"
    
    // MARK: - Initialization
    
    public init(storeKitManager: StoreKit2PurchaseManager? = nil) {
        self.storeKitManager = storeKitManager
        setupAuthStateListener()
        loadAccountSettings()
        migrateFromUserDefaults()
    }
    
    public func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserData()
    }
    
    // MARK: - Firebase Auth Integration
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                let newUserId = user?.uid ?? "guest"
                await self?.switchToUser(newUserId)
                
                if user != nil {
                    await self?.loadAccountData()
                } else {
                    self?.resetAccountData()
                }
            }
        }
    }
    
    private func switchToUser(_ userId: String) async {
        guard userId != currentUserId else { return }
        
        currentUserId = userId
        loadUserData()
        
        print("👤 UserDataManager: Switched to user '\(userId)'")
    }
    
    // MARK: - SwiftData User Profile Management
    
    private func loadUserData() {
        guard let modelContext = modelContext else { return }
        
        let predicate = #Predicate<UserData> { $0.userId == currentUserId }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let users = try modelContext.fetch(descriptor)
            
            if let userData = users.first {
                self.currentUserData = userData
                updatePublishedProperties(from: userData)
                performMigrationIfNeeded()
            } else {
                // Create new user data
                createNewUserData()
            }
        } catch {
            print("❌ UserDataManager: Failed to load user data: \(error)")
        }
    }
    
    private func createNewUserData() {
        guard let modelContext = modelContext else { return }
        
        let newUserData = UserData(userId: currentUserId)
        modelContext.insert(newUserData)
        
        do {
            try modelContext.save()
            self.currentUserData = newUserData
            updatePublishedProperties(from: newUserData)
            print("✅ UserDataManager: Created new user data for '\(currentUserId)'")
        } catch {
            print("❌ UserDataManager: Failed to create new user data: \(error)")
        }
    }
    
    private func updatePublishedProperties(from userData: UserData) {
        self.name = userData.name
        self.preferredLanguage = userData.preferredLanguage
        self.languageLevel = userData.languageLevel
        self.preferredVoice = userData.preferredVoice
        self.gender = userData.gender
        self.isSetup = userData.isSetup
        self.hasCompletedOnboarding = userData.hasCompletedOnboarding
        self.notificationsEnabled = userData.notificationsEnabled
        self.audioQualityPreference = userData.audioQualityPreference
        self.activitySensitivity = userData.activitySensitivity
        self.learningGoals = userData.learningGoals
        self.practiceDays = userData.practiceDays
        self.dailyGoalMinutes = userData.dailyGoalMinutes
        self.totalConversationTime = userData.totalConversationTime
        self.conversationsCompleted = userData.conversationsCompleted
        self.currentStreak = userData.currentStreak
        self.longestStreak = userData.longestStreak
        self.totalXP = userData.totalXP
    }
    
    private func saveUserData() {
        guard let modelContext = modelContext, let userData = currentUserData else { return }
        
        // Update UserData properties from published properties
        userData.name = self.name
        userData.preferredLanguage = self.preferredLanguage
        userData.languageLevel = self.languageLevel
        userData.preferredVoice = self.preferredVoice
        userData.gender = self.gender
        userData.isSetup = self.isSetup
        userData.hasCompletedOnboarding = self.hasCompletedOnboarding
        userData.notificationsEnabled = self.notificationsEnabled
        userData.audioQualityPreference = self.audioQualityPreference
        userData.activitySensitivity = self.activitySensitivity
        userData.learningGoals = self.learningGoals
        userData.practiceDays = self.practiceDays
        userData.dailyGoalMinutes = self.dailyGoalMinutes
        userData.totalConversationTime = self.totalConversationTime
        userData.conversationsCompleted = self.conversationsCompleted
        userData.currentStreak = self.currentStreak
        userData.longestStreak = self.longestStreak
        userData.totalXP = self.totalXP
        
        do {
            try modelContext.save()
            print("💾 UserDataManager: Saved user data for '\(currentUserId)'")
        } catch {
            print("❌ UserDataManager: Failed to save user data: \(error)")
        }
    }
    
    // MARK: - Account Data Management
    
    public func loadAccountData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load user account data
        userAccount.loadFromCurrentUser()
        
        // Load subscription status
        await loadSubscriptionStatus()
        
        // Load account settings from Firestore
        await loadAccountSettingsFromFirestore()
    }
    
    private func loadSubscriptionStatus() async {
        guard let storeKitManager = storeKitManager else { return }
        
        // First load StoreKit products
        await storeKitManager.loadProducts()
        
        // Check current subscription status
        let hasSubscription = await storeKitManager.checkSubscriptionStatusLocalFirst()
        
        // Check if user is developer or beta tester first
        if let userID = Auth.auth().currentUser?.uid {
            let isDeveloper = await checkIfDeveloper(userID: userID)
            let isBetaTester = await checkIfBetaTester(userID: userID)
            
            if isDeveloper {
                subscriptionStatus.updateFromStoreKit(
                    isActive: true,
                    tier: "developer",
                    expirationDate: nil,
                    isBillable: false,
                    environment: "developer"
                )
                return
            } else if isBetaTester {
                subscriptionStatus.updateFromStoreKit(
                    isActive: true,
                    tier: "betaTester",
                    expirationDate: nil,
                    isBillable: false,
                    environment: "beta"
                )
                return
            }
        }
        
        // Check StoreKit validation result
        if let validationResult = storeKitManager.lastValidationResult {
            subscriptionStatus.updateFromStoreKit(
                isActive: validationResult.isActive,
                tier: validationResult.tier?.rawValue,
                expirationDate: validationResult.expiresAt,
                isBillable: validationResult.isBillable,
                environment: validationResult.environment
            )
        } else if hasSubscription, let currentTier = storeKitManager.currentTier {
            subscriptionStatus.updateFromStoreKit(
                isActive: true,
                tier: currentTier.rawValue,
                expirationDate: nil,
                isBillable: true,
                environment: "production"
            )
        } else {
            // No active subscription - set to trial
            subscriptionStatus.updateFromStoreKit(
                isActive: false,
                tier: "trial",
                expirationDate: nil,
                isBillable: false,
                environment: "trial"
            )
        }
    }
    
    private func checkIfDeveloper(userID: String) async -> Bool {
        // Developer UIDs (matching those in functions/main.py)
        let developerUIDs = [
            "8PCckiIWlRP9IpUYkDTL1jDkIJz1",  // Main Developer
            // Add team members as needed
        ]
        return developerUIDs.contains(userID)
    }
    
    private func checkIfBetaTester(userID: String) async -> Bool {
        // Check if user is in beta tester list
        do {
            let document = try await db.collection("betaTesters").document(userID).getDocument()
            return document.exists
        } catch {
            print("Error checking beta tester status: \(error)")
            return false
        }
    }
    
    private func loadAccountSettingsFromFirestore() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("users").document(userID).collection("settings").document("account").getDocument()
            
            if document.exists, let data = document.data() {
                let decoder = JSONDecoder()
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let settings = try? decoder.decode(AccountSettings.self, from: jsonData) {
                    self.accountSettings = settings
                }
            }
        } catch {
            print("Error loading account settings: \(error)")
        }
    }
    
    private func loadAccountSettings() {
        // Load from local storage first for offline support
        if let data = UserDefaults.standard.data(forKey: "account_settings"),
           let settings = try? JSONDecoder().decode(AccountSettings.self, from: data) {
            self.accountSettings = settings
        }
    }
    
    private func resetAccountData() {
        userAccount = UserAccount()
        subscriptionStatus = SubscriptionStatus()
        accountSettings = AccountSettings()
    }
    
    // MARK: - Public Profile Methods
    
    public func saveProfile() {
        saveUserData()
    }
    
    public func updateConversationStats(duration: TimeInterval) {
        guard let userData = currentUserData else { return }
        
        userData.updateConversationStats(duration: duration)
        updatePublishedProperties(from: userData)
        saveUserData()
    }
    
    public func addXP(_ points: Int) {
        guard let userData = currentUserData else { return }
        
        userData.addXP(points)
        updatePublishedProperties(from: userData)
        saveUserData()
    }
    
    public func markOnboardingAsCompleted() {
        hasCompletedOnboarding = true
        saveUserData()
        print("✅ Onboarding marked as completed for current user")
    }
    
    // MARK: - Public Account Methods
    
    public func updateDisplayName(_ newName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await userAccount.updateDisplayName(newName)
            
            // Update in Firestore
            guard let userID = Auth.auth().currentUser?.uid else { return }
            try await db.collection("users").document(userID).updateData([
                "displayName": newName,
                "lastUpdated": FieldValue.serverTimestamp()
            ])
            
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    public func refreshSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadSubscriptionStatus()
    }
    
    public func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    public func updateAccountSettings(_ settings: AccountSettings) async {
        self.accountSettings = settings
        
        // Save locally for offline support
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "account_settings")
        }
        
        // Save to Firestore
        await saveAccountSettingsToFirestore(settings)
    }
    
    private func saveAccountSettingsToFirestore(_ settings: AccountSettings) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            try await db.collection("users").document(userID).collection("settings").document("account").setData(dictionary)
        } catch {
            print("Error saving account settings: \(error)")
        }
    }
    
    // MARK: - Data Export
    
    public func exportUserData() async throws -> URL {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UserDataError.noCurrentUser
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Collect all user data
            let userData = try await collectUserDataForExport(userID: userID)
            
            // Create JSON file
            let jsonData = try JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted)
            
            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("ConvAI_UserData_\(Date().timeIntervalSince1970).json")
            
            try jsonData.write(to: tempURL)
            
            return tempURL
        } catch {
            errorMessage = error.localizedDescription
            throw UserDataError.dataExportFailed
        }
    }
    
    private func collectUserDataForExport(userID: String) async throws -> [String: Any] {
        var userData: [String: Any] = [:]
        
        // Account information
        userData["account"] = [
            "userID": userAccount.userID,
            "email": userAccount.email,
            "displayName": userAccount.displayName,
            "authProvider": userAccount.authProvider.rawValue,
            "accountCreationDate": userAccount.accountCreationDate?.ISO8601Format() ?? "",
            "lastSignInDate": userAccount.lastSignInDate?.ISO8601Format() ?? ""
        ]
        
        // Subscription information
        userData["subscription"] = [
            "isActive": subscriptionStatus.isActive,
            "tier": subscriptionStatus.tier.rawValue,
            "expirationDate": subscriptionStatus.expirationDate?.ISO8601Format() ?? "",
            "lastUpdated": subscriptionStatus.lastUpdated.ISO8601Format()
        ]
        
        // Settings
        if let settingsData = try? JSONEncoder().encode(accountSettings),
           let settingsDict = try? JSONSerialization.jsonObject(with: settingsData) {
            userData["settings"] = settingsDict
        }
        
        // User profile data
        let userSnapshot = try await db.collection("users").document(userID).getDocument()
        if let userFirestoreData = userSnapshot.data() {
            userData["profile"] = userFirestoreData
        }
        
        // Conversation history (last 100 conversations for privacy)
        let conversationsSnapshot = try await db.collection("conversations")
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        let conversations = conversationsSnapshot.documents.map { $0.data() }
        userData["conversations"] = conversations
        
        userData["exportedAt"] = Date().ISO8601Format()
        userData["version"] = "1.0"
        
        return userData
    }
    
    // MARK: - Account Deletion
    
    public func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw UserDataError.noCurrentUser
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userID = user.uid
            
            // Delete user data from Firestore
            try await deleteUserDataFromFirestore(userID: userID)
            
            // Delete Firebase Auth account
            try await user.delete()
            
            // Clear local data completely (including onboarding status for fresh start)
            clearLocalDataForAccountDeletion()
            
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw UserDataError.accountDeletionFailed
        }
    }
    
    private func clearLocalDataForAccountDeletion() {
        // Clear ALL UserDefaults including onboarding completion
        UserDefaults.standard.removeObject(forKey: "account_settings")
        UserDefaults.standard.removeObject(forKey: "user_display_name")
        UserDefaults.standard.removeObject(forKey: "userProfile")
        
        // Clear onboarding completion so user can redo onboarding
        clearOnboardingCompletion()
        
        // Clear StoreKit cache
        storeKitManager?.clearSubscriptionCache()
        
        // Reset state
        resetAccountData()
        
        print("🗑️ Account deleted - all data cleared including onboarding status")
    }
    
    private func deleteUserDataFromFirestore(userID: String) async throws {
        let batch = db.batch()
        
        // Delete user profile
        let userRef = db.collection("users").document(userID)
        batch.deleteDocument(userRef)
        
        // Delete user settings
        let settingsSnapshot = try await db.collection("users").document(userID).collection("settings").getDocuments()
        for document in settingsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Delete user conversations
        let conversationsSnapshot = try await db.collection("conversations")
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        for document in conversationsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Commit batch deletion
        try await batch.commit()
    }
    
    // MARK: - Sign Out
    
    public func signOut() async throws {
        do {
            try Auth.auth().signOut()
            clearLocalDataForSignOut()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func clearLocalDataForSignOut() {
        // FOR SIGN OUT: Preserve onboarding completion status so user doesn't have to redo onboarding
        let hasCompletedOnboarding = hasUserCompletedOnboarding()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "account_settings")
        UserDefaults.standard.removeObject(forKey: "user_display_name")
        UserDefaults.standard.removeObject(forKey: "userProfile")
        
        // Restore onboarding completion status for sign out (not account deletion)
        if hasCompletedOnboarding {
            markOnboardingCompletedGlobally()
        }
        
        // Clear StoreKit cache
        storeKitManager?.clearSubscriptionCache()
        
        // Reset state
        resetAccountData()
        
        print("🚪 User signed out - onboarding status preserved")
    }
    
    // MARK: - Static Methods for Backward Compatibility
    
    public func hasUserCompletedOnboarding() -> Bool {
        return hasCompletedOnboarding
    }
    
    public func markOnboardingCompletedGlobally() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed_globally")
        print("✅ Onboarding completion handled by UserDataManager instance")
    }
    
    public func clearOnboardingCompletion() {
        UserDefaults.standard.removeObject(forKey: "onboarding_completed_globally")
        print("🗑️ Onboarding completion cleared")
    }
    
    public func clearCurrentAccountData() {
        guard let modelContext = modelContext, let userData = currentUserData else { return }
        
        modelContext.delete(userData)
        
        do {
            try modelContext.save()
            self.currentUserData = nil
            createNewUserData()
            print("🗑️ UserDataManager: Cleared all data for current user")
        } catch {
            print("❌ UserDataManager: Failed to clear user data: \(error)")
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    private func migrateFromUserDefaults() {
        guard !UserDefaults.standard.bool(forKey: "swiftdata_migration_completed") else { return }
        
        // Migration will happen when modelContext is available
        print("📦 UserDataManager: Migration from UserDefaults scheduled")
    }
    
    private func performMigrationIfNeeded() {
        guard modelContext != nil else { return }
        guard !UserDefaults.standard.bool(forKey: "swiftdata_migration_completed") else { return }
        
        print("📦 UserDataManager: Starting migration from UserDefaults to SwiftData")
        
        // Check if we have legacy data
        if let legacyData = UserDefaults.standard.data(forKey: "userProfile"),
           let legacyProfile = try? JSONDecoder().decode(UserProfileData.self, from: legacyData) {
            
            // Create or update user data with legacy values
            if let userData = currentUserData {
                userData.name = legacyProfile.name
                userData.preferredLanguage = legacyProfile.preferredLanguage ?? "en-US"
                userData.languageLevel = legacyProfile.languageLevel ?? "beginner"
                userData.preferredVoice = legacyProfile.preferredVoice
                userData.gender = legacyProfile.gender
                userData.isSetup = legacyProfile.isSetup
                userData.hasCompletedOnboarding = legacyProfile.hasCompletedOnboarding
                userData.notificationsEnabled = legacyProfile.notificationsEnabled
                userData.audioQualityPreference = legacyProfile.audioQualityPreference
                userData.activitySensitivity = legacyProfile.activitySensitivity
                userData.learningGoals = legacyProfile.learningGoals
                userData.practiceDays = legacyProfile.practiceDays
                userData.dailyGoalMinutes = legacyProfile.dailyGoalMinutes
                userData.totalConversationTime = legacyProfile.totalConversationTime
                userData.conversationsCompleted = legacyProfile.conversationsCompleted
                userData.currentStreak = legacyProfile.currentStreak
                userData.longestStreak = legacyProfile.longestStreak
                userData.totalXP = legacyProfile.totalXP
                userData.migrationCompleted = true
                
                updatePublishedProperties(from: userData)
                saveUserData()
                
                print("✅ UserDataManager: Migrated legacy data to SwiftData")
            }
        }
        
        // Mark migration as completed
        UserDefaults.standard.set(true, forKey: "swiftdata_migration_completed")
        print("✅ UserDataManager: Migration completed")
    }
}

// MARK: - Error Types

public enum UserDataError: Error, LocalizedError {
    case noCurrentUser
    case displayNameUpdateFailed
    case subscriptionUpdateFailed
    case dataExportFailed
    case accountDeletionFailed
    
    public var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No user is currently signed in"
        case .displayNameUpdateFailed:
            return "Failed to update display name"
        case .subscriptionUpdateFailed:
            return "Failed to update subscription status"
        case .dataExportFailed:
            return "Failed to export user data"
        case .accountDeletionFailed:
            return "Failed to delete account"
        }
    }
}

// MARK: - Legacy Data Structure for Migration

private struct UserProfileData: Codable {
    let name: String
    let preferredLanguage: String?
    let languageLevel: String?
    let preferredVoice: String
    let gender: String?
    let isSetup: Bool
    let hasCompletedOnboarding: Bool
    let notificationsEnabled: Bool
    let audioQualityPreference: String
    let activitySensitivity: String
    let learningGoals: [String]
    let practiceDays: [String]
    let dailyGoalMinutes: Int
    let totalConversationTime: TimeInterval
    let conversationsCompleted: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalXP: Int
}
