//
//  ConversationSession.swift
//  ConvAI
//
//  Created by Mohamad Ali on 03/08/2025.
//

import Foundation

// MARK: - Conversation Session Model (DAY 1 - HOUR 2)
struct ConversationSession: Identifiable {
    let id: UUID
    let lessonId: String
    let lessonTitle: String
    let agentId: String // Added from LessonView version
    let agentName: String // Added from LessonView version
    let startTime: Date
    var endTime: Date?
    var xpReward: Int
    var xpEarned: Int = 0
    var isCompleted: Bool = false
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    // MARK: - Initializers
    init(id: UUID = UUID(), lessonId: String, lessonTitle: String, agentId: String, agentName: String, startTime: Date = Date(), xpReward: Int = 50) {
        self.id = id
        self.lessonId = lessonId
        self.lessonTitle = lessonTitle
        self.agentId = agentId
        self.agentName = agentName
        self.startTime = startTime
        self.xpReward = xpReward
    }
    
    // MARK: - Session Management
    mutating func completeSession(xpEarned: Int? = nil) {
        self.endTime = Date()
        self.isCompleted = true
        
        // Calculate XP if not provided (matches LessonView implementation)
        if let earnedXP = xpEarned {
            self.xpEarned = earnedXP
        } else {
            self.xpEarned = calculateXP()
        }
    }
    
    // Alternative method to match LessonView's simpler version
    mutating func completeSession() {
        endTime = Date()
        isCompleted = true
        
        // Calculate XP based on conversation duration (from LessonView)
        // Base XP: 50, Bonus: 10 XP per minute of conversation
        xpEarned = 50 + Int(duration / 60) * 10
        
        // Cap XP at 200 per session
        xpEarned = min(xpEarned, 200)
    }
    
    // MARK: - XP Calculation (Basic Implementation)
    private func calculateXP() -> Int {
        var calculatedXP = xpReward // Base XP from lesson
        
        // Bonus for session length (DAY 1 - HOUR 4: Basic implementation)
        if duration >= 240 { // 4+ minutes
            calculatedXP += Int(Double(calculatedXP) * 0.2) // +20% bonus
        }
        
        // TODO: DAY 1 - HOUR 4: Add streak bonus logic
        // TODO: DAY 1 - HOUR 4: Add level difficulty multiplier
        // TODO: DAY 2 - HOUR 1: Add pronunciation bonus
        
        return calculatedXP
    }
}

// MARK: - Firebase Integration (DAY 1 - HOUR 5-6)
extension ConversationSession {
    // Convert to dictionary for Firebase storage
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "lessonId": lessonId,
            "lessonTitle": lessonTitle,
            "agentId": agentId,
            "agentName": agentName,
            "startTime": startTime.timeIntervalSince1970,
            "xpReward": xpReward,
            "xpEarned": xpEarned,
            "isCompleted": isCompleted
        ]
        
        if let endTime = endTime {
            dict["endTime"] = endTime.timeIntervalSince1970
        }
        
        return dict
    }
    
    // Create from Firebase dictionary
    static func fromDictionary(_ dict: [String: Any]) -> ConversationSession? {
        guard 
            let idString = dict["id"] as? String,
            let id = UUID(uuidString: idString),
            let lessonId = dict["lessonId"] as? String,
            let lessonTitle = dict["lessonTitle"] as? String,
            let agentId = dict["agentId"] as? String,
            let agentName = dict["agentName"] as? String,
            let startTimeInterval = dict["startTime"] as? TimeInterval,
            let xpReward = dict["xpReward"] as? Int,
            let xpEarned = dict["xpEarned"] as? Int,
            let isCompleted = dict["isCompleted"] as? Bool
        else {
            return nil
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = (dict["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        
        var session = ConversationSession(
            id: id,
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            agentId: agentId,
            agentName: agentName,
            startTime: startTime,
            xpReward: xpReward
        )
        
        session.xpEarned = xpEarned
        session.isCompleted = isCompleted
        session.endTime = endTime
        
        return session
    }
}

// MARK: - Input Validation & Security (Security Implementation)
extension ConversationSession {
    // Validate session data to prevent injection attacks
    static func sanitizeAndValidate(lessonId: String, lessonTitle: String, xpReward: Int) -> (String, String, Int)? {
        // Validate lesson ID (allow alphanumeric, underscores, and hyphens for practice sessions)
        let sanitizedLessonId = lessonId
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        
        guard !sanitizedLessonId.isEmpty && sanitizedLessonId.count <= 50 else {
            print("🚨 Invalid lesson ID: \(lessonId)")
            return nil
        }
        
        // Sanitize lesson title (remove potential injection attempts)
        let sanitizedTitle = lessonTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace || ".,!?-".contains($0) }
        
        guard !sanitizedTitle.isEmpty && sanitizedTitle.count <= 100 else {
            print("🚨 Invalid lesson title: \(lessonTitle)")
            return nil
        }
        
        // Validate XP reward bounds
        guard xpReward >= 0 && xpReward <= 1000 else {
            print("🚨 Invalid XP reward: \(xpReward)")
            return nil
        }
        
        return (sanitizedLessonId, sanitizedTitle, xpReward)
    }
    
    // Secure initializer with validation
    static func createSecure(lessonId: String, lessonTitle: String, agentId: String, agentName: String, xpReward: Int = 50) -> ConversationSession? {
        guard let (sanitizedId, sanitizedTitle, validatedXP) = sanitizeAndValidate(
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            xpReward: xpReward
        ) else {
            return nil
        }
        
        return ConversationSession(
            lessonId: sanitizedId,
            lessonTitle: sanitizedTitle,
            agentId: agentId,
            agentName: agentName,
            xpReward: validatedXP
        )
    }
}
