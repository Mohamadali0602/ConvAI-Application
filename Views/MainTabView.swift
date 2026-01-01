//
//  MainTabView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 06/08/2025.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MainTabView: View {
    @State private var selectedTab = 0
    // COMMENTED OUT: @StateObject private var userProgressService = UserProgressService.shared
    // COMMENTED OUT: @StateObject private var localizationManager = LocalizationManager.shared
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Practice Tab - Psychological Value Delivery with 3 core categories
            NavigationView {
                PracticeView()
            }
            .tabItem {
                Label("Learn", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(0)
            
            
            // Simulate Tab - Real-world practice scenarios
            NavigationView {
                SimulateView()
            }
            .tabItem {
                Label("Simulate", systemImage: "person.2.fill")
            }
            .tag(1)
            
            // Pronunciation Tab - AI-powered pronunciation practice
            NavigationView {
                PronunciationView()
            }
            .tabItem {
                Label("Pronunciation", systemImage: "waveform")
            }
            .tag(2)
            
            // Settings Tab - Production-ready settings implementation
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .accentColor(primaryColor)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
#if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(darkBackground)
        
        // Customize selected and unselected item colors
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(primaryColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(primaryColor)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
#endif
    }
}

// MARK: - Supporting Views

// Note: SettingsOptionRow moved to SettingsView.swift as it's no longer needed here

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
