//
//  UserDataDebugView.swift
//  ConvAI
//
//  Debug view to check user data sources
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// User and AgentState are defined in Agents.swift, so we can reference them directly

struct UserDataDebugView: View {
    @State private var debugInfo: String = "Loading..."
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle button
            Button(action: {
                isExpanded.toggle()
                if isExpanded {
                    checkAllUserData()
                }
            }) {
                HStack {
                    Text("🔍 Debug User Data")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            if isExpanded {
                ScrollView {
                    Text(debugInfo)
                        .font(.system(.caption, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                
                Button("Refresh Data") {
                    checkAllUserData()
                }
                .padding(.top)
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private func checkAllUserData() {
        var info = ""
        
        // 1. Check Firebase Auth current user
        if let user = Auth.auth().currentUser {
            info += "🔍 FIREBASE AUTH USER:\n"
            info += "  UID: \(user.uid)\n"
            info += "  Email: \(user.email ?? "nil")\n"
            info += "  Display Name: '\(user.displayName ?? "nil")'\n"
            info += "  Photo URL: \(user.photoURL?.absoluteString ?? "nil")\n\n"
        } else {
            info += "❌ No authenticated user found\n\n"
        }
        
        // 2. Check UserDefaults for any saved user data
        info += "🔍 USERDEFAULTS DATA:\n"
        
        // Check AgentState User data
        if let userData = UserDefaults.standard.data(forKey: "user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            info += "  AgentState User: name='\(user.name)', info='\(user.info)'\n"
        } else {
            info += "  No AgentState user data in UserDefaults\n"
        }
        
        // Check UserProfile data
        if let profileData = UserDefaults.standard.data(forKey: "userProfile") {
            // We can't decode this easily without the UserProfileData struct
            info += "  UserProfile data exists in UserDefaults\n"
        } else {
            info += "  No userProfile data in UserDefaults\n"
        }
        info += "\n"
        
        // 3. Check what GameProgressManager currently has
        let progressService = GameProgressManager.shared
        info += "🔍 GAMEPROGRESSMANAGER:\n"
        info += "  Current Level: \(progressService.currentLevel)\n"
        info += "  Total XP: \(progressService.totalXP)\n\n"
        
        // 4. Check UserProfile instance
        let userProfile = UserProfile()
        info += "🔍 USERPROFILE INSTANCE:\n"
        info += "  Name: '\(userProfile.name)'\n"
        info += "  Is Setup: \(userProfile.isSetup)\n"
        info += "  Preferred Language: \(userProfile.preferredLanguage ?? "nil")\n\n"
        
        // 5. Check AgentState
        let agentState = AgentState()
        info += "🔍 AGENTSTATE:\n"
        info += "  User Name: '\(agentState.user.name)'\n"
        info += "  User Info: '\(agentState.user.info)'\n\n"
        
        self.debugInfo = info
        
        // 6. Check Firestore user document (async)
        checkFirestoreUserData()
    }
    
    private func checkFirestoreUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.debugInfo += "❌ No user ID for Firestore check\n"
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                var firestoreInfo = "🔍 FIRESTORE USER DOCUMENT:\n"
                
                if let error = error {
                    firestoreInfo += "❌ Error: \(error.localizedDescription)\n"
                } else if let document = document, document.exists {
                    if let data = document.data() {
                        for (key, value) in data.sorted(by: { $0.key < $1.key }) {
                            firestoreInfo += "  \(key): \(value)\n"
                        }
                    } else {
                        firestoreInfo += "  Document exists but has no data\n"
                    }
                } else {
                    firestoreInfo += "❌ No Firestore user document found\n"
                }
                
                self.debugInfo += firestoreInfo
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UserDataDebugView()
}
