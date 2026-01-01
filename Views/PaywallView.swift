//
//  PaywallView.swift
//  ConvAI
//
//  Created by GitHub Copilot on 02/08/2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    let onSubscribe: () -> Void
    let onSkip: () -> Void
    
    @State private var subscriptionGroupID = "21479145" // Replace with your actual subscription group ID
    
    var body: some View {
        SubscriptionStoreView(groupID: subscriptionGroupID) {
            // Custom marketing content (optional)
            VStack(spacing: 24) {
                // ConvAI branding
                VStack(spacing: 16) {
                    Text("🎯")
                        .font(.system(size: 60))
                    
                    Text("Master Conversations with AI")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Practice real conversations with our advanced AI coach")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Feature highlights
                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "timer",
                        title: "Daily Practice Time",
                        description: "180 minutes of daily conversations"
                    )
                    
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Conversation Coach",
                        description: "Real-time feedback and personalized tips"
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress Tracking",
                        description: "Monitor your improvement over time"
                    )
                }
                .padding(.horizontal, 32)
            }
        }
        .onInAppPurchaseCompletion { product, result in
            handlePurchaseCompletion(product: product, result: result)
        }
        .subscriptionStoreButtonLabel(.action) // Use action style button
        .subscriptionStorePickerItemBackground(.primary) // Customize appearance
        .storeButton(.visible, for: .restorePurchases) // Show restore button
    }
    
    private func handlePurchaseCompletion(product: Product, result: Result<Product.PurchaseResult, Error>) {
        switch result {
        case .success(let purchaseResult):
            switch purchaseResult {
            case .success(_):
                // Handle successful purchase
                print("✅ Purchase successful: \(product.displayName)")
                onSubscribe()
                
            case .userCancelled:
                print("❌ User cancelled purchase")
                
            case .pending:
                print("⏳ Purchase pending approval")
                
            @unknown default:
                print("🤷‍♂️ Unknown purchase result")
            }
            
        case .failure(let error):
            print("❌ Purchase failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.78, green: 0.36, blue: 0.17).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.17))
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        onSubscribe: {
            print("Subscribe button tapped")
        },
        onSkip: {
            print("Skip button tapped")
        }
    )
}
