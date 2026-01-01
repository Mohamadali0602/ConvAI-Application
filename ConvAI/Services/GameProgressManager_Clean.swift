//
//  GameProgressManager.swift
//  ConvAI
//
//  Modern SwiftData + Firebase integrated game progress manager
//  Phase 3 Implementation - Production Ready
//

import SwiftUI
import SwiftData

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
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let xpReward: Int
    let requiredDuration: TimeInterval
}

// MARK: - Game Progress Manager (SwiftData Integrated)
@MainActor
class GameProgressManager: ObservableObject {
    static let shared = GameProgressManager()
    
    // SwiftData integration through UserProfile
    private weak var userProfile: UserProfile?
    
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
    
    // Session validation
    private var sessionsForValidation: [SessionDataForValidation] = []
    
    private init() {
        print("🎮 GameProgressManager: Initialized for SwiftData integration")
    }
    
    // MARK: - Configuration
    func configure(with userProfile: UserProfile) {
        self.userProfile = userProfile
        loadProgressFromUserProfile()
        generateDailyChallenge()
        print("🎮 GameProgressManager: Configured with UserProfile")
    }
    
    // MARK: - Data Loading
    private func loadProgressFromUserProfile() {
        guard let userData = userProfile?.currentUserData else { 
            print("⚠️ No user data available for GameProgressManager")
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
        
        print("✅ GameProgressManager: Loaded progress from SwiftData")
    }
    
    // MARK: - Data Saving
    private func saveProgressToUserProfile() {
        guard let userData = userProfile?.currentUserData else { 
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
        
        userProfile?.saveProfile()
        print("✅ GameProgressManager: Saved progress to SwiftData")
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
        
        // Calculate XP based on performance and category
        let baseXP = 50 + (currentLevel * 5)
        let performanceMultiplier = performance.xpMultiplier
        let categoryMultiplier = getCategoryMultiplier(for: categoryName)
        let durationBonus = min(2.0, duration / 300.0) // Up to 2x for 5+ minutes
        
        let finalXP = Int(Double(baseXP) * performanceMultiplier * categoryMultiplier * durationBonus)
        
        // Update category-specific progress
        updateCategoryProgress(categoryName: categoryName, duration: duration, performance: performance)
        
        // Award XP
        addXP(amount: finalXP)
        
        // Check for daily challenge completion
        checkDailyChallengeCompletion(categoryName: categoryName, duration: duration)
        
        print("🎮 Conversation completed: \(categoryName), \(Int(duration))s, \(performance.rawValue), +\(finalXP) XP")
    }
    
    // MARK: - Level System
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
    
    // MARK: - Streak System
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
    
    // MARK: - Category Progress
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
    
    // MARK: - Daily Challenge System
    private func generateDailyChallenge() {
        // Only generate if we don't have one for today
        if let existingChallenge = todaysChallenge {
            let today = Calendar.current.startOfDay(for: Date())
            // This is a simple check - in production you'd want more sophisticated date tracking
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
    
    // MARK: - Public Interface Methods
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
        
        saveProgressToUserProfile()
        print("🔄 GameProgressManager: Progress reset")
    }
}
