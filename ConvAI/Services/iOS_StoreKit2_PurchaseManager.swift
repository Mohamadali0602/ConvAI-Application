/*
 🛍️ StoreKit 2 Purchase Manager
 
 This file provides complete StoreKit 2 integration for ConvAI, replacing the old
 receipt validation system with modern JWS transaction verification.
 
 Features:
 ✅ Local transaction validation with Apple-signed JWS
 ✅ Real-time transaction updates via Transaction.updates
 ✅ Current entitlements checking
 ✅ Beta-safe implementation (sandbox transactions marked non-billable)
 ✅ Automatic subscription management
 ✅ Server-side JWS verification for enhanced security
 ✅ PHASE 1: Local-first subscription checking for instant UI decisions
 ✅ Offline support with 24-hour caching
 
 Requirements: iOS 15.0+
 Migration: Replaces old receipt validation entirely
 */

import StoreKit
import Foundation
import FirebaseFunctions

// MARK: - PHASE 1: Cache Models for Offline Support

public enum SubscriptionTier: String, CaseIterable, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    public var features: [String] {
        switch self {
        case .monthly:
            return ["30 days access", "Advanced AI models", "Priority support"]
        case .yearly:
            return ["365 days access", "All AI models", "Priority support", "Early access"]
        }
    }
}

/// Cached subscription status for offline support
struct CachedSubscriptionStatus: Codable {
    let isActive: Bool
    let tier: SubscriptionTier?
    let expiresAt: Date?
    let isBillable: Bool
    let isSandbox: Bool
    let cachedAt: Date
}

@available(iOS 15.0, *)
@MainActor
public class StoreKit2PurchaseManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isLoading = false
    @Published public var hasActiveSubscription = false
    @Published public var currentTier: SubscriptionTier?
    @Published public var errorMessage: String?
    @Published public var lastValidationResult: ValidationResult?
    
    // MARK: - Computed Properties
    public var isPurchasing: Bool {
        return isLoading
    }
    
    public var monthlyProduct: Product? {
        return products.first { $0.id.contains("monthly") }
    }
    
    public var yearlyProduct: Product? {
        return products.first { $0.id.contains("yearly") }
    }
    
    // MARK: - Configuration
    private let productIDs: Set<String> = [
        "com.convai.premium.monthly",
        "com.convai.premium.yearly"
    ]
    
    private var functions = Functions.functions()
    private var products: [Product] = []
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Public Types
    public struct ValidationResult {
        public let success: Bool
        public let tier: SubscriptionTier?
        public let isActive: Bool
        public let isBillable: Bool
        public let environment: String
        public let expiresAt: Date?
        public let error: String?
        
        public var isSandbox: Bool {
            return environment == "sandbox"
        }
    }
    
    // MARK: - Initialization
    public init() {
        // Start transaction listener for real-time updates
        startTransactionListener()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    public func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let loadedProducts = try await Product.products(for: productIDs)
            self.products = loadedProducts.sorted { $0.displayPrice < $1.displayPrice }
            print("✅ Loaded \(products.count) StoreKit 2 products")
            
            // Check current entitlements after loading products
            await checkCurrentEntitlements()
            
        } catch {
            print("❌ Failed to load products: \(error)")
            self.errorMessage = "Failed to load subscription options"
        }
    }
    
    public func getProducts() -> [Product] {
        return products
    }
    
    // MARK: - Purchase Flow
    public func purchase(product: Product) async -> ValidationResult {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                return await handlePurchaseSuccess(verificationResult)
                
            case .userCancelled:
                print("⏭️ User cancelled purchase")
                return ValidationResult(
                    success: false,
                    tier: nil,
                    isActive: false,
                    isBillable: false,
                    environment: "unknown",
                    expiresAt: nil,
                    error: "Purchase was cancelled"
                )
                
            case .pending:
                print("⏳ Purchase is pending approval")
                return ValidationResult(
                    success: false,
                    tier: nil,
                    isActive: false,
                    isBillable: false,
                    environment: "unknown",
                    expiresAt: nil,
                    error: "Purchase is pending approval"
                )
                
            @unknown default:
                print("❌ Unknown purchase result")
                return ValidationResult(
                    success: false,
                    tier: nil,
                    isActive: false,
                    isBillable: false,
                    environment: "unknown",
                    expiresAt: nil,
                    error: "Unknown purchase result"
                )
            }
            
        } catch {
            print("❌ Purchase failed: \(error)")
            return ValidationResult(
                success: false,
                tier: nil,
                isActive: false,
                isBillable: false,
                environment: "unknown",
                expiresAt: nil,
                error: "Purchase failed: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Purchase Success Handling
    private func handlePurchaseSuccess(_ verificationResult: VerificationResult<Transaction>) async -> ValidationResult {
        switch verificationResult {
        case .verified(let transaction):
            // ✅ Valid, Apple-signed transaction
            print("✅ Transaction verified: \(transaction.productID)")
            
            // Send JWS to server for additional verification and subscription update
            let serverValidationResult = await validateWithServer(verificationResult: verificationResult)
            
            // Finish the transaction
            await transaction.finish()
            
            // Update local state
            await updateLocalSubscriptionState(from: serverValidationResult)
            
            return serverValidationResult
            
        case .unverified(let transaction, let verificationError):
            // ❌ Invalid/tampered transaction
            print("❌ Transaction verification failed: \(verificationError)")
            
            // Still finish the transaction to prevent it from appearing again
            await transaction.finish()
            
            return ValidationResult(
                success: false,
                tier: nil,
                isActive: false,
                isBillable: false,
                environment: transaction.environment == .sandbox ? "sandbox" : "production",
                expiresAt: nil,
                error: "Transaction verification failed"
            )
        }
    }
    
    // MARK: - Current Entitlements
    
    /// PHASE 1: Local-first subscription checking for instant UI decisions
    /// Returns immediately based on local StoreKit entitlements, runs server validation in background
    public func checkSubscriptionStatusLocalFirst() async -> Bool {
        print("🚀 PHASE 1: Checking subscription status (local-first approach)")
        
        // Step 1: Check local StoreKit entitlements immediately
        let hasLocalEntitlement = await checkLocalEntitlementsOnly()
        
        if hasLocalEntitlement {
            print("✅ Local entitlement found - updating UI immediately")
            await MainActor.run {
                self.hasActiveSubscription = true
            }
            
            // Background server validation (don't block UI)
            Task.detached { [weak self] in
                await self?.performBackgroundServerValidation()
            }
            
            return true
        } else {
            print("⚠️ No local entitlements found - checking cache and server")
            
            // Step 2: Check cached results for offline support
            if let cachedResult = getCachedSubscriptionStatus() {
                print("📱 Using cached subscription status (offline support)")
                await MainActor.run {
                    self.hasActiveSubscription = cachedResult.isActive
                    self.currentTier = cachedResult.tier
                    self.lastValidationResult = cachedResult
                }
                return cachedResult.isActive
            }
            
            // Step 3: No local entitlements and no cache - fall back to server validation
            print("🌐 Falling back to server validation")
            await checkCurrentEntitlements()
            return hasActiveSubscription
        }
    }
    
    /// Check only local StoreKit entitlements (no server calls)
    private func checkLocalEntitlementsOnly() async -> Bool {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Check if subscription is still active
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        hasActiveSubscription = true
                        print("✅ Local active subscription: \(transaction.productID) expires \(expirationDate)")
                        break
                    } else {
                        print("⏰ Local expired subscription: \(transaction.productID)")
                    }
                } else {
                    // Non-consumable or lifetime purchase
                    hasActiveSubscription = true
                    print("✅ Local lifetime entitlement: \(transaction.productID)")
                    break
                }
                
            case .unverified(let transaction, let error):
                print("❌ Local unverified entitlement: \(transaction.productID) - \(error)")
            }
        }
        
        return hasActiveSubscription
    }
    
    /// Perform server validation in background without blocking UI
    private func performBackgroundServerValidation() async {
        print("🔄 Background server validation starting...")
        
        // Check if sync is actually needed
        guard shouldPerformBackgroundSync() else {
            print("⏭️ Background sync skipped - not needed yet")
            return
        }
        
        var activeSubscriptions: [(Transaction, VerificationResult<Transaction>)] = []
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        activeSubscriptions.append((transaction, result))
                    }
                } else {
                    activeSubscriptions.append((transaction, result))
                }
            case .unverified:
                continue
            }
        }
        
        // Batch process multiple subscriptions efficiently
        await processBatchValidation(subscriptions: activeSubscriptions)
        
        // Mark sync as completed
        markSyncCompleted()
        
        print("✅ Background server validation completed")
    }
    
    /// PHASE 2: Batch process multiple transactions for efficiency
    private func processBatchValidation(subscriptions: [(Transaction, VerificationResult<Transaction>)]) async {
        guard !subscriptions.isEmpty else {
            // No active subscriptions - update local state and cache
            let emptyResult = ValidationResult(
                success: true,
                tier: nil,
                isActive: false,
                isBillable: false,
                environment: "unknown",
                expiresAt: nil,
                error: nil
            )
            
            cacheSubscriptionStatus(emptyResult)
            await MainActor.run {
                if self.hasActiveSubscription {
                    print("⚠️ Server validation shows no active subscriptions - updating UI")
                    self.hasActiveSubscription = false
                    self.currentTier = nil
                }
                self.lastValidationResult = emptyResult
            }
            return
        }
        
        // Process the highest priority subscription
        if let bestSubscription = subscriptions.max(by: { getTierPriority($0.0.productID) < getTierPriority($1.0.productID) }) {
            
            // Add idempotency key to prevent duplicate processing
            let idempotencyKey = "\(bestSubscription.0.id)_\(Int(Date().timeIntervalSince1970))"
            
            let validationResult = await validateWithServerBatch(
                verificationResult: bestSubscription.1,
                idempotencyKey: idempotencyKey
            )
            
            // Cache the result for offline use
            cacheSubscriptionStatus(validationResult)
            
            // Update UI if server result differs from local assumption
            await MainActor.run {
                if !validationResult.isActive && self.hasActiveSubscription {
                    print("⚠️ Server validation differs from local - updating UI")
                    self.hasActiveSubscription = false
                    self.currentTier = nil
                } else if validationResult.isActive && !self.hasActiveSubscription {
                    print("✅ Server validation found active subscription - updating UI")
                    self.hasActiveSubscription = true
                    self.currentTier = validationResult.tier
                }
                self.lastValidationResult = validationResult
            }
        }
    }
    
    public func checkCurrentEntitlements() async {
        print("🔍 Checking current entitlements...")
        
        var activeSubscriptions: [(Transaction, VerificationResult<Transaction>)] = []
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Check if subscription is still active
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        activeSubscriptions.append((transaction, result))
                        print("✅ Active subscription found: \(transaction.productID)")
                    } else {
                        print("⏰ Expired subscription: \(transaction.productID)")
                    }
                } else {
                    // Non-consumable or lifetime purchase
                    activeSubscriptions.append((transaction, result))
                    print("✅ Lifetime entitlement found: \(transaction.productID)")
                }
                
            case .unverified(let transaction, let error):
                print("❌ Unverified entitlement: \(transaction.productID) - \(error)")
            }
        }
        
        // Update subscription state based on highest tier found
        if let bestSubscription = activeSubscriptions.max(by: { getTierPriority($0.0.productID) < getTierPriority($1.0.productID) }) {
            let validationResult = await validateWithServer(verificationResult: bestSubscription.1)
            await updateLocalSubscriptionState(from: validationResult)
        } else {
            // No active subscriptions
            await updateLocalSubscriptionState(from: ValidationResult(
                success: true,
                tier: nil,
                isActive: false,
                isBillable: false,
                environment: "unknown",
                expiresAt: nil,
                error: nil
            ))
        }
    }
    
    // MARK: - Transaction Updates Listener
    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }
    
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            print("🔄 Transaction update received: \(transaction.productID)")
            
            // Send update to server with verification result
            let validationResult = await validateTransactionUpdateWithServer(verificationResult: result)
            
            // Update local state
            await updateLocalSubscriptionState(from: validationResult)
            
            // Finish the transaction
            await transaction.finish()
            
        case .unverified(let transaction, let error):
            print("❌ Unverified transaction update: \(transaction.productID) - \(error)")
            await transaction.finish()
        }
    }
    
    // MARK: - PHASE 2: Enhanced Server Communication with Batching
    
    /// Enhanced server validation with batching support and idempotency
    private func validateWithServerBatch(verificationResult: VerificationResult<Transaction>, idempotencyKey: String) async -> ValidationResult {
        let jwsToken = verificationResult.jwsRepresentation
        
        print("🔑 JWS TOKEN FOR TESTING:")
        print("=====================================")
        print(jwsToken)
        print("=====================================")
        print("📋 Copy this token to test server validation")
        
        do {
            let result = try await functions.httpsCallable("validateStoreKit2TransactionBatch").call([
                "jwsToken": jwsToken,
                "environment": "sandbox",  // Explicitly set sandbox for Xcode testing
                "idempotencyKey": idempotencyKey,
                "batchProcessing": true
            ])
            
            let data = result.data as? [String: Any]
            
            if let data = data,
               let success = data["success"] as? Bool,
               success,
               let subscription = data["subscription"] as? [String: Any] {
                
                return parseServerValidationResult(subscription)
            } else {
                let error = (data?["message"] as? String) ?? "Server validation failed"
                print("❌ Server validation failed: \(error)")
                
                // Fallback to regular validation if batch fails
                return await validateWithServer(verificationResult: verificationResult)
            }
            
        } catch {
            print("❌ Batch server validation error: \(error)")
            
            // Fallback to regular validation
            return await validateWithServer(verificationResult: verificationResult)
        }
    }
    
    // MARK: - Server Communication
    private func validateWithServer(verificationResult: VerificationResult<Transaction>) async -> ValidationResult {
        // For StoreKit 2, we send the JWS representation for server-side validation
        // The jwsRepresentation contains the Apple-signed JWS token
        
        // 🔑 DEBUG: Print JWS token for testing/debugging
        let jwsToken = verificationResult.jwsRepresentation
        print("🔑 JWS TOKEN FOR TESTING:")
        print("=====================================")
        print(jwsToken)
        print("=====================================")
        print("📋 Copy this token to test server validation")
        
        do {
            let result = try await functions.httpsCallable("validateStoreKit2Transaction").call([
                "jwsToken": jwsToken,
                "environment": "sandbox"  // Explicitly set sandbox for Xcode testing
            ])
            
            let data = result.data as? [String: Any]
            
            if let data = data,
               let success = data["success"] as? Bool,
               success,
               let subscription = data["subscription"] as? [String: Any] {
                
                return parseServerValidationResult(subscription)
            } else {
                let error = (data?["message"] as? String) ?? "Server validation failed"
                print("❌ Server validation failed: \(error)")
                
                // Extract transaction from verification result for fallback info
                let transaction: Transaction
                switch verificationResult {
                case .verified(let verifiedTransaction):
                    transaction = verifiedTransaction
                case .unverified(let unverifiedTransaction, _):
                    transaction = unverifiedTransaction
                }
                
                return ValidationResult(
                    success: false,
                    tier: nil,
                    isActive: false,
                    isBillable: false,
                    environment: transaction.environment == .sandbox ? "sandbox" : "production",
                    expiresAt: nil,
                    error: error
                )
            }
            
        } catch {
            print("❌ Server validation error: \(error)")
            
            // Extract transaction from verification result for fallback info
            let transaction: Transaction
            switch verificationResult {
            case .verified(let verifiedTransaction):
                transaction = verifiedTransaction
            case .unverified(let unverifiedTransaction, _):
                transaction = unverifiedTransaction
            }
            
            return ValidationResult(
                success: false,
                tier: nil,
                isActive: false,
                isBillable: false,
                environment: transaction.environment == .sandbox ? "sandbox" : "production",
                expiresAt: nil,
                error: "Server communication failed"
            )
        }
    }
    
    private func validateTransactionUpdateWithServer(verificationResult: VerificationResult<Transaction>) async -> ValidationResult {
        // For StoreKit 2, we send the JWS representation for server-side validation
        do {
            let result = try await functions.httpsCallable("handleStoreKit2TransactionUpdate").call([
                "jwsToken": verificationResult.jwsRepresentation
            ])
            
            let data = result.data as? [String: Any]
            
            if let data = data,
               let success = data["success"] as? Bool,
               success,
               let subscription = data["subscription"] as? [String: Any] {
                
                return parseServerValidationResult(subscription)
            } else {
                print("❌ Transaction update validation failed")
                
                // Extract transaction from verification result for fallback info
                let transaction: Transaction
                switch verificationResult {
                case .verified(let verifiedTransaction):
                    transaction = verifiedTransaction
                case .unverified(let unverifiedTransaction, _):
                    transaction = unverifiedTransaction
                }
                
                return ValidationResult(
                    success: false,
                    tier: nil,
                    isActive: false,
                    isBillable: false,
                    environment: transaction.environment == .sandbox ? "sandbox" : "production",
                    expiresAt: nil,
                    error: "Transaction update failed"
                )
            }
            
        } catch {
            print("❌ Transaction update error: \(error)")
            
            // Extract transaction from verification result for fallback info
            let transaction: Transaction
            switch verificationResult {
            case .verified(let verifiedTransaction):
                transaction = verifiedTransaction
            case .unverified(let unverifiedTransaction, _):
                transaction = unverifiedTransaction
            }
            
            return ValidationResult(
                success: false,
                tier: nil,
                isActive: false,
                isBillable: false,
                environment: transaction.environment == .sandbox ? "sandbox" : "production",
                expiresAt: nil,
                error: "Server communication failed"
            )
        }
    }
    
    // MARK: - Helper Methods
    private func parseServerValidationResult(_ subscription: [String: Any]) -> ValidationResult {
        let hasActiveSubscription = subscription["hasActiveSubscription"] as? Bool ?? false
        let tierString = subscription["tier"] as? String
        let tier = tierString.flatMap { SubscriptionTier(rawValue: $0) }
        let billable = subscription["billable"] as? Bool ?? false
        let environment = subscription["environment"] as? String ?? "unknown"
        let error = subscription["error"] as? String
        
        var expiresAt: Date?
        if let expiresAtString = subscription["expiresAt"] as? String {
            let formatter = ISO8601DateFormatter()
            expiresAt = formatter.date(from: expiresAtString)
        }
        
        return ValidationResult(
            success: hasActiveSubscription,
            tier: tier,
            isActive: hasActiveSubscription,
            isBillable: billable,
            environment: environment,
            expiresAt: expiresAt,
            error: error
        )
    }
    
    private func updateLocalSubscriptionState(from result: ValidationResult) async {
        self.hasActiveSubscription = result.isActive
        self.currentTier = result.tier
        self.lastValidationResult = result
        
        if let error = result.error {
            self.errorMessage = error
        } else {
            self.errorMessage = nil
        }
    }
    
    private func getTierPriority(_ productID: String) -> Int {
        if productID.contains("premium") || productID.contains("yearly") {
            return 2
        } else if productID.contains("basic") || productID.contains("monthly") {
            return 1
        } else {
            return 0
        }
    }
    
    // MARK: - PHASE 2: Enhanced Public Methods
    
    /// Enhanced refresh with smart background sync
    public func refreshSubscriptionStatus() async {
        print("🔄 Refreshing subscription status with smart sync...")
        
        // Always use local-first approach for instant UI
        let hasLocal = await checkSubscriptionStatusLocalFirst()
        
        // If we have local entitlements, check if background sync is needed
        if hasLocal && shouldPerformBackgroundSync() {
            // Perform sync in background without blocking current response
            Task.detached { [weak self] in
                await self?.performBackgroundServerValidation()
            }
        }
        
        print("✅ Subscription status refresh completed")
    }
    
    /// PHASE 2: Enhanced status checking with login sync trigger
    public func checkSubscriptionStatusOnLogin() async -> Bool {
        print("🔑 Login sync - checking subscription status...")
        
        // Force a sync on login regardless of time interval
        UserDefaults.standard.set(true, forKey: forceResyncKey)
        
        return await checkSubscriptionStatusLocalFirst()
    }
    
    /// PHASE 3: Ultra-fast cached subscription status check
    public func checkSubscriptionStatusCached() async -> Bool {
        print("⚡ PHASE 3: Ultra-fast cached subscription check")
        
        do {
            let result = try await functions.httpsCallable("getSubscriptionStatusCached").call([:])
            
            let data = result.data as? [String: Any]
            
            if let data = data,
               let success = data["success"] as? Bool,
               success {
                
                let hasActiveSubscription = data["hasActiveSubscription"] as? Bool ?? false
                let tierString = data["tier"] as? String
                let tier = tierString.flatMap { SubscriptionTier(rawValue: $0) }
                
                await MainActor.run {
                    self.hasActiveSubscription = hasActiveSubscription
                    self.currentTier = tier
                }
                
                print("⚡ Cached status: \(hasActiveSubscription ? "Active" : "Inactive") (\(tierString ?? "none"))")
                return hasActiveSubscription
            } else {
                print("⚠️ Cached lookup failed - falling back to local check")
                return await checkLocalEntitlementsOnly()
            }
            
        } catch {
            print("❌ Cached lookup error - falling back to local check: \(error)")
            return await checkLocalEntitlementsOnly()
        }
    }
    
    /// PHASE 3: Enhanced hybrid approach with cached lookup
    public func checkSubscriptionStatusHybrid() async -> Bool {
        print("🔄 PHASE 3: Hybrid subscription check (cache + local + server)")
        
        // Step 1: Try cached lookup (fastest)
        let cachedResult = await checkSubscriptionStatusCached()
        if cachedResult {
            print("✅ Using cached server result")
            
            // Optional: Trigger background sync if needed
            if shouldPerformBackgroundSync() {
                Task.detached { [weak self] in
                    await self?.performBackgroundServerValidation()
                }
            }
            
            return true
        }
        
        // Step 2: Fall back to local-first approach
        print("🔄 Cached lookup unsuccessful - using local-first approach")
        return await checkSubscriptionStatusLocalFirst()
    }
    
    public func getSubscriptionDisplayInfo() -> String? {
        guard let result = lastValidationResult, result.isActive else {
            return nil
        }
        
        var info = result.tier?.displayName ?? "Active"
        
        if !result.isBillable {
            if result.isSandbox {
                info += " (TestFlight)"
            } else {
                info += " (Beta)"
            }
        }
        
        if let expiresAt = result.expiresAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            info += " • Expires \(formatter.string(from: expiresAt))"
        }
        
        return info
    }
    
    // MARK: - PHASE 2: Background Sync System
    
    private let backgroundSyncQueue = DispatchQueue(label: "subscription.background.sync", qos: .background)
    private let lastSyncKey = "storekit_last_sync_timestamp"
    private let syncIntervalHours: TimeInterval = 24 // Sync every 24 hours
    private let forceResyncKey = "storekit_force_resync"
    
    // MARK: - PHASE 1: Local Caching for Offline Support
    
    private let cacheKey = "storekit_subscription_cache"
    private let cacheTimestampKey = "storekit_cache_timestamp"
    private let cacheValidityHours: TimeInterval = 24 // Cache valid for 24 hours
    
    // MARK: - PHASE 2: Smart Sync Triggers
    
    /// Determines if background sync is needed based on various triggers
    private func shouldPerformBackgroundSync() -> Bool {
        let lastSync = UserDefaults.standard.double(forKey: lastSyncKey)
        let timeSinceLastSync = Date().timeIntervalSince1970 - lastSync
        let forceResync = UserDefaults.standard.bool(forKey: forceResyncKey)
        
        // Trigger conditions:
        let dailySyncNeeded = timeSinceLastSync > (syncIntervalHours * 3600)
        let appLaunchSync = lastSync == 0 // First launch
        
        return dailySyncNeeded || appLaunchSync || forceResync
    }
    
    /// Marks sync as completed
    private func markSyncCompleted() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSyncKey)
        UserDefaults.standard.set(false, forKey: forceResyncKey)
    }
    
    /// Forces a resync on next background sync check
    public func requestForcedSync() {
        UserDefaults.standard.set(true, forKey: forceResyncKey)
        print("🔄 Forced sync requested - will sync on next background check")
    }
    
    /// Cache subscription status locally for offline support
    private func cacheSubscriptionStatus(_ result: ValidationResult) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(CachedSubscriptionStatus(
                isActive: result.isActive,
                tier: result.tier,
                expiresAt: result.expiresAt,
                isBillable: result.isBillable,
                isSandbox: result.isSandbox,
                cachedAt: Date()
            ))
            
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
            print("💾 Cached subscription status for offline use")
            
        } catch {
            print("❌ Failed to cache subscription status: \(error)")
        }
    }
    
    /// Get cached subscription status for offline support
    private func getCachedSubscriptionStatus() -> ValidationResult? {
        // Check if cache is still valid
        let cacheTimestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let cacheAge = Date().timeIntervalSince1970 - cacheTimestamp
        
        guard cacheAge < (cacheValidityHours * 3600) else {
            print("📱 Cache expired (age: \(Int(cacheAge/3600)) hours)")
            return nil
        }
        
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            print("📱 No cached subscription data found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cached = try decoder.decode(CachedSubscriptionStatus.self, from: data)
            
            print("📱 Using cached subscription status (age: \(Int(cacheAge/60)) minutes)")
            
            return ValidationResult(
                success: true,
                tier: cached.tier,
                isActive: cached.isActive,
                isBillable: cached.isBillable,
                environment: cached.isSandbox ? "sandbox" : "production",
                expiresAt: cached.expiresAt,
                error: nil
            )
            
        } catch {
            print("❌ Failed to decode cached subscription status: \(error)")
            return nil
        }
    }
    
    /// Clear cached subscription status (useful for testing)
    public func clearSubscriptionCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        print("🗑️ Cleared subscription cache")
    }

    
    public func hasFeatureAccess() -> Bool {
        return hasActiveSubscription
    }
    
    // MARK: - Debug Functions
    /// 🔍 Debug function to print all current JWS tokens for testing
    public func printCurrentJWSTokens() async {
        print("🔍 CHECKING CURRENT ENTITLEMENTS FOR JWS TOKENS...")
        print("================================================")
        
        var tokenCount = 0
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                tokenCount += 1
                let jwsToken = result.jwsRepresentation
                print("🔑 JWS TOKEN #\(tokenCount):")
                print("Product ID: \(transaction.productID)")
                print("Transaction ID: \(transaction.id)")
                print("Environment: \(transaction.environment)")
                print("JWS Token:")
                print("-------------------------------------")
                print(jwsToken)
                print("-------------------------------------")
                print("")
                
            case .unverified(let transaction, let error):
                print("❌ Unverified transaction: \(transaction.productID) - \(error)")
            }
        }
        
        if tokenCount == 0 {
            print("ℹ️ No current entitlements found. Try:")
            print("   1. Make a test purchase in your app")
            print("   2. Restore purchases if you have existing subscriptions")
            print("   3. Check that StoreKit testing is enabled")
        } else {
            print("✅ Found \(tokenCount) JWS token(s) for testing")
        }
        print("================================================")
    }
    
    public func restorePurchases() async {
        // StoreKit 2 automatically handles restore purchases through currentEntitlements
        // We just need to check current entitlements again
        await checkSubscriptionStatusLocalFirst()
    }
    
    // MARK: - PHASE 3: Additional Utility Methods
    
    /// PHASE 3: Invalidate server-side cache for this user
    public func invalidateServerCache() async {
        print("🗑️ Invalidating server-side subscription cache...")
        
        do {
            let _ = try await functions.httpsCallable("invalidateSubscriptionCache").call([:])
            print("✅ Server cache invalidated successfully")
        } catch {
            print("❌ Error invalidating server cache: \(error)")
        }
    }
    
    /// PHASE 3: Get cache performance statistics
    public func getCacheStats() async -> [String: Any]? {
        print("📊 Getting cache performance statistics...")
        
        do {
            let result = try await functions.httpsCallable("getSubscriptionCacheStats").call([:])
            
            let data = result.data as? [String: Any]
            if let data = data, let success = data["success"] as? Bool, success {
                let stats = data["stats"] as? [String: Any]
                print("📊 Cache stats: \(stats ?? [:])")
                return stats
            } else {
                print("⚠️ Failed to get cache stats")
                return nil
            }
            
        } catch {
            print("❌ Error getting cache stats: \(error)")
            return nil
        }
    }
    
    /// PHASE 3: Complete subscription check with all optimizations
    public func checkSubscriptionStatusComplete() async -> Bool {
        print("🎯 PHASE 3: Complete optimized subscription check")
        
        // Use hybrid approach which includes all optimizations
        return await checkSubscriptionStatusHybrid()
    }
}
