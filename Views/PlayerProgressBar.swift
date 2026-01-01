//
//  PlayerProgressBar.swift
//  ConvAI
//
//  Created by Mohamad Ali on 07/08/2025.
//

import SwiftUI

// MARK: - Player Progress Bar Component
struct PlayerProgressBar: View {
    @StateObject private var gameProgress = GameProgressManager.shared
    
    // ConvAI Colors (using LoadingScreen gradient styles)
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let accentColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    let outlineColor = Color(red: 0.95, green: 0.91, blue: 0.86) // #F3E9DC
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Level & XP Display
            PlayerLevelCard()
            
            // Psychological Metrics Row
            HStack(spacing: 12) {
                ConfidenceMeterCard()
                
                PsychologicalStatsGrid()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(primaryColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Player Level Card
struct PlayerLevelCard: View {
    @StateObject private var gameProgress = GameProgressManager.shared
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let accentColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 12) {
            // Level & Title Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(gameProgress.getPlayerLevel().emoji)")
                            .font(.title)
                        
                        Text("Level \(gameProgress.currentLevel)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text(gameProgress.getPlayerLevel().title)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // XP Display
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(gameProgress.totalXP) XP")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                    
                    Text("\(gameProgress.getXPForNextLevel()) to next level")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // XP Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress to Next Level")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(Int(gameProgress.getProgressToNextLevel() * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)
                }
                
                // Animated Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 8)
                        
                        // Progress Fill - Clamped to container width
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, primaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0, min(geometry.size.width, geometry.size.width * gameProgress.getProgressToNextLevel())),
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.5), value: gameProgress.getProgressToNextLevel())
                            .clipped() // Ensure progress bar doesn't overflow container
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Confidence Meter Card (Always Goes Up!)
struct ConfidenceMeterCard: View {
    @StateObject private var gameProgress = GameProgressManager.shared
    
    let accentColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    let confidenceColor = Color(red: 0.34, green: 0.66, blue: 0.33) // Green for confidence
    
    var body: some View {
        VStack(spacing: 8) {
            // Confidence Icon & Label
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(confidenceColor)
                
                Text("Confidence")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Confidence Level
            Text("\(Int(gameProgress.confidenceMeter))%")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(confidenceColor)
            
            // Confidence Bar (Circular)
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: gameProgress.confidenceMeter / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [confidenceColor, accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: gameProgress.confidenceMeter)
            }
            
            // Status Message
            Text(gameProgress.getStatusMessage())
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(confidenceColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Psychological Stats Grid
struct PsychologicalStatsGrid: View {
    @StateObject private var gameProgress = GameProgressManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Top Row: Money & Love Metrics
            HStack(spacing: 8) {
                PsychStatCard(
                    title: "Deals Closed",
                    value: "\(gameProgress.dealsClosedCounter)",
                    icon: "dollarsign.circle.fill",
                    color: Color(red: 0.20, green: 0.66, blue: 0.33) // Money green
                )
                
                PsychStatCard(
                    title: "Rejection Score",
                    value: "\(gameProgress.rejectionScore)",
                    icon: "heart.fill",
                    color: Color(red: 0.96, green: 0.22, blue: 0.63) // Love pink
                )
            }
            
            // Bottom Row: Power & Streak
            HStack(spacing: 8) {
                PsychStatCard(
                    title: "Power Moves",
                    value: "\(gameProgress.powerMovesUsed)",
                    icon: "bolt.fill",
                    color: Color(red: 0.98, green: 0.74, blue: 0.02) // Power gold
                )
                
                PsychStatCard(
                    title: "Day Streak",
                    value: "\(gameProgress.currentStreak)",
                    icon: "flame.fill",
                    color: Color(red: 1.0, green: 0.5, blue: 0.0) // Streak orange
                )
            }
        }
    }
}

// MARK: - Individual Psychological Stat Card (Copy of ProgressStatCard pattern)
struct PsychStatCard: View {
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
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Motivational Message Card
struct MotivationalMessageCard: View {
    @StateObject private var gameProgress = GameProgressManager.shared
    @State private var currentCategory: String = "money"
    
    let accentColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(accentColor)
                
                Text("Your Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Category Selector
                Menu {
                    Button("Money") { currentCategory = "money" }
                    Button("Love") { currentCategory = "love" }
                    Button("Power") { currentCategory = "power" }
                } label: {
                    HStack {
                        Text(currentCategory.capitalized)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(accentColor)
                }
            }
            
            Text(gameProgress.getMotivationalMessage(for: currentCategory))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
struct PlayerProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PlayerProgressBar()
            
            MotivationalMessageCard()
        }
        .padding()
        .background(Color.black)
        .onAppear {
            // Mock some progress data for preview
            let manager = GameProgressManager.shared
            // Note: awardXP is removed, progress is now handled through completeConversation
            manager.completeConversation(categoryName: "money", duration: 300, performance: .excellent)
            manager.completeConversation(categoryName: "love", duration: 240, performance: .good)
            manager.completeConversation(categoryName: "power", duration: 180, performance: .excellent)
        }
    }
}
