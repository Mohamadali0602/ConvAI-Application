//
//  OnboardingAssessmentView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import SwiftUI

// MARK: - Assessment Models
struct AssessmentAnswer: Identifiable {
    let id = UUID()
    let text: String
    let value: String
    let description: String?
}

struct OnboardingAssessmentQuestion {
    let id: String
    let title: String
    let subtitle: String?
    let answers: [AssessmentAnswer]
    let allowMultiple: Bool = false
}

// MARK: - User Assessment Data
struct UserAssessmentData {
    var targetLanguage: String = ""
    var howTheyHeard: String = ""
    var currentLevel: String = ""
    var gender: String = ""
    var learningGoal: String = ""
    var dailyTimeCommitment: String = ""
    var estimatedWordsPerWeek: Int = 0
    
    var isComplete: Bool {
        return !targetLanguage.isEmpty && 
               !howTheyHeard.isEmpty && 
               !currentLevel.isEmpty && 
               !learningGoal.isEmpty && 
               !dailyTimeCommitment.isEmpty
    }
}

// MARK: - Main Assessment View
struct OnboardingAssessmentView: View {
    @State private var currentStep = 0
    @State private var assessmentData = UserAssessmentData()
    @State private var selectedAnswers: [String] = []
    @State private var showingCompletion = false
    @State private var showingReadyPage = false
    @State private var showingLevelAssessment = false
    @State private var showingPersonalizedSetup = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var userProfile: UserProfile
    
    // Callback for completion
    let onComplete: ((UserAssessmentData) -> Void)?
    
    // Initializer
    init(onComplete: ((UserAssessmentData) -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.1) // Dark background
    
    private var assessmentQuestions: [OnboardingAssessmentQuestion] {
        return [
            // Question 0: User gender
            OnboardingAssessmentQuestion(
                id: "user_gender",
                title: localizationManager.getString("user_gender_title"),
                subtitle: localizationManager.getString("user_gender_subtitle"),
                answers: [
                    AssessmentAnswer(text: localizationManager.getString("user_gender_male"), value: "male", description: localizationManager.getString("user_gender_male_desc")),
                    AssessmentAnswer(text: localizationManager.getString("user_gender_female"), value: "female", description: localizationManager.getString("user_gender_female_desc")),
                    AssessmentAnswer(text: localizationManager.getString("user_gender_nonbinary"), value: "nonbinary", description: localizationManager.getString("user_gender_nonbinary_desc")),
                    AssessmentAnswer(text: localizationManager.getString("user_gender_prefer_not_to_say"), value: "prefer_not_to_say", description: localizationManager.getString("user_gender_prefer_not_to_say_desc")),
                    AssessmentAnswer(text: localizationManager.getString("user_gender_other"), value: "other", description: localizationManager.getString("user_gender_other_desc"))
                ]
            ),
            // Question 1: Target Language
            OnboardingAssessmentQuestion(
                id: "target_language",
                title: localizationManager.getString("target_language_title"),
                subtitle: localizationManager.getString("target_language_subtitle"),
                answers: GeminiSupportedLanguages.allLanguages.map { language in
                    AssessmentAnswer(
                        text: language.displayName,
                        value: language.code,
                        description: language.nativeName
                    )
                }
            ),
            
            // Question 2: How they heard about the app
            OnboardingAssessmentQuestion(
                id: "discovery_source",
                title: localizationManager.getString("discovery_source_title"),
                subtitle: localizationManager.getString("discovery_source_subtitle"),
                answers: [
                    AssessmentAnswer(text: localizationManager.getString("app_store"), value: "app_store", description: localizationManager.getString("app_store_desc")),
                    AssessmentAnswer(text: localizationManager.getString("social_media"), value: "social_media", description: localizationManager.getString("social_media_desc")),
                    AssessmentAnswer(text: localizationManager.getString("friend"), value: "friend", description: localizationManager.getString("friend_desc")),
                    AssessmentAnswer(text: localizationManager.getString("community"), value: "community", description: localizationManager.getString("community_desc")),
                    AssessmentAnswer(text: localizationManager.getString("ad"), value: "ad", description: localizationManager.getString("ad_desc")),
                    AssessmentAnswer(text: localizationManager.getString("other"), value: "other", description: localizationManager.getString("other_desc"))
                ]
            ),
            // Inserted Personalization slide as a pseudo-question (no answers)
            OnboardingAssessmentQuestion(
                id: "personalization_info",
                title: localizationManager.getString("personalization_title"),
                subtitle: nil,
                answers: []
            ),
            
            // Question 3: Current level assessment
            OnboardingAssessmentQuestion(
                id: "current_level",
                title: localizationManager.getString("current_level_title"),
                subtitle: localizationManager.getString("current_level_subtitle"),
                answers: [
                    AssessmentAnswer(
                        text: localizationManager.getString("starting_out"),
                        value: "beginner",
                        description: localizationManager.getString("starting_out_desc")
                    ),
                    AssessmentAnswer(
                        text: localizationManager.getString("basic_words"),
                        value: "elementary",
                        description: localizationManager.getString("basic_words_desc")
                    ),
                    AssessmentAnswer(
                        text: localizationManager.getString("easy_conversations"),
                        value: "intermediate",
                        description: localizationManager.getString("easy_conversations_desc")
                    ),
                    AssessmentAnswer(
                        text: localizationManager.getString("different_topics"),
                        value: "upper_intermediate",
                        description: localizationManager.getString("different_topics_desc")
                    ),
                    AssessmentAnswer(
                        text: localizationManager.getString("any_topic"),
                        value: "advanced",
                        description: localizationManager.getString("any_topic_desc")
                    )
                ]
            ),
            
            // Question 4: Learning goals
            OnboardingAssessmentQuestion(
                id: "learning_goal",
                title: localizationManager.getString("learning_goal_title"),
                subtitle: localizationManager.getString("learning_goal_subtitle"),
                answers: [
                    AssessmentAnswer(text: localizationManager.getString("goal_love"), value: "love", description: localizationManager.getString("goal_love_desc")),
                    AssessmentAnswer(text: localizationManager.getString("goal_sales"), value: "sales", description: localizationManager.getString("goal_sales_desc")),
                    AssessmentAnswer(text: localizationManager.getString("goal_storytelling"), value: "storytelling", description: localizationManager.getString("goal_storytelling_desc")),
                    AssessmentAnswer(text: localizationManager.getString("goal_influence"), value: "influence", description: localizationManager.getString("goal_influence_desc")),
                    AssessmentAnswer(text: localizationManager.getString("goal_language_learning"), value: "language_learning", description: localizationManager.getString("goal_language_learning_desc"))
                ]
            ),
            // Commitment transformation slide (pseudo-question)
            OnboardingAssessmentQuestion(
                id: "commitment_transform",
                title: localizationManager.getString("commitment_title"),
                subtitle: nil,
                answers: []
            ),
        
            
            // Question 5: Daily time commitment
            OnboardingAssessmentQuestion(
                id: "daily_commitment",
                title: localizationManager.getString("daily_commitment_title"),
                subtitle: localizationManager.getString("daily_commitment_subtitle"),
                answers: [
                    AssessmentAnswer(
                        text: localizationManager.getString("commit_1h"),
                        value: "1h",
                        description: localizationManager.getString("commit_1h_desc")
                    ),
                    AssessmentAnswer(
                        text: localizationManager.getString("commit_3h"),
                        value: "3h",
                        description: localizationManager.getString("commit_3h_desc")
                    ),
                    AssessmentAnswer(
                        text: localizationManager.getString("commit_6h"),
                        value: "6h",
                        description: localizationManager.getString("commit_6h_desc")
                    )
                ]
            )
            ,
            // Result slide shown after daily commitment selection
            OnboardingAssessmentQuestion(
                id: "daily_commitment_result",
                title: "",
                subtitle: nil,
                answers: []
            )
        ]
    }
    
    var currentQuestion: OnboardingAssessmentQuestion {
        return assessmentQuestions[currentStep]
    }
    
    var progressPercentage: Double {
        return Double(currentStep) / Double(assessmentQuestions.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [backgroundColor, Color(red: 0.1, green: 0.1, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showingLevelAssessment {
                    LevelAssessmentTestView(
                        targetLanguage: assessmentData.targetLanguage,
                        onComplete: { level, percentage in
                            // Assessment completed with results
                            assessmentData.currentLevel = "level_\(level)"
                            
                            // Save assessment data and complete
                            UserDefaults.standard.set(true, forKey: "hasCompletedAssessment")
                            UserDefaults.standard.set(assessmentData.targetLanguage, forKey: "selectedLanguage")
                            UserDefaults.standard.set(assessmentData.gender, forKey: "userGender")
                            // Persist to UserProfile model as well
                            userProfile.gender = assessmentData.gender
                            userProfile.saveProfile()
                            UserDefaults.standard.set("level_\(level)", forKey: "userLevel")
                            UserDefaults.standard.set(assessmentData.dailyTimeCommitment, forKey: "dailyGoal")
                            UserDefaults.standard.set("assess", forKey: "startingPreference")
                            UserDefaults.standard.set(level, forKey: "determinedLevel")
                            UserDefaults.standard.set(percentage, forKey: "assessmentPercentage")
                            
                            onComplete?(assessmentData)
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingLevelAssessment = false
                                showingReadyPage = true
                            }
                        }
                    )

                } else if showingPersonalizedSetup {
                    PersonalizedSetupView(
                        assessmentData: assessmentData,
                        onComplete: {
                            showingPersonalizedSetup = false
                            showingCompletion = true
                        }
                    )
                } else if showingReadyPage {
                    ReadyToBeginView(
                        onReady: {
                            // Complete assessment and go directly to age input
                            UserDefaults.standard.set(true, forKey: "hasCompletedAssessment")
                            UserDefaults.standard.set(assessmentData.targetLanguage, forKey: "selectedLanguage")
                            UserDefaults.standard.set(assessmentData.gender, forKey: "userGender")
                            // Persist to UserProfile model as well
                            userProfile.gender = assessmentData.gender
                            userProfile.saveProfile()
                            UserDefaults.standard.set("beginner", forKey: "userLevel")
                            UserDefaults.standard.set(assessmentData.dailyTimeCommitment, forKey: "dailyGoal")
                            UserDefaults.standard.set(1, forKey: "determinedLevel")
                            
                            onComplete?(assessmentData)
                        },
                        onThinkAboutIt: {
                            // User wants to think about it - maybe go back or exit
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                // Persist gender selection even if they choose to think about it
                                UserDefaults.standard.set(assessmentData.gender, forKey: "userGender")
                                userProfile.gender = assessmentData.gender
                                userProfile.saveProfile()
                                showingReadyPage = false
                                showingCompletion = true
                            }
                        }
                    )
                } else if showingCompletion {
                    AssessmentCompletionView(
                        assessmentData: assessmentData,
                        onContinue: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingCompletion = false
                                showingReadyPage = true
                            }
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Progress bar
                        ProgressHeader(
                            currentStep: currentStep + 1,
                            totalSteps: assessmentQuestions.count,
                            progress: progressPercentage,
                            localizationManager: localizationManager
                        )
                        
                        // Question content
                        if currentQuestion.id == "personalization_info" {
                            PersonalizationSlide(localizationManager: localizationManager, secondaryColor: secondaryColor)
                        } else if currentQuestion.id == "commitment_transform" {
                            CommitmentTransformSlide(localizationManager: localizationManager, secondaryColor: secondaryColor)
                        } else if currentQuestion.id == "daily_commitment_result" {
                            DailyCommitmentResultSlide(localizationManager: localizationManager, secondaryColor: secondaryColor, dailyCommitment: assessmentData.dailyTimeCommitment)
                        } else {
                            QuestionView(
                                question: currentQuestion,
                                selectedAnswers: $selectedAnswers,
                                onSelectionChanged: { newSelections in
                                    updateAssessmentData(newSelections)
                                }
                            )
                        }
                        
                        Spacer()
                        
                        // Navigation buttons
                        NavigationButtons(
                            canGoBack: currentStep > 0,
                            canGoForward: (["personalization_info", "commitment_transform", "daily_commitment_result"].contains(currentQuestion.id) ? true : !selectedAnswers.isEmpty),
                            localizationManager: localizationManager,
                            onBack: {
                                if currentStep > 0 {
                                    currentStep -= 1
                                    loadPreviousAnswers()
                                }
                            },
                            onNext: {
                                if currentStep < assessmentQuestions.count - 1 {
                                    currentStep += 1
                                    selectedAnswers = []
                                } else {
                                    // Complete assessment - show personalized setup
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showingPersonalizedSetup = true
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func updateAssessmentData(_ selections: [String]) {
        let questionId = currentQuestion.id
        let selectedValue = selections.first ?? ""
        
        switch questionId {
        case "user_gender":
            assessmentData.gender = selectedValue
            return
        case "target_language":
            assessmentData.targetLanguage = selectedValue
        case "discovery_source":
            assessmentData.howTheyHeard = selectedValue
        case "current_level":
            assessmentData.currentLevel = selectedValue
        case "learning_goal":
            assessmentData.learningGoal = selectedValue
        case "daily_commitment":
            assessmentData.dailyTimeCommitment = selectedValue
            assessmentData.estimatedWordsPerWeek = calculateWordsPerWeek(selectedValue)
        default:
            break
        }
    }
    
    private func loadPreviousAnswers() {
        let questionId = currentQuestion.id
        selectedAnswers = []
        
        switch questionId {
        case "user_gender":
            if !assessmentData.gender.isEmpty {
                selectedAnswers = [assessmentData.gender]
            }
        case "target_language":
            if !assessmentData.targetLanguage.isEmpty {
                selectedAnswers = [assessmentData.targetLanguage]
            }
        case "discovery_source":
            if !assessmentData.howTheyHeard.isEmpty {
                selectedAnswers = [assessmentData.howTheyHeard]
            }
        case "current_level":
            if !assessmentData.currentLevel.isEmpty {
                selectedAnswers = [assessmentData.currentLevel]
            }
        case "learning_goal":
            if !assessmentData.learningGoal.isEmpty {
                selectedAnswers = [assessmentData.learningGoal]
            }
        case "daily_commitment":
            if !assessmentData.dailyTimeCommitment.isEmpty {
                selectedAnswers = [assessmentData.dailyTimeCommitment]
            }
        default:
            break
        }
    }
    
    private func calculateWordsPerWeek(_ timeCommitment: String) -> Int {
        switch timeCommitment {
        case "5min": return 25
        case "10min": return 50
        case "15min": return 75
        case "20min": return 100
        default: return 50
        }
    }
}

// MARK: - Progress Header
struct ProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    let localizationManager: LocalizationManager
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 16) {
            // Step indicator
            HStack {
                Text("Step \(currentStep)/\(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()

            }
            
            // Progress bar
            SwiftUI.ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: secondaryColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

// MARK: - Question View Component
struct QuestionView: View {
    let question: OnboardingAssessmentQuestion
    @Binding var selectedAnswers: [String]
    let onSelectionChanged: ([String]) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Question header
            VStack(spacing: 12) {
                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            // Answer options
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(question.answers) { answer in
                        AnswerOptionView(
                            answer: answer,
                            isSelected: selectedAnswers.contains(answer.value),
                            onTap: {
                                handleAnswerSelection(answer.value)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleAnswerSelection(_ value: String) {
        if question.allowMultiple {
            if selectedAnswers.contains(value) {
                selectedAnswers.removeAll { $0 == value }
            } else {
                selectedAnswers.append(value)
            }
        } else {
            selectedAnswers = [value]
        }
        onSelectionChanged(selectedAnswers)
    }
}

// MARK: - Answer Option View
struct AnswerOptionView: View {
    let answer: AssessmentAnswer
    let isSelected: Bool
    let onTap: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    // Check if this is a language selection (has many options)
    var isLanguageSelection: Bool {
        // If the description contains native characters, it's likely a language option
        return answer.description?.contains(where: { !$0.isASCII }) == true
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(answer.text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                    
                    if let description = answer.description {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? primaryColor : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? primaryColor.opacity(0.2) : Color.white.opacity(0.05))
                    .stroke(isSelected ? primaryColor : Color.white.opacity(0.1), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let localizationManager: LocalizationManager
    let onBack: () -> Void
    let onNext: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if canGoBack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text(localizationManager.getString("back"))
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next button
            Button(action: onNext) {
                HStack {
                    Text(localizationManager.getString("continue"))
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canGoForward ? primaryColor : Color.gray.opacity(0.3))
                )
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Assessment Completion View
struct AssessmentCompletionView: View {
    let assessmentData: UserAssessmentData
    let onContinue: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(primaryColor)
                }
                
                Text(LocalizationManager.shared.getString("assessment_complete_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(LocalizationManager.shared.getString("encourage_continue"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Summary of their choices
            AssessmentSummaryView(assessmentData: assessmentData)
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text(LocalizationManager.shared.getString("im_ready"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Assessment Summary
struct AssessmentSummaryView: View {
    let assessmentData: UserAssessmentData
    
    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizationManager.shared.getString("your_personalized_plan"))
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Language
                SummaryRow(
                    icon: "globe",
                    title: "Language",
                    value: getLanguageDisplayName(assessmentData.targetLanguage),
                    isHighlighted: true
                )

                // Commitment (hours per day)
                SummaryRow(
                    icon: "clock.fill",
                    title: "Commitment",
                    value: getCommitmentDisplay(assessmentData.dailyTimeCommitment),
                    isHighlighted: true
                )

                // Goal (learning goal selected)
                SummaryRow(
                    icon: "target",
                    title: "Goal",
                    value: getGoalDisplay(assessmentData.learningGoal),
                    isHighlighted: true
                )

                // Gender
                SummaryRow(
                    icon: "person.crop.circle",
                    title: "Gender",
                    value: getGenderDisplay(assessmentData.gender),
                    isHighlighted: true
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Personalized message
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.getString("perfectly_matched"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.97, green: 0.70, blue: 0.35))
                
                Text(getLevelDescription(assessmentData.currentLevel))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        return GeminiSupportedLanguages.allLanguages.first { $0.code == code }?.displayName ?? code
    }

    private func getCommitmentDisplay(_ value: String) -> String {
        // Prefer localized commit labels if available
        switch value {
        case "1h": return LocalizationManager.shared.getString("commit_1h")
        case "3h": return LocalizationManager.shared.getString("commit_3h")
        case "6h": return LocalizationManager.shared.getString("commit_6h")
        default:
            // Fallback: present raw value
            return value.isEmpty ? "—" : value
        }
    }

    private func getGoalDisplay(_ value: String) -> String {
        if value.isEmpty { return "—" }
        // Map to localized goal keys if present (e.g. goal_love)
        let key = "goal_\(value)"
        let localized = LocalizationManager.shared.getString(key)
        if localized != key { return localized }
        // Fallback: show raw value capitalized
        return value.capitalized.replacingOccurrences(of: "_", with: " ")
    }

    private func getGenderDisplay(_ value: String) -> String {
    switch value {
    case "male": return LocalizationManager.shared.getString("user_gender_male")
    case "female": return LocalizationManager.shared.getString("user_gender_female")
    case "nonbinary": return LocalizationManager.shared.getString("user_gender_nonbinary")
    case "prefer_not_to_say": return LocalizationManager.shared.getString("user_gender_prefer_not_to_say")
    case "other": return LocalizationManager.shared.getString("user_gender_other")
    default: return value.isEmpty ? "—" : value.capitalized
    }
    }
    
    private func getRecommendedLevel(_ level: String) -> String {
        switch level {
        case "beginner": return "Level 1"
        case "elementary": return "Level 3"
        case "intermediate": return "Level 5"
        case "upper_intermediate": return "Level 7"
        case "advanced": return "Level 9"
        default: return "Level 1"
        }
    }
    
    private func getLevelDescription(_ level: String) -> String {
        switch level {
        case "beginner": return LocalizationManager.shared.getString("perfect_for_beginners")
        case "elementary": return LocalizationManager.shared.getString("great_foundation")
        case "intermediate": return LocalizationManager.shared.getString("ready_for_real_conversations")
        case "upper_intermediate": return LocalizationManager.shared.getString("advanced_discussion_topics")
        case "advanced": return LocalizationManager.shared.getString("master_level_conversations")
        default: return LocalizationManager.shared.getString("starting_your_journey")
        }
    }
}

// MARK: - Ready to Begin View
struct ReadyToBeginView: View {
    let onReady: () -> Void
    let onThinkAboutIt: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Adventure illustration
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.2))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 70))
                        .foregroundColor(primaryColor)
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(spacing: 16) {
                    Text(LocalizationManager.shared.getString("ready_to_begin_adventure"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizationManager.shared.getString("personalized_path_ready"))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                // Ready button
                Button(action: onReady) {
                    Text(LocalizationManager.shared.getString("yes_im_ready"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let isHighlighted: Bool
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(primaryColor)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(isHighlighted ? secondaryColor : .white)
        }
    }
}

// MARK: - Level Assessment Test View
struct LevelAssessmentTestView: View {
    let targetLanguage: String
    let onComplete: (Int, Int) -> Void // (level, percentage)
    let onBack: () -> Void
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String] = []
    @State private var userAnswers: [String] = []
    @State private var showingResults = false
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    // Assessment questions with correct answers
    private let assessmentQuestions: [AssessmentQuestion] = [
        AssessmentQuestion(
            question: "What is the correct way to greet someone in the morning?",
            options: ["Good morning", "Good afternoon", "Good evening", "Good night"],
            correctAnswer: "Good morning",
            difficulty: 1
        ),
        AssessmentQuestion(
            question: "How do you ask for someone's name politely?",
            options: ["What your name?", "What is your name?", "What are your name?", "How is your name?"],
            correctAnswer: "What is your name?",
            difficulty: 1
        ),
        AssessmentQuestion(
            question: "Which sentence is grammatically correct?",
            options: ["I am going to the store", "I going to the store", "I am go to the store", "I goes to the store"],
            correctAnswer: "I am going to the store",
            difficulty: 2
        ),
        AssessmentQuestion(
            question: "What is the past tense of 'eat'?",
            options: ["eated", "ate", "eaten", "eating"],
            correctAnswer: "ate",
            difficulty: 2
        ),
        AssessmentQuestion(
            question: "Which sentence uses the conditional correctly?",
            options: ["If I was rich, I would travel", "If I were rich, I would travel", "If I am rich, I would travel", "If I will be rich, I would travel"],
            correctAnswer: "If I were rich, I would travel",
            difficulty: 3
        ),
        AssessmentQuestion(
            question: "What is the correct form: 'I have been _____ here for 3 years'?",
            options: ["lived", "living", "live", "lives"],
            correctAnswer: "living",
            difficulty: 3
        ),
        AssessmentQuestion(
            question: "Which sentence demonstrates advanced grammar?",
            options: ["The book that I read was good", "Having finished the book, I felt accomplished", "I read a book and it was good", "The book was good when I read it"],
            correctAnswer: "Having finished the book, I felt accomplished",
            difficulty: 4
        ),
        AssessmentQuestion(
            question: "What is the subjunctive form in: 'I suggest that he _____ early'?",
            options: ["arrives", "arrive", "arrived", "arriving"],
            correctAnswer: "arrive",
            difficulty: 4
        ),
        AssessmentQuestion(
            question: "Which sentence uses a sophisticated vocabulary correctly?",
            options: ["The ubiquitous nature of technology is evident", "Technology is everywhere we can see", "Technology is very common these days", "We see technology in many places"],
            correctAnswer: "The ubiquitous nature of technology is evident",
            difficulty: 5
        ),
        AssessmentQuestion(
            question: "Identify the correct use of inversion:",
            options: ["Never have I seen such beauty", "I have never seen such beauty", "I never have seen such beauty", "Never I have seen such beauty"],
            correctAnswer: "Never have I seen such beauty",
            difficulty: 5
        )
    ]
    
    private var currentQuestion: AssessmentQuestion {
        assessmentQuestions[currentQuestionIndex]
    }
    
    private var progressPercentage: Double {
        Double(currentQuestionIndex) / Double(assessmentQuestions.count)
    }
    
    private func calculateResults() -> (level: Int, percentage: Int) {
        let correctAnswers = zip(userAnswers, assessmentQuestions).reduce(0) { count, pair in
            count + (pair.0 == pair.1.correctAnswer ? 1 : 0)
        }
        
        let percentage = Int(Double(correctAnswers) / Double(assessmentQuestions.count) * 100)
        
        // Determine level based on percentage (1-5)
        let level: Int
        switch percentage {
        case 90...100: level = 5
        case 75...89: level = 4
        case 60...74: level = 3
        case 40...59: level = 2
        default: level = 1
        }
        
        return (level, percentage)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [backgroundColor, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showingResults {
                AssessmentResultsView(
                    results: calculateResults(),
                    onContinue: {
                        let results = calculateResults()
                        onComplete(results.level, results.percentage)
                    },
                    onRetake: {
                        // Reset test
                        currentQuestionIndex = 0
                        userAnswers = []
                        selectedAnswers = []
                        showingResults = false
                    }
                )
            } else {
                VStack(spacing: 0) {
                    // Progress header
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: onBack) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                                .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Text("Level Assessment")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(currentQuestionIndex + 1)/\(assessmentQuestions.count)")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [primaryColor, Color(red: 0.97, green: 0.70, blue: 0.35)], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    
                    // Question content
                    VStack(spacing: 24) {
                        // Question
                        Text(currentQuestion.question)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        // Answer options
                        LazyVStack(spacing: 12) {
                            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                                Button(action: {
                                    selectedAnswers = [option]
                                }) {
                                    HStack {
                                        Text(option)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        if selectedAnswers.contains(option) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(primaryColor)
                                        } else {
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedAnswers.contains(option) ? primaryColor.opacity(0.2) : Color.white.opacity(0.05))
                                            .stroke(selectedAnswers.contains(option) ? primaryColor : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Next button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            // Save answer
                            userAnswers.append(selectedAnswers.first ?? "")
                            
                            if currentQuestionIndex < assessmentQuestions.count - 1 {
                                currentQuestionIndex += 1
                                selectedAnswers = []
                            } else {
                                // Show results
                                showingResults = true
                            }
                        }) {
                            Text(currentQuestionIndex < assessmentQuestions.count - 1 ? "Next" : "See Results")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: selectedAnswers.isEmpty ? [Color.gray] : [primaryColor, Color(red: 0.97, green: 0.70, blue: 0.35)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .disabled(selectedAnswers.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Assessment Question Model
struct AssessmentQuestion {
    let question: String
    let options: [String]
    let correctAnswer: String
    let difficulty: Int
}

// MARK: - Assessment Results View
struct AssessmentResultsView: View {
    let results: (level: Int, percentage: Int)
    let onContinue: () -> Void
    let onRetake: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    private func getLevelDescription(_ level: Int) -> String {
        switch level {
        case 1: return LocalizationManager.shared.getString("beginner_foundation")
        case 2: return LocalizationManager.shared.getString("elementary_conversations") 
        case 3: return LocalizationManager.shared.getString("intermediate_situations")
        case 4: return LocalizationManager.shared.getString("upper_intermediate_topics")
        case 5: return LocalizationManager.shared.getString("advanced_discussions")
        default: return LocalizationManager.shared.getString("beginner_foundation")
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(LocalizationManager.shared.getString("assessment_complete_title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(LocalizationManager.shared.getString("got_percentage_correct").replacingOccurrences(of: "%d", with: "\(results.percentage)"))
                    .font(.title2)
                    .foregroundColor(primaryColor)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 20) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [primaryColor, Color(red: 0.97, green: 0.70, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                    
                    VStack {
                        Text("LEVEL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(results.level)")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.getString("can_start_from_level").replacingOccurrences(of: "%d", with: "\(results.level)"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(getLevelDescription(results.level))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    Text("START FROM LEVEL \(results.level)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [primaryColor, Color(red: 0.97, green: 0.70, blue: 0.35)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                }
                
                Button(action: onRetake) {
                    Text("Retake Assessment")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Gemini Supported Languages
struct GeminiSupportedLanguages {
    struct Language {
        let code: String
        let displayName: String
        let nativeName: String
    }
    
    static let allLanguages: [Language] = [
        Language(code: "en", displayName: "English", nativeName: "English"),
        Language(code: "es", displayName: "Spanish", nativeName: "Español"),
        Language(code: "fr", displayName: "French", nativeName: "Français"),
        Language(code: "de", displayName: "German", nativeName: "Deutsch"),
        Language(code: "it", displayName: "Italian", nativeName: "Italiano"),
        Language(code: "pt", displayName: "Portuguese", nativeName: "Português"),
        Language(code: "ru", displayName: "Russian", nativeName: "Русский"),
        Language(code: "ja", displayName: "Japanese", nativeName: "日本語"),
        Language(code: "ko", displayName: "Korean", nativeName: "한국어"),
        Language(code: "zh", displayName: "Chinese", nativeName: "中文"),
        Language(code: "ar", displayName: "Arabic", nativeName: "العربية"),
        Language(code: "hi", displayName: "Hindi", nativeName: "हिन्दी"),
        Language(code: "th", displayName: "Thai", nativeName: "ไทย"),
        Language(code: "vi", displayName: "Vietnamese", nativeName: "Tiếng Việt"),
        Language(code: "tr", displayName: "Turkish", nativeName: "Türkçe"),
        Language(code: "pl", displayName: "Polish", nativeName: "Polski"),
        Language(code: "nl", displayName: "Dutch", nativeName: "Nederlands"),
        Language(code: "sv", displayName: "Swedish", nativeName: "Svenska"),
        Language(code: "da", displayName: "Danish", nativeName: "Dansk"),
        Language(code: "no", displayName: "Norwegian", nativeName: "Norsk"),
        Language(code: "fi", displayName: "Finnish", nativeName: "Suomi"),
        Language(code: "cs", displayName: "Czech", nativeName: "Čeština"),
        Language(code: "hu", displayName: "Hungarian", nativeName: "Magyar"),
        Language(code: "uk", displayName: "Ukrainian", nativeName: "Українська")
    ]
}

// MARK: - Preview
struct OnboardingAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingAssessmentView()
    }
}

// MARK: - Personalization Slide View
struct PersonalizationSlide: View {
    @State private var appear = false
    let localizationManager: LocalizationManager
    let secondaryColor: Color
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text(localizationManager.getString("personalization_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Animated body text with highlighted AI token
                Group {
                let raw = localizationManager.getString("personalization_body")
                let parts = raw.components(separatedBy: "AI")
                let before = parts.first ?? ""
                let after = parts.dropFirst().joined(separator: "AI")

                (Text(before)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                 + Text("AI")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(secondaryColor)
                 + Text(after)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                )
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: appear)
                .padding(.horizontal, 36)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        appear = true
                    }
                }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Commitment Transformation Slide
struct CommitmentTransformSlide: View {
    @State private var appear = false
    let localizationManager: LocalizationManager
    let secondaryColor: Color
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text(localizationManager.getString("commitment_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Animated body text with highlighted key phrases
                // Compose the highlighted body text via helper to avoid ViewBuilder inference
                composedCommitmentBody()
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.55), value: appear)
                    .padding(.horizontal, 36)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            appear = true
                        }
                    }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func composedCommitmentBody() -> Text {
        let raw = localizationManager.getString("commitment_body")
        // Highlight only "80%" and the phrase "for life"
        let p1 = "80%"
        let p2 = "achieve transformational results within 6 months"
        let p3 = "for life"

        var text = raw
        text = text.replacingOccurrences(of: p1, with: "__P1__")
        text = text.replacingOccurrences(of: p2, with: "__P2__")
        text = text.replacingOccurrences(of: p3, with: "__P3__")
        let components = text.components(separatedBy: "__")

        var composed = Text("")
        for comp in components {
            if comp == "P1" {
                composed = composed + Text(p1).font(.body).fontWeight(.semibold).foregroundColor(secondaryColor)
            } else if comp == "P2" {
                composed = composed + Text(p2).font(.body).fontWeight(.semibold).foregroundColor(.white.opacity(0.95))
            } else if comp == "P3" {
                composed = composed + Text(p3).font(.body).fontWeight(.semibold).foregroundColor(secondaryColor)
            } else {
                composed = composed + Text(comp).font(.body).foregroundColor(.white.opacity(0.9))
            }
        }

        return composed
    }
}

// MARK: - Daily Commitment Result Slide
struct DailyCommitmentResultSlide: View {
    @State private var appear = false
    let localizationManager: LocalizationManager
    let secondaryColor: Color
    let dailyCommitment: String
    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Title: use the full sentence with highlighted duration as the title
            resultSentence(for: dailyCommitment)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
                .animation(.easeOut(duration: 0.45), value: appear)
                .padding(.horizontal, 32)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        appear = true
                    }
                }

            // Improvement note below (localized)
            Text(localizationManager.getString("commitment_result_note"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultTextParts(for commitment: String) -> (String, String) {
        switch commitment {
        case "1h": return ("Your goal can be achieved in ", "6 - 8 months")
        case "3h": return ("Your goals can be achieved in ", "3 - 4 months")
        case "6h": return ("Your goals can be achieved in ", "1 - 2 months")
        default: return ("With consistent practice, you can expect significant progress in ", "several months")
        }
    }

    private func resultSentence(for commitment: String) -> Text {
        let (base, duration) = resultTextParts(for: commitment)
        return Text(base).foregroundColor(.white.opacity(0.95)) + Text(duration).fontWeight(.semibold).foregroundColor(secondaryColor)
    }
}

// MARK: - Animatable Number Modifier
struct AnimatableNumberModifier: AnimatableModifier {
    var number: CGFloat
    
    var animatableData: CGFloat {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(Int(number))%")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }
}

extension View {
    func animatingNumber(for number: CGFloat) -> some View {
        self.modifier(AnimatableNumberModifier(number: number))
    }
}

// MARK: - Personalized Setup View
struct PersonalizedSetupView: View {
    let assessmentData: UserAssessmentData
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var completedSteps: Set<Int> = []
    @State private var progressPercentage: CGFloat = 0.0
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    private let setupSteps = [
        "Analyzing your goals",
        "Personalizing topics", 
        "Optimizing difficulty",
        "Creating schedule",
        "Setting up AI partner",
        "Finalizing your path"
    ]
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [backgroundColor, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Progress percentage
                VStack(spacing: 20) {
                    Color.clear
                        .animatingNumber(for: progressPercentage)
                        .animation(.easeInOut(duration: 12.0), value: progressPercentage)
                    
                    Text("We're setting everything up for you")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Animated progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: (progressPercentage / 100.0) * geometry.size.width, height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 12.0), value: progressPercentage)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Setup steps with checkmarks
                VStack(spacing: 24) {
                    Text("Personalized recommendations for")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 16) {
                        ForEach(Array(setupSteps.enumerated()), id: \.offset) { index, step in
                            SetupStepRow(
                                title: step,
                                isCompleted: completedSteps.contains(index),
                                isActive: currentStep == index,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor
                            )
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            startSetupAnimation()
        }
    }
    
    private func startSetupAnimation() {
        // Start the fluid percentage animation immediately
        withAnimation(.easeInOut(duration: 12.0)) {
            progressPercentage = 100.0
        }
        
        // Start first step after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            animateSteps()
        }
    }
    
    private func animateSteps() {
        for i in 0..<setupSteps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i * 2)) {
                _ = withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    completedSteps.insert(i)
                }
                
                // If this is the last step, complete after a short delay
                if i == setupSteps.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Setup Step Row
struct SetupStepRow: View {
    let title: String
    let isCompleted: Bool
    let isActive: Bool
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkmark or loading indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? secondaryColor : Color.white.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .scaleEffect(isCompleted ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isCompleted)
                } else if isActive {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isActive ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
                }
            }
            
            // Step title
            Text("• " + title)
                .font(.body)
                .fontWeight(isCompleted ? .semibold : .regular)
                .foregroundColor(isCompleted ? .white : .white.opacity(0.7))
                .animation(.easeInOut(duration: 0.3), value: isCompleted)
            
            Spacer()
        }
        .opacity(isActive || isCompleted ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.3), value: isActive || isCompleted)
    }
}
