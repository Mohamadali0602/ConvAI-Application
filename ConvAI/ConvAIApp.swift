//  ConvAI
//
//  Created by Mohamad Ali on 16/07/2025.
//

import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck

@main
struct ConvAIApp: App {
    
    // ✅ FIRESTORE CRASH FIX: Monitor scene phase at app level
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // ✅ PHASE 3: Production-ready Firebase configuration
        #if DEBUG
        // For development/debug builds, use App Check debug provider
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("🔧 App Check Debug Provider configured for development")
        #else
        // For production, use DeviceCheck
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("🛡️ App Check DeviceCheck Provider configured for production")
        #endif
        
        FirebaseApp.configure()
        configureFirestoreForSecurity()
        
        print("✅ ConvAI configured with SwiftData + Firebase integration")
        
        #if DEBUG
        printCurrentPermissionStates()
        #endif
    }
    
    // ✅ PHASE 3: Production-ready Firestore configuration
    private func configureFirestoreForSecurity() {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        
        #if DEBUG
        // Development: Enable offline persistence for testing
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = 100 * 1024 * 1024 // 100MB cache
        print("🔧 DEVELOPMENT: Firestore offline persistence enabled")
        #else
        // Production: Optimize for security and performance
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = 50 * 1024 * 1024 // 50MB cache
        print("🛡️ PRODUCTION: Firestore configured for security")
        #endif
        
        db.settings = settings
        print("✅ Firestore configured with secure settings")
    }
    
    #if DEBUG
    private func printCurrentPermissionStates() {
        // Check notification permissions
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Notification Permission: \(settings.authorizationStatus.rawValue)")
        }
        
        // Check camera permissions
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 Camera Permission: \(cameraStatus.rawValue)")
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: UserData.self)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleAppStateChange(from: oldPhase, to: newPhase)
        }
    }
    
    // ✅ PHASE 3: Enhanced app lifecycle management with Firebase integration
    private func handleAppStateChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        print("🔄 APP-LEVEL Scene phase changed: \(oldPhase) → \(newPhase)")
        
        switch newPhase {
        case .background:
            print("🔽 APP BACKGROUNDED: Firestore will handle persistence safely")
            // Let Firebase handle background gracefully with proper settings
            
        case .active:
            print("✅ APP ACTIVE: Ready for user interaction with Firebase sync")
            
        case .inactive:
            print("⚠️ APP INACTIVE: Preparing for potential background")
            
        @unknown default:
            print("❓ Unknown app phase: \(newPhase)")
        }
    }
}

// MARK: - SwiftData Test View (for development)

#if DEBUG
struct SwiftDataTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allUsers: [UserData]
    @StateObject private var userProfile = UserProfile()
    
    private var currentUser: UserData? {
        allUsers.first { $0.userId == "guest" }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SwiftData Migration Test")
                    .font(.largeTitle)
                    .bold()
                
                if let user = currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current User: \(user.userId)")
                        Text("Name: \(user.name.isEmpty ? "Not Set" : user.name)")
                        Text("Total XP: \(user.totalXP)")
                        Text("Level: \(user.currentLevel)")
                        Text("Conversations: \(user.conversationsCompleted)")
                        Text("Data Version: \(user.dataVersion)")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text("No user found - will create one")
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Button("Create/Update Test User") {
                        createOrUpdateTestUser()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Add 100 XP") {
                        addTestXP()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Complete Test Conversation") {
                        completeTestConversation()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Trigger Migration") {
                        userProfile.performMigrationIfNeeded()
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("Total Users in Database: \(allUsers.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("SwiftData Test")
        }
        .onAppear {
            userProfile.configure(with: modelContext)
        }
    }
    
    private func createOrUpdateTestUser() {
        if let user = currentUser {
            user.name = "Test User \(Date().timeIntervalSince1970)"
            user.preferredLanguage = "en-US"
            user.isSetup = true
        } else {
            let newUser = UserData(userId: "guest")
            newUser.name = "New Test User"
            newUser.preferredLanguage = "en-US"
            newUser.isSetup = true
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
            print("✅ User created/updated successfully")
        } catch {
            print("❌ Failed to save user: \(error)")
        }
    }
    
    private func addTestXP() {
        guard let user = currentUser else { return }
        
        user.addXP(100)
        
        do {
            try modelContext.save()
            print("✅ Added 100 XP successfully")
        } catch {
            print("❌ Failed to save XP: \(error)")
        }
    }
    
    private func completeTestConversation() {
        guard let user = currentUser else { return }
        
        user.updateConversationStats(duration: 180) // 3 minutes
        
        do {
            try modelContext.save()
            print("✅ Conversation stats updated successfully")
        } catch {
            print("❌ Failed to save conversation stats: \(error)")
        }
    }
}

#endif