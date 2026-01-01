//
//  AchievementNotificationView.swift
//  ConvAI
//
//  Created on 04/08/2025.
//

import SwiftUI

/// Animated achievement notification overlay
struct AchievementNotificationView: View {
    let notification: AchievementNotification
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var offset: CGFloat = -200
    @State private var scale: CGFloat = 0.8
    @State private var badgeRotation: Double = 0
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Achievement Badge with Animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [secondaryColor.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isVisible ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isVisible)
                    
                    // Badge background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(badgeRotation))
                    
                    // Achievement icon
                    Image(systemName: notification.achievement.icon)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                
                // Achievement details
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(secondaryColor)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(notification.achievement.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(notification.achievement.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // XP reward
                VStack(spacing: 2) {
                    Text("+\(notification.achievement.xpReward)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(secondaryColor)
                    
                    Text("XP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Manual dismiss button
                Button(action: {
                    HapticFeedbackManager.shared.buttonTap()
                    animateExit()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: primaryColor.opacity(0.4), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(scale)
            .offset(y: offset)
            .opacity(isVisible ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            animateEntry()
        }
        .onTapGesture {
            animateExit()
        }
    }
    
    private func animateEntry() {
        // Badge rotation animation
        withAnimation(.linear(duration: 0.5)) {
            badgeRotation = 360
        }
        
        // Slide in animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            isVisible = true
            offset = 20
            scale = 1.0
        }
        
        // Badge rotation animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            badgeRotation = 360
        }
    }
    
    private func animateExit() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = -200
            scale = 0.8
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss()
        }
    }
}

/// Overlay wrapper for achievement notifications
struct AchievementNotificationOverlay: View {
    @StateObject private var notificationService = AchievementNotificationService.shared
    
    var body: some View {
        ZStack {
            if !notificationService.activeNotifications.isEmpty {
                ForEach(notificationService.activeNotifications) { notification in
                    AchievementNotificationView(
                        notification: notification,
                        onDismiss: {
                            notificationService.dismissNotification(notification)
                        }
                    )
                    .zIndex(1000)
                }
            }
        }
        .allowsHitTesting(!notificationService.activeNotifications.isEmpty)
    }
}


#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        AchievementNotificationView(
            notification: AchievementNotification(
                achievement: .firstConversation
            ),
            onDismiss: {}
        )
    }
}

// MARK: - Preview
struct AchievementNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AchievementNotificationView(
                notification: AchievementNotification(
                    achievement: .firstConversation
                ),
                onDismiss: {}
            )
        }
    }
}
