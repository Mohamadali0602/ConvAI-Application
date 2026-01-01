
import SwiftUI

// Import the unified types from Models - SimpleLesson, Agent, and BasicFace
// These are now imported to ensure consistency between roadmap and agent instructions

// MARK: - Simple Models for EnhancedRoadMapView

struct SimpleSection: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let lessons: [SimpleLesson]
    let color: Color
    let icon: String
    let requiredXP: Int
    let isUnlocked: Bool
    
    var completedLessons: Int {
        lessons.filter { $0.isCompleted }.count
    }
    
    var totalLessons: Int {
        lessons.count
    }
}

struct SimpleLearningLevel: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let sections: [SimpleSection]
    let description: String
    let requiredXP: Int
    
    var completedSections: Int {
        sections.filter { $0.completedLessons == $0.totalLessons }.count
    }
    
    var totalSections: Int {
        sections.count
    }
    
    var progressPercentage: Double {
        guard totalSections > 0 else { return 0 }
        return Double(completedSections) / Double(totalSections)
    }
}
struct EnhancedRoadMapView: View {
    // MARK: - Lesson Selection Callback (DAY 1 - HOUR 1 Implementation)
    var onLessonSelected: ((SimpleLesson) -> Void)?
    
    @State private var currentUserLevel: Int = 1 // This would come from user progress
    @State private var currentLessonIndex: Int = 3 // Current lesson in progress
    @State private var showNextLevelPrompt = false
    @State private var showingConversation = false
    @State private var selectedLesson: SimpleLesson?
    @State private var showConversationHistory = false
    
    // COMMENTED OUT: Lesson Progress Integration (NEW - Storage Optimized)
    // @StateObject private var userProgressService = UserProgressService.shared
    @State private var completedLessonIds: Set<String> = []
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    
    // Dark gradient backgrounds that progress through sections
    let sectionBackgrounds: [LinearGradient] = [
        // Deep night to dark blue - beginning sections
        LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.12, green: 0.08, blue: 0.18)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.12, green: 0.08, blue: 0.18), Color(red: 0.15, green: 0.1, blue: 0.15)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.15, green: 0.1, blue: 0.15), Color(red: 0.18, green: 0.12, blue: 0.16)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.18, green: 0.12, blue: 0.16), Color(red: 0.2, green: 0.15, blue: 0.18)], startPoint: .top, endPoint: .bottom),
        // Mid progression - warmer tones
        LinearGradient(colors: [Color(red: 0.2, green: 0.15, blue: 0.18), Color(red: 0.22, green: 0.18, blue: 0.15)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.22, green: 0.18, blue: 0.15), Color(red: 0.25, green: 0.2, blue: 0.15)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.25, green: 0.2, blue: 0.15), Color(red: 0.28, green: 0.22, blue: 0.18)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.28, green: 0.22, blue: 0.18), Color(red: 0.3, green: 0.25, blue: 0.2)], startPoint: .top, endPoint: .bottom),
        // Final sections - approaching dawn
        LinearGradient(colors: [Color(red: 0.3, green: 0.25, blue: 0.2), Color(red: 0.35, green: 0.28, blue: 0.22)], startPoint: .top, endPoint: .bottom)
    ]
    
    // Level gradient colors
    let levelGradients: [Int: [Color]] = [
        1: [Color.green, Color.mint],
        2: [Color.blue, Color.cyan],
        3: [Color.purple, Color.pink],
        4: [Color.orange, Color.yellow],
        5: [Color.red, Color.pink]
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // Previous level preview (if not on level 1)
                            if currentUserLevel > 1 {
                                PreviousLevelPreview(
                                    levelNumber: currentUserLevel - 1,
                                    gradientColors: levelGradients[currentUserLevel - 1] ?? [Color.gray, Color.gray]
                                )
                            }
                            
                            // Current level with full lesson progression
                            CurrentLevelView(
                                levelNumber: currentUserLevel,
                                currentLessonIndex: currentLessonIndex,
                                gradientColors: levelGradients[currentUserLevel] ?? [Color.green, Color.mint],
                                onLessonTap: { lessonIndex, sectionNumber, lessonNumber in
                                    // Create SimpleLesson for navigation to LessonView
                                    let lessonId = "section_\(sectionNumber)_lesson_\(lessonNumber)"
                                    let lesson = SimpleLesson(
                                        number: lessonNumber,
                                        title: "Conversation Practice",
                                        displayTitle: "Section \(sectionNumber) - Lesson \(lessonNumber)",
                                        description: "Practice conversation skills with AI coach",
                                        conversationGoals: ["Improve fluency", "Build confidence"],
                                        keyPhrases: ["Hello", "How are you?", "Thank you"],
                                        estimatedDuration: "5 minutes",
                                        xpReward: 50,
                                        isCompleted: completedLessonIds.contains(lessonId),
                                        isUnlocked: true,
                                        icon: "message.circle.fill"
                                    )
                                    
                                    // DAY 1 - HOUR 1: Use callback instead of NavigationLink
                                    onLessonSelected?(lesson)
                                }
                            )
                            .id("currentLevel")
                    
                    // Next level preview with fog effect
                    NextLevelPreview(
                        levelNumber: currentUserLevel + 1,
                        gradientColors: levelGradients[currentUserLevel + 1] ?? [Color.blue, Color.cyan],
                        onJumpToLevel: {
                            showNextLevelPrompt = true
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
            .background(
                // Dynamic background that changes based on scroll position
                DynamicBackgroundView(
                    currentLessonIndex: currentLessonIndex,
                    sectionBackgrounds: sectionBackgrounds
                )
            )
            .onAppear {
                // Auto-scroll to current level
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo("currentLevel", anchor: .center)
                }
            }
        }
        
        // DAY 1 - HOUR 1: Removed NavigationLink - using callback approach instead
    }
    .navigationTitle("Learning Path")
    .onAppear {
        // COMMENTED OUT: Load lesson progress when view appears
        // updateCompletedLessons()
    }
    // COMMENTED OUT: Update lesson completion when progress changes
    // .onReceive(userProgressService.$userProgress) { _ in
    //     updateCompletedLessons()
    // }
}
        .alert("Jump to Level \(currentUserLevel + 1)?", isPresented: $showNextLevelPrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Jump!") {
                currentUserLevel += 1
                currentLessonIndex = 0
            }
        } message: {
            Text("Are you ready to advance to the next level? You can always come back to complete remaining lessons.")
        }
        .navigationTitle("Learning Path")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showConversationHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(primaryColor)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showConversationHistory) {
            ConversationHistoryView()
        }
    }
    
    // MARK: - Lesson Progress Helper Functions
    
    /// COMMENTED OUT: Update completed lessons based on user progress data
    private func updateCompletedLessons() {
        // var newCompletedLessons: Set<String> = []
        // 
        // // Extract completed lesson IDs from user progress
        // for (topicKey, count) in userProgressService.userProgress.topicProgress {
        //     if count > 0 {
        //         // Convert topic progress keys to lesson IDs
        //         // This handles both old format (topic_level) and new format (section_X_lesson_Y)
        //         if topicKey.contains("section_") && topicKey.contains("lesson_") {
        //             newCompletedLessons.insert(topicKey)
        //         } else {
        //             // Convert old format to new format if needed
        //             let lessonId = convertTopicKeyToLessonId(topicKey)
        //             newCompletedLessons.insert(lessonId)
        //         }
        //     }
        // }
        // 
        // DispatchQueue.main.async {
        //     self.completedLessonIds = newCompletedLessons
        //     print("✅ Updated completed lessons: \(newCompletedLessons.count) lessons completed")
        // }
    }
    
    /// Convert old topic progress keys to new lesson ID format
    private func convertTopicKeyToLessonId(_ topicKey: String) -> String {
        // Example: "travel_beginner" -> "section_1_lesson_1"
        // This is a simple mapping - you might want to make this more sophisticated
        let components = topicKey.split(separator: "_")
        if components.count >= 2 {
            let topic = String(components[0])
            let level = String(components[1])
            
            // Map topics to sections (customize this based on your lesson structure)
            let sectionNumber: Int
            switch topic.lowercased() {
            case "travel":
                sectionNumber = 1
            case "business":
                sectionNumber = 2
            case "social":
                sectionNumber = 3
            case "education":
                sectionNumber = 4
            default:
                sectionNumber = 1
            }
            
            let lessonNumber = level == "beginner" ? 1 : level == "intermediate" ? 2 : 3
            return "section_\(sectionNumber)_lesson_\(lessonNumber)"
        }
        
        return topicKey // Return as-is if can't convert
    }
}

// MARK: - Previous Level Preview
struct PreviousLevelPreview: View {
    let levelNumber: Int
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 15) {
            // Level header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(levelNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradientColors.first ?? .gray)
                    
                    Text("✅ Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Completion badge
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Collapsed lesson overview
            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { sectionIndex in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: 25, height: 8)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Current Level View
struct CurrentLevelView: View {
    let levelNumber: Int
    let currentLessonIndex: Int
    let gradientColors: [Color]
    let onLessonTap: (Int, Int, Int) -> Void
    
    // Mock data - 10 sections with 5 lessons each
    private let sectionsPerLevel = 10
    private let lessonsPerSection = 5
    
    // Section-specific gradient backgrounds
    private let sectionBackgrounds: [LinearGradient] = [
        LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.12, green: 0.08, blue: 0.18)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.12, green: 0.08, blue: 0.18), Color(red: 0.15, green: 0.1, blue: 0.15)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.15, green: 0.1, blue: 0.15), Color(red: 0.18, green: 0.12, blue: 0.16)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.18, green: 0.12, blue: 0.16), Color(red: 0.2, green: 0.15, blue: 0.18)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.2, green: 0.15, blue: 0.18), Color(red: 0.22, green: 0.18, blue: 0.15)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.22, green: 0.18, blue: 0.15), Color(red: 0.25, green: 0.2, blue: 0.15)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.25, green: 0.2, blue: 0.15), Color(red: 0.28, green: 0.22, blue: 0.18)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.28, green: 0.22, blue: 0.18), Color(red: 0.3, green: 0.25, blue: 0.2)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(red: 0.3, green: 0.25, blue: 0.2), Color(red: 0.35, green: 0.28, blue: 0.22)], startPoint: .top, endPoint: .bottom)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Level header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(levelNumber)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(gradientColors.first ?? .green)
                    
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Progress badge
                ZStack {
                    Circle()
                        .stroke(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Text("\(levelNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradientColors.first ?? .green)
                }
            }
            
            // Sections and lessons with progressive backgrounds
            ForEach(1...sectionsPerLevel, id: \.self) { sectionIndex in
                SectionView(
                    sectionNumber: sectionIndex,
                    levelNumber: levelNumber,
                    currentLessonIndex: currentLessonIndex,
                    gradientColors: gradientColors,
                    sectionBackground: sectionBackgrounds[min(sectionIndex - 1, sectionBackgrounds.count - 1)],
                    onLessonTap: onLessonTap
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(sectionBackgrounds[min(sectionIndex - 1, sectionBackgrounds.count - 1)])
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Section View
struct SectionView: View {
    let sectionNumber: Int
    let levelNumber: Int
    let currentLessonIndex: Int
    let gradientColors: [Color]
    let sectionBackground: LinearGradient
    let onLessonTap: (Int, Int, Int) -> Void
    
    private let lessonsPerSection = 5
    
    private var sectionStartIndex: Int {
        (sectionNumber - 1) * lessonsPerSection
    }
    
    private var isCurrentSection: Bool {
        currentLessonIndex >= sectionStartIndex && currentLessonIndex < sectionStartIndex + lessonsPerSection
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Section header with enhanced styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Section \(sectionNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(lessonsPerSection) Lessons")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isCurrentSection {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(gradientColors.first ?? .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Section lessons
            ForEach(0..<lessonsPerSection, id: \.self) { lessonInSection in
                let absoluteLessonIndex = sectionStartIndex + lessonInSection
                
                LessonNodeView(
                    lessonNumber: lessonInSection + 1,
                    absoluteIndex: absoluteLessonIndex,
                    sectionNumber: sectionNumber,
                    currentLessonIndex: currentLessonIndex,
                    gradientColors: gradientColors,
                    onTap: { absoluteIndex, sectionNum, lessonNum in
                        onLessonTap(absoluteIndex, sectionNum, lessonNum)
                    }
                )
                
                // Vertical connector (except for last lesson in section)
                if lessonInSection < lessonsPerSection - 1 {
                    VerticalConnector(
                        isActive: absoluteLessonIndex < currentLessonIndex,
                        gradientColors: gradientColors
                    )
                }
            }
            
            // Border toll at end of section
            BorderTollView(
                sectionNumber: sectionNumber,
                isCompleted: currentLessonIndex > sectionStartIndex + lessonsPerSection - 1,
                gradientColors: gradientColors
            )
            .padding(.bottom, 12)
            
            // Section connector (except for last section)
            if sectionNumber < 10 {
                SectionConnector(
                    isActive: currentLessonIndex > sectionStartIndex + lessonsPerSection - 1,
                    gradientColors: gradientColors
                )
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Lesson Node View
struct LessonNodeView: View {
    let lessonNumber: Int
    let absoluteIndex: Int
    let sectionNumber: Int
    let currentLessonIndex: Int
    let gradientColors: [Color]
    let onTap: (Int, Int, Int) -> Void
    
    private var lessonState: LessonState {
        if absoluteIndex < currentLessonIndex {
            return .completed
        } else if absoluteIndex == currentLessonIndex {
            return .current
        } else {
            return .locked
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Lesson circle with enhanced glow effect
            Button {
                onTap(absoluteIndex, sectionNumber, lessonNumber)
            } label: {
                ZStack {
                    Circle()
                        .fill(circleBackground)
                        .frame(width: 60, height: 60)
                        .shadow(color: shadowColor, radius: glowRadius, x: 0, y: 0)
                    
                    Circle()
                        .stroke(circleStroke, lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    lessonIcon
                        .font(.title2)
                        .foregroundColor(iconColor)
                }
            }
            .disabled(lessonState == .locked)
            
            // Lesson info with white text for dark background
            VStack(alignment: .leading, spacing: 4) {
                Text("Lesson \(lessonNumber)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(lessonState == .locked ? .gray : .white)
                
                Text("Section \(sectionNumber)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if lessonState == .current {
                    Text("▶ Continue")
                        .font(.caption)
                        .foregroundColor(gradientColors.first ?? .green)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            // Status indicator
            statusIndicator
        }
        .padding(.horizontal, 10)
        .opacity(lessonState == .locked ? 0.6 : 1.0)
    }
    
    private var circleBackground: LinearGradient {
        switch lessonState {
        case .completed:
            return LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        case .current:
            return LinearGradient(colors: [Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .locked:
            return LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var circleStroke: LinearGradient {
        switch lessonState {
        case .completed:
            return LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .current:
            return LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        case .locked:
            return LinearGradient(colors: [Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var lessonIcon: Image {
        switch lessonState {
        case .completed:
            return Image(systemName: "checkmark")
        case .current:
            return Image(systemName: "play.fill")
        case .locked:
            return Image(systemName: "lock.fill")
        }
    }
    
    private var iconColor: Color {
        switch lessonState {
        case .completed:
            return .white
        case .current:
            return gradientColors.first ?? .green
        case .locked:
            return .gray
        }
    }
    
    private var statusIndicator: some View {
        Group {
            switch lessonState {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .current:
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(gradientColors.first ?? .green)
            case .locked:
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .font(.title3)
    }
    
    // Enhanced glow effects
    private var glowRadius: CGFloat {
        switch lessonState {
        case .completed:
            return 8
        case .current:
            return 12
        case .locked:
            return 0
        }
    }
    
    private var shadowColor: Color {
        switch lessonState {
        case .completed:
            return gradientColors.first?.opacity(0.6) ?? .green.opacity(0.6)
        case .current:
            return gradientColors.first?.opacity(0.8) ?? .green.opacity(0.8)
        case .locked:
            return .clear
        }
    }
}

// MARK: - Vertical Connector
struct VerticalConnector: View {
    let isActive: Bool
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(isActive ? LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 3, height: 8)
            }
        }
    }
}

// MARK: - Border Toll View
struct BorderTollView: View {
    let sectionNumber: Int
    let isCompleted: Bool
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 10) {
            // Toll booth building
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isCompleted ? LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 70)
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 140, height: 70)
                
                VStack(spacing: 4) {
                    Image(systemName: isCompleted ? "checkmark.shield.fill" : "shield.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("SECTION \(sectionNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(isCompleted ? "CLEARED" : "REVIEW")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            Text("Progress Review")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
        }
        .opacity(isCompleted ? 1.0 : 0.6)
    }
}

// MARK: - Section Connector
struct SectionConnector: View {
    let isActive: Bool
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<8, id: \.self) { _ in
                Circle()
                    .fill(isActive ? LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Next Level Preview
struct NextLevelPreview: View {
    let levelNumber: Int
    let gradientColors: [Color]
    let onJumpToLevel: () -> Void
    
    private let backgroundColor = Color(red: 0.35, green: 0.28, blue: 0.22) // Final dark gradient color
    
    var body: some View {
        VStack(spacing: 20) {
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Next level header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(levelNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradientColors.first ?? .blue)
                    
                    Text("Coming Next")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Next level badge
                ZStack {
                    Circle()
                        .stroke(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Text("\(levelNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradientColors.first ?? .blue)
                }
            }
            
            // Fog effect with preview
            ZStack {
                // Background lessons (blurred)
                VStack(spacing: 15) {
                    ForEach(1...3, id: \.self) { _ in
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .blur(radius: 3)
                
                // Enhanced fog overlay with mystical feel
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Jump prompt
                VStack(spacing: 15) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(gradientColors.first ?? .blue)
                        .symbolEffect(.pulse)
                    
                    Text("Ready for Level \(levelNumber)?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        onJumpToLevel()
                    } label: {
                        HStack {
                            Image(systemName: "rocket.fill")
                            Text("Jump to Level \(levelNumber)")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(25)
                        .shadow(color: gradientColors.first?.opacity(0.5) ?? .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.top, 30)
            }
            .frame(height: 200)
            .cornerRadius(15)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Dynamic Background View
struct DynamicBackgroundView: View {
    let currentLessonIndex: Int
    let sectionBackgrounds: [LinearGradient]
    
    var body: some View {
        // Create an overall dark gradient that shifts based on progress
        let progressRatio = min(Double(currentLessonIndex) / 50.0, 1.0) // 50 total lessons
        let backgroundIndex = Int(progressRatio * Double(sectionBackgrounds.count - 1))
        
        return sectionBackgrounds[min(backgroundIndex, sectionBackgrounds.count - 1)]
            .ignoresSafeArea()
    }
}

// MARK: - Agent Conversation View using real Agent system
struct AgentConversationView: View {
    let lesson: SimpleLesson?
    let onDismiss: () -> Void
    
    // Use a real agent from the Agent system
    @State private var currentAgent = Agent.Convai // Start with Convai
    @State private var isRecording = false
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [darkBackground, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with lesson info
                VStack(spacing: 16) {
                    // Back button
                    HStack {
                        Button(action: onDismiss) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Lesson title and topic
                    if let lesson = lesson {
                        VStack(spacing: 12) {
                            Text("Lesson \(lesson.number)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(currentAgent.bodyColor.color)
                            
                            Text(lesson.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            // Topic/Description
                            Text(lesson.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Text("Practice Session")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(currentAgent.bodyColor.color)
                            
                            Text("Conversation Practice")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Agent face using the real BasicFace from Agent system
                BasicFace(
                    agent: currentAgent,
                    radius: 120,
                    showGlow: true,
                    isSpeaking: false
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentAgent.id)
                
                Spacer()
                
                // Voice controls
                VStack(spacing: 20) {
                    // Voice info
                    Text("Speaking with \(currentAgent.name)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Voice: \(currentAgent.voice.rawValue)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Record button
                    Button(action: {
                        withAnimation(.spring()) {
                            isRecording.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : currentAgent.bodyColor.color)
                                .frame(width: 80, height: 80)
                                .shadow(color: currentAgent.bodyColor.color.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
                    
                    // Status text
                    Text(isRecording ? "Recording..." : "Tap to speak")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Types
enum LessonState {
    case completed
    case current
    case locked
}

// MARK: - Voice Recording Button
struct VoiceRecordingButton: View {
    let onRecordingStateChanged: (Bool) -> Void
    @State private var isRecording = false
    @State private var recordingTimer: Timer?
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: {
            toggleRecording()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isRecording ? Color.red : Color(red: 0.78, green: 0.36, blue: 0.17))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation && isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Microphone icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        pulseAnimation = true
        onRecordingStateChanged(true)
        
        // Auto-stop after 30 seconds
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            stopRecording()
        }
        
        print("🎙️ Started recording...")
    }
    
    private func stopRecording() {
        isRecording = false
        pulseAnimation = false
        onRecordingStateChanged(false)
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        print("🎙️ Stopped recording...")
    }
}

// MARK: - Preview
struct EnhancedRoadMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EnhancedRoadMapView()
        }
    }
}
