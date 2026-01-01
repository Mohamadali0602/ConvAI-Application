//
//  ConversationLevel.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Level System Models
struct ConversationLevel: Identifiable, Codable {
    let id: Int // 1-10
    let title: String
    let description: String
    let color: Color
    let parts: [LevelPart]
    let requiredXP: Int
    let isLocked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, parts, requiredXP, isLocked
    }
    
    init(id: Int, title: String, description: String, color: Color, parts: [LevelPart], requiredXP: Int, isLocked: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.color = color
        self.parts = parts
        self.requiredXP = requiredXP
        self.isLocked = isLocked
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        parts = try container.decode([LevelPart].self, forKey: .parts)
        requiredXP = try container.decode(Int.self, forKey: .requiredXP)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        
        // Set color based on level
        switch id {
        case 1...3: color = .green
        case 4...6: color = .blue
        case 7...8: color = .orange
        case 9...10: color = .red
        default: color = .gray
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(parts, forKey: .parts)
        try container.encode(requiredXP, forKey: .requiredXP)
        try container.encode(isLocked, forKey: .isLocked)
    }
}

struct LevelPart: Identifiable, Codable {
    let id: Int // 1-10 within each level
    let title: String
    let description: String
    let lessons: [ConversationLesson]
    let isLocked: Bool
}

struct ConversationLesson: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let topic: String
    let estimatedDuration: Int // minutes
    let isCompleted: Bool
    let xpReward: Int
}

// MARK: - Level Data Provider
class LevelDataProvider {
    static let shared = LevelDataProvider()
    
    private init() {}
    
    func getAllLevels() -> [ConversationLevel] {
        return [
            createLevel1(),
            createLevel2(),
            createLevel3(),
            createLevel4(),
            createLevel5(),
            createLevel6(),
            createLevel7(),
            createLevel8(),
            createLevel9(),
            createLevel10()
        ]
    }
    
    // MARK: - Level 1: Foundation
    private func createLevel1() -> ConversationLevel {
        let parts = [
            LevelPart(id: 1, title: "Greetings & Introductions", description: "Learn basic greetings and how to introduce yourself", lessons: [
                ConversationLesson(id: "1-1-1", title: "Hello & Goodbye", description: "Basic greetings for any time of day", topic: "greetings_basic", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-1-2", title: "My Name Is...", description: "Introducing yourself to new people", topic: "introduction_self", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-1-3", title: "Nice to Meet You", description: "Polite responses when meeting someone", topic: "introduction_response", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-1-4", title: "Where Are You From?", description: "Talking about your hometown", topic: "hometown_basic", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "1-1-5", title: "First Day Conversations", description: "Common exchanges on your first day somewhere", topic: "first_day", estimatedDuration: 4, isCompleted: false, xpReward: 60)
            ], isLocked: false),
            
            LevelPart(id: 2, title: "Daily Basics", description: "Essential conversations for everyday situations", lessons: [
                ConversationLesson(id: "1-2-1", title: "Asking for Help", description: "How to politely ask for assistance", topic: "asking_help", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-2-2", title: "Saying Please & Thank You", description: "Politeness in everyday interactions", topic: "politeness_basic", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-2-3", title: "Excuse Me & Sorry", description: "Apologizing and getting attention", topic: "apologies_basic", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-2-4", title: "Yes, No, Maybe", description: "Basic responses and uncertainty", topic: "responses_basic", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-2-5", title: "I Don't Understand", description: "What to say when you're confused", topic: "confusion_help", estimatedDuration: 4, isCompleted: false, xpReward: 60)
            ], isLocked: true),
            
            LevelPart(id: 3, title: "Numbers & Time", description: "Talking about time, dates, and numbers", lessons: [
                ConversationLesson(id: "1-3-1", title: "What Time Is It?", description: "Asking and telling time", topic: "time_basic", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "1-3-2", title: "Days of the Week", description: "Planning and scheduling conversations", topic: "days_week", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-3-3", title: "Counting & Numbers", description: "Using numbers in conversation", topic: "numbers_basic", estimatedDuration: 3, isCompleted: false, xpReward: 50),
                ConversationLesson(id: "1-3-4", title: "How Much Does It Cost?", description: "Talking about prices", topic: "prices_basic", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "1-3-5", title: "Making Appointments", description: "Simple scheduling conversations", topic: "appointments_basic", estimatedDuration: 5, isCompleted: false, xpReward: 70)
            ], isLocked: true)
        ]
        
        return ConversationLevel(
            id: 1,
            title: "Level 1",
            description: "Master the fundamentals of everyday conversation",
            color: .green,
            parts: parts,
            requiredXP: 0,
            isLocked: false
        )
    }
    
    // MARK: - Level 2: Building Confidence
    private func createLevel2() -> ConversationLevel {
        let parts = [
            LevelPart(id: 1, title: "Food & Drink", description: "Ordering meals and talking about food preferences", lessons: [
                ConversationLesson(id: "2-1-1", title: "Ordering Coffee", description: "Coffee shop conversations", topic: "coffee_order", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "2-1-2", title: "Restaurant Basics", description: "Ordering food at a restaurant", topic: "restaurant_order", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "2-1-3", title: "Food Preferences", description: "Talking about what you like to eat", topic: "food_preferences", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "2-1-4", title: "Paying the Bill", description: "Handling payment at restaurants", topic: "restaurant_payment", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "2-1-5", title: "Grocery Shopping", description: "Buying food at the supermarket", topic: "grocery_shopping", estimatedDuration: 5, isCompleted: false, xpReward: 70)
            ], isLocked: true),
            
            LevelPart(id: 2, title: "Getting Around", description: "Transportation and directions", lessons: [
                ConversationLesson(id: "2-2-1", title: "Asking for Directions", description: "How to find your way around", topic: "directions_basic", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "2-2-2", title: "Taking a Taxi", description: "Communicating with taxi drivers", topic: "taxi_ride", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "2-2-3", title: "Public Transportation", description: "Using buses and trains", topic: "public_transport", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "2-2-4", title: "At the Airport", description: "Basic airport conversations", topic: "airport_basic", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "2-2-5", title: "Hotel Check-in", description: "Checking into accommodation", topic: "hotel_checkin", estimatedDuration: 5, isCompleted: false, xpReward: 70)
            ], isLocked: true)
        ]
        
        return ConversationLevel(
            id: 2,
            title: "Level 2",
            description: "Navigate everyday situations with confidence",
            color: .green,
            parts: parts,
            requiredXP: 500,
            isLocked: true
        )
    }
    
    // MARK: - Level 3: Social Interactions
    private func createLevel3() -> ConversationLevel {
        let parts = [
            LevelPart(id: 1, title: "Small Talk", description: "Casual conversations and social interactions", lessons: [
                ConversationLesson(id: "3-1-1", title: "Weather Conversations", description: "The universal conversation starter", topic: "weather_talk", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "3-1-2", title: "Weekend Plans", description: "Talking about your free time", topic: "weekend_plans", estimatedDuration: 4, isCompleted: false, xpReward: 60),
                ConversationLesson(id: "3-1-3", title: "Hobbies & Interests", description: "Sharing what you enjoy doing", topic: "hobbies_basic", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "3-1-4", title: "Family & Friends", description: "Talking about people in your life", topic: "family_friends", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "3-1-5", title: "Making Plans", description: "Arranging to meet with friends", topic: "making_plans", estimatedDuration: 5, isCompleted: false, xpReward: 70)
            ], isLocked: true)
        ]
        
        return ConversationLevel(
            id: 3,
            title: "Level 3",
            description: "Build social connections through conversation",
            color: .green,
            parts: parts,
            requiredXP: 1000,
            isLocked: true
        )
    }
    
    // MARK: - Level 4: Professional Communication
    private func createLevel4() -> ConversationLevel {
        let parts = [
            LevelPart(id: 1, title: "Workplace Basics", description: "Essential professional conversations", lessons: [
                ConversationLesson(id: "4-1-1", title: "Job Interview Introduction", description: "Making a strong first impression", topic: "interview_intro", estimatedDuration: 6, isCompleted: false, xpReward: 80),
                ConversationLesson(id: "4-1-2", title: "Office Small Talk", description: "Casual workplace conversations", topic: "office_smalltalk", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "4-1-3", title: "Asking for Time Off", description: "Requesting vacation or sick days", topic: "time_off_request", estimatedDuration: 5, isCompleted: false, xpReward: 70),
                ConversationLesson(id: "4-1-4", title: "Phone Calls at Work", description: "Professional telephone etiquette", topic: "work_phone_calls", estimatedDuration: 6, isCompleted: false, xpReward: 80),
                ConversationLesson(id: "4-1-5", title: "Team Meetings", description: "Participating in workplace discussions", topic: "team_meetings", estimatedDuration: 7, isCompleted: false, xpReward: 90)
            ], isLocked: true)
        ]
        
        return ConversationLevel(
            id: 4,
            title: "Level 4",
            description: "Professional communication skills",
            color: .blue,
            parts: parts,
            requiredXP: 1500,
            isLocked: true
        )
    }
    
    // Continue with levels 5-10 (abbreviated for brevity)
    private func createLevel5() -> ConversationLevel {
        return ConversationLevel(id: 5, title: "Level 5", description: "Advanced everyday situations", color: .blue, parts: [], requiredXP: 2000, isLocked: true)
    }
    
    private func createLevel6() -> ConversationLevel {
        return ConversationLevel(id: 6, title: "Level 6", description: "Complex social interactions", color: .blue, parts: [], requiredXP: 2500, isLocked: true)
    }
    
    private func createLevel7() -> ConversationLevel {
        return ConversationLevel(id: 7, title: "Level 7", description: "Professional mastery", color: .orange, parts: [], requiredXP: 3000, isLocked: true)
    }
    
    private func createLevel8() -> ConversationLevel {
        return ConversationLevel(id: 8, title: "Level 8", description: "Cultural nuances and idioms", color: .orange, parts: [], requiredXP: 3500, isLocked: true)
    }
    
    private func createLevel9() -> ConversationLevel {
        return ConversationLevel(id: 9, title: "Level 9", description: "Advanced professional scenarios", color: .red, parts: [], requiredXP: 4000, isLocked: true)
    }
    
    private func createLevel10() -> ConversationLevel {
        return ConversationLevel(id: 10, title: "Level 10", description: "Native-level conversation mastery", color: .red, parts: [], requiredXP: 5000, isLocked: true)
    }
}
