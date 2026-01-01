//
//  NewConvAIPaywall.swift
//  ConvAI
//
//  Created by Implementation on 30/08/2025.
//

import SwiftUI
import StoreKit

@available(iOS 15.0, *)
struct NewConvAIPaywall: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var trialManager = TrialManager()
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    // Callbacks for navigation
    let onSubscriptionSuccess: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    // Dynamic date calculations
    private var billingStartDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return formatter.string(from: futureDate)
    }
    
    // ConvAI Brand Colors
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    init(onSubscriptionSuccess: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onSubscriptionSuccess = onSubscriptionSuccess
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 0) {
                    // When yearly plan selected, show only the trial timeline.
                    // When monthly plan selected, show only the header text.
                    if selectedPlan == .yearly {
                        trialTimelineSection
                            .padding(.top, 20)
                    } else {
                        VStack(spacing: 16) {
                            headerSection
                                .padding(.top, 40)

                            // For monthly plan, show compact features below the header
                            compactFeaturesSection
                                .padding(.top, 12)
                        }
                    }

                    Spacer()

                    // Pricing Options (always visible)
                    pricingSection
                        .padding(.bottom, 20)

                    // Call to Action (always visible)
                    ctaSection
                        .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        // Prefer AppCoordinator-provided onDismiss to let the coordinator control navigation
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                }
            }
        }
        .onAppear {
            setupPaywall()
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Timeline Section
    private var trialTimelineSection: some View {
        VStack(spacing: 24) {
            Text("Start your 3-day FREE \ntrial to continue.")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .allowsTightening(false)
                .layoutPriority(1) 
            
            // Vertical Timeline
            VStack(spacing: 0) {
                // Today - Unlock features
                TimelineVerticalStep(
                    icon: "lock.open.fill",
                    title: "Today",
                    subtitle: "Unlock all the app's features like AI conversation practice and more.",
                    isActive: true,
                    color: secondaryColor,
                    isLast: false
                )
                
                // In 2 Days - Reminder
                TimelineVerticalStep(
                    icon: "bell.fill",
                    title: "In 2 Days - Reminder",
                    subtitle: "We'll send you a reminder that your trial is ending soon.",
                    isActive: false,
                    color: primaryColor,
                    isLast: false
                )
                
                // In 3 Days - Billing Starts
                TimelineVerticalStep(
                    icon: "creditcard.fill",
                    title: "In 3 Days - Billing Starts",
                    subtitle: "You'll be charged on \(billingStartDate) unless you cancel anytime before.",
                    isActive: false,
                    color: primaryColor,
                    isLast: true
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text("Unlock ConvAI to reach your goals faster.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .allowsTightening(false)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Compact Features Section
    private var compactFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            CompactFeatureRow(
                icon: "person.2.wave.2.fill",
                title: "AI Conversation Practice",
                description: "Practice speaking with realistic AI characters"
            )
            
            CompactFeatureRow(
                icon: "waveform.circle.fill",
                title: "Multiple Voice Personalities",
                description: "20+ voices for different conversation scenarios"
            )
            
            CompactFeatureRow(
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                title: "Track your progress",
                description: "Stay on track with personalized insights and smart reminders"
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Monthly Option
                CompactPricingCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor
                ) {
                    selectedPlan = .monthly
                }
                
                // Yearly Option
                CompactPricingCard(
                    plan: .yearly,
                    isSelected: selectedPlan == .yearly,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    showBadge: true
                ) {
                    selectedPlan = .yearly
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - CTA Section
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await purchaseSelectedPlan()
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(ctaButtonText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(isPurchasing)
            .scaleEffect(isPurchasing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPurchasing)
            
            // Pricing details
            Text(pricingDetailsText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            // Trust signals
            if selectedPlan == .yearly {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No Payment Due Now")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No Commitment - Cancel Anytime")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [darkBackground, secondaryDark],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    private var ctaButtonText: String {
        if isPurchasing {
            return "Processing..."
        }
        
        switch selectedPlan {
        case .yearly:
            return "Start My 3-Day Free Trial"
        case .monthly:
            return "Start My Journey"
        }
    }
    
    private var pricingDetailsText: String {
        switch selectedPlan {
        case .yearly:
            return "3 days free, then €34,99 per year (€2,91/mo)"
        case .monthly:
            return "Just €9,99 per month"
        }
    }
    
    // MARK: - Methods
    private func setupPaywall() {
        Task {
            await subscriptionManager.loadProducts()
        }
    }
    
    private func purchaseSelectedPlan() async {
        isPurchasing = true
        
        do {
            let success = try await subscriptionManager.purchase(plan: selectedPlan)
            
            if success {
                // Purchase successful - navigate to main tab
                DispatchQueue.main.async {
                    self.isPurchasing = false
                    self.onSubscriptionSuccess?()
                }
            } else {
                DispatchQueue.main.async {
                    self.isPurchasing = false
                    self.errorMessage = "Purchase was cancelled or failed"
                    self.showingError = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isPurchasing = false
                self.errorMessage = error.localizedDescription
                self.showingError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct TimelineVerticalStep: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let color: Color
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with connecting line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isActive ? color : Color.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isActive ? .white : .white.opacity(0.6))
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 8)
    }
}

struct CompactFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.green)
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct TimelineStep: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isActive ? color : Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isActive ? .white : .white.opacity(0.6))
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct TimelineConnector: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}

struct CompactPricingCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let showBadge: Bool
    let onTap: () -> Void
    
    init(plan: SubscriptionPlan, isSelected: Bool, primaryColor: Color, secondaryColor: Color, showBadge: Bool = false, onTap: @escaping () -> Void) {
        self.plan = plan
        self.isSelected = isSelected
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.showBadge = showBadge
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Badge (if applicable)
                if showBadge, let badge = plan.badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(secondaryColor)
                        .cornerRadius(8)
                }
                
                // Plan title
                Text(plan.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                // Price
                Text(plan.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // Original price (for yearly)
                if let originalPrice = plan.originalPrice {
                    Text(originalPrice)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .strikethrough()
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? secondaryColor : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        LinearGradient(colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.2)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? secondaryColor : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct PricingCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let showBadge: Bool
    let onTap: () -> Void
    
    init(plan: SubscriptionPlan, isSelected: Bool, primaryColor: Color, secondaryColor: Color, showBadge: Bool = false, onTap: @escaping () -> Void) {
        self.plan = plan
        self.isSelected = isSelected
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.showBadge = showBadge
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Badge (if applicable)
                if showBadge, let badge = plan.badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(secondaryColor)
                        .cornerRadius(12)
                }
                
                // Plan title
                Text(plan.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Price
                Text(plan.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Original price (for yearly)
                if let originalPrice = plan.originalPrice {
                    Text(originalPrice)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Savings/Trial info
                if let savings = plan.savings {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(plan == .yearly ? .green : .white.opacity(0.6))
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? secondaryColor : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.2)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? secondaryColor : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
@available(iOS 15.0, *)
struct NewConvAIPaywall_Previews: PreviewProvider {
    static var previews: some View {
        NewConvAIPaywall()
    }
}

#Preview {
    NewConvAIPaywall()
}     
