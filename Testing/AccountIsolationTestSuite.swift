//
//  AccountIsolationTestSuite.swift
//  ConvAI
//
//  Comprehensive test suite for account isolation validation
//

import Foundation
import SwiftUI

/// Test suite for validating account isolation functionality
@MainActor
class AccountIsolationTestSuite: ObservableObject {
    
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    @Published var currentTest = ""
    
    private let accountManager = AccountDataManager.shared
    private let gameManager = GameProgressManager.shared
    private let userProfile = UserProfile()
    
    struct TestResult {
        let testName: String
        let passed: Bool
        let details: String
        let timestamp: Date
    }
    
    // MARK: - Test Execution
    
    func runAllTests() async {
        isRunning = true
        testResults.removeAll()
        
        await runBasicStorageTests()
        await runAccountSwitchingTests()
        await runDataIsolationTests()
        await runMigrationTests()
        await runUIIntegrationTests()
        
        isRunning = false
        generateTestReport()
    }
    
    // MARK: - Basic Storage Tests
    
    private func runBasicStorageTests() async {
        currentTest = "Basic Storage Tests"
        
        // Test 1: Basic account-specific storage
        await runTest("Basic Account Storage") {
            let testKey = "test_key"
            let testValue = "test_value_\(UUID().uuidString)"
            
            accountManager.setAccountSpecific(testValue, forKey: testKey)
            let retrievedValue = accountManager.getAccountSpecific(forKey: testKey, type: String.self)
            
            return retrievedValue == testValue
        } details: { passed in
            passed ? "✅ Account-specific storage working correctly" 
                   : "❌ Failed to store/retrieve account-specific data"
        }
        
        // Test 2: Different data types
        await runTest("Multiple Data Types") {
            accountManager.setAccountSpecific(42, forKey: "test_int")
            accountManager.setAccountSpecific(true, forKey: "test_bool")
            accountManager.setAccountSpecific(["item1", "item2"], forKey: "test_array")
            
            let intValue = accountManager.getAccountSpecific(forKey: "test_int", type: Int.self)
            let boolValue = accountManager.getAccountSpecific(forKey: "test_bool", type: Bool.self)
            let arrayValue = accountManager.getAccountSpecific(forKey: "test_array", type: [String].self)
            
            return intValue == 42 && boolValue == true && arrayValue?.count == 2
        } details: { passed in
            passed ? "✅ Multiple data types stored correctly"
                   : "❌ Failed to handle different data types"
        }
        
        // Test 3: Default values
        await runTest("Default Values") {
            let nonExistentKey = "non_existent_\(UUID().uuidString)"
            let defaultValue = "default"
            
            let result = accountManager.getAccountSpecific(forKey: nonExistentKey, defaultValue: defaultValue)
            
            return result == defaultValue
        } details: { passed in
            passed ? "✅ Default values working correctly"
                   : "❌ Default values not returned properly"
        }
    }
    
    // MARK: - Account Switching Tests
    
    private func runAccountSwitchingTests() async {
        currentTest = "Account Switching Tests"
        
        // Test 4: Account switching isolation
        await runTest("Account Switch Isolation") {
            let account1 = "test_account_1"
            let account2 = "test_account_2"
            let testKey = "isolation_test"
            let value1 = "data_for_account_1"
            let value2 = "data_for_account_2"
            
            // Set data for account 1
            accountManager.switchToAccount(account1)
            await Task.yield()
            accountManager.setAccountSpecific(value1, forKey: testKey)
            
            // Switch to account 2 and set different data
            accountManager.switchToAccount(account2)
            await Task.yield()
            accountManager.setAccountSpecific(value2, forKey: testKey)
            
            // Verify account 2 data
            let account2Data = accountManager.getAccountSpecific(forKey: testKey, type: String.self)
            
            // Switch back to account 1 and verify its data
            accountManager.switchToAccount(account1)
            await Task.yield()
            let account1Data = accountManager.getAccountSpecific(forKey: testKey, type: String.self)
            
            return account1Data == value1 && account2Data == value2
        } details: { passed in
            passed ? "✅ Account switching maintains data isolation"
                   : "❌ Data leaked between accounts during switching"
        }
        
        // Test 5: Guest account isolation
        await runTest("Guest Account Isolation") {
            let originalAccount = accountManager.currentAccount
            
            // Switch to guest
            accountManager.signOutAndSwitchToGuest()
            await Task.yield()
            
            let guestAccount = accountManager.currentAccount
            accountManager.setAccountSpecific("guest_data", forKey: "guest_test")
            
            // Switch back to original account
            accountManager.switchToAccount(originalAccount)
            await Task.yield()
            
            let guestData = accountManager.getAccountSpecific(forKey: "guest_test", type: String.self)
            
            return guestAccount.contains("guest") && guestData == nil
        } details: { passed in
            passed ? "✅ Guest account properly isolated"
                   : "❌ Guest account data leaked to other accounts"
        }
    }
    
    // MARK: - Data Isolation Tests
    
    private func runDataIsolationTests() async {
        currentTest = "Data Isolation Tests"
        
        // Test 6: GameProgressManager isolation
        await runTest("Game Progress Isolation") {
            let account1 = "progress_test_1"
            let account2 = "progress_test_2"
            
            // Set progress for account 1
            accountManager.switchToAccount(account1)
            await Task.yield()
            gameManager.addXP(amount: 100)
            gameManager.setCurrentLevel(5)
            
            // Set different progress for account 2
            accountManager.switchToAccount(account2)
            await Task.yield()
            gameManager.addXP(amount: 200)
            gameManager.setCurrentLevel(3)
            
            let account2XP = gameManager.getCurrentXP()
            let account2Level = gameManager.getCurrentLevel()
            
            // Switch back to account 1
            accountManager.switchToAccount(account1)
            await Task.yield()
            
            let account1XP = gameManager.getCurrentXP()
            let account1Level = gameManager.getCurrentLevel()
            
            return account1XP == 100 && account1Level == 5 && 
                   account2XP == 200 && account2Level == 3
        } details: { passed in
            passed ? "✅ Game progress properly isolated between accounts"
                   : "❌ Game progress leaked between accounts"
        }
        
        // Test 7: UserProfile isolation
        await runTest("User Profile Isolation") {
            let account1 = "profile_test_1"
            let account2 = "profile_test_2"
            
            // Set profile for account 1
            accountManager.switchToAccount(account1)
            await Task.yield()
            userProfile.name = "User One"
            userProfile.preferredLanguage = "en-US"
            userProfile.saveProfile()
            
            // Set different profile for account 2
            accountManager.switchToAccount(account2)
            await Task.yield()
            userProfile.name = "User Two"
            userProfile.preferredLanguage = "es-ES"
            userProfile.saveProfile()
            
            let account2Name = userProfile.name
            let account2Lang = userProfile.preferredLanguage
            
            // Switch back to account 1
            accountManager.switchToAccount(account1)
            await Task.yield()
            
            let account1Name = userProfile.name
            let account1Lang = userProfile.preferredLanguage
            
            return account1Name == "User One" && account1Lang == "en-US" &&
                   account2Name == "User Two" && account2Lang == "es-ES"
        } details: { passed in
            passed ? "✅ User profiles properly isolated"
                   : "❌ User profile data leaked between accounts"
        }
    }
    
    // MARK: - Migration Tests
    
    private func runMigrationTests() async {
        currentTest = "Migration Tests"
        
        // Test 8: Migration preserves data
        await runTest("Migration Data Preservation") {
            // Create legacy data
            let legacyKey = "legacy_migration_test"
            let legacyValue = "legacy_data_\(UUID().uuidString)"
            UserDefaults.standard.set(legacyValue, forKey: legacyKey)
            
            // Perform migration
            accountManager.migrateKeysToAccountSpecific([legacyKey])
            
            // Check if data was migrated
            let migratedValue = accountManager.getAccountSpecific(forKey: legacyKey, type: String.self)
            
            return migratedValue == legacyValue
        } details: { passed in
            passed ? "✅ Migration preserves existing data"
                   : "❌ Migration lost existing data"
        }
    }
    
    // MARK: - UI Integration Tests
    
    private func runUIIntegrationTests() async {
        currentTest = "UI Integration Tests"
        
        // Test 9: Notification system
        await runTest("Account Change Notifications") {
            var notificationReceived = false
            
            let observer = NotificationCenter.default.addObserver(
                forName: .accountDidChange,
                object: nil,
                queue: .main
            ) { _ in
                notificationReceived = true
            }
            
            defer { NotificationCenter.default.removeObserver(observer) }
            
            let originalAccount = accountManager.currentAccount
            let testAccount = "notification_test_\(UUID().uuidString)"
            
            accountManager.switchToAccount(testAccount)
            await Task.yield()
            
            // Switch back
            accountManager.switchToAccount(originalAccount)
            await Task.yield()
            
            return notificationReceived
        } details: { passed in
            passed ? "✅ Account change notifications working"
                   : "❌ Account change notifications not triggered"
        }
        
        // Test 10: Validation system
        await runTest("Account Isolation Validation") {
            let issues = accountManager.validateAccountIsolation()
            
            // Filter out expected "no data" issues for test accounts
            let criticalIssues = issues.filter { !$0.contains("has no data") }
            
            return criticalIssues.isEmpty
        } details: { passed in
            let issues = accountManager.validateAccountIsolation()
            let criticalIssues = issues.filter { !$0.contains("has no data") }
            
            if passed {
                return "✅ Account isolation validation passed"
            } else {
                return "❌ Validation issues found: \(criticalIssues.joined(separator: ", "))"
            }
        }
    }
    
    // MARK: - Test Utilities
    
    private func runTest(
        _ name: String,
        test: () async throws -> Bool,
        details: (Bool) -> String
    ) async {
        do {
            let passed = try await test()
            let result = TestResult(
                testName: name,
                passed: passed,
                details: details(passed),
                timestamp: Date()
            )
            testResults.append(result)
        } catch {
            let result = TestResult(
                testName: name,
                passed: false,
                details: "❌ Test failed with error: \(error.localizedDescription)",
                timestamp: Date()
            )
            testResults.append(result)
        }
    }
    
    private func generateTestReport() {
        let passedCount = testResults.filter { $0.passed }.count
        let totalCount = testResults.count
        let passRate = totalCount > 0 ? Double(passedCount) / Double(totalCount) * 100 : 0
        
        print("🧪 Account Isolation Test Report")
        print("================================")
        print("Total Tests: \(totalCount)")
        print("Passed: \(passedCount)")
        print("Failed: \(totalCount - passedCount)")
        print("Pass Rate: \(String(format: "%.1f", passRate))%")
        print("================================")
        
        for result in testResults {
            let icon = result.passed ? "✅" : "❌"
            print("\(icon) \(result.testName)")
            print("   \(result.details)")
        }
        
        if passedCount == totalCount {
            print("\n🎉 All tests passed! Account isolation is working correctly.")
        } else {
            print("\n⚠️  Some tests failed. Please review the issues above.")
        }
    }
}

// MARK: - SwiftUI Test Interface

struct AccountIsolationTestView: View {
    @StateObject private var testSuite = AccountIsolationTestSuite()
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if testSuite.isRunning {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Running: \(testSuite.currentTest)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Run All Tests") {
                        Task {
                            await testSuite.runAllTests()
                            showingResults = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testSuite.isRunning)
                }
                
                if !testSuite.testResults.isEmpty {
                    TestResultsView(results: testSuite.testResults)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Account Isolation Tests")
            .sheet(isPresented: $showingResults) {
                TestReportView(results: testSuite.testResults)
            }
        }
    }
}

struct TestResultsView: View {
    let results: [AccountIsolationTestSuite.TestResult]
    
    var body: some View {
        List(results, id: \.testName) { result in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.passed ? .green : .red)
                    
                    Text(result.testName)
                        .font(.headline)
                    
                    Spacer()
                }
                
                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }
}

struct TestReportView: View {
    let results: [AccountIsolationTestSuite.TestResult]
    @Environment(\.dismiss) private var dismiss
    
    private var passedCount: Int {
        results.filter { $0.passed }.count
    }
    
    private var passRate: Double {
        results.isEmpty ? 0 : Double(passedCount) / Double(results.count) * 100
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Summary")
                        .font(.headline)
                    
                    HStack {
                        Label("\(results.count) Total", systemImage: "testtube.2")
                        Label("\(passedCount) Passed", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                        Label("\(results.count - passedCount) Failed", systemImage: "xmark.circle")
                            .foregroundColor(.red)
                    }
                    
                    Text("Pass Rate: \(String(format: "%.1f", passRate))%")
                        .font(.headline)
                        .foregroundColor(passRate == 100 ? .green : .orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Results
                TestResultsView(results: results)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test Report")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
