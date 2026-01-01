//
//  BonusRewardPopup.swift
//  ConvAI
//
//  Created by Assistant on 7/08/2025.
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// 🎰 Dopamine-hit Bonus Reward Popup - Variable reward schedule like slot machines
struct BonusRewardPopup: View {
    let bonusXP: Int
    let reason: String
    let category: String? // Simplified to avoid type issues
    @Binding var isShowing: Bool
    
    @State private var animationPhase = 0
    @State private var popupScale: CGFloat = 0.1
    @State private var buttonOpacity: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var bounceOffset: CGFloat = 0
    
    // Dismiss animation states
    @State private var shakeOffset: CGFloat = 0
    @State private var popupOpacity: Double = 1.0
    @State private var isDismissing = false
    
    // Sound and haptic feedback
    @State private var hasTriggeredFeedback = false
    
    var body: some View {
        if isShowing {
            ZStack {
                // Dark overlay
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPopup()
                    }
                
                // Main popup content
                VStack(spacing: 20) {
                    // Sparkle effects
                    sparkleLayer
                    
                    // Main reward display
                    rewardDisplay
                    
                    // Category bonus indicator
                    if let category = category {
                        categoryBonusIndicator(category)
                    }
                }
                .scaleEffect(popupScale)
                .offset(x: shakeOffset, y: bounceOffset)
                .opacity(popupOpacity)
                .onAppear {
                    triggerEntranceAnimation()
                    triggerFeedback()
                }
                
                // Claim bonus button (appears after 1 second)
                VStack {
                    Spacer()
                    claimBonusButton
                        .opacity(buttonOpacity)
                        .padding(.bottom, 50)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: popupScale)
            .animation(.bouncy(duration: 1.0), value: bounceOffset)
            .animation(.easeInOut(duration: 0.5), value: buttonOpacity)
            .animation(.linear(duration: 0.05), value: shakeOffset)
            .animation(.easeOut(duration: 0.3), value: popupOpacity)
        }
    }
    
    // MARK: - Sparkle Layer
    private var sparkleLayer: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 4...12))
                    .offset(
                        x: CGFloat.random(in: -100...100),
                        y: CGFloat.random(in: -100...100)
                    )
                    .opacity(sparkleOpacity)
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.5...1.5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: sparkleOpacity
                    )
            }
        }
        .frame(width: 300, height: 300)
    }
    
    // MARK: - Main Reward Display
    private var rewardDisplay: some View {
        VStack(spacing: 16) {
            // XP Badge with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow.opacity(glowOpacity), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                // Main badge
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        VStack {
                            Text("+\(bonusXP)")
                                .font(.title.bold())
                                .foregroundColor(.black)
                            
                            Text("XP")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                        }
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            
            // Bonus reason
            Text(reason)
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Excitement messaging
            Text(excitementMessage)
                .font(.subheadline)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.3),
                            Color.indigo.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
    
    // MARK: - Category Bonus Indicator
    private func categoryBonusIndicator(_ category: String) -> some View {
        HStack {
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            Text("\(category) Bonus!")
                .font(.headline.bold())
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Claim Bonus Button
    private var claimBonusButton: some View {
        Button(action: dismissPopup) {
            Text("Claim Bonus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.85, green: 0.65, blue: 0.13)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(red: 0.85, green: 0.65, blue: 0.13), lineWidth: 2)
                )
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 10, x: 0, y: 4)
        }
    }
    
    // MARK: - Dynamic Messaging
    private var excitementMessage: String {
        switch bonusXP {
        case 0...50:
            return "Every step counts! 🌟"
        case 51...100:
            return "You're on fire! 🔥"
        case 101...200:
            return "Incredible performance! 🚀"
        case 201...300:
            return "Absolutely crushing it! 💎"
        default:
            return "LEGENDARY PERFORMANCE! 👑"
        }
    }
    
    // MARK: - Animations & Effects
    private func triggerEntranceAnimation() {
        // Scale entrance for popup
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            popupScale = 1.0
        }
        
        // Sparkle effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.8)) {
                sparkleOpacity = 1.0
            }
        }
        
        // Glow effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
        
        // Bounce effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.bouncy(duration: 0.8)) {
                bounceOffset = -20
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.bouncy(duration: 0.6)) {
                    bounceOffset = 0
                }
            }
        }
        
        // Show button after 1 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                buttonOpacity = 1.0
            }
        }
        
        // Trigger haptic feedback
        triggerFeedback()
    }
    
    private func triggerFeedback() {
        guard !hasTriggeredFeedback else { return }
        hasTriggeredFeedback = true
        
        #if canImport(UIKit)
        // Use direct haptic feedback instead of manager
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        print("💰 Bonus popup displayed with haptic feedback: \(bonusXP) XP")
    }
    
    private func dismissPopup() {
        guard !isDismissing else { return }
        isDismissing = true
        
        // Start shake animation with building haptic feedback (AirDrop style)
        triggerShakeWithBuildingHaptics()
        
        // After shake completes, fade out with opacity
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                popupOpacity = 0.0
                buttonOpacity = 0.0
                sparkleOpacity = 0
                glowOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowing = false
            }
        }
    }
    
    private func triggerShakeWithBuildingHaptics() {
        #if canImport(UIKit)
        // Create haptic generators for building feedback
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        
        // Prepare haptic generators
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        #endif
        
        // Shake sequence with increasing intensity and building haptics
        let shakeSequence = [
            (offset: 2.0, delay: 0.0, haptic: "light"),
            (offset: -3.0, delay: 0.05, haptic: "light"),
            (offset: 4.0, delay: 0.1, haptic: "light"),
            (offset: -5.0, delay: 0.15, haptic: "medium"),
            (offset: 6.0, delay: 0.2, haptic: "medium"),
            (offset: -7.0, delay: 0.25, haptic: "medium"),
            (offset: 8.0, delay: 0.3, haptic: "heavy"),
            (offset: -9.0, delay: 0.35, haptic: "heavy"),
            (offset: 10.0, delay: 0.4, haptic: "heavy"),
            (offset: -8.0, delay: 0.45, haptic: "heavy"),
            (offset: 6.0, delay: 0.5, haptic: "medium"),
            (offset: -4.0, delay: 0.55, haptic: "medium"),
            (offset: 2.0, delay: 0.6, haptic: "light"),
            (offset: 0.0, delay: 0.65, haptic: "light")
        ]
        
        // Execute shake sequence
        for shake in shakeSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + shake.delay) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = shake.offset
                }
                
                #if canImport(UIKit)
                // Trigger appropriate haptic feedback
                switch shake.haptic {
                case "light":
                    lightImpact.impactOccurred()
                case "medium":
                    mediumImpact.impactOccurred()
                case "heavy":
                    heavyImpact.impactOccurred()
                default:
                    break
                }
                #endif
            }
        }
        
        print("🔥 Dismissing bonus popup with shake animation and building haptics")
    }
}

// MARK: - Bonus Reward Popup Overlay for Global Display
struct BonusRewardPopupOverlay: View {
    @State private var showingDemo = false
    
    var body: some View {
        ZStack {
            if showingDemo {
                // Demo popup for preview - DISABLED for production
                BonusRewardPopup(
                    bonusXP: 150,
                    reason: "Perfect Conversation!",
                    category: "Money",
                    isShowing: $showingDemo
                )
                .transition(
                    .asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    )
                )
                .zIndex(1000)
            }
        }
        // REMOVED: .onAppear { showingDemo = true } - this was causing automatic +150 XP at app launch
    }
}

// MARK: - Preview
#Preview {
    BonusRewardPopupOverlay()
}
