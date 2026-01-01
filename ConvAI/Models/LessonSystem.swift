//
//  LessonSystem.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import SwiftUI

// MARK: - Core Lesson Models
struct Lesson: Identifiable, Codable {
    let id: UUID
    let number: Int
    let title: String
    let description: String
    let icon: String
    let estimatedDuration: String
    let conversationGoals: [String]
    let keyPhrases: [String]
    let isCompleted: Bool
    let isUnlocked: Bool
    let xpReward: Int
    
    var displayTitle: String {
        "Lesson \(number): \(title)"
    }
}

struct Section: Identifiable, Codable {
    let id: UUID
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: SectionColor
    let lessons: [Lesson]
    let requiredXP: Int
    let isUnlocked: Bool
    
    var completedLessons: Int {
        lessons.filter { $0.isCompleted }.count
    }
    
    var totalLessons: Int {
        lessons.count
    }
    
    var progressPercentage: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
    
    var isCompleted: Bool {
        completedLessons == totalLessons
    }
}

struct LearningLevel: Identifiable, Codable {
    let id: UUID
    let number: Int
    let title: String
    let description: String
    let sections: [Section]
    let requiredXP: Int
    let color: LevelColor
    
    var completedSections: Int {
        sections.filter { $0.isCompleted }.count
    }
    
    var totalSections: Int {
        sections.count
    }
    
    var progressPercentage: Double {
        guard totalSections > 0 else { return 0 }
        return Double(completedSections) / Double(totalSections)
    }
    
    var isCompleted: Bool {
        completedSections == totalSections
    }
}

// MARK: - Enums
enum SectionColor: String, CaseIterable, Codable {
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case orange = "orange"
    case red = "red"
    case teal = "teal"
    case pink = "pink"
    case yellow = "yellow"
    
    var color: Color {
        switch self {
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .teal: return .teal
        case .pink: return .pink
        case .yellow: return .yellow
        }
    }
}

enum LevelColor: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var primaryColor: Color {
        switch self {
        case .beginner: return Color.green
        case .intermediate: return Color.orange
        case .advanced: return Color.red
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .beginner: return Color.green.opacity(0.3)
        case .intermediate: return Color.orange.opacity(0.3)
        case .advanced: return Color.red.opacity(0.3)
        }
    }
}

// MARK: - Lesson Content Data
struct LessonContent {
    static let beginnerLevel = LearningLevel(
        id: UUID(),
        number: 1,
        title: "Beginner",
        description: "Master the basics of conversation",
        sections: [
            // Section 1: Basic Greetings & Introductions
            Section(
                id: UUID(),
                number: 1,
                title: "Greetings & Introductions",
                description: "Learn how to greet people and introduce yourself",
                icon: "hand.wave.fill",
                color: .green,
                lessons: [
                    Lesson(
                        id: UUID(),
                        number: 1,
                        title: "Basic Greetings",
                        description: "Hello, Hi, Good morning, Good afternoon",
                        icon: "sunrise.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Say hello naturally",
                            "Use appropriate greetings for different times",
                            "Respond to greetings confidently"
                        ],
                        keyPhrases: ["Hello", "Hi", "Good morning", "How are you?"],
                        isCompleted: false,
                        isUnlocked: true,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 2,
                        title: "Self Introduction",
                        description: "My name is..., I'm from..., Nice to meet you",
                        icon: "person.circle.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Introduce yourself clearly",
                            "Share basic personal information",
                            "Ask for someone's name"
                        ],
                        keyPhrases: ["My name is", "I'm from", "Nice to meet you", "What's your name?"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 3,
                        title: "Asking About Others",
                        description: "Where are you from? What do you do?",
                        icon: "questionmark.circle.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Ask polite questions about others",
                            "Show interest in conversation",
                            "Keep conversation flowing"
                        ],
                        keyPhrases: ["Where are you from?", "What do you do?", "How long have you been here?"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    )
                ],
                requiredXP: 0,
                isUnlocked: true
            ),
            
            // Section 2: Basic Sentence Structure
            Section(
                id: UUID(),
                number: 2,
                title: "Sentence Building",
                description: "Learn to construct simple sentences",
                icon: "textformat.abc",
                color: .blue,
                lessons: [
                    Lesson(
                        id: UUID(),
                        number: 4,
                        title: "Subject + Verb",
                        description: "I am, You are, He/She is",
                        icon: "a.circle.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Use 'to be' verb correctly",
                            "Form simple statements",
                            "Practice basic sentence structure"
                        ],
                        keyPhrases: ["I am", "You are", "He is", "She is"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 5,
                        title: "Adding Objects",
                        description: "I like coffee, She reads books",
                        icon: "plus.circle.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Add objects to sentences",
                            "Express preferences",
                            "Talk about activities"
                        ],
                        keyPhrases: ["I like", "I have", "I want", "I need"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 6,
                        title: "Making Questions",
                        description: "Do you like...? Are you...? What is...?",
                        icon: "questionmark.bubble.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Form yes/no questions",
                            "Ask information questions",
                            "Use question words correctly"
                        ],
                        keyPhrases: ["Do you", "Are you", "What is", "Where is"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    )
                ],
                requiredXP: 150,
                isUnlocked: false
            ),
            
            // Section 3: Basic Grammar
            Section(
                id: UUID(),
                number: 3,
                title: "Essential Grammar",
                description: "Learn fundamental grammar rules",
                icon: "book.fill",
                color: .purple,
                lessons: [
                    Lesson(
                        id: UUID(),
                        number: 7,
                        title: "Present Tense",
                        description: "I work, He works, They work",
                        icon: "clock.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Use present tense correctly",
                            "Talk about daily activities",
                            "Describe current situations"
                        ],
                        keyPhrases: ["I work", "He works", "Every day", "Usually"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 8,
                        title: "Articles & Plurals",
                        description: "A, an, the, and plural forms",
                        icon: "textformat.123",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Use articles correctly",
                            "Form plural nouns",
                            "Specify and generalize"
                        ],
                        keyPhrases: ["A book", "An apple", "The car", "Two books"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 9,
                        title: "Basic Prepositions",
                        description: "In, on, at, with, for",
                        icon: "arrow.up.right.circle.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Use prepositions of place",
                            "Use prepositions of time",
                            "Describe locations and relationships"
                        ],
                        keyPhrases: ["In the", "On the", "At home", "With friends"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    )
                ],
                requiredXP: 300,
                isUnlocked: false
            ),
            
            // Section 4: Ordering Food
            Section(
                id: UUID(),
                number: 4,
                title: "Restaurant Basics",
                description: "Order food and drinks confidently",
                icon: "fork.knife.circle.fill",
                color: .orange,
                lessons: [
                    Lesson(
                        id: UUID(),
                        number: 10,
                        title: "Menu Vocabulary",
                        description: "Food and drink names, descriptions",
                        icon: "list.bullet.circle.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Understand menu items",
                            "Ask about ingredients",
                            "Express dietary preferences"
                        ],
                        keyPhrases: ["I'd like", "What's in", "Is it spicy?", "No meat please"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 11,
                        title: "Placing Orders",
                        description: "I'll have..., Can I get..., To go or dine in?",
                        icon: "hand.raised.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Place orders politely",
                            "Specify preferences",
                            "Handle ordering process"
                        ],
                        keyPhrases: ["I'll have", "Can I get", "To go", "For here"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    ),
                    Lesson(
                        id: UUID(),
                        number: 12,
                        title: "Payment & Tips",
                        description: "The check, credit card, tip",
                        icon: "creditcard.fill",
                        estimatedDuration: "5 min",
                        conversationGoals: [
                            "Ask for the bill",
                            "Handle payment",
                            "Understand tipping culture"
                        ],
                        keyPhrases: ["The check please", "Card or cash", "Keep the change", "Thank you"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 50
                    )
                ],
                requiredXP: 450,
                isUnlocked: false
            )
        ],
        requiredXP: 0,
        color: .beginner
    )
    
    static let intermediateLevel = LearningLevel(
        id: UUID(),
        number: 2,
        title: "Intermediate",
        description: "Build confidence in everyday conversations",
        sections: [
            Section(
                id: UUID(),
                number: 5,
                title: "Travel & Directions",
                description: "Navigate and communicate while traveling",
                icon: "airplane.circle.fill",
                color: .teal,
                lessons: [
                    Lesson(
                        id: UUID(),
                        number: 13,
                        title: "Asking for Directions",
                        description: "Where is...? How do I get to...?",
                        icon: "location.circle.fill",
                        estimatedDuration: "7 min",
                        conversationGoals: [
                            "Ask for directions clearly",
                            "Understand directions given",
                            "Confirm understanding"
                        ],
                        keyPhrases: ["Where is", "How do I get to", "Is it far?", "Can you show me?"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 75
                    )
                ],
                requiredXP: 600,
                isUnlocked: false
            )
        ],
        requiredXP: 600,
        color: .intermediate
    )
    
    static let advancedLevel = LearningLevel(
        id: UUID(),
        number: 3,
        title: "Advanced",
        description: "Master complex conversations and professional topics",
        sections: [
            Section(
                id: UUID(),
                number: 6,
                title: "Professional Communication",
                description: "Business meetings, job interviews, networking",
                icon: "briefcase.circle.fill",
                color: .red,
                lessons: [
                    Lesson(
                        id: UUID(),
                        number: 20,
                        title: "Job Interview Basics",
                        description: "Tell me about yourself, strengths, weaknesses",
                        icon: "person.2.circle.fill",
                        estimatedDuration: "10 min",
                        conversationGoals: [
                            "Introduce yourself professionally",
                            "Discuss experience and skills",
                            "Ask thoughtful questions"
                        ],
                        keyPhrases: ["Tell me about yourself", "My strengths are", "I'm interested in", "Do you have any questions?"],
                        isCompleted: false,
                        isUnlocked: false,
                        xpReward: 100
                    )
                ],
                requiredXP: 1200,
                isUnlocked: false
            )
        ],
        requiredXP: 1200,
        color: .advanced
    )
    
    static let allLevels = [beginnerLevel, intermediateLevel, advancedLevel]
}
