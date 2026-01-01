//
//  CloudSyncManager.swift
//  ConvAI
//
//  Production-ready Firebase Firestore synchronization with secure account management
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftData
import SwiftUI

@MainActor
class CloudSyncManager: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var isSignedIn = false
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: String?
    @Published private(set) var currentUser: User?
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication State Management
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    private func handleAuthStateChange(user: User?) {
        let wasSignedIn = isSignedIn
        currentUser = user
        isSignedIn = user != nil
        
        // Clear sync error when user changes
        syncError = nil
        
        // Handle user switching with security controls
        if wasSignedIn && !isSignedIn {
            // User signed out - clear local data and prevent access
            handleUserSignOut()
        } else if !wasSignedIn && isSignedIn {
            // User signed in - sync data
            Task {
                await syncUserData()
            }
        } else if let user = user {
            // User switched accounts - verify account is active
            Task {
                await handleAccountSwitch(user: user)
            }
        }
    }
    
    private func handleUserSignOut() {
        // Clear any cached data
        lastSyncDate = nil
        
        // Update UserProfile to guest mode
        if let userData = fetchCurrentUserData() {
            userData.firebaseUID = nil
            userData.isSignedIn = false
            saveContext()
        }
    }
    
    private func handleAccountSwitch(user: User) async {
        // Verify the account is active and has proper access
        do {
            let isAccountActive = try await verifyAccountAccess(user: user)
            
            if !isAccountActive {
                // Account is not active - sign out immediately
                try Auth.auth().signOut()
                syncError = "Account access denied. Please contact support."
                return
            }
            
            // Account is valid - proceed with sync
            await syncUserData()
            
        } catch {
            try? Auth.auth().signOut()
            syncError = "Failed to verify account access: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Account Verification
    
    private func verifyAccountAccess(user: User) async throws -> Bool {
        // Check if account exists and is active in Firestore
        let userDocRef = db.collection("users").document(user.uid)
        let document = try await userDocRef.getDocument()
        
        guard let data = document.data() else {
            // New user - create account document
            try await createUserAccount(user: user)
            return true
        }
        
        // Check if account is active
        let isActive = data["isActive"] as? Bool ?? true
        let isSuspended = data["isSuspended"] as? Bool ?? false
        
        return isActive && !isSuspended
    }
    
    private func createUserAccount(user: User) async throws {
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp(),
            "isActive": true,
            "isSuspended": false,
            "version": 1
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
    }
    
    // MARK: - Cloud Synchronization
    
    func syncUserData() async {
        guard let user = currentUser else {
            syncError = "No authenticated user"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Fetch local user data
            guard let localUserData = fetchCurrentUserData() else {
                throw CloudSyncError.noLocalData
            }
            
            // Update Firebase UID if needed
            if localUserData.firebaseUID != user.uid {
                localUserData.firebaseUID = user.uid
                localUserData.isSignedIn = true
                saveContext()
            }
            
            // Sync with Firestore
            try await syncToFirestore(userData: localUserData, userID: user.uid)
            
            // Update last sync date
            lastSyncDate = Date()
            
            // Update last active timestamp
            try await updateLastActiveTimestamp(userID: user.uid)
            
        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
            print("CloudSync Error: \(error)")
        }
        
        isSyncing = false
    }
    
    private func syncToFirestore(userData: UserData, userID: String) async throws {
        let userDocRef = db.collection("users").document(userID)
        let progressDocRef = db.collection("userProgress").document(userID)
        
        // Prepare user data for Firestore
        let firestoreUserData: [String: Any] = [
            "displayName": userData.displayName,
            "email": userData.email,
            "preferredLanguage": userData.preferredLanguage,
            "lastSyncDate": FieldValue.serverTimestamp(),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Prepare progress data for Firestore
        let firestoreProgressData: [String: Any] = [
            "totalGamesPlayed": userData.totalGamesPlayed,
            "totalCorrectAnswers": userData.totalCorrectAnswers,
            "totalIncorrectAnswers": userData.totalIncorrectAnswers,
            "currentLevel": userData.currentLevel,
            "currentScore": userData.currentScore,
            "achievements": userData.achievements,
            "preferences": [
                "soundEnabled": userData.soundEnabled,
                "hapticEnabled": userData.hapticEnabled,
                "difficultyLevel": userData.difficultyLevel
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Use batch write for atomic updates
        let batch = db.batch()
        batch.setData(firestoreUserData, forDocument: userDocRef, merge: true)
        batch.setData(firestoreProgressData, forDocument: progressDocRef, merge: true)
        
        try await batch.commit()
    }
    
    private func updateLastActiveTimestamp(userID: String) async throws {
        let userDocRef = db.collection("users").document(userID)
        try await userDocRef.updateData([
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Data Management
    
    private func fetchCurrentUserData() -> UserData? {
        let descriptor = FetchDescriptor<UserData>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        
        do {
            let userData = try modelContext.fetch(descriptor)
            return userData.first
        } catch {
            print("Failed to fetch user data: \(error)")
            return nil
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func signIn() async throws {
        // This would integrate with your preferred sign-in method
        // For now, we'll use anonymous authentication for testing
        let result = try await Auth.auth().signInAnonymously()
        print("Signed in anonymously with user ID: \(result.user.uid)")
    }
    
    func signOut() async throws {
        try Auth.auth().signOut()
    }
    
    func forceSyncNow() async {
        await syncUserData()
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflicts(localData: UserData, remoteData: [String: Any]) -> [String: Any] {
        // Server timestamp wins for most fields
        // But preserve local progress if it's more recent
        var resolvedData = remoteData
        
        // Compare game progress - keep higher values
        if let remoteGamesPlayed = remoteData["totalGamesPlayed"] as? Int,
           localData.totalGamesPlayed > remoteGamesPlayed {
            resolvedData["totalGamesPlayed"] = localData.totalGamesPlayed
        }
        
        if let remoteCorrectAnswers = remoteData["totalCorrectAnswers"] as? Int,
           localData.totalCorrectAnswers > remoteCorrectAnswers {
            resolvedData["totalCorrectAnswers"] = localData.totalCorrectAnswers
        }
        
        if let remoteLevel = remoteData["currentLevel"] as? Int,
           localData.currentLevel > remoteLevel {
            resolvedData["currentLevel"] = localData.currentLevel
        }
        
        return resolvedData
    }
}

// MARK: - Error Types

enum CloudSyncError: LocalizedError {
    case noLocalData
    case userNotAuthenticated
    case syncFailed(String)
    case accountInactive
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .noLocalData:
            return "No local user data found"
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .accountInactive:
            return "Account is not active"
        case .accessDenied:
            return "Account access denied"
        }
    }
}
