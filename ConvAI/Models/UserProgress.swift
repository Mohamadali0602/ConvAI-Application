//
//  UserProgress.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import Foundation

// MARK: - User Progress Data Model
struct UserProgress: Codable {
    var id: String = UUID().uuidString
    var userId: String
    var createdAt: Date = Date()
    var lastUpdated: Date = Date()
    
    // Assessment Results
    var targetLanguage: String = ""
    var targetLanguageCode: String = ""
    var discoverySource: String = ""
    var currentLevel: Int = 1
    var learningGoal: String = ""
    var dailyTimeCommitment: String = ""
    var estimatedWordsPerWeek: Int = 0
    
    // Progress Tracking
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var conversationsCompleted: Int = 0
    var totalMinutesPracticed: Int = 0
    
    // Level Progression
    var currentUserLevel: Int = 1
    var unlockedLevels: [Int] = [1]
    var completedTopics: [String] = []
    
    // Daily Goals
    var dailyGoalMinutes: Int = 5
    var dailyGoalConversations: Int = 1
    var lastPracticeDate: Date?
    
    // Achievements
    var unlockedAchievements: [String] = []
    var achievementProgress: [String: Int] = [:]
    
    // Statistics
    var averageSessionLength: Double = 0.0
    var favoriteTopics: [String] = []
    var pronunciationScore: Double = 0.0
    var pronunciationPracticeCount: Int = 0
    var conversationAccuracy: Double = 0.0
    
    // Settings Preferences
    var preferredDifficulty: String = "adaptive"
    var speechSpeed: Double = 1.0
    var reminderNotifications: Bool = true
    var soundEffects: Bool = true
    
    // MARK: - Computed Properties
    var isOnStreak: Bool {
        guard let lastPractice = lastPracticeDate else { return false }
        let calendar = Calendar.current
        let today = Date()
        
        // Check if practiced today or yesterday
        return calendar.isDateInToday(lastPractice) || 
               calendar.isDateInYesterday(lastPractice)
    }
    
    var practiceStreakDescription: String {
        if currentStreak == 0 {
            return "Start your first streak!"
        } else if currentStreak == 1 {
            return "1 day streak 🔥"
        } else {
            return "\(currentStreak) day streak 🔥"
        }
    }
    
    var nextLevelProgress: Double {
        let currentLevelXP = calculateLevelXP(for: currentUserLevel)
        let nextLevelXP = calculateLevelXP(for: getNextLevel())
        
        if nextLevelXP <= currentLevelXP {
            return 1.0 // Max level reached
        }
        
        let progress = Double(totalXP - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
        return max(0.0, min(1.0, progress))
    }
    
    var dailyProgressPercentage: Double {
        let today = Date()
        guard let lastPractice = lastPracticeDate,
              Calendar.current.isDate(lastPractice, inSameDayAs: today) else {
            return 0.0
        }
        
        // Calculate progress based on daily goal
        return min(1.0, Double(getTodayMinutes()) / Double(dailyGoalMinutes))
    }
    
    // MARK: - Helper Methods
    func getTodayMinutes() -> Int {
        // This would typically fetch from CoreData or similar
        // For now, return estimated based on conversations today
        return conversationsCompleted > 0 ? min(conversationsCompleted * 5, dailyGoalMinutes) : 0
    }
    
    private func calculateLevelXP(for level: Int) -> Int {
        let levelThresholds = [0, 100, 250, 450, 700, 1000, 1400, 1850, 2350, 2900, 3500]
        
        if level <= levelThresholds.count {
            return levelThresholds[level - 1]
        }
        
        // For levels beyond predefined: exponential growth
        let baseThreshold = levelThresholds.last! // 3500
        let extraLevels = level - levelThresholds.count
        return baseThreshold + (extraLevels * 500)
    }
    
    private func getNextLevel() -> Int {
        return currentUserLevel + 1
    }
    
    // MARK: - Dynamic XP System (NEW - Missing Implementation)
    
    /// Calculate session reward using 1/N formula where N = current level
    /// Level 1: 1/2 of XP needed for next level
    /// Level 2: 1/3 of XP needed for next level  
    /// Level 15+: Cap at 1/15 of XP needed for next level
    private func calculateDynamicSessionReward(currentLevel: Int) -> Int {
        let nextLevel = currentLevel + 1
        let xpNeededForNextLevel = getXPRequiredForLevel(nextLevel)
        
        // Apply 1/N formula with level 15 cap
        let divisor = min(max(currentLevel + 1, 2), 15) // Minimum 2, maximum 15
        let sessionReward = xpNeededForNextLevel / divisor
        
        // Ensure minimum reward of 10 XP to prevent frustration
        return max(sessionReward, 10)
    }
    
    /// Get XP required for a specific level (matching existing calculateLevel logic)
    private func getXPRequiredForLevel(_ level: Int) -> Int {
        let levelThresholds = [0, 100, 250, 450, 700, 1000, 1400, 1850, 2350, 2900, 3500]
        
        if level <= levelThresholds.count {
            return levelThresholds[level - 1]
        }
        
        // For levels beyond predefined: exponential growth
        let baseThreshold = levelThresholds.last! // 3500
        let extraLevels = level - levelThresholds.count
        return baseThreshold + (extraLevels * 500)
    }
    
    // MARK: - Update Methods
    mutating func addXP(_ amount: Int) {
        totalXP += amount
        lastUpdated = Date()
        
        // Check for level progression
        checkLevelProgression()
    }
    /// Award dynamic XP for practice session completion with duration multipliers
    mutating func awardDynamicXP(categoryMultiplier: Double = 1.0, duration: TimeInterval = 0) {
        // Minimum session requirement: 2 minutes
        guard duration >= 120 else {
            print("🚫 Session too short (\(Int(duration))s) - minimum 2 minutes required for XP")
            return
        }
        
        // Use currentUserLevel directly since it's now an integer
        let baseReward = calculateDynamicSessionReward(currentLevel: currentUserLevel)
        
        // Calculate duration multiplier
        let durationMultiplier = calculateDurationMultiplier(duration: duration)
        
        // Apply both multipliers
        let finalReward = Int(Double(baseReward) * categoryMultiplier * durationMultiplier)
        
        print("🎯 Dynamic XP: Level \(currentUserLevel) → \(finalReward) XP")
        print("   Base: \(baseReward), Category: \(categoryMultiplier)x, Duration: \(durationMultiplier)x (\(Int(duration))s)")
        
        addXP(finalReward)
    }
    
    /// Calculate duration-based multiplier for XP rewards
    private func calculateDurationMultiplier(duration: TimeInterval) -> Double {
        let minutes = duration / 60.0
        
        switch minutes {
        case 0..<2:
            return 0.0  // No XP for sessions under 2 minutes
        case 2..<10:
            return 1.0  // Base XP for 2-10 minutes
        case 10..<20:
            return 1.2  // 20% bonus for 10-20 minutes
        case 20..<30:
            return 1.4  // 40% bonus for 20-30 minutes
        case 30..<40:
            return 1.6  // 60% bonus for 30-40 minutes
        case 40..<50:
            return 1.8  // 80% bonus for 40-50 minutes
        case 50..<60:
            return 2.0  // 100% bonus for 50-60 minutes
        default:
            return 2.0  // Cap at 100% bonus for 60+ minutes
        }
    }
    
    
    mutating func completeConversation(duration: Int, topic: String) {
        conversationsCompleted += 1
        totalMinutesPracticed += duration
        lastPracticeDate = Date()
        lastUpdated = Date()
        
        // Update streak
        updateStreak()
        
        // Add to completed topics if not already there
        if !completedTopics.contains(topic) {
            completedTopics.append(topic)
        }
        
        // Add XP for conversation completion
        addXP(50)
        
        // Bonus XP for streak
        if currentStreak > 1 {
            addXP(currentStreak * 5)
        }
        
        // Update average session length
        updateAverageSessionLength(duration)
    }
    
    private mutating func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        guard let lastPractice = lastPracticeDate else {
            currentStreak = 1
            return
        }
        
        if calendar.isDateInToday(lastPractice) {
            // Already practiced today, maintain streak
            return
        } else if calendar.isDateInYesterday(lastPractice) {
            // Practiced yesterday, increment streak
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Streak broken, reset
            currentStreak = 1
        }
    }
    
    private mutating func updateAverageSessionLength(_ newDuration: Int) {
        if conversationsCompleted == 1 {
            averageSessionLength = Double(newDuration)
        } else {
            let totalTime = averageSessionLength * Double(conversationsCompleted - 1) + Double(newDuration)
            averageSessionLength = totalTime / Double(conversationsCompleted)
        }
    }
    
    private mutating func checkLevelProgression() {
        let requiredXP = calculateLevelXP(for: getNextLevel())
        let maxLevel = 50 // Set a reasonable max level
        
        if totalXP >= requiredXP && currentUserLevel < maxLevel {
            currentUserLevel = getNextLevel()
            
            // Unlock new level
            if !unlockedLevels.contains(currentUserLevel) {
                unlockedLevels.append(currentUserLevel)
            }
            
            // Award level up achievement
            unlockAchievement("level_up_\(currentUserLevel)")
        }
    }
    
    mutating func unlockAchievement(_ achievementId: String) {
        if !unlockedAchievements.contains(achievementId) {
            unlockedAchievements.append(achievementId)
            lastUpdated = Date()
        }
    }
    
    // MARK: - Static Factory Methods
    /*
    static func fromAssessmentData(_ assessmentData: UserAssessmentData, userId: String) -> UserProgress {
        var progress = UserProgress(userId: userId)
        
        progress.targetLanguage = assessmentData.targetLanguage
        progress.targetLanguageCode = assessmentData.targetLanguage
        progress.discoverySource = assessmentData.howTheyHeard
        progress.currentLevel = assessmentData.currentLevel
        progress.currentUserLevel = assessmentData.currentLevel
        progress.learningGoal = assessmentData.learningGoal
        progress.dailyTimeCommitment = assessmentData.dailyTimeCommitment
        progress.estimatedWordsPerWeek = assessmentData.estimatedWordsPerWeek
        
        // Set daily goal based on time commitment
        switch assessmentData.dailyTimeCommitment {
        case "5min": progress.dailyGoalMinutes = 5
        case "10min": progress.dailyGoalMinutes = 10
        case "15min": progress.dailyGoalMinutes = 15
        case "20min": progress.dailyGoalMinutes = 20
        default: progress.dailyGoalMinutes = 10
        }
        
        // Unlock appropriate starting level
        progress.unlockedLevels = [progress.currentUserLevel]
        
        // Award first achievement
        progress.unlockAchievement("assessment_completed")
        
        return progress
    }
    */
    
    // MARK: - Sample Data
    static let sampleProgress = UserProgress(
        userId: "sample_user",
        targetLanguage: "Spanish",
        targetLanguageCode: "es",
        discoverySource: "app_store",
        currentLevel: 3,
        learningGoal: "travel",
        dailyTimeCommitment: "10min",
        estimatedWordsPerWeek: 50,
        totalXP: 250,
        currentStreak: 5,
        longestStreak: 12,
        conversationsCompleted: 15,
        totalMinutesPracticed: 120,
        currentUserLevel: 2,
        unlockedLevels: [1, 2],
        completedTopics: ["greetings", "ordering_food", "directions"],
        dailyGoalMinutes: 10,
        lastPracticeDate: Date(),
        unlockedAchievements: ["assessment_completed", "first_conversation", "week_warrior"],
        averageSessionLength: 8.0,
        pronunciationScore: 0.85,
        conversationAccuracy: 0.78
    )
}

// MARK: - Achievement Definitions
struct Achievement {
    let id: String
    let title: String
    let description: String
    let icon: String
    let xpReward: Int
    let requirement: AchievementRequirement
}

enum AchievementRequirement {
    case conversationsCompleted(Int)
    case streakDays(Int)
    case xpEarned(Int)
    case topicsCompleted(Int)
    case minutesPracticed(Int)
    case levelReached(Int)
    case assessmentCompleted
    case socialShare
}

// MARK: - Achievement System
class AchievementSystem {
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "assessment_completed",
            title: "Getting Started",
            description: "Complete your initial assessment",
            icon: "checkmark.circle.fill",
            xpReward: 25,
            requirement: .assessmentCompleted
        ),
        Achievement(
            id: "first_conversation",
            title: "First Steps",
            description: "Complete your first conversation",
            icon: "message.circle.fill",
            xpReward: 50,
            requirement: .conversationsCompleted(1)
        ),
        Achievement(
            id: "week_warrior",
            title: "Week Warrior",
            description: "Maintain a 7-day practice streak",
            icon: "flame.fill",
            xpReward: 100,
            requirement: .streakDays(7)
        ),
        Achievement(
            id: "conversation_master",
            title: "Conversation Master",
            description: "Complete 20 conversations",
            icon: "star.fill",
            xpReward: 200,
            requirement: .conversationsCompleted(20)
        ),
        Achievement(
            id: "topic_explorer",
            title: "Topic Explorer",
            description: "Try 5 different conversation topics",
            icon: "globe.fill",
            xpReward: 75,
            requirement: .topicsCompleted(5)
        ),
        Achievement(
            id: "level_up_elementary",
            title: "Elementary Graduate",
            description: "Reach Level 2",
            icon: "graduationcap.fill",
            xpReward: 100,
            requirement: .levelReached(2)
        ),
        Achievement(
            id: "level_up_intermediate",
            title: "Intermediate Scholar",
            description: "Reach Level 5",
            icon: "book.fill",
            xpReward: 150,
            requirement: .levelReached(5)
        ),
        Achievement(
            id: "level_up_advanced",
            title: "Advanced Expert",
            description: "Reach Level 10",
            icon: "crown.fill",
            xpReward: 250,
            requirement: .levelReached(10)
        ),
        Achievement(
            id: "daily_dedication",
            title: "Daily Dedication",
            description: "Practice for 30 days straight",
            icon: "calendar.circle.fill",
            xpReward: 300,
            requirement: .streakDays(30)
        ),
        Achievement(
            id: "social_sharer",
            title: "Social Sharer",
            description: "Share your progress on social media",
            icon: "square.and.arrow.up.fill",
            xpReward: 50,
            requirement: .socialShare
        )
    ]
    
    static func checkAchievements(for progress: UserProgress) -> [Achievement] {
        return allAchievements.filter { achievement in
            !progress.unlockedAchievements.contains(achievement.id) &&
            isRequirementMet(achievement.requirement, progress: progress)
        }
    }
    
    private static func isRequirementMet(_ requirement: AchievementRequirement, progress: UserProgress) -> Bool {
        switch requirement {
        case .conversationsCompleted(let count):
            return progress.conversationsCompleted >= count
        case .streakDays(let days):
            return progress.currentStreak >= days
        case .xpEarned(let xp):
            return progress.totalXP >= xp
        case .topicsCompleted(let count):
            return progress.completedTopics.count >= count
        case .minutesPracticed(let minutes):
            return progress.totalMinutesPracticed >= minutes
        case .levelReached(let level):
            return progress.currentUserLevel >= level
        case .assessmentCompleted:
            return true // This should only be checked when assessment is completed
        case .socialShare:
            return false // This would be triggered by a specific action
        }
    }
}
