//
//  TopicSelectionView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import SwiftUI

// MARK: - Topic Models
struct ConversationTopic: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let difficulty: TopicDifficulty
    let estimatedDuration: String
    let practicalUse: String
    let scenarios: [String]
    let isLocked: Bool
    let requiredLevel: Int
    
    var difficultyColor: Color {
        switch difficulty {
        case .beginner:
            return Color.green
        case .intermediate:
            return Color.orange
        case .advanced:
            return Color.red
        }
    }
    
    var difficultyText: String {
        switch difficulty {
        case .beginner:
            return "beginner".localized
        case .intermediate:
            return "intermediate".localized
        case .advanced:
            return "advanced".localized
        }
    }
}

enum TopicDifficulty: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
}

// MARK: - Main Topic Selection View
struct TopicSelectionView: View {
    @State private var selectedTopic: ConversationTopic?
    @State private var userLevel: Int = 1
    @State private var showingTopicDetail = false
    
    // ConvAI Colors
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.1) // Dark background
    
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
                
                if showingTopicDetail, let topic = selectedTopic {
                    TopicDetailView(
                        topic: topic,
                        userLevel: userLevel,
                        onBack: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingTopicDetail = false
                                selectedTopic = nil
                            }
                        },
                        onStartConversation: {
                            // Start conversation with selected topic
                            print("Starting conversation with topic: \(topic.title)")
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Header
                        TopicHeaderView(userLevel: userLevel)
                        
                        // Topics Grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(ConversationTopics.allTopics) { topic in
                                    TopicCardView(
                                        topic: topic,
                                        userLevel: userLevel,
                                        onTap: {
                                            selectedTopic = topic
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                showingTopicDetail = true
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadUserLevel()
        }
    }
    
    private func loadUserLevel() {
        // Load user's current level from UserDefaults or assessment data
        let startingPreference = UserDefaults.standard.string(forKey: "startingPreference") ?? "scratch"
        let assessedLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "beginner"
        
        switch startingPreference {
        case "scratch":
            userLevel = 1
        case "recommended":
            userLevel = getRecommendedLevel(assessedLevel)
        case "assess":
            userLevel = getRecommendedLevel(assessedLevel) // Placeholder until real assessment
        default:
            userLevel = 1
        }
    }
    
    private func getRecommendedLevel(_ level: String) -> Int {
        switch level {
        case "beginner": return 1
        case "elementary": return 3
        case "intermediate": return 5
        case "upper_intermediate": return 7
        case "advanced": return 9
        default: return 1
        }
    }
}

// MARK: - Topic Header View
struct TopicHeaderView: View {
    let userLevel: Int
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and level
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Topic")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Level \(userLevel) • Ready to practice!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Level badge
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(secondaryColor)
                    Text("\(userLevel)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(primaryColor.opacity(0.3))
                        .stroke(primaryColor, lineWidth: 1)
                )
            }
            
            // Motivational message
            Text("Pick a conversation scenario that interests you most!")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Topic Card View
struct TopicCardView: View {
    let topic: ConversationTopic
    let userLevel: Int
    let onTap: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var isUnlocked: Bool {
        return userLevel >= topic.requiredLevel
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon and difficulty
                HStack {
                    // Topic icon
                    ZStack {
                        Circle()
                            .fill(isUnlocked ? primaryColor.opacity(0.2) : Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: topic.icon)
                            .font(.title2)
                            .foregroundColor(isUnlocked ? primaryColor : .gray)
                    }
                    
                    Spacer()
                    
                    // Difficulty badge
                    Text(topic.difficultyText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isUnlocked ? topic.difficultyColor : Color.gray)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(topic.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isUnlocked ? .white : .gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Description
                    Text(topic.description)
                        .font(.caption)
                        .foregroundColor(isUnlocked ? .white.opacity(0.8) : .gray.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Duration and practical use
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(isUnlocked ? secondaryColor : .gray)
                            Text(topic.estimatedDuration)
                                .font(.caption2)
                                .foregroundColor(isUnlocked ? .white.opacity(0.7) : .gray.opacity(0.5))
                        }
                        
                        HStack {
                            Image(systemName: "lightbulb")
                                .font(.caption2)
                                .foregroundColor(isUnlocked ? secondaryColor : .gray)
                            Text(topic.practicalUse)
                                .font(.caption2)
                                .foregroundColor(isUnlocked ? .white.opacity(0.7) : .gray.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Lock/unlock indicator
                if !isUnlocked {
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Unlock at Level \(topic.requiredLevel)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUnlocked ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                    .stroke(isUnlocked ? Color.white.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUnlocked ? Color.clear : Color.black.opacity(0.3))
            )
        }
        .disabled(!isUnlocked)
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isUnlocked)
    }
}

// MARK: - Topic Detail View
struct TopicDetailView: View {
    let topic: ConversationTopic
    let userLevel: Int
    let onBack: () -> Void
    let onStartConversation: () -> Void
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text(topic.difficultyText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(topic.difficultyColor)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Topic header
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(primaryColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: topic.icon)
                                .font(.system(size: 40))
                                .foregroundColor(primaryColor)
                        }
                        
                        // Title and description
                        VStack(spacing: 8) {
                            Text(topic.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(topic.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Info cards
                    VStack(spacing: 16) {
                        InfoCard(
                            icon: "clock",
                            title: "Duration",
                            content: topic.estimatedDuration
                        )
                        
                        InfoCard(
                            icon: "lightbulb",
                            title: "Practical Use",
                            content: topic.practicalUse
                        )
                    }
                    
                    // Conversation scenarios
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What You'll Practice")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(topic.scenarios.enumerated()), id: \.offset) { index, scenario in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(
                                            Circle()
                                                .fill(primaryColor)
                                        )
                                    
                                    Text(scenario)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 120) // Space for button
            }
            
            // Fixed bottom button
            VStack {
                Spacer()
                
                Button(action: onStartConversation) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("START CONVERSATION")
                        Image(systemName: "arrow.right")
                    }
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
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color.clear, Color(red: 0.05, green: 0.05, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            )
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(primaryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Conversation Topics Data
struct ConversationTopics {
    static let allTopics: [ConversationTopic] = [
        // BEGINNER TOPICS (Levels 1-3): Essential basic conversations
        ConversationTopic(
            title: "Greetings & Introductions",
            description: "Learn to say hello, introduce yourself, and meet new people",
            icon: "hand.wave.fill",
            difficulty: .beginner,
            estimatedDuration: "3-4 minutes",
            practicalUse: "Daily social interactions",
            scenarios: [
                "Saying hello and goodbye",
                "Introducing yourself with name and nationality",
                "Asking someone's name politely",
                "Simple polite phrases (please, thank you, excuse me)",
                "Basic personal information exchange"
            ],
            isLocked: false,
            requiredLevel: 1
        ),
        
        ConversationTopic(
            title: "Ordering Food",
            description: "Master basic restaurant conversations and food vocabulary",
            icon: "fork.knife",
            difficulty: .beginner,
            estimatedDuration: "3-4 minutes",
            practicalUse: "Daily dining experiences",
            scenarios: [
                "Greeting the waiter and asking for a table",
                "Reading simple menu items",
                "Ordering basic food and drinks",
                "Asking for the bill",
                "Simple 'thank you' and 'goodbye'"
            ],
            isLocked: false,
            requiredLevel: 1
        ),
        
        ConversationTopic(
            title: "Shopping Basics",
            description: "Essential conversations for buying things and asking prices",
            icon: "bag.fill",
            difficulty: .beginner,
            estimatedDuration: "3-4 minutes",
            practicalUse: "Basic shopping needs",
            scenarios: [
                "Asking 'How much does this cost?'",
                "Buying simple items (bread, water, etc.)",
                "Basic colors and sizes",
                "Saying yes/no to offers",
                "Asking for help in simple terms"
            ],
            isLocked: false,
            requiredLevel: 2
        ),
        
        // INTERMEDIATE TOPICS (Levels 4-6): More complex daily situations
        ConversationTopic(
            title: "Travel & Directions",
            description: "Navigate cities, ask for directions, and travel conversations",
            icon: "map.fill",
            difficulty: .intermediate,
            estimatedDuration: "5-6 minutes",
            practicalUse: "Tourism and navigation",
            scenarios: [
                "Asking for directions to specific places",
                "Understanding basic directions (left, right, straight)",
                "Using public transportation",
                "Hotel check-in conversations",
                "Airport and travel vocabulary"
            ],
            isLocked: false,
            requiredLevel: 4
        ),
        
        ConversationTopic(
            title: "Small Talk & Social",
            description: "Build confidence in casual conversations about daily topics",
            icon: "person.2.fill",
            difficulty: .intermediate,
            estimatedDuration: "5-6 minutes",
            practicalUse: "Social interactions and networking",
            scenarios: [
                "Talking about weather and seasons",
                "Discussing hobbies and free time",
                "Sharing weekend plans",
                "Talking about family and friends",
                "Making small talk with colleagues"
            ],
            isLocked: false,
            requiredLevel: 4
        ),
        
        ConversationTopic(
            title: "At the Doctor",
            description: "Medical appointments and basic health conversations",
            icon: "cross.fill",
            difficulty: .intermediate,
            estimatedDuration: "5-7 minutes",
            practicalUse: "Healthcare situations",
            scenarios: [
                "Describing basic symptoms (headache, fever, etc.)",
                "Making doctor appointments",
                "Understanding simple medical advice",
                "Asking about medication",
                "Emergency situations"
            ],
            isLocked: false,
            requiredLevel: 5
        ),
        
        // ADVANCED TOPICS (Levels 7+): Professional and complex scenarios
        ConversationTopic(
            title: "Job Interview",
            description: "Professional interview skills and workplace conversations",
            icon: "briefcase.fill",
            difficulty: .advanced,
            estimatedDuration: "8-10 minutes",
            practicalUse: "Career advancement and professional growth",
            scenarios: [
                "Introducing yourself professionally",
                "Describing your experience and qualifications",
                "Answering behavioral interview questions",
                "Asking thoughtful questions about the company",
                "Discussing salary expectations and benefits"
            ],
            isLocked: false,
            requiredLevel: 7
        ),
        
        ConversationTopic(
            title: "Business Meetings",
            description: "Professional communication and workplace discussions",
            icon: "person.3.fill",
            difficulty: .advanced,
            estimatedDuration: "8-10 minutes",
            practicalUse: "Professional workplace communication",
            scenarios: [
                "Participating in team meetings",
                "Presenting ideas and proposals",
                "Giving and receiving feedback",
                "Negotiating and problem-solving",
                "Leading discussions and making decisions"
            ],
            isLocked: false,
            requiredLevel: 8
        ),
        
        ConversationTopic(
            title: "Academic Discussions",
            description: "Complex topics, debates, and intellectual conversations",
            icon: "graduationcap.fill",
            difficulty: .advanced,
            estimatedDuration: "10-12 minutes",
            practicalUse: "Academic and intellectual discussions",
            scenarios: [
                "Discussing complex topics and current events",
                "Expressing and defending opinions",
                "Academic presentations and research",
                "Philosophical and abstract conversations",
                "Debating different viewpoints respectfully"
            ],
            isLocked: false,
            requiredLevel: 9
        )
    ]
}

// MARK: - Preview
struct TopicSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TopicSelectionView()
    }
}
