//
//  NavigationManager.swift
//  ConvAI
//
//  Created by Implementation on 30/08/2025.
//

import SwiftUI
import Combine

@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedTab: MainTab = .learn
    @Published var shouldShowPaywall = false
    @Published var isSubscriptionActive = false
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    
    enum MainTab: String, CaseIterable {
        case learn = "Learn"
        case simulate = "Simulate"
        case pronunciation = "Pronunciation"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .learn: return "bubble.left.and.bubble.right.fill"
            case .simulate: return "person.2.fill"
            case .pronunciation: return "waveform"
            case .settings: return "gearshape.fill"
            }
        }
        
        var index: Int {
            switch self {
            case .learn: return 0
            case .simulate: return 1
            case .pronunciation: return 2
            case .settings: return 3
            }
        }
    }
    
    init() {
        // Monitor subscription status changes
        setupSubscriptionMonitoring()
    }
    
    // MARK: - Navigation Methods
    func navigateToTab(_ tab: MainTab) {
        selectedTab = tab
    }
    
    func showPaywall() {
        shouldShowPaywall = true
    }
    
    func hidePaywall() {
        shouldShowPaywall = false
    }
    
    func handleSuccessfulSubscription() {
        // Hide paywall and navigate to main app
        shouldShowPaywall = false
        isSubscriptionActive = true
        
        // Navigate to learn tab as default after subscription
        selectedTab = .learn
        
        print("✅ Subscription successful - navigated to main app")
    }
    
    // MARK: - Subscription Monitoring
    private func setupSubscriptionMonitoring() {
        // This would integrate with SubscriptionManager in a real app
        // For now, we'll handle the basic flow
    }
    
    func checkSubscriptionStatus() async {
        // This method would check with SubscriptionManager
        // and update isSubscriptionActive accordingly
    }
    
    // MARK: - Deep Linking Support
    func handleDeepLink(url: URL) {
        // Handle deep links to specific sections of the app
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        
        switch components.path {
        case "/learn":
            selectedTab = .learn
        case "/simulate":
            selectedTab = .simulate
        case "/pronunciation":
            selectedTab = .pronunciation
        case "/settings":
            selectedTab = .settings
        case "/subscription":
            showPaywall()
        default:
            selectedTab = .learn
        }
    }
}

// Note: All view definitions removed from NavigationManager to avoid conflicts with actual app views
// NavigationManager should only contain navigation logic, not view definitions
// Progress tracking is handled within the actual MainTabView, not as a separate view here

