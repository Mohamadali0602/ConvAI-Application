//
//  PracticeView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 07/08/2025.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Universal Top Banner (Tab-Aware with Expanding Feature)
struct UniversalTopBanner: View {
    let title: String
    @StateObject private var gameProgress = GameProgressManager.shared
    @State private var isExpanded = false
    @Binding var bannerHeight: CGFloat
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    private var currentXPInLevel: Int {
        let totalXPForCurrentLevel = getTotalXPUpToLevel(gameProgress.currentLevel - 1)
        return max(0, gameProgress.totalXP - totalXPForCurrentLevel)
    }
    
    private func getTotalXPUpToLevel(_ level: Int) -> Int {
        if level <= 0 { return 0 }
        var totalXP = 0
        for i in 1..<level {
            totalXP += getXPRequiredForLevel(i)
        }
        return totalXP
    }
    
    private func getXPRequiredForLevel(_ level: Int) -> Int {
        if level <= 1 { return 100 }
        var requirement = 100
        for _ in 2...level {
            requirement = Int(Double(requirement) * 1.5)
        }
        return requirement
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header section (never moves)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    bannerHeight = isExpanded ? 600 : 120
                    
                    // Haptic feedback
                    #if os(iOS)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    #endif
                }
            }) {
                HStack(spacing: 8) {
                    // Dynamic title
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Fixed spacing instead of Spacer
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 100)
                    
                    // Level & XP with info icon
                    HStack(spacing: 10) {
                        Text("Level \(gameProgress.currentLevel)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        // XP Circle with info icon
                        ZStack {
                            Circle()
                                .stroke(primaryColor, lineWidth: 3)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .fill(primaryColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            VStack(spacing: 0) {
                                Text("\(gameProgress.totalXP)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("XP")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Info icon positioned on the circle
                            if !isExpanded {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(secondaryColor)
                                    .offset(x: 20, y: -20)
                                    .scaleEffect(1.1)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: !isExpanded)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 70)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Bottom accent line (always visible)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
            
            // Expanded content (grows from the line downward)
            VStack(spacing: 0) {
                if isExpanded {
                    // Progress content that appears below the line
                    VStack(spacing: 16) {
                        // Top level card with progress bar
                        VStack(spacing: 12) {
                            HStack {
                                // Plant icon and level info
                                HStack(spacing: 12) {
                                    Image(systemName: "leaf.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Level \(gameProgress.currentLevel)")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                        
                                        Text("Novice Speaker")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                
                                Spacer()
                                
                                // XP display
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(gameProgress.totalXP) XP")
                                        .font(.title2.bold())
                                        .foregroundColor(secondaryColor)
                                    
                                    Text("\(getXPRequiredForLevel(gameProgress.currentLevel + 1) - currentXPInLevel) to next level")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            // Progress to next level
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Progress to Next Level")
                                        .font(.caption.bold())
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(gameProgress.getProgressToNextLevel() * 100))%")
                                        .font(.caption.bold())
                                        .foregroundColor(secondaryColor)
                                }
                                
                                SwiftUI.ProgressView(value: gameProgress.getProgressToNextLevel())
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .accentColor(secondaryColor)
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Stats grid with confidence and 4 stat boxes
                        HStack(spacing: 12) {
                            // Confidence box (larger - spans full height)
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                    Text("Confidence")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                }
                                
                                Text("2%")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.green)
                                
                                // Progress circle
                                ZStack {
                                    Circle()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 4)
                                        .frame(width: 40, height: 40)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.02) // 2% progress
                                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .frame(width: 40, height: 40)
                                        .rotationEffect(.degrees(-90))
                                }
                                
                                Text("Every expert was once a beginner!")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200) // Increased height for better text visibility
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 4 stat boxes grid (aligned to match confidence box height)
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // Deals Closed
                                    VStack(spacing: 6) {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                        Text("1")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                        Text("Deals Closed")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 90) // Increased height for better text visibility
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                    )
                                    
                                    // Rejection Score
                                    VStack(spacing: 6) {
                                        Image(systemName: "heart.fill")
                                            .font(.title3)
                                            .foregroundColor(.pink)
                                        Text("0")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                        Text("Rejection Score")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 90)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                
                                HStack(spacing: 12) {
                                    // Power Moves
                                    VStack(spacing: 6) {
                                        Image(systemName: "bolt.fill")
                                            .font(.title3)
                                            .foregroundColor(.yellow)
                                        Text("3")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                        Text("Power Moves")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 90)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                                    )
                                    
                                    // Day Streak
                                    VStack(spacing: 6) {
                                        Image(systemName: "flame.fill")
                                            .font(.title3)
                                            .foregroundColor(.orange)
                                        Text("0")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                        Text("Day Streak")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 90)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        // Extended background for expanded content
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.05, green: 0.05, blue: 0.1),
                                    Color(red: 0.08, green: 0.08, blue: 0.12),
                                    Color(red: 0.1, green: 0.1, blue: 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryColor.opacity(0.05),
                                            secondaryColor.opacity(0.03),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.0, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 1.0, anchor: .top).combined(with: .opacity)
                    ))
                }
            }
            .clipped() // Ensures content doesn't overflow during animation
        }
        .background(
            ZStack {
                // Darker background matching app template
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1), // darkBackground
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle accent overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                primaryColor.opacity(0.05),
                                secondaryColor.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 16 : 0))
        .shadow(color: .black.opacity(isExpanded ? 0.4 : 0.2), radius: isExpanded ? 15 : 8, x: 0, y: isExpanded ? 8 : 4)
    }
}

// MARK: - Practice View with Loss Aversion Psychology
struct PracticeView: View {
    @StateObject private var agentState = AgentState()
    @ObservedObject private var progressService = GameProgressManager.shared
    @StateObject private var gameProgress = GameProgressManager.shared
    @State private var selectedCategory: PracticeCategory?
    @EnvironmentObject var practiceCoordinator: PracticeCoordinator
    
    // Add state for expandable banner
    @State private var bannerHeight: CGFloat = 70 // Collapsed height
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    // Computed property to get XP earned in current level
    private var currentXPInLevel: Int {
        // Calculate XP needed to START current level
        let totalXPForCurrentLevel = getTotalXPUpToLevel(gameProgress.currentLevel - 1)
        // Current XP minus XP needed to start current level = XP earned in current level
        return max(0, gameProgress.totalXP - totalXPForCurrentLevel)
    }
    
    // Helper function to calculate total XP up to a specific level (matching GameProgressManager logic)
    private func getTotalXPUpToLevel(_ level: Int) -> Int {
        if level <= 0 { return 0 }
        
        var totalXP = 0
        for i in 1..<level {
            totalXP += getXPRequiredForLevel(i)
        }
        return totalXP
    }
    
    // Helper function to get XP required for a specific level (matching GameProgressManager logic)
    private func getXPRequiredForLevel(_ level: Int) -> Int {
        if level <= 1 { return 100 }
        var requirement = 100
        for _ in 2...level {
            requirement = Int(Double(requirement) * 1.5)
        }
        return requirement
    }
    
    var body: some View {
        // Main scrollable content with banner at top
        ScrollView {
            VStack(spacing: 0) {
                // Banner at the top of scroll content
                UniversalTopBanner(title: "Learn", bannerHeight: $bannerHeight)
                
                VStack(spacing: 24) {
                    // 🎯 FOMO: Daily Challenge prominently displayed
                    DailyChallengeCard()
                    
                    // Header
                    headerView
                    
                    // Value Proposition
                    valuePropositionView
                    
                    // Practice Categories Grid
                    categoriesGrid
                    
                    // Coming Soon Preview
                    comingSoonPreview
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // Use SwiftUI toolbarBackground (iOS 16+) to color the navigation bar / status area
        .toolbarBackground(
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            // Centered app name on the toolbar background
            ToolbarItem(placement: .principal) {
                Text("CONVAI")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .kerning(1.8)
            }
        }
        .fullScreenCover(isPresented: $showingLessonView) {
            if let category = selectedLessonCategory {
                NavigationView {
                    LessonView(
                        lessonID: "practice_\(category.rawValue.lowercased())",
                        lessonTitle: category.title,
                        lessonNumber: 1,
                        agentType: getLessonAgentType(for: category),
                        category: category.rawValue.lowercased(),
                        isSimulation: false,
                        simulationContext: ""
                    )
                }
            }
        }
        // TODO: Uncomment when notification names are defined
        /*
        .onReceive(NotificationCenter.default.publisher(for: .saveStreak)) { _ in
            selectCategory(.power)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startDailyChallenge)) { notification in
            if let userInfo = notification.object as? [String: Any],
               let challenge = userInfo["challenge"] as? DailyChallenge {
                let category = categoryFromChallenge(challenge)
                selectCategory(category)
            }
        }
        */
    }
    
    // MARK: - Header View with Loss Aversion
    private var headerView: some View {
        VStack(spacing: 12) {
            // Streak display with loss aversion
            if progressService.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    
                    Text("\(progressService.currentStreak) Day Streak")
                        .font(.headline.bold())
                        .foregroundColor(.orange)
                    
                    // Risk indicator
                    let riskLevel = GameProgressManager.shared.checkStreakRisk()
                    if riskLevel != .none {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(spacing: 6) {
                Text("Level yourself up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            // Loss aversion subtext (only show when important)
            if !headerSubtext.isEmpty {
                Text(headerSubtext)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // Dynamic header messaging based on progress
    private var headerSubtext: String {
    let streak = progressService.currentStreak
    let riskLevel = GameProgressManager.shared.checkStreakRisk()
        
        if riskLevel == StreakRiskLevel.critical {
            return "⚠️ Practice now or lose your elite features!"
        } else if riskLevel == StreakRiskLevel.high {
            return "🔥 Don't break your \(streak)-day streak!"
        } else if streak >= 7 {
            return "🏆 Elite member - Keep your momentum!"
        } else {
            return ""
        }
    }
    
    // MARK: - Value Proposition
    private var valuePropositionView: some View {
        VStack(spacing: 16) {
            Text("Choose a Mentor")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // explanatory paragraph removed per request
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Categories Grid
    private var categoriesGrid: some View {
        VStack(spacing: 20) {
            // All cards in a single vertical column
            PracticeCategoryCard(
                category: .money,
                isSelected: selectedCategory == .money
            ) {
                selectCategory(.money)
            }
            
            PracticeCategoryCard(
                category: .love,
                isSelected: selectedCategory == .love
            ) {
                selectCategory(.love)
            }
            
            PracticeCategoryCard(
                category: .power,
                isSelected: selectedCategory == .power
            ) {
                selectCategory(.power)
            }
            
            PracticeCategoryCard(
                category: .language,
                isSelected: selectedCategory == .language
            ) {
                selectCategory(.language)
            }
            
            PracticeCategoryCard(
                category: .story,
                isSelected: selectedCategory == .story
            ) {
                selectCategory(.story)
            }
        }
    }
    
    // MARK: - Coming Soon Preview
    private var comingSoonPreview: some View {
        VStack(spacing: 16) {
            Text("Future Expansions")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 12) {
                ComingSoonCard(title: "Job Interviews", icon: "briefcase.fill")
                ComingSoonCard(title: "Public Speaking", icon: "mic.fill")
                ComingSoonCard(title: "Team Management", icon: "person.2.fill")
            }
            
            Text("Master all 5 core pillars first, then unlock specialized scenarios")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Navigation States
    @State private var showingLessonView = false
    @State private var selectedLessonCategory: PracticeCategory?
    
    // MARK: - Actions
    private func selectCategory(_ category: PracticeCategory) {
        selectedCategory = category
        selectedLessonCategory = category
        
        // Set the appropriate agent based on category
        if let agent = agentState.getAgentById(category.agentId) {
            agentState.setCurrent(agent)
        }
        
        // Add haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        // Navigate to LessonView with correct parameters
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingLessonView = true
        }
        
        print("🃏 Practice category selected: \(category.title)")
    }
    
    // Map daily challenges to practice categories
    // TODO: Implement when DailyChallenge type is available
    /*
    private func categoryFromChallenge(_ challenge: DailyChallenge) -> PracticeCategory {
        switch challenge.category {
        case "Money": return .money
        case "Love": return .love
        case "Power": return .power
        case "Language": return .language
        case "Story": return .story
        default: return .power // Default fallback
        }
    }
    */
    
    // Helper function to map PracticeCategory to LessonAgentType
    private func getLessonAgentType(for category: PracticeCategory) -> LessonAgentType {
        switch category {
        case .money:
            return .mentor
        case .language:
            return .language
        case .story:
            return .story
        case .love:
            return .coach
        case .power:
            return .tutor
        }
    }
}

// MARK: - Practice Category Card
struct PracticeCategoryCard: View {
    let category: PracticeCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Icon and XP Multiplier
                HStack {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: category.icon)
                            .font(.title)
                            .foregroundColor(category.color)
                    }
                    
                    Spacer()
                    
                    // XP Multiplier badge
                    Text("\(String(format: "%.1f", category.xpMultiplier))x XP")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(category.color)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Category name
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(category.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Title
                    Text(category.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Description
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Value proposition
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(category.color)
                        
                        Text(category.valueProposition)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(category.color)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Start button
                HStack {
                    Text("Start Practice")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.8))
                )
            }
            .padding(20)
            .frame(minHeight: 280)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .stroke(category.color.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [category.color.opacity(0.6), category.color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .opacity(isSelected ? 1.0 : 0.0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Coming Soon Card
struct ComingSoonCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.4))
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Compact Stat Item (Symbol + Value only)
struct CompactStatItem: View {
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(value.isEmpty ? "0" : value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

// MARK: - Stats Banner Card
struct StatsBannerCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PracticeView()
                .environmentObject(PracticeCoordinator(startPractice: { _ in
                    print("Mock practice started")
                }))
        }
        .preferredColorScheme(.dark)
    }
}
