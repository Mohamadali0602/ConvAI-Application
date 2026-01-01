//
//  SubscriptionManager.swift
//  ConvAI
//
//  Created by Implementation on 30/08/2025.
//

import Foundation
import StoreKit
import Combine

enum SubscriptionPlan {
    case monthly, yearly
    
    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$19.99/mo"
        case .yearly: return "$9.99/mo"
        }
    }
    
    var originalPrice: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "$119.99/year"
        }
    }
    
    var badge: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "3 DAYS FREE"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return "No Trial"
        case .yearly: return "Save 50%"
        }
    }
    
    var productId: String {
        switch self {
        case .monthly: return "com.convai.premium.monthly"
        case .yearly: return "com.convai.premium.yearly"
        }
    }
}

@available(iOS 15.0, *)
@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isSubscribed = false
    @Published var isInTrial = false
    @Published var trialEndDate: Date?
    
    // Use the existing StoreKit2PurchaseManager
    private let purchaseManager = StoreKit2PurchaseManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe changes from the existing purchase manager
        purchaseManager.$hasActiveSubscription
            .assign(to: \.isSubscribed, on: self)
            .store(in: &cancellables)
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        await purchaseManager.loadProducts()
        self.products = purchaseManager.getProducts()
        print("✅ Loaded \(products.count) products from StoreKit2PurchaseManager")
    }
    
    // MARK: - Purchase Flow
    func purchase(plan: SubscriptionPlan) async throws -> Bool {
        guard let product = products.first(where: { $0.id == plan.productId }) else {
            throw SubscriptionError.productNotFound
        }
        
        print("🛒 Initiating purchase for: \(product.id)")
        
        let result = await purchaseManager.purchase(product: product)
        
        if result.success && result.isActive {
            // Purchase successful - update trial status if yearly
            if plan == .yearly {
                await checkTrialStatus()
            }
            return true
        } else {
            if let error = result.error {
                throw SubscriptionError.purchaseFailed(error)
            }
            return false
        }
    }
    
    // MARK: - Subscription Status
    func updateSubscriptionStatus() async {
        let hasActive = await purchaseManager.checkSubscriptionStatusLocalFirst()
        
        await MainActor.run {
            self.isSubscribed = hasActive
            
            // Check if this is a trial for yearly subscription
            if hasActive {
                Task {
                    await self.checkTrialStatus()
                }
            } else {
                self.isInTrial = false
                self.trialEndDate = nil
            }
        }
    }
    
    private func checkTrialStatus() async {
        // For StoreKit 2, we need to check subscription status to determine trial
        // This is a simplified implementation - in production you'd check the actual subscription status
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is a yearly subscription that might be in trial
                if transaction.productID.contains("yearly") {
                    let purchaseDate = transaction.purchaseDate
                    let potentialTrialEnd = Calendar.current.date(byAdding: .day, value: 3, to: purchaseDate)!
                    
                    await MainActor.run {
                        if Date() < potentialTrialEnd {
                            self.isInTrial = true
                            self.trialEndDate = potentialTrialEnd
                            
                            // Schedule trial reminders
                            NotificationManager.shared.scheduleTrialReminders(trialEndDate: potentialTrialEnd)
                        } else {
                            self.isInTrial = false
                            self.trialEndDate = nil
                        }
                    }
                    
                    break
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
    }
    
    // MARK: - Transaction Verification
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Utility Methods
    func getProduct(for plan: SubscriptionPlan) -> Product? {
        return products.first { $0.id == plan.productId }
    }
    
    func hasActiveSubscription() -> Bool {
        return isSubscribed
    }
    
    func isYearlySubscriber() -> Bool {
        return purchaseManager.currentTier == .yearly
    }
    
    func getTrialDaysRemaining() -> Int? {
        guard isInTrial, let trialEndDate = trialEndDate else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: trialEndDate)
        
        return max(0, components.day ?? 0)
    }
}

// MARK: - Errors
enum SubscriptionError: LocalizedError {
    case failedVerification
    case productNotFound
    case networkError
    case userNotSignedIn
    case purchaseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase"
        case .productNotFound:
            return "Subscription product not found"
        case .networkError:
            return "Network connection error"
        case .userNotSignedIn:
            return "Please sign in to your Apple ID"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        }
    }
}
