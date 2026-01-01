//
//  GameAchievement.swift
//  ConvAI
//
//  Simple achievement system for Phase 3 implementation
//

import Foundation

// MARK: - Game Achievement Types
enum GameAchievement: String, CaseIterable, Codable {
    case firstConversation = "first_conversation"
    case streak3Days = "streak_3_days"
    case streak7Days = "streak_7_days"
    case streak30Days = "streak_30_days"
    case level5Reached = "level_5_reached"
    case level10Reached = "level_10_reached"
    case moneyMaster = "money_master"
    case loveCoach = "love_coach"
    case powerPlayer = "power_player"
    case languageMaster = "language_master"
    case storyteller = "storyteller"
    
    var title: String {
        switch self {
        case .firstConversation:
            return "First Steps"
        case .streak3Days:
            return "Getting Started"
        case .streak7Days:
            return "Week Warrior"
        case .streak30Days:
            return "Dedication Master"
        case .level5Reached:
            return "Rising Star"
        case .level10Reached:
            return "Conversation Expert"
        case .moneyMaster:
            return "Money Master"
        case .loveCoach:
            return "Love Coach"
        case .powerPlayer:
            return "Power Player"
        case .languageMaster:
            return "Language Master"
        case .storyteller:
            return "Master Storyteller"
        }
    }
    
    var description: String {
        switch self {
        case .firstConversation:
            return "Completed your first conversation"
        case .streak3Days:
            return "Practiced for 3 days in a row"
        case .streak7Days:
            return "Achieved a 7-day practice streak"
        case .streak30Days:
            return "Incredible! 30 days of consistent practice"
        case .level5Reached:
            return "Reached Level 5"
        case .level10Reached:
            return "Reached Level 10"
        case .moneyMaster:
            return "Mastered business conversations"
        case .loveCoach:
            return "Mastered relationship conversations"
        case .powerPlayer:
            return "Mastered influence conversations"
        case .languageMaster:
            return "Mastered language skills"
        case .storyteller:
            return "Mastered storytelling techniques"
        }
    }
    
    var emoji: String {
        switch self {
        case .firstConversation:
            return "🎯"
        case .streak3Days:
            return "🔥"
        case .streak7Days:
            return "⚡"
        case .streak30Days:
            return "💎"
        case .level5Reached:
            return "⭐"
        case .level10Reached:
            return "🏆"
        case .moneyMaster:
            return "💰"
        case .loveCoach:
            return "💕"
        case .powerPlayer:
            return "👑"
        case .languageMaster:
            return "🗣️"
        case .storyteller:
            return "📚"
        }
    }
    
    var xpReward: Int {
        switch self {
        case .firstConversation:
            return 50
        case .streak3Days:
            return 100
        case .streak7Days:
            return 250
        case .streak30Days:
            return 1000
        case .level5Reached:
            return 200
        case .level10Reached:
            return 500
        case .moneyMaster, .loveCoach, .powerPlayer, .languageMaster, .storyteller:
            return 300
        }
    }
}
