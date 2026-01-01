//
//  SimulateView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 09/08/2025.
//

import SwiftUI
import Foundation

struct SimulateView: View {
    @StateObject private var progressManager = GameProgressManager.shared
    @StateObject private var userProgressService = GameProgressManager.shared
    @StateObject private var characterService = SimulationCharacterService()
    @State private var selectedCategory: PracticeCategory = .money
    @State private var selectedScenario: SimulationScenario?
    @State private var selectedCharacter: CharacterProfile?
    @State private var selectedAgent: Agent? // Add this for the created simulation agent
    @State private var currentScreen: SimulationScreen = .cardGrid
    @State private var showingLessonView = false // Add this for fullScreenCover
    @AppStorage("userGender") private var userGender: String = ""
    
    // Navigation states
    enum SimulationScreen {
        case cardGrid
        case scenarioDetail  
        // lesson removed - using fullScreenCover instead
    }
    
    // ConvAI Colors - matching other tabs
    let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    // Computed property for simulation mastery progress
    private var simulationMasteryProgress: Double {
        let totalScenarios = SimulationScenario.allCases.count
        let completedScenarios = progressManager.simulationsCompleted
        return min(Double(completedScenarios) / Double(totalScenarios), 1.0)
    }
    
    // Available scenarios filtered by category
    private var filteredScenarios: [SimulationScenario] {
        SimulationScenario.allCases.filter { $0.category == selectedCategory }
    }
    
    // User's current level for unlock logic
    private var userCurrentLevel: Int {
    userProgressService.currentLevel
    }
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .cardGrid:
                cardGridScreen
            case .scenarioDetail:
                scenarioDetailScreen
            }
        }
        .navigationTitle(currentScreen == .cardGrid ? "Real-World Practice" : "")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showingLessonView) {
            // Create LessonView with simulation agent - wrapped in NavigationView for toolbar
            NavigationView {
                LessonView(
                    lessonID: selectedScenario?.id ?? "unknown",
                    lessonTitle: selectedScenario?.title ?? "Unknown",
                    lessonNumber: 1,
                    agentType: getAgentTypeForScenario(selectedScenario ?? .coldCall),
                    category: selectedScenario?.category.rawValue.lowercased() ?? "money",
                    isSimulation: true,
                    simulationContext: createEnhancedPrompt(scenario: selectedScenario!, character: selectedCharacter!),
                    characterName: selectedCharacter?.name ?? "",
                    characterVoice: selectedCharacter?.voice ?? "",
                    characterPersonality: selectedCharacter?.personality ?? "",
                    characterBodyColor: selectedCharacter?.bodyColor,
                    preCreatedAgent: selectedAgent // Pass the pre-created agent
                )
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Screen Views
    
    private var cardGridScreen: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                simulationHeaderView
                
                // Category Filter
                categoryFilterView
                
                // Scenario Cards Grid
                scenarioCardsGrid
                
                // Progress Overview
                simulationProgressView
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    private var scenarioDetailScreen: some View {
        SimulationDetailView(
            scenario: selectedScenario!,
            character: selectedCharacter, // Pass the selected character
            onStart: startSimulation,
            onBack: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = .cardGrid
                }
            }
        )
    }
    

    
    
    // MARK: - Header Section
    private var simulationHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Real Scenarios")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Build confidence before real-world situations")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Simulation completion badge
                VStack {
                    Text("\(progressManager.simulationsCompleted)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Progress bar showing overall simulation mastery
            SwiftUI.ProgressView(value: simulationMasteryProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(0.15),
                            Color.orange.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Category Filter
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([PracticeCategory.money, .love, .power], id: \.self) { category in
                    CategoryFilterButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Scenario Cards Grid
    private var scenarioCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredScenarios, id: \.self) { scenario in
                SimulationCard(
                    scenario: scenario,
                    userLevel: userProgressService.currentLevel
                ) {
                    // Navigate to detail screen
                    print("🎯 NAVIGATION: Card tapped - \(scenario.title)")
                    selectedScenario = scenario
                    selectedCharacter = characterService.getRandomCharacter(for: scenario.category.rawValue)
                    print("🎭 CHARACTER: Generated \(selectedCharacter?.name ?? "unknown") with voice \(selectedCharacter?.voice ?? "unknown")")
                    print("🎭 CHARACTER: Personality: \(selectedCharacter?.personality.prefix(50) ?? "unknown")...")
                    
                    // Create the simulation agent immediately when card is tapped
                    createSimulationAgent(for: scenario)
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .scenarioDetail
                        print("🎯 NAVIGATION: Switched to scenarioDetail screen")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Progress Overview
    private var simulationProgressView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(simulationMasteryProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            // Category breakdown
            ForEach([PracticeCategory.money, .love, .power], id: \.self) { category in
                CategoryProgressRow(category: category)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    private func startSimulation(_ scenario: SimulationScenario) {
        print("🚀 SIMULATION START: Starting simulation for \(scenario.title)")
        print("🎭 CHARACTER CHECK: \(selectedCharacter?.name ?? "NO CHARACTER")")
        print("🎯 SCENARIO CHECK: \(selectedScenario?.title ?? "NO SCENARIO")")
        print("🤖 AGENT CHECK: \(selectedAgent?.name ?? "NO AGENT")")
        
        // Set the selected scenario
        selectedScenario = scenario
        print("📝 Set selectedScenario: \(selectedScenario?.title ?? "FAILED")")
        
        // Verify we have both character and agent
        guard let character = selectedCharacter, let agent = selectedAgent else {
            print("❌ ERROR: Missing character or agent for simulation")
            if selectedCharacter == nil { print("   Missing character") }
            if selectedAgent == nil { print("   Missing agent") }
            return
        }
        
        print("🎭 CHARACTER DETAILS:")
        print("   Name: \(character.name)")
        print("   Voice: \(character.voice)")
        print("   Personality: \(character.personality.prefix(100))...")
        print("   Body Color: \(character.bodyColor)")
        
        print("🤖 AGENT DETAILS:")
        print("   Agent Name: \(agent.name)")
        print("   Agent ID: \(agent.id)")
        
        // Present lesson view using fullScreenCover
        showingLessonView = true
        print("🎯 NAVIGATION: Presenting lesson view with fullScreenCover")
        print("✅ SIMULATION START: Complete")
    }
    
    // MARK: - Agent Creation
    private func createSimulationAgent(for scenario: SimulationScenario) {
        guard let character = selectedCharacter else {
            print("❌ Cannot create simulation agent: no character selected")
            return
        }
        
        print("🤖 AGENT CREATION: Creating simulation agent for \(character.name)")
        
        // Parse character gender from voice or assume from character
        let characterGender = determineCharacterGender(from: character.voice)
        
        // Get appropriate voice enum
        guard let voiceEnum = getVoiceEnum(from: character.voice) else {
            print("❌ Cannot create simulation agent: invalid voice \(character.voice)")
            return
        }
        
        // Create enhanced simulation agent using the new method
        selectedAgent = Agent.createSimulationAgent(
            name: character.name,
            gender: characterGender,
            personality: character.personality,
            voice: voiceEnum,
            bodyColor: character.bodyColor,
            scenarioInstructions: createEnhancedPrompt(scenario: scenario, character: character)
        )
        
        print("🤖 ✅ Created simulation agent: \(character.name) with voice \(character.voice)")
        print("🎭 Agent personality: \(character.personality.prefix(100))...")
    }
    
    private func determineCharacterGender(from voiceName: String) -> String {
        // Try to determine from voice name (voices are gender-specific)
        let femaleVoices = ["Achernar", "Aoede", "Autonoe", "Callirrhoe", "Despina", "Erinome", "Gacrux", "Kore", "Laomedeia", "Leda", "Pulcherrima", "Sulafat", "Vindemiatrix", "Zephyr"]
        
        if femaleVoices.contains(voiceName) {
            return "female"
        } else {
            return "male"
        }
    }
    
    private func getVoiceEnum(from voiceName: String) -> InterlocutorVoice? {
        return InterlocutorVoice.allCases.first { $0.rawValue == voiceName }
    }
    
    // MARK: - Enhanced Prompt Creation
    private func createEnhancedPrompt(scenario: SimulationScenario, character: CharacterProfile) -> String {
        // Return empty string - LessonView will handle all prompt generation
        return ""
    }

    
    // MARK: - Agent Mapping
    


    
    // MARK: - Agent Mapping
    private func getAgentTypeForScenario(_ scenario: SimulationScenario) -> LessonAgentType {
        // Map scenario categories to the correct agent types
        switch scenario.category {
        case .language:
            return .language
        case .story:
            return .story
        case .money:
            return .mentor
        case .love:
            return .coach
        case .power:
            return .tutor
        }
    }
}

// MARK: - Supporting Views

struct CategoryFilterButton: View {
    let category: PracticeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [category.color, category.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? category.color.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? category.color.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct CategoryProgressRow: View {
    let category: PracticeCategory
    
    // Mock progress calculation - replace with actual data
    private var categoryProgress: Double {
        // Calculate actual progress based on completed scenarios in this category
        let categoryScenarios = SimulationScenario.allCases.filter { $0.category == category }
        let completedCount = categoryScenarios.filter { $0.isCompleted }.count
        return categoryScenarios.isEmpty ? 0 : Double(completedCount) / Double(categoryScenarios.count)
    }
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.subheadline)
                .foregroundColor(category.color)
                .frame(width: 20)
            
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            SwiftUI.ProgressView(value: categoryProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: category.color))
                .frame(width: 80)
            
            Text("\(Int(categoryProgress * 100))%")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 35, alignment: .trailing)
        }
    }
}
// MARK: - Simulation-Specific UI Components

struct SimulationCategoryFilterButton: View {
    let category: PracticeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [category.color, category.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? category.color.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? category.color.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
struct SimulateView_Previews: PreviewProvider {
    static var previews: some View {
        SimulateView()
    }
}
