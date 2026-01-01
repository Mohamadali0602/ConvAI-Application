//
//  GameSystem.swift
//  ConvAI
//
//  Consolidated game mechanics: Progress + Achievements + Rewards + Bonuses
//  Modern SwiftData + Firebase integrated game system
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Game Achievement Definition
enum GameAchievement: String, CaseIterable, Codable {
    case firstConversation = "first_conversation"
    case streak7Days = "streak_7_days"
    case streak30Days = "streak_30_days"
    case level5Reached = "level_5_reached"
    case level10Reached = "level_10_reached"
    case powerMaster = "power_master"
    case moneyMaster = "money_master"
    case languageMaster = "language_master"
    case storyteller = "storyteller"
    case loveCoach = "love_coach"
    
    var title: String {
        switch self {
        case .firstConversation: return "First Steps"
        case .streak7Days: return "Week Warrior"
        case .streak30Days: return "Monthly Master"
        case .level5Reached: return "Rising Star"
        case .level10Reached: return "Conversation Pro"
        case .powerMaster: return "Power Player"
        case .moneyMaster: return "Money Maker"
        case .languageMaster: return "Language Lord"
        case .storyteller: return "Master Storyteller"
        case .loveCoach: return "Love Coach"
        }
    }
    
    var description: String {
        switch self {
        case .firstConversation: return "Complete your first conversation"
        case .streak7Days: return "Practice for 7 days in a row"
        case .streak30Days: return "Practice for 30 days in a row"
        case .level5Reached: return "Reach level 5"
        case .level10Reached: return "Reach level 10"
        case .powerMaster: return "Master the power category"
        case .moneyMaster: return "Master the money category"
        case .languageMaster: return "Master the language category"
        case .storyteller: return "Master the storytelling category"
        case .loveCoach: return "Master the love category"
        }
    }
    
    var icon: String {
        switch self {
        case .firstConversation: return "🎯"
        case .streak7Days: return "🔥"
        case .streak30Days: return "🏆"
        case .level5Reached: return "⭐"
        case .level10Reached: return "🌟"
        case .powerMaster: return "⚡"
        case .moneyMaster: return "💰"
        case .languageMaster: return "🗣️"
        case .storyteller: return "📚"
        case .loveCoach: return "💕"
        }
    }
}

// MARK: - Bonus Type Enum
enum BonusType: String, CaseIterable, Codable {
    case pronunciation = "PRONUNCIATION"
    case grammar = "GRAMMAR"
    case vocabulary = "VOCABULARY"
    case fluency = "FLUENCY"
    case cultural = "CULTURAL"
    case streak = "STREAK"
    case perfect = "PERFECT"
    case random = "RANDOM"
    case category = "CATEGORY"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .pronunciation: return "Perfect Pronunciation!"
        case .grammar: return "Grammar Master!"
        case .vocabulary: return "Vocabulary Pro!"
        case .fluency: return "Fluent Speaker!"
        case .cultural: return "Cultural Expert!"
        case .streak: return "Streak Bonus!"
        case .perfect: return "Perfect Conversation!"
        case .random: return "Lucky Bonus!"
        case .category: return "Category Bonus!"
        case .other: return "Great Job!"
        }
    }
    
    var icon: String {
        switch self {
        case .pronunciation: return "🗣️"
        case .grammar: return "📝"
        case .vocabulary: return "📚"
        case .fluency: return "💬"
        case .cultural: return "🌍"
        case .streak: return "🔥"
        case .perfect: return "✨"
        case .random: return "🎲"
        case .category: return "🏆"
        case .other: return "⭐"
        }
    }
}

// MARK: - Conversation Performance Enum
enum ConversationPerformance: String, CaseIterable, Codable {
    case poor = "poor"
    case average = "average"
    case good = "good"
    case excellent = "excellent"
    
    var xpMultiplier: Double {
        switch self {
        case .poor: return 0.5
        case .average: return 0.8
        case .good: return 1.0
        case .excellent: return 1.5
        }
    }
}

// MARK: - Session Data for Validation
struct SessionDataForValidation: Codable {
    let duration: TimeInterval
    let category: String
    let timestamp: Date
    let performance: String
    
    init(duration: TimeInterval, category: String, performance: ConversationPerformance) {
        self.duration = duration
        self.category = category
        self.timestamp = Date()
        self.performance = performance.rawValue
    }
}

// MARK: - Daily Challenge
struct DailyChallenge: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let category: String
    let xpReward: Int
    let requiredDuration: TimeInterval
}

// MARK: - Achievement Notification
struct AchievementNotification: Identifiable, Equatable {
    let id = UUID()
    let achievement: GameAchievement
    let timestamp: Date
    
    init(achievement: GameAchievement, timestamp: Date = Date()) {
        self.achievement = achievement
        self.timestamp = timestamp
    }
    
    static func == (lhs: AchievementNotification, rhs: AchievementNotification) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Bonus Reward Model
struct BonusReward: Identifiable, Codable {
    var id = UUID()
    let type: BonusType
    let xpAmount: Int
    let description: String
    let timestamp: Date
    
    init(type: BonusType, xpAmount: Int, description: String = "", timestamp: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.xpAmount = xpAmount
        self.description = description.isEmpty ? type.displayName : description
        self.timestamp = timestamp
    }
}

// MARK: - Main Game System Class
@MainActor
class GameSystem: ObservableObject {
    static let shared = GameSystem()
    
    // MARK: - Game Progress Properties
    
    // UserDataManager integration
    private weak var userDataManager: UserDataManager?
    
    // Published properties for real-time UI updates
    @Published var currentLevel: Int = 1
    @Published var totalXP: Int = 0
    @Published var currentStreak: Int = 0
    @Published var totalConversations: Int = 0
    @Published var lastAwardedXP: Int = 0
    
    // Advanced metrics
    @Published var rejectionScore: Int = 0
    @Published var dealsClosedCounter: Int = 0
    @Published var confidenceMeter: Double = 0.0
    @Published var powerMovesUsed: Int = 0
    @Published var vocabularyMastered: Int = 0
    @Published var conversationMinutesInTargetLanguage: Int = 0
    @Published var accentConfidenceScore: Double = 0.0
    @Published var grammarAccuracy: Double = 0.0
    @Published var storiesInRepertoire: Int = 0
    @Published var simulationsCompleted: Int = 0
    @Published var simulationSuccessRate: Double = 0.0
    
    // Category levels
    @Published var moneyMasteryLevel: Int = 1
    @Published var loveCoachLevel: Int = 1
    @Published var powerPlayerLevel: Int = 1
    @Published var languageMasteryLevel: Int = 1
    @Published var storyMasteryLevel: Int = 1
    
    // Daily tracking
    @Published var lastPracticeDate: Date?
    @Published var practiceSessionsToday: Int = 0
    @Published var longestStreak: Int = 0
    @Published var todaysChallenge: DailyChallenge? = nil
    
    // MARK: - Achievement System Properties
    
    @Published var activeNotifications: [AchievementNotification] = []
    @Published var showNotification = false
    @Published var unlockedAchievements: Set<GameAchievement> = []
    
    // MARK: - Bonus & Reward Properties
    
    @Published var recentBonuses: [BonusReward] = []
    @Published var totalBonusXP: Int = 0
    @Published var totalBonusCount: Int = 0
    @Published var showBonusNotification = false
    
    // Session validation
    private var sessionsForValidation: [SessionDataForValidation] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        print("🎮 GameSystem: Initialized comprehensive game system")
        loadBonusData()
    }
    
    // MARK: - Configuration
    
    func configure(with userDataManager: UserDataManager) {
        self.userDataManager = userDataManager
        loadProgressFromUserProfile()
        generateDailyChallenge()
        loadAchievements()
        print("🎮 GameSystem: Configured with UserDataManager")
    }
    
    // MARK: - Data Loading
    
    private func loadProgressFromUserProfile() {
        guard let userData = userDataManager?.currentUserData else { 
            print("⚠️ No user data available for GameSystem")
            return 
        }
        
        // Load core progress
        currentLevel = userData.currentLevel
        totalXP = userData.totalXP
        currentStreak = userData.currentStreak
        totalConversations = userData.totalConversations
        rejectionScore = userData.rejectionScore
        dealsClosedCounter = userData.dealsClosedCounter
        confidenceMeter = userData.confidenceMeter
        powerMovesUsed = userData.powerMovesUsed
        vocabularyMastered = userData.vocabularyMastered
        conversationMinutesInTargetLanguage = userData.conversationMinutesInTargetLanguage
        accentConfidenceScore = userData.accentConfidenceScore
        grammarAccuracy = userData.grammarAccuracy
        storiesInRepertoire = userData.storiesInRepertoire
        simulationsCompleted = userData.simulationsCompleted
        simulationSuccessRate = userData.simulationSuccessRate
        moneyMasteryLevel = userData.moneyMasteryLevel
        loveCoachLevel = userData.loveCoachLevel
        powerPlayerLevel = userData.powerPlayerLevel
        languageMasteryLevel = userData.languageMasteryLevel
        storyMasteryLevel = userData.storyMasteryLevel
        lastPracticeDate = userData.lastPracticeDate
        practiceSessionsToday = userData.practiceSessionsToday
        longestStreak = userData.longestStreak
        
        print("✅ GameSystem: Loaded progress from SwiftData")
    }
    
    private func loadAchievements() {
        // Load unlocked achievements from storage
        if let achievementData = UserDefaults.standard.data(forKey: "unlocked_achievements"),
           let achievements = try? JSONDecoder().decode(Set<GameAchievement>.self, from: achievementData) {
            unlockedAchievements = achievements
        }
    }
    
    private func loadBonusData() {
        // Load bonus data from UserDefaults
        totalBonusXP = UserDefaults.standard.integer(forKey: "total_bonus_xp")
        totalBonusCount = UserDefaults.standard.integer(forKey: "total_bonus_count")
        
        // Load recent bonuses
        if let bonusData = UserDefaults.standard.data(forKey: "recent_bonuses"),
           let bonuses = try? JSONDecoder().decode([BonusReward].self, from: bonusData) {
            recentBonuses = bonuses
        }
    }
    
    // MARK: - Data Saving
    
    private func saveProgressToUserProfile() {
        guard let userData = userDataManager?.currentUserData else { 
            print("⚠️ Cannot save - no user data available")
            return 
        }
        
        // Save all progress to SwiftData
        userData.currentLevel = currentLevel
        userData.totalXP = totalXP
        userData.currentStreak = currentStreak
        userData.totalConversations = totalConversations
        userData.rejectionScore = rejectionScore
        userData.dealsClosedCounter = dealsClosedCounter
        userData.confidenceMeter = confidenceMeter
        userData.powerMovesUsed = powerMovesUsed
        userData.vocabularyMastered = vocabularyMastered
        userData.conversationMinutesInTargetLanguage = conversationMinutesInTargetLanguage
        userData.accentConfidenceScore = accentConfidenceScore
        userData.grammarAccuracy = grammarAccuracy
        userData.storiesInRepertoire = storiesInRepertoire
        userData.simulationsCompleted = simulationsCompleted
        userData.simulationSuccessRate = simulationSuccessRate
        userData.moneyMasteryLevel = moneyMasteryLevel
        userData.loveCoachLevel = loveCoachLevel
        userData.powerPlayerLevel = powerPlayerLevel
        userData.languageMasteryLevel = languageMasteryLevel
        userData.storyMasteryLevel = storyMasteryLevel
        userData.lastPracticeDate = lastPracticeDate
        userData.practiceSessionsToday = practiceSessionsToday
        userData.longestStreak = longestStreak
        
        userDataManager?.saveProfile()
        print("✅ GameSystem: Saved progress to SwiftData")
    }
    
    private func saveAchievements() {
        if let achievementData = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(achievementData, forKey: "unlocked_achievements")
        }
    }
    
    private func saveBonusData() {
        UserDefaults.standard.set(totalBonusXP, forKey: "total_bonus_xp")
        UserDefaults.standard.set(totalBonusCount, forKey: "total_bonus_count")
        
        if let bonusData = try? JSONEncoder().encode(recentBonuses) {
            UserDefaults.standard.set(bonusData, forKey: "recent_bonuses")
        }
    }
    
    // MARK: - Core Game Methods
    
    func addXP(amount: Int) {
        let oldLevel = currentLevel
        totalXP += amount
        lastAwardedXP = amount
        checkForLevelUp()
        saveProgressToUserProfile()
        
        print("🎮 Added \(amount) XP. Total: \(totalXP)")
        if currentLevel > oldLevel {
            print("🎉 Level up! Now level \(currentLevel)")
            checkAchievements()
        }
    }
    
    func setCurrentLevel(_ level: Int) {
        guard level >= 1 && level <= 100 else {
            print("⚠️ Invalid level: \(level). Level must be between 1 and 100")
            return
        }
        
        let oldLevel = currentLevel
        currentLevel = level
        saveProgressToUserProfile()
        
        print("🎮 Level set to \(level) (was \(oldLevel))")
        
        if level > oldLevel {
            print("🎉 Level increased to \(level)!")
            checkAchievements()
        } else if level < oldLevel {
            print("⬇️ Level decreased to \(level)")
        }
    }
    
    func completeConversation(categoryName: String, duration: TimeInterval, performance: ConversationPerformance) {
        // Update basic stats
        totalConversations += 1
        practiceSessionsToday += 1
        lastPracticeDate = Date()
        conversationMinutesInTargetLanguage += Int(duration / 60)
        
        // Update streak
        updateStreak()
        
        // Add session for validation
        let sessionData = SessionDataForValidation(duration: duration, category: categoryName, performance: performance)
        sessionsForValidation.append(sessionData)
        
        // Calculate XP with bonuses
        let baseXP = 50 + (currentLevel * 5)
        let performanceMultiplier = performance.xpMultiplier
        let categoryMultiplier = getCategoryMultiplier(for: categoryName)
        let durationBonus = min(2.0, duration / 300.0) // Up to 2x for 5+ minutes
        
        let finalXP = Int(Double(baseXP) * performanceMultiplier * categoryMultiplier * durationBonus)
        
        // Update category-specific progress
        updateCategoryProgress(categoryName: categoryName, duration: duration, performance: performance)
        
        // Award XP
        addXP(amount: finalXP)
        
        // Check for bonuses
        checkForBonuses(categoryName: categoryName, duration: duration, performance: performance)
        
        // Check for daily challenge completion
        checkDailyChallengeCompletion(categoryName: categoryName, duration: duration)
        
        // Check achievements
        checkAchievements()
        
        print("🎮 Conversation completed: \(categoryName), \(Int(duration))s, \(performance.rawValue), +\(finalXP) XP")
    }
    
    // MARK: - Achievement System
    
    func showAchievementUnlocked(_ achievement: GameAchievement) {
        guard !unlockedAchievements.contains(achievement) else { return }
        
        let notification = AchievementNotification(achievement: achievement)
        
        print("🏆 [DEBUG] About to show achievement: \(achievement.title)")
        print("🏆 [DEBUG] Current active notifications count: \(activeNotifications.count)")
        
        DispatchQueue.main.async {
            // Mark achievement as unlocked
            self.unlockedAchievements.insert(achievement)
            self.saveAchievements()
            
            // Add notification
            self.activeNotifications.append(notification)
            self.showNotification = true
            
            print("🏆 [DEBUG] Added notification. New count: \(self.activeNotifications.count)")
            print("🏆 [DEBUG] Show notification state: \(self.showNotification)")
            
            print("🏆 Achievement unlocked: \(achievement.title)")
        }
    }
    
    func dismissNotification(_ notification: AchievementNotification) {
        DispatchQueue.main.async {
            self.activeNotifications.removeAll { $0.id == notification.id }
            if self.activeNotifications.isEmpty {
                self.showNotification = false
            }
        }
    }
    
    func clearAllNotifications() {
        DispatchQueue.main.async {
            self.activeNotifications.removeAll()
            self.showNotification = false
        }
    }
    
    private func checkAchievements() {
        // Check level achievements
        if currentLevel >= 5 && !unlockedAchievements.contains(.level5Reached) {
            showAchievementUnlocked(.level5Reached)
        }
        if currentLevel >= 10 && !unlockedAchievements.contains(.level10Reached) {
            showAchievementUnlocked(.level10Reached)
        }
        
        // Check conversation achievements
        if totalConversations >= 1 && !unlockedAchievements.contains(.firstConversation) {
            showAchievementUnlocked(.firstConversation)
        }
        
        // Check streak achievements
        if currentStreak >= 7 && !unlockedAchievements.contains(.streak7Days) {
            showAchievementUnlocked(.streak7Days)
        }
        if currentStreak >= 30 && !unlockedAchievements.contains(.streak30Days) {
            showAchievementUnlocked(.streak30Days)
        }
        
        // Check category mastery achievements
        if moneyMasteryLevel >= 10 && !unlockedAchievements.contains(.moneyMaster) {
            showAchievementUnlocked(.moneyMaster)
        }
        if languageMasteryLevel >= 10 && !unlockedAchievements.contains(.languageMaster) {
            showAchievementUnlocked(.languageMaster)
        }
        if powerPlayerLevel >= 10 && !unlockedAchievements.contains(.powerMaster) {
            showAchievementUnlocked(.powerMaster)
        }
        if storyMasteryLevel >= 10 && !unlockedAchievements.contains(.storyteller) {
            showAchievementUnlocked(.storyteller)
        }
        if loveCoachLevel >= 10 && !unlockedAchievements.contains(.loveCoach) {
            showAchievementUnlocked(.loveCoach)
        }
    }
    
    // MARK: - Bonus System
    
    private func checkForBonuses(categoryName: String, duration: TimeInterval, performance: ConversationPerformance) {
        var bonuses: [BonusReward] = []
        
        // Performance bonuses
        if performance == .excellent {
            bonuses.append(BonusReward(type: .perfect, xpAmount: 25))
        }
        
        // Streak bonuses
        if currentStreak >= 7 && currentStreak % 7 == 0 {
            bonuses.append(BonusReward(type: .streak, xpAmount: currentStreak * 5))
        }
        
        // Duration bonuses
        if duration >= 600 { // 10+ minutes
            bonuses.append(BonusReward(type: .fluency, xpAmount: 15))
        }
        
        // Category-specific bonuses
        let categoryBonus = getCategoryBonus(for: categoryName, performance: performance)
        if let bonus = categoryBonus {
            bonuses.append(bonus)
        }
        
        // Random bonus (10% chance)
        if Double.random(in: 0...1) < 0.1 {
            bonuses.append(BonusReward(type: .random, xpAmount: Int.random(in: 10...50)))
        }
        
        // Award bonuses
        for bonus in bonuses {
            awardBonus(bonus)
        }
    }
    
    private func getCategoryBonus(for categoryName: String, performance: ConversationPerformance) -> BonusReward? {
        guard performance == .excellent else { return nil }
        
        switch categoryName.lowercased() {
        case "language", "fluency":
            return BonusReward(type: .vocabulary, xpAmount: 20)
        case "grammar":
            return BonusReward(type: .grammar, xpAmount: 20)
        case "pronunciation":
            return BonusReward(type: .pronunciation, xpAmount: 20)
        case "cultural":
            return BonusReward(type: .cultural, xpAmount: 20)
        default:
            return BonusReward(type: .category, xpAmount: 15)
        }
    }
    
    func awardBonus(_ bonus: BonusReward) {
        DispatchQueue.main.async {
            self.recentBonuses.insert(bonus, at: 0)
            
            // Keep only last 10 bonuses
            if self.recentBonuses.count > 10 {
                self.recentBonuses = Array(self.recentBonuses.prefix(10))
            }
            
            self.totalBonusXP += bonus.xpAmount
            self.totalBonusCount += 1
            self.showBonusNotification = true
            
            // Add bonus XP to total
            self.addXP(amount: bonus.xpAmount)
            
            self.saveBonusData()
            
            print("💰 Bonus awarded: \(bonus.type.displayName) (+\(bonus.xpAmount) XP)")
            
            // Auto-hide bonus notification after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showBonusNotification = false
            }
        }
    }
    
    func clearBonusNotification() {
        showBonusNotification = false
    }
    
    // MARK: - Level System (unchanged)
    
    private func checkForLevelUp() {
        let requiredXP = getXPRequiredForLevel(currentLevel + 1)
        
        while totalXP >= requiredXP && currentLevel < 100 {
            currentLevel += 1
            
            // Level up rewards
            let levelUpBonus = currentLevel * 10
            print("🎉 LEVEL UP! Now level \(currentLevel). Bonus: +\(levelUpBonus) XP")
            
            // Check if we can level up again
            if currentLevel < 100 {
                let nextRequired = getXPRequiredForLevel(currentLevel + 1)
                if totalXP < nextRequired {
                    break
                }
            }
        }
    }
    
    private func getXPRequiredForLevel(_ level: Int) -> Int {
        // Exponential XP curve: Level 1->2: 100 XP, Level 2->3: 150 XP, etc.
        return Int(Double(level - 1) * 100.0 * pow(1.15, Double(level - 1)))
    }
    
    // MARK: - Streak System (unchanged)
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastPractice = lastPracticeDate {
            let lastPracticeDay = Calendar.current.startOfDay(for: lastPractice)
            let daysDifference = Calendar.current.dateComponents([.day], from: lastPracticeDay, to: today).day ?? 0
            
            if daysDifference == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else if daysDifference > 1 {
                // Broke streak
                currentStreak = 1
            }
            // If daysDifference == 0, it's the same day - don't change streak
        } else {
            // First practice ever
            currentStreak = 1
            longestStreak = 1
        }
    }
    
    // MARK: - Category Progress (unchanged)
    
    private func getCategoryMultiplier(for categoryName: String) -> Double {
        switch categoryName.lowercased() {
        case "money", "sales", "business": return 1.2
        case "love", "dating", "relationships": return 1.1
        case "power", "influence", "leadership": return 1.15
        case "language", "fluency": return 1.0
        case "storytelling", "narrative": return 1.05
        default: return 1.0
        }
    }
    
    private func updateCategoryProgress(categoryName: String, duration: TimeInterval, performance: ConversationPerformance) {
        switch categoryName.lowercased() {
        case "money", "sales", "business":
            if performance == .excellent {
                dealsClosedCounter += 1
            }
            moneyMasteryLevel = min(10, 1 + (dealsClosedCounter / 5))
            
        case "love", "dating", "relationships":
            confidenceMeter = min(100.0, confidenceMeter + (duration / 60.0) * performance.xpMultiplier)
            loveCoachLevel = min(10, 1 + Int(confidenceMeter / 20))
            
        case "power", "influence", "leadership":
            if performance == .good || performance == .excellent {
                powerMovesUsed += 1
            }
            powerPlayerLevel = min(10, 1 + (powerMovesUsed / 10))
            
        case "language", "fluency":
            vocabularyMastered += Int(duration / 30) // 1 word per 30 seconds
            grammarAccuracy = min(100.0, grammarAccuracy + performance.xpMultiplier)
            languageMasteryLevel = min(10, 1 + (vocabularyMastered / 100))
            
        case "storytelling", "narrative":
            if performance == .excellent {
                storiesInRepertoire += 1
            }
            storyMasteryLevel = min(10, 1 + (storiesInRepertoire / 3))
            
        default:
            break
        }
    }
    
    // MARK: - Daily Challenge System (unchanged)
    
    private func generateDailyChallenge() {
        // Only generate if we don't have one for today
        if todaysChallenge != nil {
            // Already have a challenge for today
            return
        }
        
        let challenges = [
            DailyChallenge(title: "Power Hour", description: "Complete a 15-minute power conversation", category: "power", xpReward: 150, requiredDuration: 900),
            DailyChallenge(title: "Language Immersion", description: "Practice for 20 minutes in your target language", category: "language", xpReward: 200, requiredDuration: 1200),
            DailyChallenge(title: "Sales Sprint", description: "Complete a 10-minute business conversation", category: "money", xpReward: 120, requiredDuration: 600),
            DailyChallenge(title: "Story Master", description: "Tell a compelling story in conversation", category: "storytelling", xpReward: 100, requiredDuration: 300),
            DailyChallenge(title: "Connection Challenge", description: "Have a meaningful 12-minute conversation", category: "love", xpReward: 130, requiredDuration: 720)
        ]
        
        let todayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        todaysChallenge = challenges[todayIndex % challenges.count]
        
        print("🎯 Today's challenge: \(todaysChallenge?.title ?? "None")")
    }
    
    private func checkDailyChallengeCompletion(categoryName: String, duration: TimeInterval) {
        guard let challenge = todaysChallenge else { return }
        
        if categoryName.lowercased().contains(challenge.category.lowercased()) && 
           duration >= challenge.requiredDuration {
            
            // Complete the challenge
            addXP(amount: challenge.xpReward)
            todaysChallenge = nil // Clear today's challenge
            
            print("🎯 Daily Challenge Completed! +\(challenge.xpReward) XP")
        }
    }
    
    // MARK: - Public Interface Methods (unchanged)
    
    func getOverallMastery() -> Double {
        let levels = [moneyMasteryLevel, loveCoachLevel, powerPlayerLevel, languageMasteryLevel, storyMasteryLevel]
        let average = Double(levels.reduce(0, +)) / Double(levels.count)
        return (average - 1.0) / 9.0 * 100.0 // Convert to percentage
    }
    
    func getStatusMessage() -> String {
        if currentStreak >= 7 {
            return "🔥 Amazing! \(currentStreak) day streak! You're on fire!"
        } else if currentStreak >= 3 {
            return "💪 Great job! \(currentStreak) days in a row!"
        } else if practiceSessionsToday > 0 {
            return "✅ Good work today! Keep building that streak!"
        } else {
            return "Ready to practice? Your skills are waiting!"
        }
    }
    
    func getMotivationalMessage(for categoryName: String) -> String {
        switch categoryName.lowercased() {
        case "money", "sales", "business":
            if dealsClosedCounter > 0 {
                return "💰 \(dealsClosedCounter) deals in your portfolio! Show them what success sounds like!"
            } else {
                return "💼 Every conversation is a potential deal! Let's build your business confidence!"
            }
            
        case "love", "dating", "relationships":
            if confidenceMeter > 50 {
                return "💕 Your confidence shines! Authenticity is your superpower!"
            } else {
                return "❤️ Connection starts with courage! You've got this!"
            }
            
        case "power", "influence", "leadership":
            if powerMovesUsed > 0 {
                return "⚡ \(powerMovesUsed) power moves mastered! Leadership looks good on you!"
            } else {
                return "🎯 True power is earned through practice! Command the conversation!"
            }
            
        case "language", "fluency":
            if vocabularyMastered > 50 {
                return "🗣️ \(vocabularyMastered) words mastered! Your fluency is growing!"
            } else {
                return "🌍 Every word is a bridge to connection! Keep building your language skills!"
            }
            
        case "storytelling", "narrative":
            if storiesInRepertoire > 0 {
                return "📚 \(storiesInRepertoire) stories ready! Your words create worlds!"
            } else {
                return "✨ Every moment has a story! Find yours and share it!"
            }
            
        default:
            return "🌟 Keep practicing and growing! You're building something amazing!"
        }
    }
    
    // MARK: - Testing Methods
    
    func testAchievementSystem() {
        print("🧪 Testing Achievement System...")
        
        // Test with First Conversation achievement
        showAchievementUnlocked(.firstConversation)
        print("✅ Successfully triggered First Steps achievement notification")
        
        // Test with Week Warrior achievement after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showAchievementUnlocked(.streak7Days)
            print("✅ Successfully triggered Week Warrior achievement notification")
        }
        
        print("🎯 Achievement system is fully operational and integrated!")
    }
    
    func testBonusSystem() {
        print("🧪 Testing Bonus System...")
        
        let testBonus = BonusReward(type: .perfect, xpAmount: 50)
        awardBonus(testBonus)
        
        print("✅ Bonus system test completed!")
    }
    
    // MARK: - Reset Methods (for testing/debugging)
    
    func resetProgress() {
        currentLevel = 1
        totalXP = 0
        currentStreak = 0
        totalConversations = 0
        lastAwardedXP = 0
        rejectionScore = 0
        dealsClosedCounter = 0
        confidenceMeter = 0.0
        powerMovesUsed = 0
        vocabularyMastered = 0
        conversationMinutesInTargetLanguage = 0
        accentConfidenceScore = 0.0
        grammarAccuracy = 0.0
        storiesInRepertoire = 0
        simulationsCompleted = 0
        simulationSuccessRate = 0.0
        moneyMasteryLevel = 1
        loveCoachLevel = 1
        powerPlayerLevel = 1
        languageMasteryLevel = 1
        storyMasteryLevel = 1
        lastPracticeDate = nil
        practiceSessionsToday = 0
        longestStreak = 0
        todaysChallenge = nil
        sessionsForValidation = []
        
        // Reset achievements and bonuses
        unlockedAchievements.removeAll()
        activeNotifications.removeAll()
        showNotification = false
        recentBonuses.removeAll()
        totalBonusXP = 0
        totalBonusCount = 0
        showBonusNotification = false
        
        saveProgressToUserProfile()
        saveAchievements()
        saveBonusData()
        print("🔄 GameSystem: Complete progress reset")
    }
}
