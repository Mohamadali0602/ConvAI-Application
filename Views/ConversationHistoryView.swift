//
//  ConversationHistoryView.swift
//  ConvAI
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ConversationHistoryView: View {
    // COMMENTED OUT: @ObservedObject var userProgressService = UserProgressService.shared
    
    // TEMPORARY: Mock data while UserProgressService is commented out
    private let mockProgress = MockProgress()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [darkBackground, Color(red: 0.1, green: 0.1, blue: 0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Stats
                    headerStatsView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Progress Overview instead of individual sessions
                    progressOverviewView
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Progress Overview")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadLocalProgress()
        }
    }
    
    // MARK: - Header Stats
    private var headerStatsView: some View {
        VStack(spacing: 15) {
            // Overall Stats
            HStack(spacing: 20) {
                ProgressStatCard(
                    title: "Total Sessions",
                    value: "\(mockProgress.conversationsCompleted)",
                    icon: "message.circle.fill",
                    color: primaryColor
                )
                
                ProgressStatCard(
                    title: "Total XP",
                    value: "\(mockProgress.totalXP)",
                    icon: "star.fill",
                    color: secondaryColor
                )
                
                ProgressStatCard(
                    title: "Current Streak",
                    value: "\(mockProgress.dailyStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Progress Overview
    private var progressOverviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Achievement Progress
                achievementProgressView
                
                // Weekly Progress
                weeklyProgressView
                
                // Level Progress
                levelProgressView
                
                // Recent Activity Summary
                recentActivityView
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Achievement Progress
    private var achievementProgressView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Achievement Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(mockProgress.unlockedAchievements.prefix(6), id: \.id) { achievement in
                    VStack(spacing: 8) {
                        Image(systemName: achievement.icon)
                            .font(.title2)
                            .foregroundColor(secondaryColor)
                        
                        Text(achievement.title)
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(secondaryColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Weekly Progress
    private var weeklyProgressView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Week")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                ProgressStatCard(
                    title: "Days Active",
                    value: "\(min(mockProgress.dailyStreak, 7))/7",
                    icon: "calendar.badge.checkmark",
                    color: .green
                )
                
                ProgressStatCard(
                    title: "Level Progress",
                    value: "Level \(mockProgress.currentLevel)",
                    icon: "star.circle.fill",
                    color: primaryColor
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Level Progress
    private var levelProgressView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Level Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Level \(mockProgress.currentLevel)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(mockProgress.totalXP) XP")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Progress bar (simplified - you can calculate next level XP requirement)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(primaryColor)
                            .frame(width: geometry.size.width * 0.6, height: 8) // Example progress
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Recent Activity
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ActivityItem(
                    title: "Conversations Completed",
                    value: "\(mockProgress.conversationsCompleted)",
                    icon: "message.circle.fill",
                    color: primaryColor
                )
                
                ActivityItem(
                    title: "Current Streak",
                    value: "\(mockProgress.dailyStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ActivityItem(
                    title: "Achievements Earned",
                    value: "\(mockProgress.unlockedAchievements.count)",
                    icon: "trophy.fill",
                    color: secondaryColor
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Load Local Progress
    private func loadLocalProgress() {
        // This now just refreshes the view with current progress
        // No server calls needed since everything is in UserProgressService
    }
}

// MARK: - Progress Stat Card Component
struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Activity Item Component
struct ActivityItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Mock Progress (Temporary while UserProgressService is commented out)
struct MockProgress {
    let conversationsCompleted = 15
    let totalXP = 750
    let dailyStreak = 5
    let currentLevel = 2
    let unlockedAchievements: [MockAchievement] = [
        MockAchievement(id: "first_conversation", title: "First Steps", icon: "message.circle.fill"),
        MockAchievement(id: "streak_7_days", title: "Week Warrior", icon: "flame.fill"),
        MockAchievement(id: "conversation_milestone_10", title: "Chatty", icon: "star.fill"),
        MockAchievement(id: "level_up_2", title: "Level 2", icon: "trophy.fill"),
        MockAchievement(id: "xp_milestone_500", title: "Rising Star", icon: "star.circle.fill"),
        MockAchievement(id: "dedicated_learner", title: "Dedicated", icon: "book.fill")
    ]
}

struct MockAchievement: Identifiable {
    let id: String
    let title: String
    let icon: String
}

// MARK: - Preview
struct ConversationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationHistoryView()
    }
}
