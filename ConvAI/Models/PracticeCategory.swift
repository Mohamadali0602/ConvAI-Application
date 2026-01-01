//
//  PracticeCategory.swift
//  ConvAI
//
//  Created by Mohamad Ali on 07/08/2025.
//

import SwiftUI

// MARK: - Practice Categories Enum (5-Pillar System)
public enum PracticeCategory: String, CaseIterable {
    case language = "Language"
    case money = "Money"
    case love = "Love" 
    case power = "Power"
    case story = "Story"
    
    public var icon: String {
        switch self {
        case .language: return "globe"
        case .money: return "dollarsign.circle.fill"
        case .love: return "heart.fill"
        case .power: return "bolt.fill"
        case .story: return "book.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .language: return Color(red: 0.26, green: 0.52, blue: 0.96) // Phoenix blue
        case .money: return Color(red: 0.20, green: 0.66, blue: 0.33) // Money green
    case .love: return Color(red: 0.81, green: 0.06, blue: 0.12) // Love - lava red
        case .power: return Color(red: 0.98, green: 0.74, blue: 0.02) // Power gold
        case .story: return Color(red: 0.63, green: 0.26, blue: 0.96) // Deep purple
        }
    }
    
    public var xpMultiplier: Double {
        switch self {
        case .language: return 1.4  // Global communication value
        case .money: return 1.5  // Highest value - "One deal pays for years"
    case .power: return 1.5  // Command respect and influence
    case .love: return 1.5   // Authentic connection
    case .story: return 1.8  // Charismatic storytelling
        }
    }
    
    public var title: String {
        switch self {
        case .language: return "Speak Fluently"
        case .money: return "Close More Deals"
        case .love: return "Connect Authentically"
        case .power: return "Command Respect"
        case .story: return "Become Unforgettable"
        }
    }
    
    public var description: String {
        switch self {
        case .language: return "Eliminate speaking anxiety with Phoenix. Transform nervous conversations into confident communication in any language."
        case .money: return "Master sales techniques with Money Master. Learn the Straight Line System and close deals like a top 1% performer."
    case .love: return "Build lasting connections with Love Coach. Master dating psychology and never be lonely again through powerful, deep conversation."
        case .power: return "Develop influence with Power Player. Learn frame control and command any room with ethical persuasion techniques."
        case .story: return "Master storytelling with Sage. Transform ordinary moments into captivating narratives that make you absolutely unforgettable."
        }
    }
    
    public var valueProposition: String {
        switch self {
        case .language: return "Speak any language with confidence"
        case .money: return "One deal pays for years of training"
        case .love: return "Never be lonely again"
        case .power: return "Feel powerful after every conversation"
        case .story: return "Become absolutely unforgettable"
        }
    }
    
    public var agentId: String {
        switch self {
        case .language: return "phoenix"              // Phoenix - Language Master
        case .money: return "money-master"            // Money Master
        case .love: return "love-coach"               // Love Coach  
        case .power: return "power-player"            // Power Player
        case .story: return "master-storyteller"     // Sage - Master Storyteller
        }
    }
    
    // MARK: - Practice Goals for Each Category
    var practiceGoals: [String] {
        switch self {
        case .language:
            return [
                "Build conversation confidence",
                "Overcome speaking anxiety",
                "Master accent confidence",
                "Practice cultural communication"
            ]
        case .money:
            return [
                "Practice cold calling techniques",
                "Handle common sales objections", 
                "Master closing techniques",
                "Build compelling value propositions"
            ]
        case .love:
            return [
                "Practice conversation starters",
                "Build authentic connections",
                "Overcome approach anxiety", 
                "Express interest naturally"
            ]
        case .power:
            return [
                "Practice frame control",
                "Build confident communication",
                "Learn ethical influence techniques",
                "Master verbal self-defense"
            ]
        case .story:
            return [
                "Master narrative structure",
                "Practice emotional storytelling",
                "Build captivating presence",
                "Create memorable conversations"
            ]
        }
    }
    
    // MARK: - Key Phrases for Practice
    var keyPhrases: [String] {
        switch self {
        case .language:
            return [
                "That's really interesting, tell me more about...",
                "I've never thought about it that way...",
                "What's your experience with...",
                "That reminds me of...",
                "Help me understand..."
            ]
        case .money:
            return [
                "Let me ask you a question...",
                "What if I could show you...",
                "Does that make sense?", 
                "Are you ready to move forward?"
            ]
        case .love:
            return [
                "I couldn't help but notice...",
                "What brings you here tonight?",
                "That's really interesting, tell me more",
                "I'd love to continue this conversation"
            ]
        case .power:
            return [
                "I understand your perspective, however...",
                "Let's focus on what we can control",
                "That's an interesting point, here's another way to look at it",
                "I appreciate your input, and here's what I think"
            ]
        case .story:
            return [
                "Let me tell you about the time...",
                "You know what this reminds me of?",
                "I'll never forget when...",
                "The strangest thing happened to me...",
                "Here's what I learned from that experience..."
            ]
        }
    }
    
    // MARK: - Psychological Hooks
    var psychologicalHook: String {
        switch self {
        case .language: return "🌍 LANGUAGE - Speak any language confidently"
        case .money: return "💰 MONEY - Make $10K more this year"
        case .love: return "💖 LOVE - Never be lonely again"
        case .power: return "⚡ POWER - Command any room"
        case .story: return "🎭 STORY - Become absolutely unforgettable"
        }
    }
    
    // MARK: - Category ROI Value
    var roiValue: String {
        switch self {
        case .language: return "Global opportunities = priceless"
        case .money: return "One sale = pays for 5 years"
        case .love: return "Dating coach = $500/month alternative"
        case .power: return "Therapy alternative = $150/session"
        case .story: return "Charisma coaching = $200/hour alternative"
        }
    }
}

// MARK: - Supporting Enums

enum Difficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate" 
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Conversation Scenario
struct ConversationScenario {
    let title: String
    let description: String
    let difficulty: Difficulty
    let category: PracticeCategory
    let xpReward: Int
    
    init(title: String, description: String, difficulty: Difficulty, category: PracticeCategory) {
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.category = category
        self.xpReward = Int(100 * category.xpMultiplier * difficulty.multiplier)
    }
}

extension Difficulty {
    var multiplier: Double {
        switch self {
        case .beginner: return 1.0
        case .intermediate: return 1.5
        case .advanced: return 2.0
        }
    }
}

// MARK: - Default Scenarios for MVP
extension PracticeCategory {
    var scenarios: [ConversationScenario] {
        switch self {
        case .language:
            return [
                ConversationScenario(title: "Accent Confidence", description: "Speak with clarity and confidence", difficulty: .beginner, category: self),
                ConversationScenario(title: "Cultural Bridge", description: "Share your perspective as valuable insight", difficulty: .intermediate, category: self),
                ConversationScenario(title: "Fluent Flow", description: "Master natural conversation rhythm", difficulty: .advanced, category: self)
            ]
        case .money:
            return [
                ConversationScenario(title: "Cold Call Master", description: "Practice opening calls that get results", difficulty: .beginner, category: self),
                ConversationScenario(title: "Objection Handler", description: "Overcome the 5 most common objections", difficulty: .intermediate, category: self),
                ConversationScenario(title: "Close the Deal", description: "Master closing techniques that work", difficulty: .advanced, category: self)
            ]
        case .love:
            return [
                ConversationScenario(title: "First Approach", description: "Start conversations naturally and confidently", difficulty: .beginner, category: self),
                ConversationScenario(title: "Deep Connection", description: "Build meaningful rapport quickly", difficulty: .intermediate, category: self),
                ConversationScenario(title: "Confident Expression", description: "Express interest authentically", difficulty: .advanced, category: self)
            ]
        case .power:
            return [
                ConversationScenario(title: "Frame Control", description: "Maintain composure in any conversation", difficulty: .beginner, category: self),
                ConversationScenario(title: "Influence Techniques", description: "Persuade ethically and effectively", difficulty: .intermediate, category: self),
                ConversationScenario(title: "Command Presence", description: "Lead conversations with confidence", difficulty: .advanced, category: self)
            ]
        case .story:
            return [
                ConversationScenario(title: "Story Structure", description: "Master the universal narrative arc", difficulty: .beginner, category: self),
                ConversationScenario(title: "Emotional Journey", description: "Create captivating emotional experiences", difficulty: .intermediate, category: self),
                ConversationScenario(title: "Unforgettable Presence", description: "Become a magnetic storyteller", difficulty: .advanced, category: self)
            ]
        }
    }
}
