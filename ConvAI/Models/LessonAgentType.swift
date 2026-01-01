//
//  LessonAgentType.swift
//  ConvAI
//
//  Created by Mohamad Ali on 09/08/2025.
//

import SwiftUI
import Foundation

// MARK: - Lesson Agent Type (Links to new lesson agents from Agents.swift)

public enum LessonAgentType: String, CaseIterable {
    case mentor = "Mentor"
    case coach = "Coach" 
    case tutor = "Tutor"
    case language = "Language"
    case story = "Story"
    case simulation = "Simulation"
    
    public var agent: Agent {
        switch self {
        case .mentor: return Agent.moneyMaster  // Money Master
        case .coach: return Agent.loveCoach     // Love Coach  
        case .tutor: return Agent.powerPlayer   // Power Player
        case .language: return Agent.phoenix    // Language Master
        case .story: return Agent.masterStoryteller // Story Master
        case .simulation: return Agent.Convai   // Default - will be overridden by simulation agent
        }
    }
    
    public var description: String {
        switch self {
        case .mentor: return "Guides your learning journey with patience and wisdom"
        case .coach: return "Provides motivation and builds your confidence"
        case .tutor: return "Explains concepts clearly and celebrates progress"
        case .language: return "Helps you master language skills with interactive practice"
        case .story: return "Creates engaging narratives to enhance your learning experience"
        case .simulation: return "Provides realistic role-play scenarios for practical experience"
        }
    }
}
