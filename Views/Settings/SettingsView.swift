//
//  SettingsView.swift
//  ConvAI
//
//  Production-ready Settings tab with Account & Profile functionality
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: EnhancedAuthenticationService
    @State private var showingSignInSheet = false
    
    // ConvAI Colors
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    var body: some View {
        NavigationView {
            if authService.isSignedIn {
                authenticatedSettingsView
            } else {
                unauthenticatedView
            }
        }
        .sheet(isPresented: $showingSignInSheet) {
            SignInSheetView()
        }
    }
    
    // MARK: - Authenticated Settings View
    
    private var authenticatedSettingsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Settings Sections
                VStack(spacing: 16) {
                    // Account & Profile Section
                    NavigationLink(destination: AccountProfileView()) {
                        SettingsSection(
                            title: "Account & Profile",
                            subtitle: "Manage your account and subscription",
                            icon: "person.circle.fill",
                            items: [
                                SettingsItem(title: "Profile Information", icon: "person.fill"),
                                SettingsItem(title: "Subscription Status", icon: "crown.fill"),
                                SettingsItem(title: "Account Settings", icon: "gearshape.fill")
                            ]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Language Settings Section
                    NavigationLink(destination: LanguageSettingsView()) {
                        SettingsSection(
                            title: "Language Settings",
                            subtitle: "Configure app and conversation languages",
                            icon: "globe",
                            items: [
                                SettingsItem(title: "App Language", icon: "textformat"),
                                SettingsItem(title: "Conversation Language", icon: "bubble.left.and.bubble.right"),
                                SettingsItem(title: "Voice & Accent", icon: "waveform")
                            ]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Support Section
                    NavigationLink(destination: SupportView()) {
                        SettingsSection(
                            title: "Support",
                            subtitle: "Get help and send feedback",
                            icon: "questionmark.circle.fill",
                            items: [
                                SettingsItem(title: "Help & FAQ", icon: "book.fill"),
                                SettingsItem(title: "Contact Support", icon: "envelope.fill"),
                                SettingsItem(title: "Report Bug", icon: "exclamationmark.triangle.fill")
                            ]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Legal & Info Section
                    NavigationLink(destination: LegalInfoView()) {
                        SettingsSection(
                            title: "Legal & Info",
                            subtitle: "App information and legal documents",
                            icon: "info.circle.fill",
                            items: [
                                SettingsItem(title: "About ConvAI", icon: "info"),
                                SettingsItem(title: "Privacy Policy", icon: "lock.shield"),
                                SettingsItem(title: "Terms of Service", icon: "doc.text")
                            ]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Unauthenticated View
    
    private var unauthenticatedView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "gearshape.fill")
                .font(.system(size: 80))
                .foregroundColor(primaryColor)
            
            // Title & Subtitle
            VStack(spacing: 12) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to access your account settings and preferences")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Sign In Button
            Button(action: { showingSignInSheet = true }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Sign In")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(primaryColor)
                .cornerRadius(25)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Settings Header
    
    private var settingsHeader: some View {
        VStack(spacing: 12) {
            // Compact User Avatar (tappable to open Account & Profile)
            if let user = authService.currentUser {
                NavigationLink(destination: AccountProfileView()) {
                    HStack {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(getInitials(from: user.displayName ?? user.email ?? ""))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        if names.count >= 2 {
            let firstName = String(names[0].prefix(1))
            let lastName = String(names[1].prefix(1))
            return "\(firstName)\(lastName)".uppercased()
        } else if let firstChar = name.first {
            return String(firstChar).uppercased()
        } else {
            return "U"
        }
    }
}

// MARK: - Settings Section View

struct SettingsSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let items: [SettingsItem]
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(primaryColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Items Preview
            VStack(spacing: 0) {
                ForEach(items.prefix(3)) { item in
                    HStack {
                        Image(systemName: item.icon)
                            .font(.caption)
                            .foregroundColor(primaryColor)
                            .frame(width: 16)
                        
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

// MARK: - Placeholder Views (to be implemented)

struct LanguageSettingsView: View {
    var body: some View {
        Text("Language Settings")
            .navigationTitle("Language Settings")
            .preferredColorScheme(.dark)
    }
}

struct SupportView: View {
    var body: some View {
        Text("Support")
            .navigationTitle("Support")
            .preferredColorScheme(.dark)
    }
}

struct LegalInfoView: View {
    var body: some View {
        Text("Legal & Info")
            .navigationTitle("Legal & Info")
            .preferredColorScheme(.dark)
    }
}

struct SignInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            AuthGateView()
                .navigationTitle("Sign In")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helper Extension for Corner Radius

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}
