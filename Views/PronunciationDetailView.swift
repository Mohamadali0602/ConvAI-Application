//
//  PronunciationDetailView.swift
//  ConvAI
//
//  Created by Copilot on 15/08/2025.
//

import SwiftUI

struct PronunciationDetailView: View {
    let result: PronunciationResult
    @Environment(\.dismiss) private var dismiss
    
    // ConvAI Colors
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    @State private var selectedTab: DetailTab = .overview
    @State private var showPhoneticHelp = false
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case words = "Words"
        case feedback = "Feedback"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [darkBackground, secondaryDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        overviewTab
                            .tag(DetailTab.overview)
                        
                        wordsTab
                            .tag(DetailTab.words)
                        
                        feedbackTab
                            .tag(DetailTab.feedback)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showPhoneticHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showPhoneticHelp) {
            PhoneticHelpView()
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.headline)
                            .fontWeight(selectedTab == tab ? .bold : .medium)
                            .foregroundColor(selectedTab == tab ? primaryColor : .white.opacity(0.6))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? primaryColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Score Section
                overallScoreSection
                
                // Comparison Section
                comparisonSection
                
                // Session Info
                sessionInfoSection
            }
            .padding()
        }
    }
    
    private var overallScoreSection: some View {
        VStack(spacing: 20) {
            Text("Overall Score")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: result.overallScore)
                    .stroke(scoreColor(result.overallScore), lineWidth: 12)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2.0), value: result.overallScore)
                
                // Score text
                VStack(spacing: 4) {
                    Text("\(Int(result.overallScore * 100))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("/ 100")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Score interpretation
            VStack(spacing: 8) {
                Text(scoreInterpretation)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor(result.overallScore))
                
                Text(scoreDescription)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(scoreColor(result.overallScore).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(scoreColor(result.overallScore).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pronunciation Comparison")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Target pronunciation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.green)
                        Text("Target")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Text(result.targetText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Your pronunciation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(primaryColor)
                        Text("Your Pronunciation")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                    }
                    
                    Text(result.recognizedText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(primaryColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar",
                    title: "Date",
                    value: formatDate(result.timestamp)
                )
                
                InfoRow(
                    icon: "clock",
                    title: "Time",
                    value: formatTime(result.timestamp)
                )
                
                InfoRow(
                    icon: "textformat.abc",
                    title: "Word Count",
                    value: "\(result.targetText.components(separatedBy: .whitespacesAndNewlines).count) words"
                )
                
                InfoRow(
                    icon: "checkmark.circle",
                    title: "Accuracy",
                    value: "\(Int(result.overallScore * 100))%"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Words Tab
    private var wordsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if result.wordScores.isEmpty {
                    // Fallback when no word-level data available
                    VStack(spacing: 16) {
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Word-level analysis not available")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("This session used overall pronunciation scoring.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Word-by-Word Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(result.wordScores, id: \.word) { wordScore in
                                WordScoreCard(wordScore: wordScore)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Feedback Tab
    private var feedbackTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Strengths Section
                if !result.feedback.strengths.isEmpty {
                    FeedbackSection(
                        title: "What You Did Well",
                        items: result.feedback.strengths,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                }
                
                // Improvements Section
                if !result.feedback.improvements.isEmpty {
                    FeedbackSection(
                        title: "Areas for Improvement",
                        items: result.feedback.improvements,
                        color: .orange,
                        icon: "arrow.up.circle.fill"
                    )
                }
                
                // Specific Tips Section
                if !result.feedback.specificTips.isEmpty {
                    FeedbackSection(
                        title: "Pronunciation Tips",
                        items: result.feedback.specificTips,
                        color: primaryColor,
                        icon: "lightbulb.fill"
                    )
                }
                
                // Practice Words Section
                if !result.feedback.practiceWords.isEmpty {
                    practiceWordsSection
                }
            }
            .padding()
        }
    }
    
    private var practiceWordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .foregroundColor(secondaryColor)
                Text("Words to Practice")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(result.feedback.practiceWords, id: \.self) { word in
                    Text(word)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(secondaryColor.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(secondaryColor.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Helper Methods
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return secondaryColor
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
    
    private var scoreInterpretation: String {
        switch result.overallScore {
        case 0.95...1.0:
            return "Perfect!"
        case 0.9..<0.95:
            return "Excellent"
        case 0.8..<0.9:
            return "Very Good"
        case 0.7..<0.8:
            return "Good"
        case 0.6..<0.7:
            return "Fair"
        case 0.5..<0.6:
            return "Needs Practice"
        default:
            return "Keep Practicing"
        }
    }
    
    private var scoreDescription: String {
        switch result.overallScore {
        case 0.95...1.0:
            return "Outstanding pronunciation! You sound like a native speaker."
        case 0.9..<0.95:
            return "Excellent pronunciation with perfect clarity."
        case 0.8..<0.9:
            return "Very good pronunciation. Minor improvements possible."
        case 0.7..<0.8:
            return "Good pronunciation. Some areas need work."
        case 0.6..<0.7:
            return "Fair pronunciation. Regular practice will help."
        case 0.5..<0.6:
            return "Pronunciation needs improvement. Focus on clarity."
        default:
            return "Keep practicing! Every session makes you better."
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(primaryColor)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

struct WordScoreCard: View {
    let wordScore: WordPronunciationScore
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word and score
            HStack {
                Text(wordScore.word)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(wordScore.accuracy * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(wordScore.accuracy))
            }
            
            // Phonetic comparison
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(wordScore.targetPhonemes)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Yours:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(wordScore.recognizedPhonemes)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(scoreColor(wordScore.accuracy))
                }
            }
            
            // Suggestions
            if !wordScore.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                    
                    ForEach(wordScore.suggestions.prefix(2), id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(scoreColor(wordScore.accuracy).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return Color(red: 0.97, green: 0.70, blue: 0.35)
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

struct FeedbackSection: View {
    let title: String
    let items: [String]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            )
    }
}

struct PhoneticHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [darkBackground, secondaryDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Understanding Phonetic Symbols")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Phonetic symbols help you understand the exact pronunciation of words. Here are some common symbols:")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 16) {
                            PhoneticSymbolRow(symbol: "θ", example: "think", description: "Voiceless 'th' sound")
                            PhoneticSymbolRow(symbol: "ð", example: "this", description: "Voiced 'th' sound")
                            PhoneticSymbolRow(symbol: "ʃ", example: "ship", description: "'sh' sound")
                            PhoneticSymbolRow(symbol: "tʃ", example: "chip", description: "'ch' sound")
                            PhoneticSymbolRow(symbol: "dʒ", example: "jump", description: "'j' sound")
                            PhoneticSymbolRow(symbol: "ŋ", example: "sing", description: "'ng' sound")
                            PhoneticSymbolRow(symbol: "ə", example: "about", description: "Schwa (neutral vowel)")
                        }
                        
                        Text("Practice Tip")
                            .font(.headline)
                            .foregroundColor(primaryColor)
                            .padding(.top)
                        
                        Text("Listen carefully to the target pronunciation and try to match the sounds exactly. The phonetic symbols show you the precise sounds to make.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
            }
            .navigationTitle("Phonetic Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
        }
    }
}

struct PhoneticSymbolRow: View {
    let symbol: String
    let example: String
    let description: String
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        HStack(spacing: 16) {
            Text(symbol)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(primaryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(example)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview
struct PronunciationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PronunciationDetailView(result: PronunciationResult(
            targetText: "Hello world",
            recognizedText: "Hello world",
            overallScore: 0.85,
            wordScores: [
                WordPronunciationScore(
                    word: "Hello",
                    targetPhonemes: "həˈloʊ",
                    recognizedPhonemes: "həˈloʊ",
                    accuracy: 0.9,
                    confidence: 0.95,
                    suggestions: ["Great pronunciation!"]
                )
            ],
            feedback: PronunciationFeedback(
                overallMessage: "Very good pronunciation!",
                strengths: ["Clear consonants", "Good rhythm"],
                improvements: ["Work on vowel sounds"],
                specificTips: ["Practice the 'o' sound"],
                practiceWords: ["world"]
            ),
            timestamp: Date()
        ))
    }
}
