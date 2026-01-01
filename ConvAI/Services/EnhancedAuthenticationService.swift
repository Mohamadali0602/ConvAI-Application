//
//  EnhancedAuthenticationService.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class EnhancedAuthenticationService: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var currentNonce: String?
    
    override init() {
        super.init()
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isSignedIn = user != nil
                // Ensure user profile exists when auth state changes
                if user != nil {
                    self?.ensureUserProfileExists()
                }
            }
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // As you're not using view controllers to retrieve the presentingViewController, access it through
        // the shared instance of the UIApplication
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

        isLoading = true

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] result, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error doing Google Sign-In, \(error)")
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard
                  let user = result?.user,
                  let idToken = user.idToken?.tokenString
                else {
                  print("Error during Google Sign-In authentication")
                  return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)
                  
                // Authenticate with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        if let e = error {
                            print(e.localizedDescription)
                            self.errorMessage = e.localizedDescription
                        } else {
                            print("Signed in with Google")
                            // Create user profile in Firestore if it doesn't exist
                            self.ensureUserProfileExists()
                            // The auth state listener will automatically update isSignedIn
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let failure):
            DispatchQueue.main.async {
                self.errorMessage = failure.localizedDescription
                self.isLoading = false
            }
        case .success(let success):
            // Check if the credential is an Apple ID credential.
            if let appleIDCredential = success.credential as? ASAuthorizationAppleIDCredential {
                
                // Retrieve the raw nonce you stored before the request.
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                
                // Retrieve the identity token from Apple.
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token.")
                    return
                }

                // Convert the token to a string.
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return
                }

                // Create an OAuth credential for Firebase.
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                             rawNonce: nonce,
                                                             fullName: appleIDCredential.fullName)
                
                // Use the credential to sign in with Firebase.
                Task {
                    do {
                        let result = try await Auth.auth().signIn(with: credential)
                        
                        // Update the user's display name if it's the first sign-in.
                        await updateDisplayName(for: result.user, with: appleIDCredential)
                        
                        DispatchQueue.main.async {
                            self.currentUser = result.user
                            self.isSignedIn = true
                            self.isLoading = false
                            // Create user profile in Firestore if it doesn't exist
                            self.ensureUserProfileExists()
                        }

                    } catch {
                        DispatchQueue.main.async {
                            self.errorMessage = "Error authenticating: \(error.localizedDescription)"
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    func updateDisplayName(for user: FirebaseAuth.User, with appleIDCredential: ASAuthorizationAppleIDCredential) async {
        // Check if the current display name is empty (or nil)
        if let currentDisplayName = user.displayName, !currentDisplayName.isEmpty {
            return // Don't overwrite an existing display name.
        }
        
        // Check if Apple provided a name.
        guard let displayName = appleIDCredential.displayName else { return }

        // Create a change request for the user's profile.
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        
        do {
            // Commit the changes to Firebase Auth.
            try await changeRequest.commitChanges()
            
            // Update the local view model property to refresh the UI.
            DispatchQueue.main.async {
                // Refresh the user data if needed
                self.currentUser = Auth.auth().currentUser
            }
            
        } catch {
            print("Unable to update the user's displayname: \(error.localizedDescription)")
        }
    }
    
    private func signInWithCredential(_ credential: AuthCredential) {
        isLoading = true
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user else { return }
                
                // Check if this is a new user
                if result?.additionalUserInfo?.isNewUser == true {
                    // New user - need age input and profile completion
                    // This will be handled by the coordinator
                } else {
                    // Existing user
                    self?.currentUser = user
                    self?.isSignedIn = true
                }
            }
        }
    }
    
    private func saveUserData(userId: String, email: String, username: String, age: Int) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": email,
            "username": username,
            "age": age,
            "createdAt": Timestamp(),
            "level": "beginner",
            "xp": 0,
            "streak": 0
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error)")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            currentUser = nil
            errorMessage = ""
            print("🚪 User signed out successfully - isSignedIn set to false")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign out failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper functions
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - User Profile Management
    
    private func ensureUserProfileExists() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        // Check if user profile exists
        userRef.getDocument { [weak self] (document, error) in
            if let error = error {
                print("❌ Error checking user profile: \(error)")
                return
            }
            
            if let document = document, document.exists {
                print("✅ User profile already exists")
            } else {
                // Create new user profile
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "displayName": user.displayName ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastLoginAt": FieldValue.serverTimestamp(),
                    "totalXP": 0,
                    "currentLevel": 1,
                    "streakDays": 0,
                    "lessonsCompleted": 0,
                    "conversationMinutes": 0
                ]
                
                userRef.setData(userData) { error in
                    if let error = error {
                        print("❌ Error creating user profile: \(error)")
                    } else {
                        print("✅ User profile created successfully")
                    }
                }
            }
        }
    }
}

// MARK: - Apple Sign-In Delegates

extension EnhancedAuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleSignInWithAppleCompletion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleSignInWithAppleCompletion(.failure(error))
    }
}

extension EnhancedAuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Helper Extension for Apple Sign-In

extension ASAuthorizationAppleIDCredential {
    var displayName: String? {
        guard let fullName = fullName else { return nil }
        return PersonNameComponentsFormatter().string(from: fullName)
    }
}
