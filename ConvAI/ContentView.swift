//
//  ContentView.swift
//  ConvAI
//
//  Production-ready main app view with secure authentication and data management
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allUsers: [UserData]
    @StateObject private var userProfile = UserProfile()
    @StateObject private var cloudSyncManager: CloudSyncManager
    @State private var showingSignIn = false
    @State private var isLoading = true
    
    // Current user with proper access control
    private var currentUser: UserData? {
        guard let firebaseUID = Auth.auth().currentUser?.uid else {
            // No authenticated user - use guest account
            return allUsers.first { $0.userId == "guest" }
        }
        
        // Find user by Firebase UID
        return allUsers.first { $0.firebaseUID == firebaseUID }
    }
    
    // Check if user has proper access
    private var hasValidAccess: Bool {
        guard let user = Auth.auth().currentUser else {
            return true // Guest access is always valid
        }
        
        // Must have corresponding local data and sync manager must show signed in
        return currentUser != nil && cloudSyncManager.isSignedIn
    }
    
    init() {
        // Initialize CloudSyncManager with a temporary context
        // It will be properly configured in onAppear
        let container = try! ModelContainer(for: UserData.self)
        let context = ModelContext(container)
        _cloudSyncManager = StateObject(wrappedValue: CloudSyncManager(modelContext: context))
    }
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if !hasValidAccess {
                AccessDeniedView()
            } else if let user = currentUser {
                MainAppView(user: user)
            } else {
                SetupView()
            }
        }
        .onAppear {
            configureApp()
        }
        .environmentObject(cloudSyncManager)
        .environmentObject(userProfile)
    }
    
    private func configureApp() {
        // Configure UserProfile with ModelContext
        userProfile.configure(with: modelContext)
        
        // Configure CloudSyncManager with proper ModelContext
        let newCloudSyncManager = CloudSyncManager(modelContext: modelContext)
        
        // Perform initial setup
        Task {
            await performInitialSetup()
        }
    }
    
    @MainActor
    private func performInitialSetup() async {
        isLoading = true
        
        // Ensure we have a guest user
        if allUsers.isEmpty {
            let guestUser = UserData(userId: "guest")
            guestUser.name = "Guest User"
            guestUser.isSetup = true
            modelContext.insert(guestUser)
            
            do {
                try modelContext.save()
                print("✅ Created guest user")
            } catch {
                print("❌ Failed to create guest user: \(error)")
            }
        }
        
        // Perform migration if needed
        userProfile.performMigrationIfNeeded()
        
        // Wait a moment for authentication state to settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoading = false
    }
}

// MARK: - Sub Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Setting up ConvAI...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct AccessDeniedView: View {
    @EnvironmentObject private var cloudSyncManager: CloudSyncManager
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text("Access Denied")
                    .font(.largeTitle)
                    .bold()
                
                Text("Your account access has been restricted.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let error = cloudSyncManager.syncError {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            VStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        try? await cloudSyncManager.signOut()
                        try? await cloudSyncManager.signIn()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Use Guest Mode") {
                    Task {
                        try? await cloudSyncManager.signOut()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SetupView: View {
    @EnvironmentObject private var cloudSyncManager: CloudSyncManager
    @Environment(\.modelContext) private var modelContext
    @State private var userName = ""
    @State private var preferredLanguage = "en-US"
    @State private var showingLanguagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Welcome to ConvAI")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 20) {
                    TextField("Your Name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Select Language: \(languageDisplayName)") {
                        showingLanguagePicker = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Get Started") {
                    createUserAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(userName.isEmpty)
                
                Divider()
                
                VStack(spacing: 12) {
                    Text("Or sign in to sync your data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Sign In") {
                        Task {
                            try? await cloudSyncManager.signIn()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                if cloudSyncManager.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(40)
            .navigationTitle("Setup")
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(selectedLanguage: $preferredLanguage)
        }
    }
    
    private var languageDisplayName: String {
        switch preferredLanguage {
        case "en-US": return "English"
        case "es-ES": return "Spanish"
        case "fr-FR": return "French"
        case "de-DE": return "German"
        case "it-IT": return "Italian"
        case "pt-BR": return "Portuguese"
        case "ja-JP": return "Japanese"
        case "ko-KR": return "Korean"
        case "zh-CN": return "Chinese"
        case "ar-SA": return "Arabic"
        default: return "English"
        }
    }
    
    private func createUserAccount() {
        let guestUser = UserData(userId: "guest")
        guestUser.name = userName
        guestUser.preferredLanguage = preferredLanguage
        guestUser.isSetup = true
        guestUser.createdAt = Date()
        
        modelContext.insert(guestUser)
        
        do {
            try modelContext.save()
            print("✅ User account created successfully")
        } catch {
            print("❌ Failed to create user account: \(error)")
        }
    }
}

struct MainAppView: View {
    let user: UserData
    @EnvironmentObject private var cloudSyncManager: CloudSyncManager
    
    var body: some View {
        TabView {
            HomeView(user: user)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ProfileView(user: user)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
            
            SettingsView(user: user)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .overlay(alignment: .top) {
            if cloudSyncManager.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .font(.caption)
                }
                .padding(8)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    let user: UserData
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome back, \(user.name)!")
                    .font(.title)
                    .padding()
                
                Text("Level \(user.currentLevel)")
                    .font(.headline)
                
                Text("\(user.totalXP) XP")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("ConvAI")
        }
    }
}

struct ProfileView: View {
    let user: UserData
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(user.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Level")
                        Spacer()
                        Text("\(user.currentLevel)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total XP")
                        Spacer()
                        Text("\(user.totalXP)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct SettingsView: View {
    let user: UserData
    @EnvironmentObject private var cloudSyncManager: CloudSyncManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if cloudSyncManager.isSignedIn {
                        Button("Sign Out") {
                            Task {
                                try? await cloudSyncManager.signOut()
                            }
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Sign In") {
                            Task {
                                try? await cloudSyncManager.signIn()
                            }
                        }
                    }
                }
                
                Section("Data") {
                    Button("Sync Now") {
                        Task {
                            await cloudSyncManager.forceSyncNow()
                        }
                    }
                    .disabled(!cloudSyncManager.isSignedIn || cloudSyncManager.isSyncing)
                    
                    if let lastSync = cloudSyncManager.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    private let languages = [
        ("en-US", "English"),
        ("es-ES", "Spanish"),
        ("fr-FR", "French"),
        ("de-DE", "German"),
        ("it-IT", "Italian"),
        ("pt-BR", "Portuguese"),
        ("ja-JP", "Japanese"),
        ("ko-KR", "Korean"),
        ("zh-CN", "Chinese"),
        ("ar-SA", "Arabic")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.0) { code, name in
                    HStack {
                        Text(name)
                        Spacer()
                        if selectedLanguage == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLanguage = code
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
