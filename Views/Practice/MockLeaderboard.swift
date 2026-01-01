//
//  MockLeaderboard.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import SwiftUI

// 🏆 Mock Leaderboard for Social Proof - Creates FOMO and competitive drive
struct MockLeaderboard: View {
    @State private var leaderboardType: LeaderboardType = .weekly
    @State private var userRank: Int = 42
    @State private var topUsers: [LeaderboardUser] = []
    @State private var userXP: Int = 0
    @State private var showingDetail = false
    @State private var selectedUser: LeaderboardUser?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Leaderboard Type Selector
            typeSelector
            
            // Top 3 Podium
            podiumView
            
            // User's Position
            userRankCard
            
            // Leaderboard List
            leaderboardList
            
            // Share Achievement Button
            shareButton
        }
        .padding()
        .background(Color.black)
        .onAppear {
            loadLeaderboard()
            loadUserStats()
        }
        .sheet(isPresented: $showingDetail) {
            if let user = selectedUser {
                UserDetailSheet(user: user)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                
                Text("Leaderboard")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // Live indicator
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("LIVE")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            
            Text("See how you rank against other ConvAI masters")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Type Selector
    private var typeSelector: some View {
        Picker("Leaderboard", selection: $leaderboardType) {
            ForEach(LeaderboardType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: leaderboardType) { _ in
            loadLeaderboard()
        }
    }
    
    // MARK: - Podium View
    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2nd Place
            if topUsers.count > 1 {
                podiumPosition(user: topUsers[1], rank: 2, height: 80)
            }
            
            // 1st Place
            if topUsers.count > 0 {
                podiumPosition(user: topUsers[0], rank: 1, height: 100)
            }
            
            // 3rd Place
            if topUsers.count > 2 {
                podiumPosition(user: topUsers[2], rank: 3, height: 60)
            }
        }
        .padding(.vertical, 20)
    }
    
    private func podiumPosition(user: LeaderboardUser, rank: Int, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Crown for first place
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
            
            // User info
            VStack(spacing: 4) {
                Circle()
                    .fill(user.profileColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    )
                
                Text(user.displayName)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(user.xp) XP")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                // Success story
                if !user.achievement.isEmpty {
                    Text(user.achievement)
                        .font(.caption2)
                        .foregroundColor(user.achievementColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                }
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(podiumColor(rank: rank))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(podiumBorderColor(rank: rank), lineWidth: 2)
                    )
            )
            
            // Podium base
            Rectangle()
                .fill(podiumColor(rank: rank))
                .frame(width: 90, height: height)
                .overlay(
                    Text("#\(rank)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                )
        }
        .onTapGesture {
            selectedUser = user
            showingDetail = true
        }
    }
    
    // MARK: - User Rank Card
    private var userRankCard: some View {
        HStack {
            // Rank indicator
            Text("#\(userRank)")
                .font(.title2.bold())
                .foregroundColor(.orange)
                .frame(width: 50)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text("You")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Text("\(userXP) XP")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Progress to next rank
            VStack(alignment: .trailing, spacing: 4) {
                Text("Next: #\(userRank - 1)")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                
                if userRank > 1, topUsers.count >= userRank - 1 {
                    let nextUserXP = topUsers[userRank - 2].xp
                    let xpNeeded = nextUserXP - userXP
                    
                    Text("+\(xpNeeded) XP needed")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange, lineWidth: 2)
                )
        )
    }
    
    // MARK: - Leaderboard List
    private var leaderboardList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(topUsers.enumerated()), id: \.element.id) { index, user in
                LeaderboardRow(user: user, rank: index + 1)
                    .onTapGesture {
                        selectedUser = user
                        showingDetail = true
                    }
            }
        }
    }
    
    // MARK: - Share Button
    private var shareButton: some View {
        Button(action: shareAchievement) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.headline)
                
                Text("Share Your Rank")
                    .font(.headline.bold())
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helper Methods
    private func podiumColor(rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.3)
        case 2: return Color.gray.opacity(0.3)
        case 3: return Color.orange.opacity(0.3)
        default: return Color.blue.opacity(0.3)
        }
    }
    
    private func podiumBorderColor(rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private func shareAchievement() {
        let text = "I'm ranked #\(userRank) this \(leaderboardType.rawValue.lowercased()) on ConvAI! 🏆 Join me to improve your conversation skills and climb the leaderboard!"
        
        let shareSheet = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(shareSheet, animated: true)
        }
    }
    
    private func loadLeaderboard() {
        // Generate realistic mock data based on leaderboard type
        topUsers = generateMockUsers(for: leaderboardType)
        
        // Adjust user rank based on type
        userRank = {
            switch leaderboardType {
            case .daily: return Int.random(in: 25...60)
            case .weekly: return Int.random(in: 35...75)
            case .monthly: return Int.random(in: 40...90)
            case .allTime: return Int.random(in: 50...150)
            }
        }()
    }
    
    private func loadUserStats() {
        userXP = UserDefaults.standard.integer(forKey: "userXP")
    }
    
    private func generateMockUsers(for type: LeaderboardType) -> [LeaderboardUser] {
        let baseXP = {
            switch type {
            case .daily: return 500
            case .weekly: return 2000
            case .monthly: return 8000
            case .allTime: return 25000
            }
        }()
        
        return [
            // Top performers with success stories
            LeaderboardUser(
                id: "sarah_m",
                name: "Sarah Martinez",
                xp: baseXP + 500,
                level: 25,
                achievement: "Closed $50K deal last week! 💰",
                achievementColor: .green,
                profileColor: .pink
            ),
            LeaderboardUser(
                id: "mike_r",
                name: "Mike Rodriguez",
                xp: baseXP + 300,
                level: 22,
                achievement: "Got 3 dates this week! 💖",
                achievementColor: .pink,
                profileColor: .blue
            ),
            LeaderboardUser(
                id: "alex_k",
                name: "Alex Kim",
                xp: baseXP + 100,
                level: 20,
                achievement: "Promoted to team lead! 🚀",
                achievementColor: .orange,
                profileColor: .purple
            ),
            LeaderboardUser(
                id: "jessica_w",
                name: "Jessica Wu",
                xp: baseXP - 50,
                level: 18,
                achievement: "Aced job interview! 🎯",
                achievementColor: .blue,
                profileColor: .green
            ),
            LeaderboardUser(
                id: "david_l",
                name: "David Lee",
                xp: baseXP - 150,
                level: 16,
                achievement: "7-day streak master 🔥",
                achievementColor: .red,
                profileColor: .yellow
            ),
            LeaderboardUser(
                id: "emma_s",
                name: "Emma Smith",
                xp: baseXP - 200,
                level: 15,
                achievement: "Confidence through the roof! ⚡",
                achievementColor: .yellow,
                profileColor: .orange
            ),
            LeaderboardUser(
                id: "carlos_g",
                name: "Carlos Garcia",
                xp: baseXP - 280,
                level: 14,
                achievement: "Sales skills paying off! 💎",
                achievementColor: .green,
                profileColor: .red
            ),
            LeaderboardUser(
                id: "priya_p",
                name: "Priya Patel",
                xp: baseXP - 350,
                level: 13,
                achievement: "Social butterfly mode! 🦋",
                achievementColor: .purple,
                profileColor: .teal
            )
        ]
    }
}

// MARK: - LeaderboardRow Component
struct LeaderboardRow: View {
    let user: LeaderboardUser
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("#\(rank)")
                .font(.headline.bold())
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            // Profile
            Circle()
                .fill(user.profileColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.name.prefix(1)))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !user.achievement.isEmpty {
                    Text(user.achievement)
                        .font(.caption)
                        .foregroundColor(user.achievementColor)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // XP and level
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(user.xp) XP")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Text("Level \(user.level)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        case 4...10: return .blue
        default: return .white.opacity(0.6)
        }
    }
}

// MARK: - User Detail Sheet
struct UserDetailSheet: View {
    let user: LeaderboardUser
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile section
                VStack(spacing: 16) {
                    Circle()
                        .fill(user.profileColor)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(user.name.prefix(1)))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        )
                    
                    Text(user.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Level \(user.level) • \(user.xp) XP")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Achievement
                if !user.achievement.isEmpty {
                    VStack(spacing: 8) {
                        Text("Latest Achievement")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(user.achievement)
                            .font(.title3.bold())
                            .foregroundColor(user.achievementColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(user.achievementColor.opacity(0.2))
                    )
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Models
enum LeaderboardType: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case allTime = "All Time"
}

struct LeaderboardUser {
    let id: String
    let name: String
    let xp: Int
    let level: Int
    let achievement: String
    let achievementColor: Color
    let profileColor: Color
    
    var displayName: String {
        // Privacy-friendly display (first name + last initial)
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0]) \(components[1].prefix(1))."
        }
        return name
    }
}

// MARK: - Preview
#Preview {
    MockLeaderboard()
}
