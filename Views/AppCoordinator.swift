//
//  AppCoordinator.swift
//  ConvAI
//
//  Created by Mohamad Ali on 28/07/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

struct AppCoordinator: View {
    @State private var isLoading = true
    @State private var showAssessment = false
    @State private var showAgeInput = false
    @State private var showHabitFormation = false
    @State private var needsAuthentication = false
    @State private var showProfileSetup = false
    @State private var showPaywall = false
    @State private var showHome = false
    @State private var showLanguageSelection = false
    @State private var showRoadMapDemo = false  // Keep for existing functionality
    @State private var showMainApp = false      // Keep for existing functionality
    @State private var hasCompletedAssessment = false // Keep for existing functionality
    @State private var userAge: Int?
    @State private var pendingNewUser = false
    @State private var showMicrophonePermission = false
    
    // MARK: - Navigation States for Lesson Flow (DAY 1 - HOUR 1 Implementation)
    @State private var showingConversation = false
    @State private var selectedLesson: SimpleLesson?
    @State private var conversationSession: ConversationSession?
    
    // MARK: - Navigation States for Practice Flow (MVP Step 7 Implementation)
    @State private var showingPracticeConversation = false
    @State private var selectedPracticeCategory: PracticeCategory?
    @State private var practiceConversationSession: ConversationSession?
    
    @EnvironmentObject var authService: EnhancedAuthenticationService
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var microphoneService = MicrophonePermissionService.shared
    @StateObject private var purchaseManager: StoreKit2PurchaseManager = {
        if #available(iOS 15.0, *) {
            return StoreKit2PurchaseManager()
        } else {
            fatalError("StoreKit 2 requires iOS 15.0 or later")
        }
    }()
    
    var body: some View {
        ZStack {
            if isLoading {
                // 1. Loading Screen - First step in workflow
                LoadingScreen {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        isLoading = false
                        checkUserStatus()
                    }
                }
                .transition(.opacity)
            } else if showAssessment {
                // 2. Onboarding + Assessment Flow - For new users
                OnboardingAssessmentView { assessmentData in
                    // Assessment completed, proceed to age input
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showAssessment = false
                        showAgeInput = true
                    }
                }
                .transition(.opacity)
                
            } else if showAgeInput {
                // 3. Age Input - Third step in workflow
                AgeInputView(
                    onContinue: { age in
                        userAge = age
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showAgeInput = false
                            showHabitFormation = true
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showAgeInput = false
                            showAssessment = true
                        }
                    }
                )
                .transition(.opacity)
                
            } else if showHabitFormation {
                // 4. Habit Formation - Fourth step in workflow
                HabitFormationView(
                    onContinue: {
                        print("🔔 Habit formation continue pressed")
                        
                        // Mark onboarding as completed since user reached the authentication step
                        UserProfile.markOnboardingCompletedGlobally()
                        
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showHabitFormation = false
                            needsAuthentication = true
                        }
                        print("🔔 Transitioning to needsAuthentication = true")
                    },
                    onEnableNotifications: {
                        // Notification permission handled within the view
                        print("🔔 Enable notifications called")
                    },
                    onSkip: {
                        print("🔔 Habit formation skip pressed")
                        
                        // Mark onboarding as completed since user reached the authentication step
                        UserProfile.markOnboardingCompletedGlobally()
                        
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showHabitFormation = false
                            needsAuthentication = true
                        }
                        print("🔔 Transitioning to needsAuthentication = true")
                    }
                )
                .transition(.opacity)
                
            } else if needsAuthentication {
                // 5. Authentication Gate - Fifth step in workflow
                // Ensure only authentication screen is shown
                AuthGateView()
                    .onReceive(authService.$isSignedIn) { isSignedIn in
                        print("🔐 Auth state changed: isSignedIn = \(isSignedIn)")
                        if isSignedIn {
                            print("🔐 User signed in, transitioning from auth gate")
                            withAnimation(.easeInOut(duration: 0.4)) {
                                needsAuthentication = false
                                // Check if user has completed onboarding (new user)
                                if userAge != nil {
                                    // New user - go to profile setup
                                    print("🔐 New user flow - going to profile setup")
                                    showProfileSetup = true
                                } else {
                                    // Existing user - check subscription and go to main app
                                    print("🔐 Existing user flow - checking subscription")
                                    Task {
                                        print("🔍 Checking subscription for existing user...")
                                        
                                        let hasActiveSubscription = await purchaseManager.checkSubscriptionStatusLocalFirst()
                                        
                                        await MainActor.run {
                                            print("🔍 Existing user subscription result: \(hasActiveSubscription)")
                                            print("🔍 Purchase manager hasActiveSubscription: \(purchaseManager.hasActiveSubscription)")
                                            
                                            if hasActiveSubscription {
                                                print("✅ Existing user has subscription - proceeding to main app")
                                                checkMicrophonePermissionAndProceed()
                                            } else {
                                                print("⚠️ Existing user no subscription - showing paywall")
                                                showPaywall = true
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // User signed out - reset all states and go to auth
                            print("🚪 User signed out - resetting app state")
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showMainApp = false
                                showPaywall = false
                                showHome = false
                                showProfileSetup = false
                                showMicrophonePermission = false
                                needsAuthentication = true
                            }
                        }
                    }
                .transition(.opacity)
                
            } else if showProfileSetup {
                // 6. Profile Setup - Username and Icon Selection
                ProfileSetupView(
                    userAge: userAge ?? 18,
                    onComplete: { username, profileImageUrl in
                        // Save the username to multiple places for persistence
                        Task {
                            await saveUserProfile(username: username, profileImageUrl: profileImageUrl)
                        }
                        
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showProfileSetup = false
                            showPaywall = true
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showProfileSetup = false
                            showPaywall = true
                        }
                    }
                )
                .transition(.opacity)

            } else if showPaywall {
                // 7. Premium Paywall - Show subscription options 
                // This can be shown either during onboarding or for returning users without active subscription
                NewConvAIPaywall(
                    onSubscriptionSuccess: {
                        print("🛍️ Purchase completed - navigating to main app")
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showPaywall = false
                            checkMicrophonePermissionAndProceed()
                        }
                    },
                    onDismiss: {
                        // CRITICAL: Never allow dismissing paywall for signed-in users without subscription
                        // Only allow dismissing during onboarding (when user isn't signed in yet)
                        if !authService.isSignedIn {
                            print("🔄 Paywall dismissed during onboarding - proceeding to main app")
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showPaywall = false
                                checkMicrophonePermissionAndProceed()
                            }
                        } else {
                            print("⚠️ Paywall dismiss blocked - signed-in users must subscribe")
                            // Don't do anything - force user to subscribe or sign out
                        }
                    }
                )
                .transition(.opacity)

            } else if showMicrophonePermission {
                // 8. Microphone Permission - Request audio access before main app
                MicrophonePermissionView(
                    onPermissionGranted: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showMicrophonePermission = false
                            showMainApp = true
                        }
                    },
                    onPermissionDenied: {
                        // Still proceed to main app, but with limited functionality
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showMicrophonePermission = false
                            showMainApp = true
                        }
                    }
                )
                .transition(.opacity)

            } else if showMainApp {
                // Main App - Tab-based Navigation System (Step 1 Implementation)
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(PracticeCoordinator(startPractice: startPracticeWithCategory))
                    .environmentObject(purchaseManager)
                .transition(.opacity)
            }
        }
        .environment(\.layoutDirection, localizationManager.layoutDirection)
        .overlay(
            // Interactive Achievement Notification Overlay - Show draggable achievement unlocks globally
            InteractiveAchievementNotificationOverlay()
                .zIndex(2000) // Higher z-index to ensure it appears above all other content
                .allowsHitTesting(true)
        )
        .overlay(
            // Step 10: Bonus Reward Popup Overlay - Show bonus XP popups globally (keeping separate as requested)
            BonusRewardPopupOverlay()
                .zIndex(1500)
        )
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionSheet()
        }
        .fullScreenCover(isPresented: $showingConversation) {
            
        }
        .animation(.easeInOut(duration: 0.6), value: showAssessment)
        .animation(.easeInOut(duration: 0.6), value: showAgeInput)
        .animation(.easeInOut(duration: 0.6), value: showHabitFormation)
        .animation(.easeInOut(duration: 0.6), value: needsAuthentication)
        .animation(.easeInOut(duration: 0.6), value: showProfileSetup)
        .animation(.easeInOut(duration: 0.6), value: showPaywall)
        .animation(.easeInOut(duration: 0.6), value: showMicrophonePermission)
        .animation(.easeInOut(duration: 0.6), value: showHome)
        .animation(.easeInOut(duration: 0.6), value: showMainApp)
        .animation(.easeInOut(duration: 0.6), value: isLoading)
        .animation(.easeInOut(duration: 0.6), value: showRoadMapDemo)
        .animation(.easeInOut(duration: 0.6), value: showingConversation)
        .animation(.easeInOut(duration: 0.6), value: showingPracticeConversation)
        .onAppear {
            // Loading will automatically start and call the completion callback
            // No need to manually set timers here
            
            // Initialize PurchaseManager on app startup
            Task {
                print("🛍️ PHASE 1: Initializing PurchaseManager on app startup...")
                await purchaseManager.checkSubscriptionStatusLocalFirst()
                print("🛍️ PurchaseManager initialization complete")
            }
            
            // 🔔 LOSS AVERSION: Initialize notification scheduler
            NotificationScheduler.shared.setupNotificationCategories()
            NotificationScheduler.shared.scheduleAllNotifications()
            
            // 🧪 For development: Test notification system
            // Tests have been moved to TestingControlView for manual triggering on Learn tab
            #if DEBUG
            // Automatic testing disabled - use TestingControlView on Learn tab instead
            #endif
        }
        .onReceive(authService.$isSignedIn) { isSignedIn in
            // Global auth state listener - handles sign out from anywhere in the app
            print("🔐 Global auth state changed: isSignedIn = \(isSignedIn)")
            
            if !isSignedIn {
                // User signed out - immediately reset to authentication screen
                print("🚪 User signed out - immediately resetting all app state")
                
                // Reset ALL navigation states synchronously (no animation to avoid glitches)
                showMainApp = false
                showPaywall = false
                showHome = false
                showProfileSetup = false
                showMicrophonePermission = false
                showAssessment = false
                showAgeInput = false
                showHabitFormation = false
                showLanguageSelection = false
                showRoadMapDemo = false
                showingConversation = false
                showingPracticeConversation = false
                
                // Clear user session data
                userAge = nil
                selectedLesson = nil
                conversationSession = nil
                selectedPracticeCategory = nil
                practiceConversationSession = nil
                
                // Set authentication screen with animation after state reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        needsAuthentication = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // PHASE 1: Recheck subscription status when app comes to foreground using local-first approach
            // This handles subscription changes made outside the app (Settings, other apps, etc.)
            if authService.isSignedIn && !isLoading {
                Task {
                    let hasActiveSubscription = await purchaseManager.checkSubscriptionStatusLocalFirst()
                    
                    await MainActor.run {
                        // If user lost subscription while in main app, redirect to paywall
                        if showMainApp && !hasActiveSubscription {
                            print("⚠️ Subscription status changed - redirecting to paywall")
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showMainApp = false
                                showPaywall = true
                            }
                        }
                        // If user gained subscription while on paywall, redirect to main app
                        else if showPaywall && hasActiveSubscription {
                            print("✅ Subscription activated - redirecting to main app")
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showPaywall = false
                                showMainApp = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - DAY 1 - HOUR 1: Lesson Selection Handler
    private func startConversationWithLesson(_ lesson: SimpleLesson) {
        print("🎯 Starting conversation with lesson: \(lesson.displayTitle)")
        
        // DAY 1 - HOUR 2: Create conversation session
        let session = ConversationSession.createSecure(
            lessonId: lesson.id.uuidString,
            lessonTitle: lesson.displayTitle,
            agentId: "agent_mentor", // Default agent for lessons
            agentName: "ConvAI Mentor",
            xpReward: lesson.xpReward
        )
        
        guard let session = session else {
            print("🚨 Failed to create secure conversation session")
            return
        }
        
        // Set up conversation state
        selectedLesson = lesson
        conversationSession = session
        
        // DAY 1 - HOUR 1: Navigate to conversation
        withAnimation(.easeInOut(duration: 0.4)) {
            showingConversation = true
        }
    }
    
    // MARK: - DAY 1 - HOUR 3: Conversation Completion Handler
    private func handleConversationCompletion(session: ConversationSession) {
        print("🎯 Conversation completed for lesson: \(session.lessonTitle)")
        print("🎯 XP earned: \(session.xpEarned)")
        print("🎯 Duration: \(Int(session.duration)) seconds")
        
        // 🔒 SECURITY: Validate XP bounds before awarding
        guard session.xpEarned >= 0 && session.xpEarned <= 1000 else {
            print("🚨 SECURITY: Invalid XP amount blocked: \(session.xpEarned)")
            return
        }
        
        // DAY 1 - HOUR 4: Basic XP calculation and awarding
        let currentXP = UserDefaults.standard.integer(forKey: "userXP")
        let newXP = currentXP + session.xpEarned
        
        // 🔒 SECURITY: Validate total XP bounds
        guard newXP <= 10_000_000 else {
            print("🚨 SECURITY: Total XP would exceed maximum: \(newXP)")
            return
        }
        
        // Update UserDefaults immediately
        UserDefaults.standard.set(newXP, forKey: "userXP")
        
        // Mark lesson as completed (simplified for now)
        // 🔒 SECURITY: Sanitize lesson ID for storage key
        let sanitizedLessonId = session.lessonId.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        guard !sanitizedLessonId.isEmpty else {
            print("🚨 SECURITY: Invalid lesson ID for completion storage")
            return
        }
        
        UserDefaults.standard.set(true, forKey: "lesson_\(sanitizedLessonId)_completed")
        
        print("🎯 Updated user XP: \(currentXP) → \(newXP)")
        print("🎯 Lesson \(sanitizedLessonId) marked as completed")
        
        // Trigger achievement checking after XP update
        checkAndTriggerAchievements()
        
        // COMMENTED OUT: Track conversation usage for subscription limits
        // UserProgressService.shared.trackConversationUsage(session: session) { success, error in
        //     if success {
        //         print("📊 Usage tracking completed successfully")
        //     } else {
        //         print("❌ Usage tracking failed: \(error ?? "Unknown error")")
        //     }
        // }
        
        // TODO: DAY 1 - HOUR 5-6: Firebase sync will be added here
        // TODO: DAY 2 - HOUR 1-2: Achievement checking will be added here
        
        // Show success feedback (optional - could add toast notification)
        print("🎉 Lesson completed successfully! Returning to roadmap...")
    }
    
    // MARK: - MVP Step 7: Practice Category Selection Handler
    func startPracticeWithCategory(_ category: PracticeCategory) {
        print("🎯 Starting practice with category: \(category.title)")
        
        // Create conversation session for practice
        let session = ConversationSession.createSecure(
            lessonId: "practice_\(category.rawValue.lowercased())",
            lessonTitle: category.title,
            agentId: category.agentId,
            agentName: getAgentNameForCategory(category),
            xpReward: Int(100 * category.xpMultiplier) // Base XP with category multiplier
        )
        
        guard let session = session else {
            print("🚨 Failed to create secure practice session")
            return
        }
        
        // Set up practice conversation state
        selectedPracticeCategory = category
        practiceConversationSession = session
        
        // Navigate to practice conversation
        withAnimation(.easeInOut(duration: 0.4)) {
            showingPracticeConversation = true
        }
    }
    
    // MARK: - MVP Step 7: Practice Completion Handler
    private func handlePracticeCompletion(session: ConversationSession, category: PracticeCategory) {
        print("🎯 Practice completed for category: \(category.title)")
        print("🎯 XP earned: \(session.xpEarned)")
        print("🎯 Duration: \(Int(session.duration)) seconds")
        
        // 🔒 SECURITY: Validate XP bounds before awarding
        guard session.xpEarned >= 0 && session.xpEarned <= 1000 else {
            print("🚨 SECURITY: Invalid XP amount blocked: \(session.xpEarned)")
            return
        }
        
        // Calculate XP with category multiplier
        let baseXP = session.xpEarned
        let bonusXP = Int(Double(baseXP) * (category.xpMultiplier - 1.0))
        let totalXP = baseXP + bonusXP
        
        // Update total user XP
        let currentXP = UserDefaults.standard.integer(forKey: "userXP")
        let newXP = currentXP + totalXP
        
        // 🔒 SECURITY: Validate total XP bounds
        guard newXP <= 10_000_000 else {
            print("🚨 SECURITY: Total XP would exceed maximum: \(newXP)")
            return
        }
        
        // Update UserDefaults immediately
        UserDefaults.standard.set(newXP, forKey: "userXP")
        
        // Track category-specific progress
        let categoryKey = "practice_\(category.rawValue.lowercased())_count"
        let currentCount = UserDefaults.standard.integer(forKey: categoryKey)
        UserDefaults.standard.set(currentCount + 1, forKey: categoryKey)
        
        // Update practice streak (daily practice tracking)
        updatePracticeStreak()
        
        // Update psychological metrics in GameProgressManager
        updatePsychologicalMetrics(for: category, session: session)
        
        // 🔔 LOSS AVERSION: Update notification scheduler after practice
        NotificationScheduler.shared.onPracticeCompleted()
        
        // Check if this was a daily challenge completion
        if let dailyChallenge = GameProgressManager.shared.getTodaysChallenge() {
            let challengeXP = GameProgressManager.shared.completeDailyChallenge()
            if challengeXP > 0 {
                print("🎯 Daily challenge completed! Bonus XP: \(challengeXP)")
            }
        }
        
        print("🎯 Updated user XP: \(currentXP) → \(newXP) (base: \(baseXP), bonus: \(bonusXP))")
        print("🎯 Category \(category.title) count: \(currentCount + 1)")
        
        // 🎰 STEP 10: Trigger Smart Bonus System
        triggerSmartBonusSystem(baseXP: baseXP, category: category, session: session)
        
        // Trigger achievement checking after XP and progress updates
        checkAndTriggerAchievements()
        
        // Show category bonus popup if significant bonus earned
        if bonusXP > 0 {
            triggerCategoryBonusPopup(bonusXP: bonusXP, category: category)
        }
        
        print("🎉 Practice completed successfully! Returning to practice...")
    }
    
    private func getAgentNameForCategory(_ category: PracticeCategory) -> String {
        switch category {
        case .money: return "Money Master"
        case .love: return "Love Coach"
        case .power: return "Power Player"
        case .language: return "Phoenix"
        case .story: return "Sage"
        }
    }
    
    private func updatePsychologicalMetrics(for category: PracticeCategory, session: ConversationSession) {
        // Update GameProgressManager metrics based on category
        let gameManager = GameProgressManager.shared
        
        // Determine performance based on session duration (simple heuristic for MVP)
        let performance: ConversationPerformance
        if session.duration >= 180 { // 3+ minutes = excellent
            performance = .excellent
        } else if session.duration >= 120 { // 2+ minutes = good
            performance = .good
        } else if session.duration >= 60 { // 1+ minute = average
            performance = .average
        } else {
            performance = .poor
        }
        
        // Use existing completeConversation method that handles all psychological metrics
        let categoryName = category.rawValue
        let estimatedDuration: TimeInterval = 300 // Default 5 minutes for conversations
        gameManager.completeConversation(categoryName: categoryName, duration: estimatedDuration, performance: performance)
        
        print("📊 Updated psychological metrics for \(category.title) with \(performance) performance")
    }
    
    // MARK: - Bonus XP Popup Integration
    private func triggerBonusXPPopup(bonusXP: Int, category: PracticeCategory) {
        // For now, just show a simple achievement-style notification for bonus XP
        // This could be enhanced with a custom BonusReward system later
        print("🎉 Bonus XP earned: +\(bonusXP) XP for \(category.title) (\(category.xpMultiplier)x multiplier)")
        
        // Add haptic feedback for bonus using centralized manager
        HapticFeedbackManager.shared.bonusEarned(amount: bonusXP)
    }
    
    // MARK: - Step 10: Smart Bonus System Implementation
    private func triggerSmartBonusSystem(baseXP: Int, category: PracticeCategory, session: ConversationSession) {
        let smartBonusManager = SmartBonusXPManager.shared
        
        // 1. Assess conversation quality based on session data
        let conversationQuality = assessConversationQuality(session: session)
        
        // 2. Check for variable reward bonuses (addiction psychology)
        smartBonusManager.checkForVariableRewards(
            baseXP: baseXP,
            category: category,
            conversationQuality: conversationQuality
        )
        
        // 3. Check for time-based bonuses (habit formation)
        smartBonusManager.checkTimeBonus(category: category)
        
        // 4. Check for streak bonuses
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        if currentStreak > 0 && currentStreak % 7 == 0 { // Every 7 days
            smartBonusManager.triggerStreakBonus(streakDays: currentStreak, category: category)
        }
        
        print("🎰 Smart bonus system triggered for \(category.title) with quality: \(conversationQuality.description)")
    }
    
    private func assessConversationQuality(session: ConversationSession) -> ConversationQuality {
        let duration = session.duration
        let xpEarned = session.xpEarned
        
        // Simple quality assessment based on duration and XP
        switch (duration, xpEarned) {
        case (let d, let xp) where d >= 300 && xp >= 80: // 5+ minutes, high XP
            return .excellent
        case (let d, let xp) where d >= 180 && xp >= 60: // 3+ minutes, good XP
            return .good
        case (let d, let xp) where d >= 120 && xp >= 30: // 2+ minutes, average XP
            return .average
        default:
            return .poor
        }
    }
    
    private func triggerCategoryBonusPopup(bonusXP: Int, category: PracticeCategory) {
        // Create category bonus reward
        let bonus = BonusReward(
            type: .category,
            points: bonusXP,
            detail: "\(category.title) mastery bonus!",
            category: category
        )
        
        // Add to the Smart Bonus Manager
        SmartBonusXPManager.shared.bonusTracker.addBonus(bonus)
        
        print("🎯 Category bonus triggered: +\(bonusXP) XP for \(category.title)")
    }
    
    // MARK: - Achievement Integration
    private func checkAndTriggerAchievements() {
        // Create current UserProgress from UserDefaults
        let currentXP = UserDefaults.standard.integer(forKey: "userXP")
        let currentLevel = calculateLevelFromXP(currentXP)
        
        // Get conversation counts for achievement checking
        let totalConversations = getTotalConversationCount()
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        
        // Create a UserProgress object for achievement checking
        let userProgress = UserProgress(
            id: UUID().uuidString,
            userId: authService.currentUser?.uid ?? "anonymous_user",
            totalXP: currentXP,
            currentStreak: currentStreak,
            conversationsCompleted: totalConversations,
            totalMinutesPracticed: 0,
            currentUserLevel: currentLevel, // Now using Int directly
            completedTopics: [], // Simplified for MVP
            unlockedAchievements: [] // Simplified for MVP
        )
        
        // Check for new achievements
        let newAchievements = AchievementSystem.checkAchievements(for: userProgress)
        
        // Show notifications for new achievements
        for achievement in newAchievements {
            if let gameAchievement = GameAchievement(rawValue: achievement.id) {
                AchievementNotificationService.shared.showAchievementUnlocked(gameAchievement)
                print("� Achievement unlocked: \(achievement.title)")
            }
        }
    }
    
    // MARK: - Helper Methods for Achievement System
    private func calculateLevelFromXP(_ xp: Int) -> Int {
        // Simple level calculation: every 1000 XP = 1 level
        return max(1, xp / 1000 + 1)
    }
    
    private func getTotalConversationCount() -> Int {
        // Sum up all conversation counts
        let moneyCount = UserDefaults.standard.integer(forKey: "practice_money_count")
        let loveCount = UserDefaults.standard.integer(forKey: "practice_love_count") 
        let powerCount = UserDefaults.standard.integer(forKey: "practice_power_count")
        return moneyCount + loveCount + powerCount
    }
    
    // MARK: - Step 9 Achievement Testing & Verification (Now with Interactive Drag Physics!)
    func testAchievementNotificationSystem() {
        print("🧪 Testing Interactive Achievement Notification System...")
        print("📱 Note: Notifications now follow finger with resistance physics - try dragging them!")
        
        // Test with First Conversation achievement
        let firstStepsAchievement = GameAchievement.firstConversation
        AchievementNotificationService.shared.showAchievementUnlocked(firstStepsAchievement)
        print("✅ Successfully triggered Interactive First Steps achievement notification")
        
        // Test with Week Warrior achievement after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let weekWarriorAchievement = GameAchievement.streak7Days
            AchievementNotificationService.shared.showAchievementUnlocked(weekWarriorAchievement)
            print("✅ Successfully triggered Interactive Week Warrior achievement notification")
        }
        
        print("🎯 Interactive achievement system with drag physics is fully operational!")
    }
    
    // MARK: - Step 10 Bonus System Testing & Verification
    func testBonusRewardSystem() {
        print("🧪 Testing Bonus Reward System...")
        
        let smartBonusManager = SmartBonusXPManager.shared
        
        // Test random bonus
        let randomBonus = BonusReward(
            type: .random,
            points: 75,
            detail: "Lucky bonus!"
        )
        smartBonusManager.bonusTracker.addBonus(randomBonus)
        print("✅ Successfully triggered Random Bonus notification")
        
        // Test category bonus after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            let categoryBonus = BonusReward(
                type: .category,
                points: 150,
                detail: "Money mastery bonus!",
                category: .money
            )
            smartBonusManager.bonusTracker.addBonus(categoryBonus)
            print("✅ Successfully triggered Category Bonus notification")
        }
        
        // Test perfect conversation bonus after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            let perfectBonus = BonusReward(
                type: .perfect,
                points: 200,
                detail: "Flawless execution!"
            )
            smartBonusManager.bonusTracker.addBonus(perfectBonus)
            print("✅ Successfully triggered Perfect Bonus notification")
        }
        
        print("🎰 Bonus reward system is fully operational and integrated!")
    }
    
    // MARK: - Streak Management
    private func updatePracticeStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastPracticeDate = UserDefaults.standard.object(forKey: "lastPracticeDate") as? Date {
            let lastPracticeDay = calendar.startOfDay(for: lastPracticeDate)
            
            if calendar.dateInterval(of: .day, for: today) == calendar.dateInterval(of: .day, for: lastPracticeDay) {
                // Same day, don't update streak
                return
            } else if calendar.dateInterval(of: .day, for: today)?.start == calendar.date(byAdding: .day, value: 1, to: lastPracticeDay) {
                // Consecutive day, increment streak
                let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
                UserDefaults.standard.set(currentStreak + 1, forKey: "currentStreak")
                print("🔥 Streak continued! Current streak: \(currentStreak + 1) days")
            } else {
                // Streak broken, reset to 1
                UserDefaults.standard.set(1, forKey: "currentStreak")
                print("🔥 New streak started! Current streak: 1 day")
            }
        } else {
            // First practice ever
            UserDefaults.standard.set(1, forKey: "currentStreak")
            print("🔥 First practice session! Current streak: 1 day")
        }
        
        // Update last practice date
        UserDefaults.standard.set(today, forKey: "lastPracticeDate")
    }
    
    // MARK: - Microphone Permission Check
    private func checkMicrophonePermissionAndProceed() {
        microphoneService.updatePermissionStatus()
        
        if microphoneService.isMicrophonePermissionGranted {
            // Permission already granted, proceed to main app
            showMainApp = true
            print("🎤 Microphone permission already granted, proceeding to main app")
        } else {
            // Need to request permission
            showMicrophonePermission = true
            print("🎤 Requesting microphone permission")
        }
    }
    
    // MARK: - User Status Check
    private func checkUserStatus() {
        print("📱 checkUserStatus called - current auth state: \(authService.isSignedIn)")
        
        // Check if user is already authenticated and has completed setup
        if authService.isSignedIn {
            print("✅ User is signed in, checking subscription status...")
            
            // PHASE 1: Local-first subscription checking for instant UI
            Task {
                print("🔍 PHASE 1: Starting local-first subscription check...")
                
                let hasActiveSubscription = await purchaseManager.checkSubscriptionStatusLocalFirst()
                
                await MainActor.run {
                    print("🔍 PHASE 1: Subscription check result: \(hasActiveSubscription)")
                    print("🔍 Purchase manager hasActiveSubscription: \(purchaseManager.hasActiveSubscription)")
                    print("🔍 Current tier: \(purchaseManager.currentTier?.rawValue ?? "nil")")
                    
                    if hasActiveSubscription {
                        print("✅ User has active subscription - going to MainTabView")
                        checkMicrophonePermissionAndProceed()
                    } else {
                        print("⚠️ User signed in but no active subscription - going to PaywallView")
                        showPaywall = true
                    }
                }
            }
        } else {
            // User not signed in - check if they've completed onboarding before
            let hasCompletedOnboarding = UserProfile.hasUserCompletedOnboarding()
            
            if hasCompletedOnboarding {
                print("🔄 User not signed in but has completed onboarding before - going directly to authentication")
                needsAuthentication = true
            } else {
                print("🔄 New user - starting onboarding flow")
                showAssessment = true
            }
        }
    }
    
    // MARK: - Public Methods
    /// Show paywall for subscription upgrade (can be called from MainTabView)
    public func showSubscriptionPaywall() {
        withAnimation(.easeInOut(duration: 0.4)) {
            showMainApp = false
            showPaywall = true
        }
    }
    
    // MARK: - Profile Setup Helper
    @MainActor
    private func saveUserProfile(username: String, profileImageUrl: String?) async {
        print("💾 Saving user profile: username='\(username)', imageUrl='\(profileImageUrl ?? "nil")'")
        
        // 1. Save to UserDefaults via UserProfile (local storage)
        let userProfile = UserProfile()
        userProfile.name = username
        userProfile.isSetup = true
        userProfile.saveProfile()
        print("✅ Saved to UserProfile (UserDefaults)")
        
        // 2. Save to AgentState (for system instructions)
        let agentState = AgentState()
        agentState.updateUser(name: username, info: "New user")
        print("✅ Saved to AgentState")
        
        // 3. Update GameProgressManager current user
        GameProgressManager.shared.updateUserInfo(name: username, info: "New user")
        print("✅ Saved to GameProgressManager")
        
        // 4. Save to Firebase Auth displayName
        if let currentUser = authService.currentUser {
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = username
            
            do {
                try await changeRequest.commitChanges()
                print("✅ Updated Firebase Auth displayName")
            } catch {
                print("❌ Failed to update Firebase Auth displayName: \(error)")
            }
        }
        
        // 5. Save to Firestore user document
        if let userId = authService.currentUser?.uid {
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "displayName": username,
                "profileImageUrl": profileImageUrl ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            do {
                try await db.collection("users").document(userId).updateData(userData)
                print("✅ Updated Firestore user document")
            } catch {
                print("❌ Failed to update Firestore: \(error)")
                // Try creating the document if it doesn't exist
                do {
                    let newUserData: [String: Any] = [
                        "uid": userId,
                        "email": authService.currentUser?.email ?? "",
                        "displayName": username,
                        "profileImageUrl": profileImageUrl ?? "",
                        "createdAt": FieldValue.serverTimestamp(),
                        "lastLoginAt": FieldValue.serverTimestamp(),
                        "totalXP": 0,
                        "currentLevel": 1,
                        "streakDays": 0,
                        "lessonsCompleted": 0,
                        "conversationMinutes": 0
                    ]
                    try await db.collection("users").document(userId).setData(newUserData)
                    print("✅ Created new Firestore user document")
                } catch {
                    print("❌ Failed to create Firestore document: \(error)")
                }
            }
        }
    }
}

// MARK: - App Menu Button
struct AppMenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Practice Coordinator (MVP Step 7)
class PracticeCoordinator: ObservableObject {
    let startPractice: (PracticeCategory) -> Void
    
    init(startPractice: @escaping (PracticeCategory) -> Void) {
        self.startPractice = startPractice
    }
}

// MARK: - Preview
struct AppCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinator()
            .environmentObject(EnhancedAuthenticationService())
    }
}

// MARK: - Simple Language Selection View
struct SimpleLanguageSelectionView: View {
    let localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    let languages = [
        ("en", "English", "🇺🇸"),
        ("es", "Español", "🇪🇸"),
        ("fr", "Français", "🇫🇷"),
        ("de", "Deutsch", "🇩🇪"),
        ("it", "Italiano", "🇮🇹"),
        ("pt", "Português", "🇵🇹")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Choose Language")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(languages, id: \.0) { code, name, flag in
                            Button(action: {
                                localizationManager.changeUILanguage(to: code)
                                dismiss()
                            }) {
                                VStack(spacing: 8) {
                                    Text(flag)
                                        .font(.system(size: 32))
                                    Text(name)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(localizationManager.currentUILanguage == code ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(localizationManager.currentUILanguage == code ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            }.foregroundColor(.white))
        }
    }
}
