//
//  ShareAchievementSheet.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import SwiftUI
import UIKit

// 📤 Viral Achievement Sharing System - Drives organic growth and social proof
struct ShareAchievementSheet: View {
    let achievement: ShareableAchievement
    @Binding var isPresented: Bool
    
    @State private var selectedTemplate: ShareTemplate = .story
    @State private var customMessage: String = ""
    @State private var isGeneratingImage = false
    @State private var showingSuccessToast = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Achievement Preview
                achievementPreview
                
                // Share Templates
                shareTemplates
                
                // Custom Message
                customMessageSection
                
                // Share Buttons
                shareButtons
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Share Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Share") { shareAchievement() }
                    .foregroundColor(.orange)
            )
        }
        .overlay(
            // Success toast
            successToast
        )
    }
    
    // MARK: - Achievement Preview
    private var achievementPreview: some View {
        VStack(spacing: 16) {
            // Achievement card
            ZStack {
                // Background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                achievement.category?.color.opacity(0.3) ?? Color.purple.opacity(0.3),
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                VStack(spacing: 12) {
                    // ConvAI Logo/Branding
                    HStack {
                        Text("ConvAI")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("🚀")
                            .font(.title)
                    }
                    
                    Spacer()
                    
                    // Achievement content
                    VStack(spacing: 8) {
                        Image(systemName: achievement.icon)
                            .font(.largeTitle)
                            .foregroundColor(achievement.category?.color ?? .yellow)
                        
                        Text(achievement.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Stats
                    HStack {
                        StatBadge(label: "XP", value: "\(achievement.xpEarned)")
                        
                        if let category = achievement.category {
                            StatBadge(label: "Category", value: category.title)
                        }
                        
                        StatBadge(label: "Level", value: "\(achievement.userLevel)")
                    }
                }
                .padding(20)
            }
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Share Templates
    private var shareTemplates: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Template")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShareTemplate.allCases, id: \.self) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate == template
                        ) {
                            selectedTemplate = template
                            customMessage = template.generateMessage(for: achievement)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Custom Message Section
    private var customMessageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Message")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            TextEditor(text: $customMessage)
                .frame(height: 100)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Share Buttons
    private var shareButtons: some View {
        VStack(spacing: 12) {
            // Primary share platforms
            HStack(spacing: 12) {
                SharePlatformButton(
                    platform: .twitter,
                    action: { shareToTwitter() }
                )
                
                SharePlatformButton(
                    platform: .instagram,
                    action: { shareToInstagram() }
                )
                
                SharePlatformButton(
                    platform: .linkedin,
                    action: { shareToLinkedIn() }
                )
                
                SharePlatformButton(
                    platform: .general,
                    action: { shareGeneral() }
                )
            }
            
            // Copy link button
            Button(action: copyShareLink) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .font(.headline)
                    
                    Text("Copy Shareable Link")
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
    }
    
    // MARK: - Success Toast
    private var successToast: some View {
        VStack {
            if showingSuccessToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Shared successfully!")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 1)
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessToast)
    }
    
    // MARK: - Share Actions
    private func shareToTwitter() {
        let twitterText = customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let twitterURL = "twitter://post?message=\(twitterText)"
        let webTwitterURL = "https://twitter.com/intent/tweet?text=\(twitterText)"
        
        if let url = URL(string: twitterURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webTwitterURL) {
            UIApplication.shared.open(url)
        }
        
        trackShare(platform: "twitter")
        showSuccessToast()
    }
    
    private func shareToInstagram() {
        // Generate achievement image and share to Instagram Stories
        generateAchievementImage { image in
            if let image = image {
                shareImageToInstagramStories(image: image)
            }
        }
        
        trackShare(platform: "instagram")
        showSuccessToast()
    }
    
    private func shareToLinkedIn() {
        let linkedInText = customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let linkedInURL = "https://www.linkedin.com/sharing/share-offsite/?url=https://convai.app&summary=\(linkedInText)"
        
        if let url = URL(string: linkedInURL) {
            UIApplication.shared.open(url)
        }
        
        trackShare(platform: "linkedin")
        showSuccessToast()
    }
    
    private func shareGeneral() {
        let shareSheet = UIActivityViewController(
            activityItems: [customMessage, "Download ConvAI: https://convai.app"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(shareSheet, animated: true)
        }
        
        trackShare(platform: "general")
        showSuccessToast()
    }
    
    private func copyShareLink() {
        let shareLink = "https://convai.app/achievement/\(achievement.id)?ref=\(UUID().uuidString)"
        UIPasteboard.general.string = "\(customMessage)\n\n\(shareLink)"
        
        trackShare(platform: "copy_link")
        showSuccessToast()
    }
    
    private func shareAchievement() {
        shareGeneral()
    }
    
    // MARK: - Helper Methods
    private func generateAchievementImage(completion: @escaping (UIImage?) -> Void) {
        isGeneratingImage = true
        
        // Generate achievement card as image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // This would typically render the achievement view as an image
            // For now, we'll use a placeholder
            completion(nil)
            isGeneratingImage = false
        }
    }
    
    private func shareImageToInstagramStories(image: UIImage) {
        let instagramURL = URL(string: "instagram-stories://share")
        
        if let url = instagramURL, UIApplication.shared.canOpenURL(url) {
            let imageData = image.pngData()
            UIPasteboard.general.setData(imageData!, forPasteboardType: "com.instagram.sharedSticker.backgroundImage")
            UIApplication.shared.open(url)
        }
    }
    
    private func trackShare(platform: String) {
        // Track sharing for analytics
        UserDefaults.standard.set(
            (UserDefaults.standard.integer(forKey: "total_shares") + 1),
            forKey: "total_shares"
        )
        
        let platformKey = "shares_\(platform)"
        UserDefaults.standard.set(
            (UserDefaults.standard.integer(forKey: platformKey) + 1),
            forKey: platformKey
        )
        
        print("📤 Achievement shared on \(platform)")
    }
    
    private func showSuccessToast() {
        showingSuccessToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingSuccessToast = false
            
            // Auto-dismiss sheet after successful share
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: ShareTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: template.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .orange : .white.opacity(0.6))
            
            Text(template.name)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .orange : .white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.orange : Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Share Platform Button
struct SharePlatformButton: View {
    let platform: SharePlatform
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(platform.name)
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(platform.color.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(platform.color, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Models
struct ShareableAchievement {
    let id: String
    let title: String
    let description: String
    let icon: String
    let xpEarned: Int
    let userLevel: Int
    let category: PracticeCategory?
    let timestamp: Date
}

enum ShareTemplate: CaseIterable {
    case humble
    case excited
    case motivational
    case story
    
    var name: String {
        switch self {
        case .humble: return "Humble"
        case .excited: return "Excited"
        case .motivational: return "Motivational"
        case .story: return "Story"
        }
    }
    
    var icon: String {
        switch self {
        case .humble: return "hand.raised.fill"
        case .excited: return "party.popper.fill"
        case .motivational: return "flame.fill"
        case .story: return "book.fill"
        }
    }
    
    func generateMessage(for achievement: ShareableAchievement) -> String {
        switch self {
        case .humble:
            return "Just unlocked '\(achievement.title)' on ConvAI! 🙏 Small steps, big progress. Anyone else working on their conversation skills?"
            
        case .excited:
            return "YES! 🎉 Just achieved '\(achievement.title)' on ConvAI! \(achievement.xpEarned) XP earned and feeling unstoppable! Who's joining me on this journey? 🚀"
            
        case .motivational:
            return "'\(achievement.title)' ✅ Another milestone conquered on ConvAI! 💪 Remember: every conversation is a chance to grow. What are you working on today? #ConversationMastery"
            
        case .story:
            return "Story time: Remember when I was nervous about conversations? Just unlocked '\(achievement.title)' on ConvAI! \(achievement.description) The transformation is real. If I can do it, you can too! 💫"
        }
    }
}

enum SharePlatform {
    case twitter
    case instagram
    case linkedin
    case general
    
    var name: String {
        switch self {
        case .twitter: return "Twitter"
        case .instagram: return "Instagram"
        case .linkedin: return "LinkedIn"
        case .general: return "More"
        }
    }
    
    var icon: String {
        switch self {
        case .twitter: return "message.circle.fill"
        case .instagram: return "camera.circle.fill"
        case .linkedin: return "person.crop.circle.fill"
        case .general: return "square.and.arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .twitter: return .blue
        case .instagram: return .pink
        case .linkedin: return .blue
        case .general: return .gray
        }
    }
}

// MARK: - Preview
#Preview {
    ShareAchievementSheet(
        achievement: ShareableAchievement(
            id: "first_sale",
            title: "First Sale Closed",
            description: "Completed first sales conversation successfully",
            icon: "dollarsign.circle.fill",
            xpEarned: 150,
            userLevel: 5,
            category: .money,
            timestamp: Date()
        ),
        isPresented: .constant(true)
    )
}
