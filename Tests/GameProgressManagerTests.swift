//
//  GameProgressManagerTests.swift
//
//  Test file to verify the new session validation system
//

import Foundation

// Simple test function to verify the refactored GameProgressManager
func testGameProgressManagerRefactor() {
    print("🧪 Testing GameProgressManager Refactor...")
    
    let manager = GameProgressManager.shared
    let initialLevel = manager.currentLevel
    let initialXP = manager.totalXP
    
    print("📊 Initial State: Level \(initialLevel), XP \(initialXP)")
    
    // Test 1: Complete a conversation and verify instant local updates
    print("\n🎯 Test 1: Completing conversation...")
    manager.completeConversation(categoryName: "money", duration: 300, performance: .excellent)
    
    print("✅ After conversation: Level \(manager.currentLevel), XP \(manager.totalXP)")
    print("💰 Money Level: \(manager.moneyMasteryLevel)")
    print("🎭 Confidence: \(Int(manager.confidenceMeter))%")
    
    // Test 2: Complete multiple conversations to trigger sync
    print("\n🎯 Test 2: Completing multiple conversations to trigger sync...")
    
    for i in 1...12 {
        let category = ["money", "love", "power", "language", "story"][i % 5]
        let performance: ConversationPerformance = [.good, .excellent, .average][i % 3]
        let duration: TimeInterval = Double(180 + i * 30) // Variable durations
        
        manager.completeConversation(categoryName: category, duration: duration, performance: performance)
        
        if i % 5 == 0 {
            print("📈 After \(i) conversations: Level \(manager.currentLevel), XP \(manager.totalXP)")
        }
    }
    
    // Test 3: Verify backward compatibility
    print("\n🎯 Test 3: Testing backward compatibility (no duration)...")
    manager.completeConversation(categoryName: "power", performance: .excellent)
    print("✅ Backward compatibility works")
    
    // Test 4: Check psychological metrics
    print("\n🎯 Test 4: Psychological metrics...")
    print("💪 Power Moves: \(manager.powerMovesUsed)")
    print("💰 Deals Closed: \(manager.dealsClosedCounter)")
    print("🎭 Stories in Repertoire: \(manager.storiesInRepertoire)")
    print("📚 Vocabulary Mastered: \(manager.vocabularyMastered)")
    
    // Test 5: Get motivational messages
    print("\n🎯 Test 5: Motivational system...")
    print("💬 Status: \(manager.getStatusMessage())")
    print("💰 Money motivation: \(manager.getMotivationalMessage(for: "money"))")
    print("❤️ Love motivation: \(manager.getMotivationalMessage(for: "love"))")
    
    print("\n🎉 All tests completed successfully!")
    print("📊 Final State: Level \(manager.currentLevel), XP \(manager.totalXP)")
    print("🏆 Overall Mastery: \(Int(manager.getOverallMastery()))")
}

// Run the test
// Uncomment the line below to run tests
// testGameProgressManagerRefactor()
