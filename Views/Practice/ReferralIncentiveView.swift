//
//  ReferralIncentiveView.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// 🎯 Referral Incentive System - Drives exponential user acquisition
struct ReferralIncentiveView: View {
    @StateObject private var referralManager = ReferralManager()
    @State private var showingShareSheet = false
    @State private var showingRewardDetail = false
    @State private var selectedReward: ReferralReward?
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with current stats
                    currentStatsHeader
                    
                    // Active referral challenges
                    if !referralManager.activeChallenges.isEmpty {
                        activeChallengesSection
                    }
                    
                    // Referral rewards timeline
                    rewardTimelineSection
                    
                    // Your referral code
                    referralCodeSection
                    
                    // Leaderboard preview
                    leaderboardPreview
                    
                    // Share incentive
                    shareIncentiveSection
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                referralManager.loadReferralData()
                startPulseAnimation()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ReferralShareSheet(
                referralCode: referralManager.userReferralCode,
                isPresented: $showingShareSheet
            )
        }
        .sheet(item: $selectedReward) { reward in
            RewardDetailView(reward: reward, isPresented: $selectedReward)
        }
    }
    
    // MARK: - Current Stats Header
    private var currentStatsHeader: some View {
        VStack(spacing: 16) {
            // Main CTA with urgency
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: pulseAnimation)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("🚀")
                            .font(.largeTitle)
                        
                        VStack(alignment: .leading) {
                            Text("Invite 3 Friends")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Get Premium FREE for 3 months!")
                                .font(.subheadline.bold())
                                .foregroundColor(.yellow)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(
                                    width: geometry.size.width * min(1.0, Double(referralManager.successfulReferrals) / 3.0),
                                    height: 8
                                )
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                    
                    Text("\(referralManager.successfulReferrals)/3 friends joined")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Current stats grid
            HStack(spacing: 16) {
                ReferralStatCard(
                    title: "Referred",
                    value: "\(referralManager.totalReferrals)",
                    subtitle: "friends",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                ReferralStatCard(
                    title: "XP Earned", 
                    value: "\(referralManager.totalXPEarned)",
                    subtitle: "bonus points",
                    icon: "star.fill",
                    color: .yellow
                )
                
                ReferralStatCard(
                    title: "Rank",
                    value: "#\(referralManager.userRank)",
                    subtitle: "globally",
                    icon: "trophy.fill",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Active Challenges Section
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ Active Challenges")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ForEach(referralManager.activeChallenges, id: \.id) { challenge in
                ReferralChallengeCard(challenge: challenge)
            }
        }
    }
    
    // MARK: - Reward Timeline Section
    private var rewardTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎁 Referral Rewards")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(referralManager.rewardMilestones, id: \.referralCount) { reward in
                    RewardMilestoneCard(
                        reward: reward,
                        currentReferrals: referralManager.successfulReferrals,
                        onTap: {
                            selectedReward = reward
                            showingRewardDetail = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Referral Code Section
    private var referralCodeSection: some View {
        VStack(spacing: 16) {
            Text("📱 Your Referral Code")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                VStack(spacing: 12) {
                    Text(referralManager.userReferralCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    HStack(spacing: 16) {
                        Button(action: copyReferralCode) {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copy Code")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: shareReferralCode) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Share Now")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Leaderboard Preview
    private var leaderboardPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🏆 Referral Leaderboard")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full leaderboard
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                ForEach(referralManager.topReferrers.prefix(3), id: \.userId) { referrer in
                    HStack {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(for: referrer.rank))
                                .frame(width: 32, height: 32)
                            
                            Text("\(referrer.rank)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(referrer.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            
                            Text("\(referrer.referralCount) referrals")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        if referrer.userId == referralManager.currentUserId {
                            Text("YOU")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - Share Incentive Section
    private var shareIncentiveSection: some View {
        VStack(spacing: 16) {
            Text("💫 Why Share ConvAI?")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                IncentivePoint(
                    icon: "gift.fill",
                    title: "Free Premium Features",
                    description: "Unlock advanced conversation training for every friend who joins",
                    color: .purple
                )
                
                IncentivePoint(
                    icon: "star.fill",
                    title: "Bonus XP for Life",
                    description: "Earn 25% of your friends' XP forever (they keep 100%)",
                    color: .yellow
                )
                
                IncentivePoint(
                    icon: "crown.fill",
                    title: "VIP Status",
                    description: "Get exclusive access to new features and personal coaching",
                    color: .orange
                )
            }
            
            // Final CTA
            Button(action: { showingShareSheet = true }) {
                HStack {
                    Text("🚀")
                        .font(.title2)
                    
                    Text("Start Sharing Now")
                        .font(.title3.bold())
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Helper Methods
    private func startPulseAnimation() {
        pulseAnimation = true
    }
    
    private func copyReferralCode() {
        #if canImport(UIKit)
        UIPasteboard.general.string = referralManager.userReferralCode
        // Simple haptic feedback using centralized manager
        HapticFeedbackManager.shared.buttonTap()
        #endif
    }
    
    private func shareReferralCode() {
        showingShareSheet = true
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Referral Challenge Card
struct ReferralChallengeCard: View {
    let challenge: ReferralChallenge
    
    var body: some View {
        HStack {
            // Challenge icon and info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(challenge.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Text(challenge.emoji)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Text("Reward: \(challenge.rewardDescription)")
                            .font(.caption.bold())
                            .foregroundColor(challenge.color)
                        
                        Spacer()
                        
                        Text(challenge.timeRemaining)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(challenge.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Reward Milestone Card
struct RewardMilestoneCard: View {
    let reward: ReferralReward
    let currentReferrals: Int
    let onTap: () -> Void
    
    private var isUnlocked: Bool {
        currentReferrals >= reward.referralCount
    }
    
    private var isNext: Bool {
        !isUnlocked && reward.referralCount == nextMilestone
    }
    
    private var nextMilestone: Int {
        // Find the next milestone after current referrals
        return reward.referralCount // Simplified for this example
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Milestone indicator
                ZStack {
                    Circle()
                        .fill(isUnlocked ? .green : (isNext ? .orange : .gray.opacity(0.3)))
                        .frame(width: 48, height: 48)
                    
                    if isUnlocked {
                        Image(systemName: "checkmark")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    } else {
                        Text("\(reward.referralCount)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text(reward.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if isNext {
                        Text("\(reward.referralCount - currentReferrals) more friends to unlock")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Text(reward.emoji)
                    .font(.title)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? Color.green.opacity(0.1) : (isNext ? Color.orange.opacity(0.1) : Color.white.opacity(0.1)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isUnlocked ? .green : (isNext ? .orange : .gray.opacity(0.3)), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Incentive Point
struct IncentivePoint: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Referral Share Sheet
struct ReferralShareSheet: UIViewControllerRepresentable {
    let referralCode: String
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let shareText = """
        🚀 I'm improving my conversation skills with ConvAI and it's incredible!
        
        Use my code \(referralCode) to get started and we both get bonus features!
        
        Download: https://convai.app/invite/\(referralCode)
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Referral Stat Card
struct ReferralStatCard: View {
    let title: String
    let value: String
    let subtitle: String
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
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
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

// MARK: - Reward Detail View
struct RewardDetailView: View {
    let reward: ReferralReward
    @Binding var isPresented: ReferralReward?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    VStack(spacing: 16) {
                        Text(reward.emoji)
                            .font(.system(size: 100))
                        
                        Text(reward.title)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(reward.referralCount) Referrals Required")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange, lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Reward details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What You Get:")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        Text(reward.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                        
                        // Additional benefits based on reward type
                        if reward.referralCount >= 10 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🌟 Exclusive Benefits:")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.yellow)
                                
                                BenefitRow(icon: "crown.fill", text: "VIP status badge in app", color: .yellow)
                                BenefitRow(icon: "star.fill", text: "Priority customer support", color: .blue)
                                BenefitRow(icon: "gift.fill", text: "Early access to new features", color: .purple)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }
                    
                    // Progress indicator
                    let currentReferrals = 0 // This would come from referralManager
                    if currentReferrals < reward.referralCount {
                        VStack(spacing: 12) {
                            Text("Your Progress")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            
                            SwiftUI.ProgressView(value: Double(currentReferrals), total: Double(reward.referralCount))
                                .tint(.orange)
                                .scaleEffect(1.2)
                            
                            Text("\(currentReferrals) / \(reward.referralCount) referrals")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(reward.referralCount - currentReferrals) more friends needed")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                    
                    // CTA
                    Button(action: { isPresented = nil }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Start Inviting Friends")
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
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Reward Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = nil
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ReferralIncentiveView()
}
