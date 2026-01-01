//
//  InteractiveNotificationView.swift
//  ConvAI
//
//  Created by Assistant on 9/08/2025.
//

import SwiftUI

// Import the required services and models

/// Interactive notification that follows finger with resistance physics
struct InteractiveNotificationView<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    let dismissThreshold: CGFloat
    
    @State private var dragOffset = CGSize.zero
    @State private var isVisible = false
    @State private var isDragging = false
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0
    @State private var resistanceEffect: CGFloat = 1.0
    
    // Physics constants
    private let maxDragDistance: CGFloat = 200
    private let resistanceFactor: CGFloat = 0.3
    private let snapBackThreshold: CGFloat = 100
    
    init(dismissThreshold: CGFloat = 150, onDismiss: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.dismissThreshold = dismissThreshold
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Dark overlay with opacity based on drag
            Color.black
                .opacity(overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isDragging {
                        animateExit()
                    }
                }
            
            VStack {
                // Content with interactive drag behavior
                content
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .offset(dragOffset)
                    .opacity(isVisible ? 1 : 0)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDragChanged(value)
                            }
                            .onEnded { value in
                                handleDragEnded(value)
                            }
                    )
                
                Spacer()
            }
        }
        .onAppear {
            animateEntry()
        }
    }
    
    // MARK: - Drag Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            HapticFeedbackManager.shared.buttonTap()
        }
        
        // Calculate resistance effect (only using vertical distance)
        let dragDistance = abs(value.translation.height)
        let resistance = calculateResistance(for: dragDistance)
        
        // Apply resistance to translation (only vertical movement)
        let resistedTranslation = CGSize(
            width: 0, // Lock horizontal movement
            height: value.translation.height * resistance
        )
        
        dragOffset = resistedTranslation
        
        // Update visual effects based on drag
        updateDragEffects(dragDistance: dragDistance)
        
        // Trigger resistance haptic feedback
        if dragDistance > 50 && Int(dragDistance) % 20 == 0 {
            HapticFeedbackManager.shared.buttonTap()
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        
        let dragDistance = abs(value.translation.height)
        
        if dragDistance > dismissThreshold {
            // Dismiss with momentum (only vertical)
            animateExit(withMomentum: CGSize(width: 0, height: value.translation.height))
        } else {
            // Snap back with elastic animation
            snapBackToCenter()
        }
    }
    
    // MARK: - Physics Calculations
    
    private func calculateResistance(for distance: CGFloat) -> CGFloat {
        // Exponential resistance curve - gets harder to pull further
        let normalizedDistance = min(distance / maxDragDistance, 1.0)
        return 1.0 - pow(normalizedDistance, 2) * (1.0 - resistanceFactor)
    }
    
    private func updateDragEffects(dragDistance: CGFloat) {
        let normalizedDistance = min(dragDistance / maxDragDistance, 1.0)
        
        // Scale effect - gets smaller when pulled
        scale = 1.0 - (normalizedDistance * 0.2)
        
        // Rotation effect - slight tilt based on drag direction
        rotation = Double(dragOffset.width / 10)
        
        // Resistance visual effect
        resistanceEffect = 1.0 + (normalizedDistance * 0.1)
        
        // Update overlay opacity
        withAnimation(.easeOut(duration: 0.1)) {
            // Overlay becomes more transparent as dragged further
        }
    }
    
    // MARK: - Animations
    
    private func animateEntry() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isVisible = true
            scale = 1.0
            dragOffset = .zero
        }
    }
    
    private func animateExit(withMomentum momentum: CGSize = .zero) {
        HapticFeedbackManager.shared.notificationReceived()
        
        let exitOffset = CGSize(
            width: momentum.width * 2,
            height: momentum.height * 2
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = exitOffset
            scale = 0.3
            isVisible = false
            rotation = Double.random(in: -30...30)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss()
        }
    }
    
    private func snapBackToCenter() {
        HapticFeedbackManager.shared.buttonTap()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            dragOffset = .zero
            scale = 1.0
            rotation = 0
            resistanceEffect = 1.0
        }
    }
    
    // MARK: - Computed Properties
    
    private var overlayOpacity: Double {
        let dragDistance = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
        let normalizedDistance = min(dragDistance / dismissThreshold, 1.0)
        return 0.7 - (normalizedDistance * 0.3)
    }
}

// MARK: - Enhanced Achievement Notification with Drag

struct DraggableAchievementNotificationView: View {
    let notification: AchievementNotification
    let onDismiss: () -> Void
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    
    @State private var badgeRotation: Double = 0
    @State private var glowIntensity: Double = 1.0
    
    var body: some View {
        InteractiveNotificationView(
            dismissThreshold: 120,
            onDismiss: onDismiss
        ) {
            achievementContent
        }
    }
    
    private var achievementContent: some View {
        HStack(spacing: 16) {
            // Achievement Badge with Enhanced Animation
            ZStack {
                // Dynamic glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [secondaryColor.opacity(0.8), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(glowIntensity)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowIntensity)
                
                // Badge background with subtle pulsing
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .rotationEffect(.degrees(badgeRotation))
                    .shadow(color: primaryColor.opacity(0.6), radius: 15, x: 0, y: 5)
                
                // Achievement icon
                Image(systemName: notification.achievement.icon)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Achievement details with enhanced typography
            VStack(alignment: .leading, spacing: 6) {
                Text("🎉 Achievement Unlocked!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(secondaryColor)
                    .textCase(.uppercase)
                    .tracking(1.2)
                
                Text(notification.achievement.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(notification.achievement.description)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // XP reward with enhanced styling
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(secondaryColor)
                        .font(.caption)
                    
                    Text("+\(notification.achievement.xpReward) XP")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(secondaryColor)
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Drag indicator
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4, height: 12)
                }
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.95),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor, primaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Badge rotation animation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            badgeRotation = 360
        }
        
        // Glow intensity animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.3
        }
    }
}

// MARK: - Enhanced Bonus Reward with Drag

struct DraggableBonusRewardView: View {
    let bonusXP: Int
    let reason: String
    let category: String?
    let onDismiss: () -> Void
    
    @State private var sparkleAnimation = false
    @State private var pulseEffect = false
    
    var body: some View {
        InteractiveNotificationView(
            dismissThreshold: 100,
            onDismiss: onDismiss
        ) {
            bonusContent
        }
    }
    
    private var bonusContent: some View {
        VStack(spacing: 20) {
            // Sparkle effects
            sparkleLayer
            
            // Main bonus display
            VStack(spacing: 12) {
                // Bonus amount with enhanced styling
                Text("+\(bonusXP)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulseEffect ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseEffect)
                
                Text("BONUS XP!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(2)
                
                Text(reason)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let category = category {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("\(category.uppercased()) BONUS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .tracking(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
                }
                
                // Drag hint
                Text("🤏 Drag to dismiss")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.black.opacity(0.9)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            AngularGradient(
                                colors: [.yellow, .orange, .pink, .purple, .blue, .yellow],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .purple.opacity(0.5), radius: 25, x: 0, y: 10)
        )
        .onAppear {
            startBonusAnimations()
        }
    }
    
    private var sparkleLayer: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange, .pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 3...8))
                    .offset(
                        x: CGFloat.random(in: -80...80),
                        y: CGFloat.random(in: -80...80)
                    )
                    .opacity(sparkleAnimation ? 1.0 : 0.3)
                    .scaleEffect(sparkleAnimation ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.5...2.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: sparkleAnimation
                    )
            }
        }
        .frame(width: 200, height: 120)
    }
    
    private func startBonusAnimations() {
        sparkleAnimation = true
        pulseEffect = true
    }
}

// MARK: - Usage Examples and Integration

/// Overlay wrapper for interactive achievement notifications
struct InteractiveAchievementNotificationOverlay: View {
    @StateObject private var notificationService = AchievementNotificationService.shared
    
    var body: some View {
        ZStack {
            if !notificationService.activeNotifications.isEmpty {
                Color.clear
                    .onAppear {
                        print("🏆 [DEBUG] Overlay showing \(notificationService.activeNotifications.count) notifications")
                    }
                
                ForEach(notificationService.activeNotifications) { notification in
                    DraggableAchievementNotificationView(
                        notification: notification,
                        onDismiss: {
                            notificationService.dismissNotification(notification)
                        }
                    )
                    .zIndex(1000)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .onAppear {
                        print("🏆 [DEBUG] Showing notification: \(notification.achievement.title)")
                    }
                }
            } else {
                Color.clear
                    .onAppear {
                        print("🏆 [DEBUG] Overlay has no active notifications")
                    }
            }
        }
        .allowsHitTesting(!notificationService.activeNotifications.isEmpty)
        .onReceive(notificationService.$activeNotifications) { notifications in
            print("🏆 [DEBUG] Active notifications changed: \(notifications.count) notifications")
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        DraggableAchievementNotificationView(
            notification: AchievementNotification(
                achievement: .firstConversation
            ),
            onDismiss: {}
        )
    }
}
