//
//  ReferralManager.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import Foundation
import SwiftUI

// 🚀 Referral Management System - Core logic for exponential growth
class ReferralManager: ObservableObject {
    // MARK: - Published Properties
    @Published var userReferralCode: String = ""
    @Published var totalReferrals: Int = 0
    @Published var successfulReferrals: Int = 0
    @Published var totalXPEarned: Int = 0
    @Published var userRank: Int = 999
    @Published var activeChallenges: [ReferralChallenge] = []
    @Published var rewardMilestones: [ReferralReward] = []
    @Published var topReferrers: [TopReferrer] = []
    @Published var referralHistory: [ReferralRecord] = []
    
    // MARK: - Properties
    let currentUserId = UUID().uuidString
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        generateUserReferralCode()
        setupRewardMilestones()
        setupActiveChallenges()
        generateMockLeaderboard()
    }
    
    // MARK: - Public Methods
    func loadReferralData() {
        // Load user's referral data
        totalReferrals = userDefaults.integer(forKey: "total_referrals")
        successfulReferrals = userDefaults.integer(forKey: "successful_referrals")
        totalXPEarned = userDefaults.integer(forKey: "referral_xp_earned")
        userRank = calculateUserRank()
        
        // Update challenges based on current progress
        updateActiveChallenges()
        
        print("📊 Loaded referral data: \(totalReferrals) total, \(successfulReferrals) successful")
    }
    
    func processReferralSignup(referralCode: String, newUserId: String) {
        // Process when someone signs up with user's referral code
        guard referralCode == userReferralCode else { return }
        
        // Record the referral
        let referral = ReferralRecord(
            id: UUID().uuidString,
            referredUserId: newUserId,
            referralCode: referralCode,
            signupDate: Date(),
            status: .pending,
            xpEarned: 0
        )
        
        referralHistory.append(referral)
        totalReferrals += 1
        
        // Save to UserDefaults
        userDefaults.set(totalReferrals, forKey: "total_referrals")
        
        // Schedule follow-up to check if referral becomes successful
        scheduleReferralFollowUp(referralId: referral.id)
        
        print("🎯 New referral recorded: \(newUserId)")
    }
    
    func processSuccessfulReferral(referralId: String) {
        // Called when referred user completes onboarding/first lesson
        guard let index = referralHistory.firstIndex(where: { $0.id == referralId }) else { return }
        
        referralHistory[index].status = .successful
        referralHistory[index].xpEarned = calculateReferralXP(for: successfulReferrals + 1)
        
        successfulReferrals += 1
        totalXPEarned += referralHistory[index].xpEarned
        
        // Save progress
        userDefaults.set(successfulReferrals, forKey: "successful_referrals")
        userDefaults.set(totalXPEarned, forKey: "referral_xp_earned")
        
        // Check for milestone rewards
        checkMilestoneRewards()
        
        // Update challenges
        updateActiveChallenges()
        
        print("✅ Successful referral processed: +\(referralHistory[index].xpEarned) XP")
    }
    
    func generateShareMessage() -> String {
        let messages = [
            "🚀 I'm mastering conversations on ConvAI! Join me with code \(userReferralCode) and we both get bonus XP!",
            "💬 Want to get better at talking to people? ConvAI is amazing! Use my code \(userReferralCode) to start",
            "🎯 Found the secret to confident conversations: ConvAI! Use code \(userReferralCode) and thank me later 😉",
            "💡 Learning conversation skills that actually work on ConvAI. Join with \(userReferralCode) for exclusive bonuses!",
            "🔥 This app is changing how I communicate! Try ConvAI with my referral code: \(userReferralCode)"
        ]
        
        return messages.randomElement() ?? messages[0]
    }
    
    func getShareURL(for platform: String = "general") -> String {
        let baseURL = "https://convai.app/join"
        let referralParam = "?ref=\(userReferralCode)"
        let sourceParam = "&src=\(platform)"
        let userParam = "&uid=\(currentUserId)"
        
        return "\(baseURL)\(referralParam)\(sourceParam)\(userParam)"
    }
    
    // MARK: - Private Methods
    private func generateUserReferralCode() {
        // Check if user already has a code
        if let existingCode = userDefaults.string(forKey: "user_referral_code") {
            userReferralCode = existingCode
            return
        }
        
        // Generate new code: adjective + animal + number
        let adjectives = ["SMART", "QUICK", "BRIGHT", "SHARP", "COOL", "SUPER", "MEGA", "ULTRA"]
        let animals = ["LION", "EAGLE", "SHARK", "WOLF", "TIGER", "BEAR", "HAWK", "FOX"]
        let numbers = (10...99).map { String($0) }
        
        let adjective = adjectives.randomElement()!
        let animal = animals.randomElement()!
        let number = numbers.randomElement()!
        
        userReferralCode = "\(adjective)\(animal)\(number)"
        
        // Save to UserDefaults
        userDefaults.set(userReferralCode, forKey: "user_referral_code")
        
        print("🎯 Generated referral code: \(userReferralCode)")
    }
    
    private func setupRewardMilestones() {
        rewardMilestones = [
            ReferralReward(
                referralCount: 1,
                title: "First Friend",
                description: "500 bonus XP + exclusive conversation tips",
                emoji: "🎉",
                xpReward: 500,
                premiumDays: 0,
                specialRewards: ["Exclusive conversation guide PDF"]
            ),
            ReferralReward(
                referralCount: 3,
                title: "Social Butterfly",
                description: "1500 XP + 1 month Premium FREE",
                emoji: "🦋",
                xpReward: 1500,
                premiumDays: 30,
                specialRewards: ["Premium features unlocked", "Advanced conversation scenarios"]
            ),
            ReferralReward(
                referralCount: 5,
                title: "Network Builder",
                description: "3000 XP + Personal coaching session",
                emoji: "🏗️",
                xpReward: 3000,
                premiumDays: 0,
                specialRewards: ["1-on-1 conversation coaching", "Custom learning path"]
            ),
            ReferralReward(
                referralCount: 10,
                title: "Influencer",
                description: "5000 XP + 3 months Premium + VIP status",
                emoji: "👑",
                xpReward: 5000,
                premiumDays: 90,
                specialRewards: ["VIP Discord access", "Beta feature previews", "Monthly group coaching"]
            ),
            ReferralReward(
                referralCount: 25,
                title: "ConvAI Ambassador",
                description: "10000 XP + 6 months Premium + Revenue share",
                emoji: "🌟",
                xpReward: 10000,
                premiumDays: 180,
                specialRewards: ["Revenue sharing program", "Brand partnership opportunities", "Personal success manager"]
            ),
            ReferralReward(
                referralCount: 50,
                title: "Growth Legend",
                description: "25000 XP + Lifetime Premium + Equity",
                emoji: "🚀",
                xpReward: 25000,
                premiumDays: 99999,
                specialRewards: ["Lifetime Premium access", "Company equity consideration", "Advisory role opportunity"]
            )
        ]
    }
    
    private func setupActiveChallenges() {
        let now = Date()
        let calendar = Calendar.current
        
        activeChallenges = [
            ReferralChallenge(
                id: "weekend_boost",
                title: "Weekend Warrior",
                description: "Refer 2 friends this weekend for double XP",
                emoji: "⚡",
                color: .orange,
                targetReferrals: 2,
                multiplier: 2.0,
                endDate: calendar.date(byAdding: .day, value: 2, to: now)!,
                rewardDescription: "2000 XP (double bonus)"
            ),
            ReferralChallenge(
                id: "streak_master",
                title: "Sharing Streak",
                description: "Share ConvAI 3 days in a row",
                emoji: "🔥",
                color: .red,
                targetReferrals: 0, // This is about sharing, not referrals
                multiplier: 1.0,
                endDate: calendar.date(byAdding: .day, value: 7, to: now)!,
                rewardDescription: "Exclusive badge + 500 XP"
            )
        ]
    }
    
    private func generateMockLeaderboard() {
        let mockReferrers = [
            ("Alex Chen", 127),
            ("Sarah Wilson", 89),
            ("Mike Rodriguez", 76),
            ("Emma Thompson", 54),
            ("David Kim", 43),
            ("Lisa Johnson", 38),
            ("Tom Anderson", 31),
            ("Maria Garcia", 28),
            ("John Smith", 24),
            ("Anna Brown", 19)
        ]
        
        topReferrers = mockReferrers.enumerated().map { index, data in
            TopReferrer(
                userId: index == 3 ? currentUserId : UUID().uuidString, // Put user at rank 4
                displayName: index == 3 ? "You" : data.0,
                referralCount: index == 3 ? successfulReferrals : data.1,
                rank: index + 1,
                xpEarned: (index == 3 ? successfulReferrals : data.1) * 100,
                isCurrentUser: index == 3
            )
        }
        
        // Update user rank based on position
        if let userReferrer = topReferrers.first(where: { $0.isCurrentUser }) {
            userRank = userReferrer.rank
        }
    }
    
    private func calculateUserRank() -> Int {
        // Calculate user's rank based on successful referrals
        // This would typically be done server-side
        switch successfulReferrals {
        case 0...2: return Int.random(in: 500...999)
        case 3...5: return Int.random(in: 100...499)
        case 6...10: return Int.random(in: 50...99)
        case 11...25: return Int.random(in: 10...49)
        case 26...50: return Int.random(in: 3...9)
        default: return Int.random(in: 1...2)
        }
    }
    
    private func calculateReferralXP(for referralNumber: Int) -> Int {
        // XP increases with each referral to incentivize continued sharing
        let baseXP = 100
        let bonusXP = min(referralNumber * 50, 500) // Max 500 bonus XP
        
        return baseXP + bonusXP
    }
    
    private func checkMilestoneRewards() {
        let unlockedMilestones = rewardMilestones.filter { 
            successfulReferrals >= $0.referralCount && !hasClaimedReward($0)
        }
        
        for milestone in unlockedMilestones {
            // Award the milestone reward
            awardMilestoneReward(milestone)
        }
    }
    
    private func hasClaimedReward(_ reward: ReferralReward) -> Bool {
        return userDefaults.bool(forKey: "claimed_reward_\(reward.referralCount)")
    }
    
    private func awardMilestoneReward(_ reward: ReferralReward) {
        // Mark as claimed
        userDefaults.set(true, forKey: "claimed_reward_\(reward.referralCount)")
        
        // Award XP
        totalXPEarned += reward.xpReward
        userDefaults.set(totalXPEarned, forKey: "referral_xp_earned")
        
        // Award premium days if any
        if reward.premiumDays > 0 {
            let currentPremiumEnd = userDefaults.object(forKey: "premium_end_date") as? Date ?? Date()
            let newPremiumEnd = Calendar.current.date(byAdding: .day, value: reward.premiumDays, to: max(currentPremiumEnd, Date()))!
            userDefaults.set(newPremiumEnd, forKey: "premium_end_date")
        }
        
        // Show reward notification
        scheduleRewardNotification(for: reward)
        
        print("🎁 Milestone reward awarded: \(reward.title)")
    }
    
    private func updateActiveChallenges() {
        // Remove expired challenges
        activeChallenges.removeAll { $0.endDate < Date() }
        
        // Add new challenges based on user progress
        if successfulReferrals > 0 && successfulReferrals % 5 == 0 {
            // Add special challenge every 5 referrals
            addSpecialChallenge()
        }
    }
    
    private func addSpecialChallenge() {
        let specialChallenge = ReferralChallenge(
            id: "milestone_boost_\(successfulReferrals)",
            title: "Milestone Boost",
            description: "You're on fire! Refer 3 more for massive bonus",
            emoji: "🎯",
            color: .purple,
            targetReferrals: 3,
            multiplier: 3.0,
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            rewardDescription: "3000 XP (triple bonus)"
        )
        
        if !activeChallenges.contains(where: { $0.id == specialChallenge.id }) {
            activeChallenges.append(specialChallenge)
        }
    }
    
    private func scheduleReferralFollowUp(referralId: String) {
        // Schedule a check in 24 hours to see if referral completed onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 86400) { // 24 hours
            // In a real app, this would be handled by backend
            // For demo, we'll randomly mark some as successful
            if Bool.random() {
                self.processSuccessfulReferral(referralId: referralId)
            }
        }
    }
    
    private func scheduleRewardNotification(for reward: ReferralReward) {
        // Schedule local notification for reward
        let content = UNMutableNotificationContent()
        content.title = "🎉 Milestone Unlocked!"
        content.body = "You've earned: \(reward.title) - \(reward.description)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "reward_\(reward.referralCount)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Models
struct ReferralChallenge {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let color: Color
    let targetReferrals: Int
    let multiplier: Double
    let endDate: Date
    let rewardDescription: String
    
    var timeRemaining: String {
        let now = Date()
        let timeInterval = endDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Expired"
        }
        
        let days = Int(timeInterval) / 86400
        let hours = Int(timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600
        
        if days > 0 {
            return "\(days)d \(hours)h left"
        } else {
            return "\(hours)h left"
        }
    }
}

struct ReferralReward: Identifiable {
    let id = UUID()
    let referralCount: Int
    let title: String
    let description: String
    let emoji: String
    let xpReward: Int
    let premiumDays: Int
    let specialRewards: [String]
}

struct TopReferrer {
    let userId: String
    let displayName: String
    let referralCount: Int
    let rank: Int
    let xpEarned: Int
    let isCurrentUser: Bool
}

struct ReferralRecord {
    let id: String
    let referredUserId: String
    let referralCode: String
    let signupDate: Date
    var status: ReferralStatus
    var xpEarned: Int
}

enum ReferralStatus {
    case pending
    case successful
    case expired
}
