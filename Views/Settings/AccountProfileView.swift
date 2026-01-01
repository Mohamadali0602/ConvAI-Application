//
//  AccountProfileView.swift
//  ConvAI
//
//  Production-ready Account & Profile settings view
//

import SwiftUI
import Firebase
import FirebaseAuth

struct AccountProfileView: View {
    @StateObject private var accountService: AccountSettingsService
    @StateObject private var storeKitManager: StoreKit2PurchaseManager
    @EnvironmentObject var authService: EnhancedAuthenticationService
    @State private var showingDisplayNameEdit = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingDataExport = false
    @State private var showingError = false
    @State private var editingDisplayName = ""
    @State private var exportedDataURL: URL?
    
    // ConvAI Colors
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    init() {
        let storeKit = StoreKit2PurchaseManager()
        self._storeKitManager = StateObject(wrappedValue: storeKit)
        self._accountService = StateObject(wrappedValue: AccountSettingsService(storeKitManager: storeKit))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Account Information Section
                accountInformationSection
                
                // Subscription Section
                subscriptionSection
                
                // Account Actions Section
                accountActionsSection
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
        .navigationTitle("Account & Profile")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                await accountService.loadUserData()
                await storeKitManager.loadProducts()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(accountService.errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingDisplayNameEdit) {
            displayNameEditSheet
        }
        .sheet(isPresented: $showingDataExport) {
            dataExportSheet
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                // Use the global auth service to ensure proper state synchronization
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await accountService.deleteAccount()
                    } catch {
                        showingError = true
                    }
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    // MARK: - Account Information Section
    
    private var accountInformationSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Account Information", icon: "person.circle.fill")
            
            VStack(spacing: 12) {
                // Display Name
                AccountInfoRow(
                    title: "Name",
                    value: accountService.userAccount.displayName.isEmpty ? "Not set" : accountService.userAccount.displayName,
                    icon: "person.fill",
                    action: {
                        editingDisplayName = accountService.userAccount.displayName
                        showingDisplayNameEdit = true
                    }
                )
                
                // Email
                AccountInfoRow(
                    title: "Email",
                    value: accountService.userAccount.email,
                    icon: "envelope.fill"
                )
                
                // Auth Provider
                AccountInfoRow(
                    title: "Sign-in Method",
                    value: accountService.userAccount.authProvider.displayName,
                    icon: accountService.userAccount.authProvider.iconName
                )
                
                // Account Creation Date
                if let creationDate = accountService.userAccount.accountCreationDate {
                    AccountInfoRow(
                        title: "Member Since",
                        value: formatDate(creationDate),
                        icon: "calendar"
                    )
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Subscription", icon: "crown.fill")
            
            VStack(spacing: 16) {
                // Current Plan Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: accountService.subscriptionStatus.tier.iconName)
                                .foregroundColor(primaryColor)
                            Text(accountService.subscriptionStatus.statusText)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        if let expirationText = accountService.subscriptionStatus.expirationText {
                            Text(expirationText)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Status Indicator
                    Circle()
                        .fill(accountService.subscriptionStatus.isActive ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                }
                .padding(16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                
                // Subscription Actions
                VStack(spacing: 12) {
                    Button(action: {
                        accountService.openSubscriptionManagement()
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Manage Subscription")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(primaryColor)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            await accountService.refreshSubscriptionStatus()
                        }
                    }) {
                        HStack {
                            if accountService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh Status")
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .disabled(accountService.isLoading)
                }
                
                // Features List
                if !accountService.subscriptionStatus.tier.features.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Included Features:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ForEach(accountService.subscriptionStatus.tier.features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Account Actions Section
    
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Account Actions", icon: "gear")
            
            VStack(spacing: 12) {
                // Export Data
                ActionButton(
                    title: "Export My Data",
                    subtitle: "Download all your account data",
                    icon: "square.and.arrow.up",
                    action: { showingDataExport = true }
                )
                
                // Sign Out
                ActionButton(
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    icon: "rectangle.portrait.and.arrow.right",
                    action: { showingSignOutAlert = true }
                )
                
                // Delete Account
                ActionButton(
                    title: "Delete Account",
                    subtitle: "Permanently delete your account and data",
                    icon: "trash.fill",
                    isDestructive: true,
                    action: { showingDeleteAccountAlert = true }
                )
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Display Name Edit Sheet
    
    private var displayNameEditSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Display Name", text: $editingDisplayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                
                Text("This name will be displayed in your profile and conversations.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Display Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDisplayNameEdit = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            do {
                                try await accountService.updateDisplayName(editingDisplayName)
                                showingDisplayNameEdit = false
                            } catch {
                                showingError = true
                            }
                        }
                    }
                    .disabled(editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Data Export Sheet
    
    private var dataExportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(primaryColor)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("We'll create a file containing all your account data, including profile information, settings, and conversation history.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let exportedURL = exportedDataURL {
                    ShareLink(item: exportedURL) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Exported Data")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(primaryColor)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        Task {
                            do {
                                exportedDataURL = try await accountService.exportUserData()
                            } catch {
                                showingError = true
                                showingDataExport = false
                            }
                        }
                    }) {
                        HStack {
                            if accountService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text("Export Data")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(primaryColor)
                        .cornerRadius(12)
                    }
                    .disabled(accountService.isLoading)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        showingDataExport = false
                        exportedDataURL = nil
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(primaryColor)
                .font(.title2)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct AccountInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let action: (() -> Void)?
    
    init(title: String, value: String, icon: String, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.17))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if action != nil {
                Button(action: action!) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : Color(red: 0.78, green: 0.36, blue: 0.17))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption)
            }
            .padding(12)
            .background(isDestructive ? Color.red.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct AccountProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountProfileView()
        }
        .preferredColorScheme(.dark)
    }
}
