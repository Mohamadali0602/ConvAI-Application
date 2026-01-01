//
//  PronunciationView.swift
//  ConvAI
//
//  Created by Copilot on 15/08/2025.
//

import SwiftUI
import Speech

struct PronunciationView: View {
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var userProgress = GameProgressManager.shared
    
    // ConvAI Colors
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    // MARK: - State Management
    @State private var currentExercise: PronunciationExercise?
    @State private var isRecording = false
    @State private var currentResult: PronunciationResult?
    @State private var showResult = false
    @State private var errorMessage: String?
    @State private var isPermissionGranted = false
    @State private var selectedDifficulty: PronunciationDifficulty = .beginner
    @State private var selectedCategory: PronunciationCategory = .basicWords
    @State private var practiceHistory: [PronunciationResult] = []
    @State private var showHistory = false
    @State private var isProcessing = false
    
    // MARK: - Exercise Data
    private let exercises: [PronunciationCategory: [PronunciationDifficulty: [PronunciationExercise]]] = [
        .basicWords: [
            .beginner: [
                PronunciationExercise(id: "basic_1", text: "Hello", phonetic: "həˈloʊ", category: .basicWords, difficulty: .beginner),
                PronunciationExercise(id: "basic_2", text: "Thank you", phonetic: "θæŋk ju", category: .basicWords, difficulty: .beginner),
                PronunciationExercise(id: "basic_3", text: "Good morning", phonetic: "ɡʊd ˈmɔrnɪŋ", category: .basicWords, difficulty: .beginner),
                PronunciationExercise(id: "basic_4", text: "How are you?", phonetic: "haʊ ɑr ju", category: .basicWords, difficulty: .beginner)
            ],
            .intermediate: [
                PronunciationExercise(id: "basic_int_1", text: "Wonderful", phonetic: "ˈwʌndərfəl", category: .basicWords, difficulty: .intermediate),
                PronunciationExercise(id: "basic_int_2", text: "Delicious", phonetic: "dɪˈlɪʃəs", category: .basicWords, difficulty: .intermediate),
                PronunciationExercise(id: "basic_int_3", text: "Beautiful", phonetic: "ˈbjutəfəl", category: .basicWords, difficulty: .intermediate)
            ],
            .advanced: [
                PronunciationExercise(id: "basic_adv_1", text: "Extraordinary", phonetic: "ɪkˈstrɔrdəˌnɛri", category: .basicWords, difficulty: .advanced),
                PronunciationExercise(id: "basic_adv_2", text: "Pronunciation", phonetic: "prəˌnʌnsiˈeɪʃən", category: .basicWords, difficulty: .advanced)
            ]
        ],
        .phrases: [
            .beginner: [
                PronunciationExercise(id: "phrase_1", text: "Nice to meet you", phonetic: "naɪs tu mit ju", category: .phrases, difficulty: .beginner),
                PronunciationExercise(id: "phrase_2", text: "See you later", phonetic: "si ju ˈleɪtər", category: .phrases, difficulty: .beginner)
            ],
            .intermediate: [
                PronunciationExercise(id: "phrase_int_1", text: "Could you please help me?", phonetic: "kʊd ju pliz hɛlp mi", category: .phrases, difficulty: .intermediate),
                PronunciationExercise(id: "phrase_int_2", text: "I would like to order", phonetic: "aɪ wʊd laɪk tu ˈɔrdər", category: .phrases, difficulty: .intermediate)
            ],
            .advanced: [
                PronunciationExercise(id: "phrase_adv_1", text: "I appreciate your assistance", phonetic: "aɪ əˈpriʃiˌeɪt jʊr əˈsɪstəns", category: .phrases, difficulty: .advanced)
            ]
        ],
        .difficultSounds: [
            .beginner: [
                PronunciationExercise(id: "sound_1", text: "Think", phonetic: "θɪŋk", category: .difficultSounds, difficulty: .beginner),
                PronunciationExercise(id: "sound_2", text: "Three", phonetic: "θri", category: .difficultSounds, difficulty: .beginner)
            ],
            .intermediate: [
                PronunciationExercise(id: "sound_int_1", text: "Thoroughly", phonetic: "ˈθɜroʊli", category: .difficultSounds, difficulty: .intermediate),
                PronunciationExercise(id: "sound_int_2", text: "Rhythm", phonetic: "ˈrɪðəm", category: .difficultSounds, difficulty: .intermediate)
            ],
            .advanced: [
                PronunciationExercise(id: "sound_adv_1", text: "Sixth", phonetic: "sɪksθ", category: .difficultSounds, difficulty: .advanced),
                PronunciationExercise(id: "sound_adv_2", text: "Statistics", phonetic: "stəˈtɪstɪks", category: .difficultSounds, difficulty: .advanced)
            ]
        ]
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Permission Check
                    if !isPermissionGranted {
                        permissionSection
                    } else {
                        // Main Content
                        VStack(spacing: 20) {
                            // Controls Section
                            controlsSection
                            
                            // Current Exercise
                            if let exercise = currentExercise {
                                currentExerciseSection(exercise: exercise)
                            } else {
                                exerciseSelectionSection
                            }
                            
                            // Results Section
                            if let result = currentResult {
                                resultSection(result: result)
                            }
                            
                            // History Button
                            historyButton
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PRONUNCIATION")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .kerning(1.5)
            }
        }
        .onAppear {
            checkSpeechPermission()
            setupSpeechCallbacks()
        }
        .sheet(isPresented: $showHistory) {
            PronunciationHistoryView(history: practiceHistory)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 32))
                    .foregroundColor(primaryColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pronunciation Practice")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Master your pronunciation with AI feedback")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            // Progress Stats
            HStack(spacing: 20) {
                PronunciationExerciseStatCard(
                    title: "Sessions",
                    value: "\(practiceHistory.count)",
                    icon: "mic.circle.fill"
                )
                
                PronunciationExerciseStatCard(
                    title: "Avg Score",
                    value: averageScore,
                    icon: "chart.line.uptrend.xyaxis.circle.fill"
                )
                
                PronunciationExerciseStatCard(
                    title: "Best Score",
                    value: bestScore,
                    icon: "star.circle.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Permission Section
    private var permissionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text("Speech Recognition Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("To practice pronunciation, we need access to your microphone and speech recognition.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: requestSpeechPermission) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                    Text("Grant Permission")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(primaryColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Difficulty Selector
            HStack {
                Text("Difficulty:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Difficulty", selection: $selectedDifficulty) {
                    Text("Beginner").tag(PronunciationDifficulty.beginner)
                    Text("Intermediate").tag(PronunciationDifficulty.intermediate)
                    Text("Advanced").tag(PronunciationDifficulty.advanced)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(primaryColor)
            }
            
            // Category Selector
            HStack {
                Text("Category:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Category", selection: $selectedCategory) {
                    Text("Words").tag(PronunciationCategory.basicWords)
                    Text("Phrases").tag(PronunciationCategory.phrases)
                    Text("Sounds").tag(PronunciationCategory.difficultSounds)
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(primaryColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Exercise Selection Section
    private var exerciseSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Choose an Exercise")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            let availableExercises = exercises[selectedCategory]?[selectedDifficulty] ?? []
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(availableExercises, id: \.id) { exercise in
                    ExerciseCard(exercise: exercise) {
                        currentExercise = exercise
                        currentResult = nil
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Current Exercise Section
    private func currentExerciseSection(exercise: PronunciationExercise) -> some View {
        VStack(spacing: 20) {
            // Exercise Header
            HStack {
                Button(action: { currentExercise = nil }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(primaryColor)
                }
                
                Spacer()
                
                Text(exercise.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(primaryColor.opacity(0.3))
                    )
            }
            
            // Target Text
            VStack(spacing: 12) {
                Text("Say this:")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(exercise.text)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("[\(exercise.phonetic)]")
                    .font(.title3)
                    .foregroundColor(secondaryColor)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Recording Controls
            VStack(spacing: 16) {
                if isProcessing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                            .scaleEffect(1.5)
                        
                        Text("Processing your pronunciation...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                } else {
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording(exercise: exercise)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(isRecording ? .red : primaryColor)
                                .scaleEffect(isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                            
                            Text(isRecording ? "Tap to Stop" : "Tap to Record")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .scaleEffect(isRecording ? 1.05 : 1.0)
                        )
                    }
                    .disabled(isProcessing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Result Section
    private func resultSection(result: PronunciationResult) -> some View {
        VStack(spacing: 16) {
            // Overall Score
            VStack(spacing: 8) {
                Text("Your Score")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: result.overallScore)
                        .stroke(scoreColor(result.overallScore), lineWidth: 8)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5), value: result.overallScore)
                    
                    VStack {
                        Text("\(Int(result.overallScore * 100))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("%")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Feedback Message
            Text(result.feedback.overallMessage)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor(result.overallScore))
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scoreColor(result.overallScore).opacity(0.2))
                )
            
            // Word-by-Word Breakdown
            if !result.wordScores.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Word Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(result.wordScores, id: \.word) { wordScore in
                            HStack {
                                Text(wordScore.word)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(wordScore.accuracy * 100))%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(scoreColor(wordScore.accuracy))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Try Again") {
                    currentResult = nil
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .background(Color.white.opacity(0.1))
                )
                .cornerRadius(12)
                
                Button("Next Exercise") {
                    selectNextExercise()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(primaryColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - History Button
    private var historyButton: some View {
        Button(action: { showHistory = true }) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("Practice History")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .disabled(practiceHistory.isEmpty)
    }
    
    // MARK: - Helper Methods
    private func checkSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                isPermissionGranted = status == .authorized
            }
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                isPermissionGranted = status == .authorized
                if status != .authorized {
                    errorMessage = "Speech recognition permission is required for pronunciation practice."
                }
            }
        }
    }
    
    private func setupSpeechCallbacks() {
        // Assign pronunciation result handler directly on the StateObject.
        // Provide explicit parameter types to avoid inference issues with property wrappers.
        speechService.onPronunciationResult = { (result: PronunciationResult) in
            DispatchQueue.main.async {
                self.currentResult = result
                self.practiceHistory.append(result)
                self.isProcessing = false
                self.isRecording = false
                
                // Update user progress
                GameProgressManager.shared.addPronunciationScore(result.overallScore)
            }
        }

        // Assign recognition error handler with explicit type
        speechService.onRecognitionError = { (error: Error) in
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
                self.isRecording = false
            }
        }
    }
    
    private func startRecording(exercise: PronunciationExercise) {
        Task {
            do {
                isRecording = true
                try await speechService.startPronunciationExercise(targetText: exercise.text)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isRecording = false
                }
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        isProcessing = true
        speechService.stopRecognition()
    }
    
    private func selectNextExercise() {
        let availableExercises = exercises[selectedCategory]?[selectedDifficulty] ?? []
        if let currentIndex = availableExercises.firstIndex(where: { $0.id == currentExercise?.id }),
           currentIndex + 1 < availableExercises.count {
            currentExercise = availableExercises[currentIndex + 1]
        } else {
            // Move to next difficulty or cycle back
            currentExercise = availableExercises.first
        }
        currentResult = nil
    }
    
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
    
    private var averageScore: String {
        guard !practiceHistory.isEmpty else { return "0%" }
        let average = practiceHistory.reduce(0) { $0 + $1.overallScore } / Double(practiceHistory.count)
        return "\(Int(average * 100))%"
    }
    
    private var bestScore: String {
        guard !practiceHistory.isEmpty else { return "0%" }
        let best = practiceHistory.max { $0.overallScore < $1.overallScore }?.overallScore ?? 0
        return "\(Int(best * 100))%"
    }
}

// MARK: - Supporting Data Models
struct PronunciationExercise {
    let id: String
    let text: String
    let phonetic: String
    let category: PronunciationCategory
    let difficulty: PronunciationDifficulty
}

enum PronunciationCategory: String, CaseIterable {
    case basicWords = "basic_words"
    case phrases = "phrases"
    case difficultSounds = "difficult_sounds"
}

enum PronunciationDifficulty: CaseIterable {
    case beginner, intermediate, advanced
}

// MARK: - Supporting Views
struct PronunciationExerciseStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(primaryColor)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ExerciseCard: View {
    let exercise: PronunciationExercise
    let action: () -> Void
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(exercise.text)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(exercise.phonetic)
                    .font(.caption)
                    .foregroundColor(primaryColor)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}



// MARK: - Preview
struct PronunciationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PronunciationView()
        }
    }
}
