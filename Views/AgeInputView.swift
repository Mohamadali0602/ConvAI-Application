//
//  AgeInputView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import SwiftUI

struct AgeInputView: View {
    @State private var ageText = ""
    @State private var showError = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Date picker states
    @State private var selectedMonth = 1
    @State private var selectedDay = 1
    @State private var selectedYear = 1999 // Default to someone who would be ~25 years old
    
    let onContinue: (Int) -> Void
    let onBack: () -> Void
    
    // Cache localized strings at view initialization to avoid repeated lookups
    private let ageTitle: String
    private let agePlaceholder: String
    private let ageError: String
    private let continueText: String
    private let termsText: String
    
    // Month names for display
    private let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    init(onContinue: @escaping (Int) -> Void, onBack: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onBack = onBack
        
        // Cache strings once at initialization - using fallback values for now
        self.ageTitle = "When were you born?"
        self.agePlaceholder = "Enter your age"
        self.ageError = "Please enter a valid date"
        self.continueText = "Continue"
        self.termsText = "This will be used to calibrate your custom plan."
    }
    
    var body: some View {
        ZStack {
            // ConvAI gradient background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Title
                Text(ageTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Date picker wheels
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        // Month picker
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthNames[month - 1])
                                    .tag(month)
                                    .foregroundColor(.white)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        #endif
                        .frame(maxWidth: .infinity)
                        .onChange(of: selectedMonth) { _, _ in
                            // Adjust day if necessary
                            let maxDays = daysInMonth(month: selectedMonth, year: selectedYear)
                            if selectedDay > maxDays {
                                selectedDay = maxDays
                            }
                            // Haptic feedback
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            #endif
                        }
                        
                        // Day picker
                        Picker("Day", selection: $selectedDay) {
                            ForEach(1...daysInMonth(month: selectedMonth, year: selectedYear), id: \.self) { day in
                                Text("\(day)")
                                    .tag(day)
                                    .foregroundColor(.white)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        #endif
                        .frame(maxWidth: .infinity)
                        
                        // Year picker
                        Picker("Year", selection: $selectedYear) {
                            ForEach(1900...2030, id: \.self) { year in
                                Text("\(year)")
                                    .tag(year)
                                    .foregroundColor(.white)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        #endif
                        .frame(maxWidth: .infinity)
                        .onChange(of: selectedYear) { _, _ in
                            // Adjust day for leap year
                            let maxDays = daysInMonth(month: selectedMonth, year: selectedYear)
                            if selectedDay > maxDays {
                                selectedDay = maxDays
                            }
                            // Haptic feedback
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            #endif
                        }
                    }
                    .frame(height: 150)
                    
                    if showError {
                        Text(ageError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    validateAndContinue()
                }) {
                    Text(continueText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidAge ? Color(red: 0.78, green: 0.36, blue: 0.17) : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValidAge)
                .padding(.horizontal, 20)
                
                // Terms and conditions
                Text(termsText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .onChange(of: ageText) { _, newValue in
            if showError {
                showError = false
            }
        }
        .onChange(of: selectedMonth) { _, _ in
            if showError {
                showError = false
            }
        }
        .onChange(of: selectedDay) { _, _ in
            if showError {
                showError = false
            }
            // Haptic feedback
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
        }
        .onChange(of: selectedYear) { _, _ in
            if showError {
                showError = false
            }
        }
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        switch month {
        case 2:
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
    
    private func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    private var isValidAge: Bool {
        let birthDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay))
        guard let birthDate = birthDate else { return false }
        
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age >= 18 && age <= 100
    }
    
    private func validateAndContinue() {
        let birthDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay))
        guard let birthDate = birthDate else {
            showError = true
            return
        }
        
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        guard age >= 18 && age <= 100 else {
            showError = true
            return
        }
        
        // Update the ageText to maintain compatibility with existing code
        ageText = "\(age)"
        onContinue(age)
    }
}

#Preview {
    AgeInputView(
        onContinue: { age in print("Age: \(age)") },
        onBack: { print("Back") }
    )
}
