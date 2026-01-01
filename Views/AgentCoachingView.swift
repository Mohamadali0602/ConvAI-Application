//
//  AgentCoachingView.swift
//  ConvAI
//
//  Created by Mohamad Ali on 03/08/2025.
//

import SwiftUI
import AVFoundation

/// Enhanced coaching view using the new Agent system with live AI conversation
struct AgentCoachingView: View {
    @StateObject private var agentState = AgentState()
    @StateObject private var liveClient = GeminiLiveClient()
    @State private var isRecording = false
    @State private var conversationState: ConversationState = .idle
    @State private var audioOutputVolume: Float = 0.0
    @State private var volumeUpdateTimer: Timer?
    @State private var basicFaceRef: BasicFace?
    
    // Audio session management
    @State private var audioEngine: AVAudioEngine?
    @State private var isStreamingToAI = false
    @State private var errorMessage: String?
    
    // ConvAI color scheme
    let backgroundColor = Color(red: 0.95, green: 0.91, blue: 0.86) // #F3E9DC
    
    enum ConversationState {
        case idle
        case listening
        case thinking
        case responding
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor,
                        backgroundColor.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header with agent selector
                    VStack(spacing: 16) {
                        Text("ConvAI Coach")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(agentState.currentAgent.bodyColor.color)
                        
                        // Agent name and selector
                        HStack {
                            Text("Speaking with \(agentState.currentAgent.name)")
                                .font(.headline)
                                .foregroundColor(agentState.currentAgent.bodyColor.color.opacity(0.8))
                            
                            Spacer()
                            
                            Menu {
                                ForEach(agentState.availablePresets) { agent in
                                    Button(agent.name) {
                                        withAnimation(.spring()) {
                                            agentState.setCurrent(agent)
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "person.3.fill")
                                    .font(.title3)
                                    .foregroundColor(agentState.currentAgent.bodyColor.color)
                                    .padding(8)
                                    .background(agentState.currentAgent.bodyColor.color.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Text(conversationStateText)
                            .font(.subheadline)
                            .foregroundColor(agentState.currentAgent.bodyColor.color.opacity(0.7))
                            .animation(.easeInOut(duration: 0.3), value: conversationState)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Agent Face - Using the new BasicFace component!
                    BasicFace(
                        agent: agentState.currentAgent,
                        radius: min(geometry.size.width * 0.25, 150),
                        showGlow: true,
                        isSpeaking: false
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: agentState.currentAgent.id)
                    
                    Spacer()
                    
                    // Control Panel
                    VStack(spacing: 20) {
                        // Voice indicator
                        VStack(spacing: 8) {
                            Text("Voice: \(agentState.currentAgent.voice.rawValue)")
                                .font(.caption)
                                .foregroundColor(agentState.currentAgent.bodyColor.color.opacity(0.7))
                            
                            // Status indicator
                            HStack {
                                Circle()
                                    .fill(conversationState == .idle ? Color.gray : agentState.currentAgent.bodyColor.color)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(conversationState == .responding ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: conversationState == .responding)
                                
                                Text(conversationStateText)
                                    .font(.caption)
                                    .foregroundColor(agentState.currentAgent.bodyColor.color.opacity(0.7))
                            }
                        }
                        
                        // Control buttons
                        HStack(spacing: 30) {
                            // Record button
                            Button(action: toggleRecording) {
                                ZStack {
                                    Circle()
                                        .fill(isRecording ? .red : agentState.currentAgent.bodyColor.color)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
                            
                            // Settings button
                            Button(action: openSettings) {
                                ZStack {
                                    Circle()
                                        .fill(agentState.currentAgent.bodyColor.color.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Circle()
                                                .stroke(agentState.currentAgent.bodyColor.color.opacity(0.3), lineWidth: 2)
                                        )
                                    
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3)
                                        .foregroundColor(agentState.currentAgent.bodyColor.color)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var conversationStateText: String {
        switch conversationState {
        case .idle:
            return "Tap to start coaching session"
        case .listening:
            return "Listening to your speech..."
        case .thinking:
            return "\(agentState.currentAgent.name) is thinking..."
        case .responding:
            return "\(agentState.currentAgent.name) is responding..."
        }
    }
    
    // MARK: - Actions
    private func toggleRecording() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isRecording.toggle()
            
            if isRecording {
                conversationState = .listening
            } else {
                conversationState = .thinking
                
                // Simulate AI processing and response
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        conversationState = .responding
                    }
                    
                    // End AI response after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            conversationState = .idle
                        }
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        // Implement settings action
        print("Opening settings for agent: \(agentState.currentAgent.name)")
    }
}

// MARK: - Agent Creation View
struct AgentCreationView: View {
    @StateObject private var agentState = AgentState()
    @State private var newAgentName = ""
    @State private var newAgentPersonality = ""
    @State private var selectedColorIndex = 0
    @State private var selectedVoice = InterlocutorVoice.aoede
    @State private var showingCreation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Your Agent")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agent Name")
                        .font(.headline)
                    TextField("Enter agent name", text: $newAgentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Personality field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personality")
                        .font(.headline)
                    TextField("Describe your agent's personality", text: $newAgentPersonality, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Color selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agent Color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Agent.agentColors.indices, id: \.self) { index in
                            Circle()
                                .fill(Agent.agentColors[index].color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColorIndex == index ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColorIndex = index
                                }
                        }
                    }
                }
                
                // Voice selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Voice")
                        .font(.headline)
                    
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(InterlocutorVoice.allCases, id: \.self) { voice in
                            Text(voice.rawValue).tag(voice)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Preview
                if !newAgentName.isEmpty {
                    VStack(spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                        
                        let previewAgent = Agent(
                            name: newAgentName,
                            personality: newAgentPersonality.isEmpty ? "A helpful assistant" : newAgentPersonality,
                            bodyColor: Agent.agentColors[selectedColorIndex],
                            voice: selectedVoice
                        )
                        
                        BasicFace(agent: previewAgent, radius: 60, showGlow: false, isSpeaking: false)
                            .frame(height: 140)
                        
                        Text(previewAgent.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Agent.agentColors[selectedColorIndex].color.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Create button
                Button("Create Agent") {
                    createAgent()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Agent.agentColors[selectedColorIndex].color)
                .cornerRadius(12)
                .disabled(newAgentName.isEmpty)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func createAgent() {
        let newAgent = Agent(
            name: newAgentName,
            personality: newAgentPersonality.isEmpty ? "A helpful AI assistant ready to chat." : newAgentPersonality,
            bodyColor: Agent.agentColors[selectedColorIndex],
            voice: selectedVoice
        )
        
        agentState.addAgent(newAgent)
        agentState.setCurrent(newAgent)
        
        // Reset form
        newAgentName = ""
        newAgentPersonality = ""
        selectedColorIndex = 0
        selectedVoice = .aoede
        
        print("Created new agent: \(newAgent.name)")
    }
}

// MARK: - Previews
struct AgentCoachingView_Previews: PreviewProvider {
    static var previews: some View {
        AgentCoachingView()
            .preferredColorScheme(.light)
    }
}

struct AgentCreationView_Previews: PreviewProvider {
    static var previews: some View {
        AgentCreationView()
            .preferredColorScheme(.light)
    }
}
