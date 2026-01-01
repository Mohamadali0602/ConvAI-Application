
import SwiftUI
import AVFoundation
import AudioToolbox
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Audio Output Management

enum AudioOutput: String, CaseIterable, Identifiable {
    case speaker = "speaker"
    case bluetooth = "bluetooth"
    case headphones = "headphones"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .speaker:
            return "Speaker"
        case .bluetooth:
            return "AirPods" // Will be dynamically updated with actual device name
        case .headphones:
            return "Headphones"
        }
    }
    
    var icon: String {
        switch self {
        case .speaker:
            return "speaker.wave.3"
        case .bluetooth:
            return "airpods"
        case .headphones:
            return "headphones"
        }
    }
}

struct LessonView: View {
    
    let lessonID: String
    let lessonTitle: String
    let lessonNumber: Int
    let agentType: LessonAgentType
    let category: String // Added for dynamic XP calculation
    
    // NEW: Simulation support with enhanced character system
    var isSimulation: Bool = false
    var simulationContext: String = ""
    var characterName: String = ""
    var characterVoice: String = ""
    var characterPersonality: String = ""
    var characterBodyColor: AgentColor?
    var preCreatedAgent: Agent? // Add this to accept pre-created agent
    
    // For simulations, use enhanced agent instead of regular agent
    @State private var simulationAgent: Agent?
    
    @State private var isConversationActive = false
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var statusText = "Ready to start conversation"
    
    // ✅ FIRESTORE CRASH FIX: Monitor app state to prevent background crashes
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasActiveBeforeBackground = false
    
    // Extracted from CoachView - GeminiLiveClient integration
    @StateObject private var liveClient = GeminiLiveClient()
    
    // ✅ Step 1.1: Speech Recognition Service for AI transcript
    @StateObject private var speechRecognitionService = SpeechRecognitionService()
    
    // SEPARATE ENGINES APPROACH (following Google's pattern)
    // Recording engine (input) - 16kHz for Gemini Live API
    @State private var recordingEngine: AVAudioEngine?
    
    // Playback engine (output) - 24kHz for AI response audio  
    @State private var playbackEngine: AVAudioEngine?
    @State private var playbackPlayerNode: AVAudioPlayerNode?
    
    @State private var audioBuffer: Data = Data()
    @State private var lastPlaybackTime: Date = Date()
    @State private var isPlayingAudio = false
    @State private var pendingPlaybackTimer: Timer?
    
    // 🔧 PERFORMANCE: Create audio converters once and reuse them to avoid overhead.
    @State private var audioConverter: AVAudioConverter?
    @State private var playbackConverter: AVAudioConverter?
    @State private var cachedPlaybackFormat: AVAudioFormat?
    @State private var cachedTargetFormat: AVAudioFormat?
    
    // Audio buffering for efficient transmission
    @State private var outgoingAudioBuffer = Data()
    @State private var audioSendTimer: Timer?
    @State private var lastAudioSendTime = Date()
    private let audioBufferTargetSize = 4096 // 4KB chunks for more efficient sending
    private let maxAudioSendInterval: TimeInterval = 0.05 // ✅ OPTIMIZED: Reduced from 0.1 to 0.05 (50ms) for faster response
    
    // ✅ CRITICAL FIX: Voice Activity Detection (VAD) to prevent silent audio waste
    @State private var isUserSpeaking = false
    @State private var lastVoiceActivityTime = Date()
    @State private var silenceTimer: Timer?
    @State private var consecutiveSpeechFrames = 0 // Track consecutive frames above threshold
    private let voiceActivityThreshold: Float = 0.001 // ✅ OPTIMIZED: Lowered from 0.05 to 0.001 for better speech detection
    private let minConsecutiveFrames = 2 // Require 2 consecutive frames above threshold to confirm speech
    private let silenceTimeoutInterval: TimeInterval = 1.0 // Stop sending after 1 second of silence
    private let vadEnabled = true // Feature flag for VAD
    
    // ✅ PHASE 1: Enhanced buffer monitoring for LessonView
    @State private var bufferAnalyticsCount = 0
    @State private var totalBufferedBytes = 0
    @State private var bufferSizeHistory: [Int] = []
    
    // Session management for XP and progress
    @State private var currentSession: ConversationSession?
    
    // MARK: - Session Monitoring (10-minute limit handling)
    @State private var sessionTimer: Timer?
    @State private var conversationStartTime: Date?
    @State private var sessionRefreshCount = 0
    @State private var isRefreshing = false // Prevent concurrent refreshes
    private let sessionRefreshInterval: TimeInterval = 480 // 8 minutes (before 10-minute limit)
    
    // MARK: - Timer Display
    @State private var elapsedTime: TimeInterval = 0
    @State private var displayTimer: Timer?
    @State private var formattedElapsedTime: String = "00:00"
    
    // ✅ Enhanced audio volume for mouth animation with better processing
    @State private var currentAudioVolume: Float = 0.0
    @State private var volumeUpdateTimer: Timer?
    @State private var lastVolumeUpdate: Date = Date()
    @State private var peakVolume: Float = 0.0
    @State private var volumeDecayRate: Float = 0.85 // Adjustable decay rate
    @State private var isActivelySpeaking: Bool = false
    
    // Congratulations flow state
    @State private var showCongratulations = false
    @State private var earnedXP: Int = 0
    @State private var sessionDuration: TimeInterval = 0

    // Transcript state (Phase 2) ✅ Step 2.2: added transcript state variables
    @State private var showTranscript = true // Toggle button state - default enabled
    @State private var transcriptMessages: [TranscriptMessage] = []
    @State private var currentTranscriptChunk: String = "" // For accumulating streaming text
    
    // ✅ ADD THIS LINE: To track the ID of the current AI message being built
    @State private var currentAIMessageID: UUID? = nil
    
    @State private var transcriptScrollProxy: ScrollViewProxy? = nil // For smooth programmatic scrolling
    
    // Audio output selection (like iPhone call interface)
    @State private var showAudioOutputPicker = false
    @State private var availableAudioOutputs: [AudioOutput] = []
    @State private var selectedAudioOutput: AudioOutput = .speaker
    
    // Simplified audio gating (let Gemini handle VAD)
    @State private var isAISpeaking = false
    @State private var lastAISpeechTime = Date.distantPast
    
    // Audio deduplication to prevent duplicate playback
    @State private var lastAudioHash: Int = 0
    @State private var lastAudioTime: Date = Date.distantPast
    private let audioDeduplicationWindow: TimeInterval = 1.0 // 1 second window
    
    // 🔧 IMPROVED: Audio buffer management with controlled overlap
    @State private var activeAudioChunkCount: Int = 0
    @State private var isNewAIResponse: Bool = true // Track if this is the start of a new AI response
    @State private var audioChunkCount: Int = 0 // Count chunks in current response
    
    @EnvironmentObject var authService: EnhancedAuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    // Rate limiting for conversation starts DISABLED - was blocking conversations
    // @State private var lastConversationStart: Date = Date.distantPast
    // private let conversationRateLimit: TimeInterval = 5.0 // 5 seconds between starts
    
    var currentAgent: Agent {
        // For simulations, use enhanced simulation agent if available
        if isSimulation, let simAgent = simulationAgent {
            print("🤖 USING SIMULATION AGENT: \(simAgent.name) (ID: \(simAgent.id))")
            return simAgent
        }
        // Otherwise use regular lesson agent
        print("📚 USING LESSON AGENT: \(agentType.agent.name) (ID: \(agentType.agent.id))")
        return agentType.agent
    }
    
    // Helper function to get practice category from current agent for dynamic XP
    private func getPracticeCategoryFromAgent() -> String? {
        switch currentAgent.id {
        case "money-master": return "money"
        case "love-coach": return "love"  
        case "power-player": return "power"
        case "phoenix": return "language"
        case "master-storyteller": return "story"
        default: return nil
        }
    }
    
    // Helper function to get agent type string for Cloud Function
    private func getAgentTypeString() -> String {
        // Use the actual agent IDs from Agents.swift for voice mapping
        switch currentAgent.id {
        case "phoenix": return "phoenix"                    // Language Master → Puck voice
        case "master-storyteller": return "master-storyteller"  // Story Master → Zephyr voice
        case "money-master": return "money-master"          // Money Master → Umbriel voice
        case "love-coach": return "love-coach"              // Love Coach → Sadachbia voice
        case "power-player": return "power-player"          // Power Player → Algenib voice
        default:
            // Fallback to agentType enum mapping for older lesson types
            switch agentType {
            case .mentor: return "money-master"    // Maps to Money Master
            case .coach: return "love-coach"       // Maps to Love Coach  
            case .tutor: return "power-player"     // Maps to Power Player
            default: return "money-master"
            }
        }
    }
    
    /// ✅ REPLACEMENT: Processes transcript text from the AI.
    /// It creates a new message for the first chunk of an AI's turn,
    /// and updates that same message for all subsequent chunks in that turn.
    private func updateAITranscript(with text: String, isFinal: Bool) {
        // Ensure the text is not empty
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Check if we are already updating a message for the current AI turn.
        if let currentID = currentAIMessageID,
           let index = transcriptMessages.firstIndex(where: { $0.id == currentID }) {
            
            // If yes, UPDATE the existing message by replacing it with a new one that keeps the same ID
            let existingMessage = transcriptMessages[index]
            let updatedMessage = TranscriptMessage(
                id: existingMessage.id, // Keep the same ID
                text: trimmedText,
                timestamp: existingMessage.timestamp, // Keep the original timestamp
                isComplete: isFinal
            )
            transcriptMessages[index] = updatedMessage
            
            print("📝 Updated transcript [\(currentID)]: '\(trimmedText)'")
            
        } else {
            // If no, this is the FIRST text for a new AI turn. CREATE a new message.
            let newMessage = TranscriptMessage(text: trimmedText, isComplete: isFinal)
            transcriptMessages.append(newMessage)
            
            // REMEMBER the ID of this new message so we can update it next time.
            currentAIMessageID = newMessage.id
            
            print("📝 Created new transcript [\(newMessage.id)]: '\(trimmedText)'")
        }

        // Auto-scroll to the bottom to keep the latest text in view.
        if let proxy = transcriptScrollProxy {
            withAnimation(.easeOut(duration: 0.3)) {
                if let id = currentAIMessageID {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
        
        // Prune old messages to keep only the last few for performance.
        let maxMessages = 2 // Keep last 2 turns
        if transcriptMessages.count > maxMessages {
            transcriptMessages.removeFirst(transcriptMessages.count - maxMessages)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Lesson title moved higher up
            VStack(spacing: 8) {
                Text(lessonTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // AI Agent in center - Fixed height to prevent expansion
            VStack(spacing: 12) {
                if isSimulation, let simAgent = simulationAgent {
                    SimulationAgentView(agent: simAgent, isActive: isConversationActive, isSpeaking: isPlayingAudio, audioVolume: currentAudioVolume)
                } else {
                    AgentView(agentType: agentType, isActive: isConversationActive, isSpeaking: isPlayingAudio, audioVolume: currentAudioVolume)
                }
            }
            .frame(height: 250) // Fixed height to prevent expansion
            .padding(.top, 50) // Lower the face
            .padding(.bottom, 10)
            
            // Add some spacing before transcript
            Spacer().frame(height: 80) // Lowered the text box
            
            // ✅ Conditional transcript display (compact)
            if showTranscript {
                TranscriptDisplayView(
                    messages: transcriptMessages,
                    currentChunk: currentTranscriptChunk
                ) { proxy in
                    transcriptScrollProxy = proxy
                }
                .frame(height: 100) // Fixed height to prevent expansion
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Error message display (compact)
            if let errorMessage = errorMessage {
                VStack(spacing: 8) {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineLimit(3)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
            }
            
            Spacer() // This will push the button towards the bottom but keep it visible
            
            // Conversation button - always visible and well positioned
            Button(action: {
                startConversation()
            }) {
                HStack {
                    Image(systemName: isConversationActive ? "stop.fill" : "mic.fill")
                    Text(isConversationActive ? "End Conversation" : "Start Conversation")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isConversationActive ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30) // Safe area padding
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Stop conversation if active before navigating back
                    if isConversationActive {
                        stopConversation()
                    }
                    // Navigate back to previous view (homepage or simulation list)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(isSimulation ? "Back" : "Home")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Timer in the center of navigation bar
            ToolbarItem(placement: .principal) {
                if isConversationActive {
                    VStack(spacing: 2) {
                        Text(formattedElapsedTime)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        
                        if sessionRefreshCount > 0 {
                            Text("Refreshed \(sessionRefreshCount)x")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    EmptyView()
                }
            }
            
            // ✅ Step 3.1: Transcript toggle button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTranscript.toggle()
                        
                        // ✅ Step 2.3: Handle speech recognition when transcript is toggled
                        if showTranscript {
                            // Start speech recognition if conversation is active
                            if isConversationActive {
                                Task {
                                    await startSpeechRecognitionForTranscript()
                                }
                            }
                        } else {
                            // Stop speech recognition when transcript is disabled
                            stopSpeechRecognitionForTranscript()
                        }
                    }
                }) {
                    Image(systemName: "doc.text")
                        .foregroundColor(showTranscript ? .blue : .gray)
                        .font(.system(size: 18, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showCongratulations) {
            CongratulationsView(
                lessonTitle: lessonTitle,
                agentName: currentAgent.name,
                xpEarned: GameProgressManager.shared.lastAwardedXP ?? currentSession?.xpEarned ?? 0,
                duration: sessionDuration,
                onContinue: {
                    showCongratulations = false
                    // Navigate back to roadmap - this will pop the current view
                }
            )
        }
        .onAppear {
            print("🔄 LessonView onAppear - Starting initialization")
            print("📝 Lesson ID: \(lessonID)")
            print("📝 Lesson Title: \(lessonTitle)")
            print("📝 Lesson Number: \(lessonNumber)")
            print("📝 Agent Type: \(agentType.rawValue)")
            print("🎭 Is Simulation: \(isSimulation)")
            print("🔐 Auth Status: \(authService.isSignedIn)")
            print("👤 Current User: \(authService.currentUser?.uid ?? "nil")")
            
            // ✅ FIRESTORE CRASH FIX: Add notification observers for app lifecycle
            setupAppLifecycleObservers()
            
            // Use pre-created agent if available, otherwise create simulation agent if needed
            if isSimulation {
                if let preAgent = preCreatedAgent {
                    print("🤖 Using pre-created simulation agent: \(preAgent.name)")
                    simulationAgent = preAgent
                } else if !characterName.isEmpty {
                    print("🎭 Creating simulation agent for character: \(characterName)")
                    createSimulationAgentIfNeeded()
                } else {
                    print("❌ No simulation agent or character data provided")
                }
            }
            
            // Validate inputs before setting up audio
            guard validateLessonInputs() else {
                print("❌ LessonView: Input validation failed")
                errorMessage = "Invalid lesson data detected"
                return
            }
            
            print("✅ LessonView: Input validation passed")
            setupAudioSession()
            setupSeparateAudioEngines()
            setupAudioOutputDetection()
            setupSpeechRecognitionCallbacks() // ✅ Step 1.2: Setup speech recognition
            print("✅ LessonView: Initialization complete")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onDisappear {
            // Cleanup when view disappears
            if isConversationActive {
                stopConversation()
            }
            
            // ✅ Stop volume monitoring
            stopVolumeMonitoring()
            
            // Stop all timers
            stopSessionMonitoring()
            stopDisplayTimer()

#if os(iOS)
            // Remove audio route change observer
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
            
            // ✅ FIRESTORE CRASH FIX: Remove app lifecycle observers
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
#endif
        }
    }
    
    // MARK: - ✅ FIRESTORE CRASH FIX: Scene Phase Management
    
    private func setupAppLifecycleObservers() {
#if os(iOS)
        // Add notification observers for more reliable background detection
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🔽 NOTIFICATION: App entered background - Emergency conversation stop")
            if self.isConversationActive {
                self.emergencyStopConversation()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("✅ NOTIFICATION: App will enter foreground")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("✅ NOTIFICATION: App became active")
        }
#endif
    }
    
    private func emergencyStopConversation() {
        print("🚨 EMERGENCY STOP: Immediately stopping conversation to prevent Firestore crash")
        
        // Immediately stop all operations without cleanup delay
        isConversationActive = false
        isConnecting = false
        
        // Stop audio engines immediately
        if let recordingEngine = recordingEngine, recordingEngine.isRunning {
            recordingEngine.stop()
            recordingEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let playbackEngine = playbackEngine, playbackEngine.isRunning {
            playbackEngine.stop()
        }
        
        if let playerNode = playbackPlayerNode, playerNode.isPlaying {
            playerNode.stop()
        }
        
        // Cancel all timers
        audioSendTimer?.invalidate()
        audioSendTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
        displayTimer?.invalidate()
        displayTimer = nil
        volumeUpdateTimer?.invalidate()
        volumeUpdateTimer = nil
        
        // Clear audio buffers
        outgoingAudioBuffer.removeAll()
        
        // Stop live client without waiting
        Task {
            await liveClient.stop()
        }
        
        // Set user message
        statusText = "Conversation stopped due to app backgrounding"
        errorMessage = "Conversation was automatically stopped to prevent crashes. Tap to start a new conversation."
        
        print("✅ EMERGENCY STOP: Conversation stopped successfully")
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        print("🔄 Scene phase changed: \(oldPhase) → \(newPhase)")
        
        switch newPhase {
        case .active:
            print("✅ App became active")
            if wasActiveBeforeBackground && isConversationActive {
                print("🔄 Conversation was active before background - maintaining state")
                // Don't restart conversation, just maintain current state
            }
            wasActiveBeforeBackground = false
            
        case .inactive:
            print("⚠️ App became inactive")
            // Don't do anything yet - user might just be switching apps temporarily
            
        case .background:
            print("🔽 App went to background")
            wasActiveBeforeBackground = isConversationActive
            
            if isConversationActive {
                print("🛑 FIRESTORE CRASH PREVENTION: Stopping conversation due to background state")
                // Stop conversation to prevent Firestore write operations in background
                stopConversation()
                
                // Show user-friendly message for when they return
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.statusText = "Conversation paused while app was in background"
                    self.errorMessage = "Conversation was automatically stopped when app went to background. Tap to start a new conversation."
                }
            }
            
        @unknown default:
            print("❓ Unknown scene phase: \(newPhase)")
        }
    }
    
    // MARK: - Simulation Agent Creation
    
    private func createSimulationAgentIfNeeded() {
        guard isSimulation && !characterName.isEmpty else {
            print("❌ Cannot create simulation agent: missing character data")
            print("   isSimulation: \(isSimulation)")
            print("   characterName: '\(characterName)'")
            return
        }
        
        print("🎭 AGENT CREATION: Starting for character: \(characterName)")
        
        // Parse character gender from characterName or characterVoice
        let characterGender = determineCharacterGender()
        print("🎭 AGENT CREATION: Determined gender: \(characterGender)")
        
        // Get appropriate voice enum
        guard let voiceEnum = getVoiceEnum(from: characterVoice) else {
            print("❌ Cannot create simulation agent: invalid voice \(characterVoice)")
            return
        }
        print("🎭 AGENT CREATION: Voice enum: \(voiceEnum)")
        
        // Define default agent colors (from Agent.swift)
        let defaultColors = [
            AgentColor(red: 0.26, green: 0.52, blue: 0.96), // #4285f4
            AgentColor(red: 0.92, green: 0.26, blue: 0.21), // #ea4335
            AgentColor(red: 0.98, green: 0.74, blue: 0.02), // #fbbc04
            AgentColor(red: 0.20, green: 0.66, blue: 0.33), // #34a853
            AgentColor(red: 0.98, green: 0.48, blue: 0.09), // #fa7b17
            AgentColor(red: 0.96, green: 0.22, blue: 0.63), // #f538a0
            AgentColor(red: 0.63, green: 0.26, blue: 0.96), // #a142f4
            AgentColor(red: 0.14, green: 0.76, blue: 0.88), // #24c1e0
        ]
        
        // Get body color (use default if not provided)
        let bodyColor = characterBodyColor ?? defaultColors.randomElement() ?? defaultColors[0]
        print("🎭 AGENT CREATION: Body color selected")
        
        // Use personality if provided, otherwise get random one
        let personality = characterPersonality.isEmpty ? GlobalPersonalities.getRandomPersonality() : characterPersonality
        print("🎭 AGENT CREATION: Personality: \(personality.prefix(50))...")
        
        // 🔧 IMPROVED: Use enhanced context generation
        let scenarioInstructions = getEnhancedSimulationContext()
        print("🎭 CONTEXT: Using enhanced context: \(scenarioInstructions.prefix(100))...")
        
        // Create enhanced simulation agent using the new method
        simulationAgent = Agent.createSimulationAgent(
            name: characterName,
            gender: characterGender,
            personality: personality,
            voice: voiceEnum,
            bodyColor: bodyColor,
            scenarioInstructions: scenarioInstructions
        )
        
        print("🎭 ✅ SIMULATION AGENT CREATED!")
        print("   Name: \(simulationAgent?.name ?? "nil")")
        print("   ID: \(simulationAgent?.id ?? "nil")")
        print("   Voice: \(simulationAgent?.voice ?? InterlocutorVoice.aoede)")
        print("🎭 Personality: \(personality.prefix(100))...")
    }
    
    private func determineCharacterGender() -> String {
        // Try to determine from voice name (voices are gender-specific)
        let femaleVoices = ["Achernar", "Aoede", "Autonoe", "Callirrhoe", "Despina", "Erinome", "Gacrux", "Kore", "Laomedeia", "Leda", "Pulcherrima", "Sulafat", "Vindemiatrix", "Zephyr"]
        
        if femaleVoices.contains(characterVoice) {
            return "female"
        } else {
            return "male"
        }
    }
    
    private func getVoiceEnum(from voiceName: String) -> InterlocutorVoice? {
        return InterlocutorVoice.allCases.first { $0.rawValue == voiceName }
    }
    
    // MARK: - Scenario Context Generation
    
    private func getEnhancedSimulationContext() -> String {
        // Return enhanced context (generate if empty)
        let context = simulationContext.trimmingCharacters(in: .whitespacesAndNewlines)
        if context.isEmpty {
            return generateScenarioContext(from: lessonID)
        }
        return context
    }
    
    private func generateScenarioContext(from scenarioID: String) -> String {
        // Map scenario IDs to appropriate context (based on SimulateView's createSimulationContext)
        let userGender = UserDefaults.standard.string(forKey: "userGender") ?? "person"
        
        switch scenarioID {
        // MONEY CATEGORY
        case "cold_call":
            return """
            You are a busy business owner who just answered an unexpected sales call but you don't know at first that it is a sales call. You're skeptical of salespeople and pressed for time, but you'll listen if they demonstrate clear value quickly. 
            Be moderately challenging and expect competent responses. Stay slightly annoyed but become more interested if they handle the call professionally and address your specific business needs and be brutally honest about your expectations. 
            Don't be afraid to push back if you feel your time is being wasted. Don't let them waste your time with generic pitches. Don't help them with their sales tactics. Be demanding and realistic, expecting professional-level skills with minimal patience for mistakes or hesitation.
            """
            
        case "price_objection":
            return """
            You are a potential customer interested in the user's product but concerned about the price being higher than expected. You're budget-conscious but willing to pay for demonstrated value and clear ROI. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Challenge them to justify the cost and show skepticism until they prove the investment is worthwhile.
            """
            
        case "job_negotiation":
            return """
            You are an HR manager who wants to hire the user but has budget constraints and company policies to consider. You're open to negotiation but need compelling justification for any increases. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Test their confidence and ability to articulate their value proposition while maintaining professional boundaries.
            """
            
        case "client_pitch":
            return """
            You are a demanding potential client evaluating the user's proposal with high standards and specific business needs. You've seen many pitches before and appreciate professionalism over flashy presentations. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Ask tough questions about implementation, timeline, and results to test their expertise and preparation.
            """
            
        case "networking_event":
            return """
            You are a successful professional at a networking event who values genuine connections over superficial small talk. You're open to conversation but can quickly identify authentic networking versus pushy self-promotion. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Respond positively to thoughtful questions and mutual value exchange while being polite but distant to generic approaches.
            """
            
        case "investor_meeting":
            return """
            You are a skeptical investor who has seen countless startup pitches and focuses on market viability, scalability, and proven traction. You ask pointed questions about revenue models, competition, and growth strategy. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Challenge their assumptions and demand concrete data while remaining professional but tough in your evaluation.
            """
            
        case "contract_negotiation":
            return """
            You are the other party in a contract negotiation with your own set of requirements and constraints. You're firm on key terms but willing to find creative solutions that benefit both parties. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Push back on unfavorable terms while remaining open to compromise and win-win scenarios.
            """
            
        case "business_partnership":
            return """
            You are considering a business partnership and need to evaluate the user's commitment, resources, and strategic fit. You're excited about potential collaboration but cautious about rushing into agreements. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Probe their long-term vision, available resources, and how they handle partnership challenges.
            """
            
        // LOVE CATEGORY
        case "first_approach":
            let oppositeGender = userGender == "male" ? "female" : "male"
            return """
            You are an attractive \(oppositeGender) at a coffee shop, reading and enjoying your drink. You're friendly but selective about who you engage with, appreciating genuine confidence over pickup lines. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. React based on their approach style - warmly to authentic conversation starters, coolly to generic lines.
            """
            
        case "first_date":
            return """
            You are on a first date feeling excited but slightly nervous about making a good impression. You're looking for genuine connection beyond surface-level conversation and appreciate good listening skills. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Show increasing interest for engaging questions and authentic sharing, but become distant if conversation feels one-sided or superficial.
            """
            
        case "relationship_conflict":
            return """
            You are in a relationship disagreement feeling unheard and frustrated but wanting to resolve the issue constructively. You become defensive if attacked but responsive to empathy and validation. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Test their emotional intelligence and willingness to truly listen before moving toward compromise.
            """
            
        case "breakup_conversation":
            return """
            You are in a relationship that isn't working and need to have a difficult conversation about ending it. You're emotional but trying to handle the situation maturely and with respect for your shared history. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. React based on how compassionately and clearly they communicate during this sensitive discussion.
            """
            
        case "meeting_parents":
            return """
            You are the protective parent of the user's romantic partner, polite but evaluating their character and intentions. You care deeply about your child's happiness and want to see genuine respect and commitment. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Ask probing questions about their relationship goals and how they treat your child while maintaining parental authority.
            """
            
        case "long_distance_relationship":
            return """
            You are in a long-distance relationship discussing its future challenges and possibilities. You have genuine feelings but realistic concerns about the difficulties and sacrifices involved. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Express your fears and hopes honestly while testing their commitment and practical planning for the relationship's future.
            """
            
        case "marriage_proposal":
            return """
            You are being proposed to by someone you care about but need to feel that this is the right decision at the right time. You're emotional but also practical about marriage as a life commitment. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. React based on the thoughtfulness of their proposal and how well they understand your needs and dreams.
            """
            
        case "couples_therapy":
            return """
            You are in couples therapy feeling frustrated about relationship issues but willing to work on them with professional guidance. You're defensive about your perspective but open to feedback if delivered constructively. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Challenge their willingness to take responsibility while showing your own vulnerability and desire for positive change.
            """
            
        // POWER CATEGORY
        case "job_interview":
            return """
            You are a hiring manager conducting a final interview for a senior position, looking for competence, confidence, and cultural fit. You ask challenging questions to test the candidate's experience and decision-making abilities. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Evaluate their answers for specific examples and clear communication while maintaining professional but demanding standards.
            """
            
        case "team_leadership":
            return """
            You are an experienced team member skeptical of the new team leader's proposed changes. You're loyal to the team but resistant to change without clear justification and inclusive leadership. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Test their leadership style and willingness to listen while representing legitimate team concerns about new initiatives.
            """
            
        case "difficult_conversation":
            return """
            You are a colleague who needs to address performance issues with the user in a constructive but serious conversation. You're uncomfortable with confrontation but know it's necessary for team success. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Respond based on how professionally they receive feedback and whether they take ownership of the issues raised.
            """
            
        case "performance_review":
            return """
            You are an employee receiving performance feedback from your manager, feeling defensive about criticisms but wanting to improve and advance in your career. You respond better to specific examples than vague complaints. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. React based on how constructively they deliver feedback and whether they provide actionable guidance for improvement.
            """
            
        case "conflict_resolution":
            return """
            You are one of two team members in conflict, frustrated with the situation but willing to resolve it if the mediator shows fairness and understanding. You have legitimate grievances but also some responsibility for the conflict. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Test their mediation skills and ability to find balanced solutions while representing your perspective firmly.
            """
            
        case "public_speaking":
            return """
            You are an audience member listening to the user's presentation, representing a diverse group with varying interests and attention spans. You appreciate clear, engaging communication but quickly lose interest in boring or unclear content. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. React based on their speaking effectiveness, clarity of message, and ability to maintain audience engagement throughout their presentation.
            """
            
        case "board_presentation":
            return """
            You are a board member reviewing quarterly results with fiduciary responsibility to challenge assumptions and ensure company success. You ask tough questions about performance, strategy, and future projections. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Scrutinize their data, challenge their conclusions, and test their ability to defend their strategies under pressure while maintaining professional standards.
            """
            
        case "mentorship_meeting":
            return """
            You are a struggling mentee seeking guidance and direction from someone more experienced. You're receptive to good advice but need clear, actionable guidance rather than vague encouragement. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Respond positively to specific, practical advice while challenging them to provide concrete steps and accountability for your professional development.
            """
            
        default:
            return """
            You are engaging in a realistic role-play scenario with the user. Stay in character and respond authentically to their communication style and approach. Be moderately challenging and expect competent responses, but offer hints if they struggle significantly. Provide realistic reactions and feedback to help them practice their interpersonal skills.
            """
        }
    }
    
    // MARK: - Clean System Prompt Creation
    
    private func createCleanSimulationPrompt(agent: Agent, enhancedContext: String) -> String {
        // Single unified system prompt with all components
        return """
        You are \(agent.name). 
        
        Character Profile:
        \(agent.personality)
        
        Scenario Context:
        \(enhancedContext)
        
        RESPONSES TO GIVE:
        - Initial greeting: "Hello?" (as you would normally answer a phone)

        IMPORTANT CHARACTER CONTEXT:
        - You are playing the role of \(agent.name), a \(determineCharacterGender()) character
        - Use the name \(agent.name) when introducing yourself or when asked
        - Maintain character consistency throughout the conversation
        - Respond in a way that matches \(agent.name)'s personality and the scenario context
        - Do NOT describe your tones (e.g., "In an annoyed tone"). 
        - You can speak multiple languages if needed. You reply to the user in the language they used.
        """
    }
    
    // MARK: - Audio Output Management
    
    private func setupAudioOutputDetection() {
#if os(iOS)
        // Listen for audio route changes
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Note: In SwiftUI views (structs), we don't need weak self
            // The notification observer will be removed in onDisappear
            Task { @MainActor in
                self.updateAvailableAudioOutputs()
            }
        }
        
        // Initial setup
        updateAvailableAudioOutputs()
#endif
    }
    
    private func updateAvailableAudioOutputs() {
#if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        var outputs: [AudioOutput] = []
        
        // Always available: Speaker only (removed iPhone earpiece option)
        outputs.append(.speaker)
        
        // Check for connected Bluetooth devices
        let currentRoute = audioSession.currentRoute
        for output in currentRoute.outputs {
            switch output.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                if !outputs.contains(.bluetooth) {
                    outputs.append(.bluetooth)
                }
            case .headphones:
                if !outputs.contains(.headphones) {
                    outputs.append(.headphones)
                }
            default:
                break
            }
        }
        
        // Also check available inputs for connected devices
        for input in audioSession.availableInputs ?? [] {
            switch input.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                if !outputs.contains(.bluetooth) {
                    outputs.append(.bluetooth)
                }
            case .headphones:
                if !outputs.contains(.headphones) {
                    outputs.append(.headphones)
                }
            default:
                break
            }
        }
        
        availableAudioOutputs = outputs
        
        // Update selected output if current one is no longer available
        if !outputs.contains(selectedAudioOutput) {
            selectedAudioOutput = .speaker // Default fallback
        }
        
        print("🎧 Available audio outputs updated: \(outputs.map { $0.displayName })")
#endif
    }
    
    private func getDisplayNameForOutput(_ output: AudioOutput) -> String {
#if os(iOS)
        if output == .bluetooth {
            // Try to get the actual Bluetooth device name
            let audioSession = AVAudioSession.sharedInstance()
            let currentRoute = audioSession.currentRoute
            
            for routeOutput in currentRoute.outputs {
                if routeOutput.portType == .bluetoothA2DP || routeOutput.portType == .bluetoothHFP || routeOutput.portType == .bluetoothLE {
                    return routeOutput.portName
                }
            }
            
            // Check available inputs for Bluetooth devices
            for input in audioSession.availableInputs ?? [] {
                if input.portType == .bluetoothA2DP || input.portType == .bluetoothHFP || input.portType == .bluetoothLE {
                    return input.portName
                }
            }
        }
#endif
        return output.displayName
    }
    
    private func getDisplayNameForSelectedOutput() -> String {
        return getDisplayNameForOutput(selectedAudioOutput)
    }
    
    private func selectAudioOutput(_ output: AudioOutput) {
#if os(iOS)
        selectedAudioOutput = output
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Never use overrideOutputAudioPort - it breaks echo cancellation
            switch output {
            case .speaker:
                // Use defaultToSpeaker option for speaker routing
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
                )
                
            case .bluetooth, .headphones:
                // Let iOS handle routing to connected devices
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [.allowBluetooth, .allowBluetoothA2DP]
                )
                
                // Set preferred input for Bluetooth
                if output == .bluetooth {
                    if let bluetoothInput = audioSession.availableInputs?.first(where: { 
                        $0.portType == .bluetoothHFP || $0.portType == .bluetoothA2DP 
                    }) {
                        try audioSession.setPreferredInput(bluetoothInput)
                    }
                }
            }
            
            try audioSession.setActive(true)
            print("✅ Audio routed to: \(output.displayName)")
            
        } catch {
            print("❌ Audio routing failed: \(error)")
        }
#endif
    }
    
    // MARK: - Extracted from CoachView - Audio Session Setup
    
    private func setupAudioSession() {
#if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // CRITICAL: Use .voiceChat for hardware echo cancellation
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            
            try audioSession.setActive(true)
            
            print("✅ Audio session configured with hardware echo cancellation")
            print("   Mode: \(audioSession.mode.rawValue)")
            print("   Sample Rate: \(audioSession.sampleRate)Hz")
            
        } catch {
            print("❌ Audio session setup failed: \(error)")
            errorMessage = "Audio setup failed: \(error.localizedDescription)"
        }
#endif
    }
    
    private func setupSeparateAudioEngines() {
        print("🎵 Setting up audio engines with iOS echo cancellation")
        
        // Recording engine - 16kHz for Gemini
        recordingEngine = AVAudioEngine()
        
        // Playback engine - 24kHz from Gemini
        playbackEngine = AVAudioEngine()
        playbackPlayerNode = AVAudioPlayerNode()
        
        guard let playbackEng = playbackEngine, 
              let playerNode = playbackPlayerNode else { return }
        
        playbackEng.attach(playerNode)
        
        // Use the main mixer for proper echo cancellation integration
        let mixer = playbackEng.mainMixerNode
        let outputFormat = mixer.outputFormat(forBus: 0)
        
        // Connect through mixer for echo cancellation
        playbackEng.connect(playerNode, to: mixer, format: outputFormat)
        playbackEng.connect(mixer, to: playbackEng.outputNode, format: outputFormat)
        
        print("✅ Audio engines configured with echo cancellation path")
        
        // Cache formats and create converters
        cachedPlaybackFormat = outputFormat
        cachedTargetFormat = outputFormat
        
        // Create the playback converter (Gemini 24kHz → Device format)
        let geminiAudioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: true
        )!
        
        playbackConverter = AVAudioConverter(from: geminiAudioFormat, to: outputFormat)
        
        if playbackConverter != nil {
            print("✅ Playback converter created: 24kHz mono → \(outputFormat.sampleRate)Hz \(outputFormat.channelCount)ch")
        } else {
            print("❌ Failed to create playback converter")
        }
        
        print("✅ Audio engines configured and ready.")
    }
    
    // MARK: - Enhanced Conversation Logic from CoachView
    
    private func startConversation() {
        print("🎤 startConversation called - isActive: \(isConversationActive)")
        
        if isConversationActive {
            print("🛑 Stopping conversation")
            stopConversation()
        } else {
            print("🔄 Starting new conversation")
            
            // Security check: Rate limiting DISABLED - was blocking conversations
            // guard canStartConversation() else {
            //     print("❌ Rate limit check failed")
            //     errorMessage = "Please wait before starting another conversation"
            //     return
            // }
            // print("✅ Rate limit check passed")
            
            // Security check: Authentication
            guard validateAuthentication() else {
                print("❌ Authentication check failed")
                errorMessage = "Authentication required to start conversation"
                return
            }
            print("✅ Authentication check passed")
            
            // lastConversationStart = Date() // Rate limiting disabled
            
            // 🔧 NEW: Mark that the next AI response should clear previous transcript
            isNewAIResponse = true
            
            print("🚀 Launching streaming task")
            _Concurrency.Task {
                await startStreaming()
            }
        }
    }
    
    private func startStreaming() async {
        print("🔄 startStreaming() called")
        guard !isConversationActive, !isConnecting else { 
            print("❌ Guard failed - isConversationActive: \(isConversationActive), isConnecting: \(isConnecting)")
            return 
        }
        
        print("✅ Setting isConnecting = true")
        isConnecting = true
        errorMessage = nil
        statusText = "Connecting to AI coach..."
        
        // Record conversation start time and start session monitoring
        conversationStartTime = Date()
        startSessionMonitoring()
        startDisplayTimer()
        
        // Reset audio state for new conversation
        isNewAIResponse = true
        audioChunkCount = 0
        
        // ✅ Reset enhanced mouth animation state
        await MainActor.run {
            self.currentAudioVolume = 0.0
            self.peakVolume = 0.0
            self.isActivelySpeaking = false
            self.lastVolumeUpdate = Date()
            self.volumeDecayRate = 0.85 // Reset to default
        }
         
        // Create lesson session for XP tracking
        currentSession = ConversationSession(
            lessonId: lessonID,
            lessonTitle: lessonTitle,
            agentId: currentAgent.id,
            agentName: currentAgent.name
        )
        print("✅ Created conversation session")
        
        do {
            // Update user information from Firebase Auth before creating conversation
            GameProgressManager.shared.updateUserFromAuth()
            
            // Create simple personalized system prompt (agent personality + user info)
            print("🔄 Creating system prompt...")
            print("🤖 AGENT CHECK before system prompt: \(currentAgent.name) (ID: \(currentAgent.id))")
            print("🎭 Is Simulation: \(isSimulation)")
            print("🤖 Simulation Agent Available: \(simulationAgent?.name ?? "NONE")")
            
            // ✅ Use appropriate system prompt method based on conversation type
            let systemPrompt: String
            if isSimulation {
                // Use custom simulation prompt with our enhanced context (avoid duplication)
                systemPrompt = createCleanSimulationPrompt(
                    agent: currentAgent,
                    enhancedContext: getEnhancedSimulationContext()
                )
                print("✅ Clean simulation system prompt created: \(systemPrompt.prefix(100))...")
            } else {
                // Use lesson-specific prompt for educational conversations
                systemPrompt = SystemInstructions.createForLesson(
                    agent: currentAgent,
                    user: GameProgressManager.shared.currentUser
                )
                print("✅ Lesson system prompt created: \(systemPrompt.prefix(100))...")
            }
            
            // DEBUG: Print full system prompt for inspection (clear delimiters)
            print("\n========== SYSTEM PROMPT START ==========")
            print(systemPrompt)
            print("=========== SYSTEM PROMPT END ===========\n")

            print("🔄 Calling liveClient.start()...")
            let agentTypeString = getAgentTypeString()
            
            // 🎤 For simulations, use the character's voice; for lessons, let cloud function decide
            let voiceToUse: String? = {
                if isSimulation && !characterVoice.isEmpty {
                    return characterVoice
                } else if isSimulation && simulationAgent != nil {
                    return simulationAgent!.voice.rawValue
                } else {
                    return nil // Let cloud function decide based on agent type
                }
            }()
            print("🎤 Voice parameter: \(voiceToUse ?? "nil (cloud function will decide)")")
            print("🎤 Character voice from input: '\(characterVoice)'")
            print("🎤 Simulation agent voice: '\(simulationAgent?.voice.rawValue ?? "none")'")
            
            // ✅ Step 4.2: Updated liveClient.start to include onTextOut callback
            try await liveClient.start(
                systemPrompt: systemPrompt, 
                agentType: agentTypeString,
                voiceName: voiceToUse,
                onAudioOut: { audioData in
                    _Concurrency.Task { @MainActor in
                        let apiHash = audioData.hashValue
                        let timestamp = Date().timeIntervalSince1970
                        print("📡 API RECEIVED: Audio chunk \(audioData.count) bytes, hash: \(apiHash), time: \(timestamp)")
                        
                        // 🔧 NEW: Clear transcript for new AI response
                        if self.isNewAIResponse {
                            print("🔄 NEW AI RESPONSE: Clearing previous transcript")
                            
                            // ✅ ADD THIS LINE: Signal that the next transcript chunk should create a new message
                            self.currentAIMessageID = nil
                            
                            self.currentTranscriptChunk = ""
                            
                            // DON'T reset isNewAIResponse here - let playAudioResponse handle it
                            self.audioChunkCount = 0 // Reset chunk counter for new AI response
                        }
                        
                        await self.playAudioResponse(audioData)
                    }
                },
                onTextOut: { textChunk in
                    // DO NOTHING HERE. This prevents the server's transcript from interfering.
                }
            )
            print("✅ liveClient.start() completed successfully")
            
            // Start audio streaming to Live API
            print("🔄 Starting audio streaming...")
            try await startAudioStreaming()
            print("✅ Audio streaming started successfully")
            
            isConversationActive = true
            isConnecting = false
            statusText = "Conversation active - speak with \(currentAgent.name)"
            print("🎯 CONVERSATION STARTED: Speaking with \(currentAgent.name) (ID: \(currentAgent.id))")
            print("✅ startStreaming() completed successfully - isConversationActive: \(isConversationActive)")
            
            // ✅ Reset audio deduplication state for new conversation
            lastAudioHash = 0
            lastAudioTime = Date.distantPast
            
            // 🔧 IMPROVED: Reset audio state
            activeAudioChunkCount = 0
            
            // 🔧 NEW: Clear transcript state between conversations
            currentTranscriptChunk = ""
            transcriptMessages.removeAll()
            
            // ✅ Step 1.2: Setup speech recognition callbacks BEFORE starting recognition
            setupSpeechRecognitionCallbacks()
            
            // ✅ Step 2.1: Start speech recognition for AI transcript after conversation is active
            await startSpeechRecognitionForTranscript()
            
            // Auto-greeting disabled: do not force agents to introduce themselves.
            print("ℹ️ AUTO-GREETING disabled: agents will not automatically introduce themselves")
            
        } catch {
            print("❌ ERROR in startStreaming(): \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ NSError domain: \(nsError.domain)")
                print("❌ NSError code: \(nsError.code)")
                print("❌ NSError userInfo: \(nsError.userInfo)")
            }
            
            isConnecting = false
            let sanitizedError = sanitizeErrorMessage(error.localizedDescription)
            errorMessage = "Failed to start conversation: \(sanitizedError)"
            statusText = "Ready to start conversation"
            print("❌ startStreaming() failed - isConnecting: \(isConnecting), isConversationActive: \(isConversationActive)")
        }
    }
    
    // MARK: - Auto-Greeting Implementation (from chatterbots)
    private func startInitialGreeting() async {
        // Auto-greeting intentionally disabled. Keep function for easy re-enable if needed.
        print("ℹ️ startInitialGreeting() called but auto-greeting is disabled")
        return
    }
    
    private func getCategoryContext() -> String {
        // Extract category from agent type for more specific context
        switch agentType {
        case .mentor:
            return "sales and negotiation"
        case .coach:
            return "dating and authentic connection"
        case .tutor:
            return "leadership and influence"
        case .language:
            return "language learning and communication"
        case .story:
            return "storytelling and narrative development"
        case .simulation:
            return "realistic scenario practice and role-playing"
        }
    }
    
    private func stopConversation() {
        guard isConversationActive else { return }
        
        stopAudioStreaming()
        stopSessionMonitoring() // Stop session monitoring
        stopDisplayTimer() // Stop display timer
        
        // Clean up audio state - much simpler now
        pendingPlaybackTimer?.invalidate()
        pendingPlaybackTimer = nil
        
        // Complete session and calculate XP using dynamic system
        if let session = currentSession {
            // Store duration for congratulations screen
            sessionDuration = session.duration
            
            print("🎯 Completed conversation session: \(session.lessonTitle)")
            print("🎯 Session duration: \(session.duration) seconds")
            
            // Use new dynamic XP system with category multiplier and session duration
            let categoryName = getPracticeCategoryFromAgent() ?? "general"
            GameProgressManager.shared.completeConversation(
                categoryName: categoryName,
                duration: sessionDuration,
                performance: ConversationPerformance.good // Default performance, could be calculated based on session metrics
            )
            
            // In conversation completion, add simulation tracking:
            if isSimulation {
                // Extra XP for simulations will be calculated by dynamic system
                print("🎯 Simulation completed with bonus XP")
                
                // Track simulation completion (if GameProgressManager exists)
                // GameProgressManager.shared.simulationsCompleted += 1
            }
            
            currentSession = nil as ConversationSession?
            
            // Show congratulations screen (XP will be updated via real-time listener)
            // Log the XP that will be shown (use lastAwardedXP if available)
            let xpToShow = GameProgressManager.shared.lastAwardedXP ?? 50 // fallback XP
            print("🎉 Preparing CongratulationsView - XP to show: \(xpToShow)")
            showCongratulations = true
        }
        
        // ✅ Step 2.1: Stop speech recognition when conversation ends
        stopSpeechRecognitionForTranscript()
        
        _Concurrency.Task {
            await liveClient.stop()
        }
        
        isConversationActive = false
        statusText = "Ready to start conversation"
    }
    
    // MARK: - Cleanup (handled in onDisappear)
    
    // MARK: - Extracted from CoachView - Audio Streaming Methods
    
    private func startAudioStreaming() async throws {
        // Use the RECORDING ENGINE for microphone input
        guard let recordingEngine = recordingEngine else {
            print("❌ Recording engine not setup!")
            throw URLError(.cannotCreateFile)
        }
        
        let inputNode = recordingEngine.inputNode
        let recordingFormat = inputNode.inputFormat(forBus: 0)

        // Live API expects 16kHz mono PCM - Define target format once
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        )!

        // 🚀 ELITE REFINEMENT: Single-step direct conversion
        // Convert directly from microphone's native format to Gemini's 16kHz format
        guard let directConverter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
            print("❌ Failed to create direct converter from \(recordingFormat.sampleRate)Hz \(recordingFormat.channelCount)ch to 16kHz mono")
            throw URLError(.cannotCreateFile)
        }
        
        // Cache the converter for performance optimization
        self.audioConverter = directConverter
        
        print("🎙️ Elite audio pipeline configured:")
        print("   Input: \(recordingFormat.sampleRate)Hz \(recordingFormat.commonFormat.rawValue) \(recordingFormat.channelCount)ch")
        print("   Output: \(targetFormat.sampleRate)Hz \(targetFormat.commonFormat.rawValue) \(targetFormat.channelCount)ch")
        print("   Conversion: Single-step direct (optimal performance)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // 🚀 ELITE HOT PATH: Minimal processing for maximum performance
            
            // Calculate target frame count based on sample rate conversion
            let targetFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / recordingFormat.sampleRate)
            
            // Create target buffer for direct conversion
            guard let targetBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: targetFrameCount) else { 
                print("❌ Failed to create target buffer")
                return 
            }
            
            // Single-step direct conversion using cached converter
            var conversionError: NSError?
            let conversionStatus = self.audioConverter?.convert(to: targetBuffer, error: &conversionError) { _, inputStatus in
                inputStatus.pointee = .haveData
                return buffer
            }
            
            // Handle conversion errors efficiently
            guard conversionStatus != .error else {
                print("❌ Direct conversion failed: \(conversionError?.localizedDescription ?? "Unknown")")
                return
            }
            
            // Process the converted audio buffer
            Task { @MainActor in
                await self.processAudioBuffer(targetBuffer, targetFormat: targetFormat)
            }
        }
        
        // Start the RECORDING ENGINE only
        recordingEngine.prepare()
        try recordingEngine.start()
        
        // Start the PLAYBACK ENGINE for audio responses - ONCE at conversation start
        guard let playbackEngine = playbackEngine, let playerNode = playbackPlayerNode else {
            print("❌ Playback engine not setup!")
            throw URLError(.cannotCreateFile)
        }
        
        // 🔧 KEY IMPROVEMENT: Start playback engine ONCE here, not in playAudioResponse
        if playbackEngine.isRunning {
            playbackEngine.stop()
        }
        
        print("🎵 Preparing playback engine...")
        playbackEngine.prepare()
        
        // Verify engine is ready before starting
        guard playbackEngine.attachedNodes.contains(playerNode) else {
            print("❌ Player node not attached to playback engine!")
            throw URLError(.cannotCreateFile)
        }
        
        print("🎵 Starting playback engine...")
        try playbackEngine.start()
        
        // 🔧 KEY IMPROVEMENT: Start player node ONCE here, not in playAudioResponse
        playerNode.play()
        
        // 🔧 DIAGNOSTIC: Add delay to ensure engines are fully ready
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        print("✅ Separate audio engines started successfully - ready for real-time audio.")
        print("🔍 ENGINE STATE: Playback engine running: \(playbackEngine.isRunning), Player node playing: \(playerNode.isPlaying)")
    }
    
    private func stopAudioStreaming() {
        // 🔧 CRITICAL FIX: Proper cleanup sequence to prevent engine state conflicts
        
        // Stop recording engine first
        if let recordingEngine = recordingEngine, recordingEngine.isRunning {
            recordingEngine.stop()
            recordingEngine.inputNode.removeTap(onBus: 0)
            print("✅ Recording engine stopped and tap removed")
        }
        
        // Stop playback engine
        if let playbackEngine = playbackEngine, playbackEngine.isRunning {
            playbackEngine.stop()
            print("✅ Playback engine stopped")
        }
        
        // Stop player node
        if let playerNode = playbackPlayerNode, playerNode.isPlaying {
            playerNode.stop()
            print("✅ Player node stopped")
        }
        
        // Clean up audio buffering
        audioSendTimer?.invalidate()
        audioSendTimer = nil
        
        // ✅ PHASE 1: Enhanced buffer cleanup analysis
        print("🔍 === AUDIO CLEANUP ANALYSIS ===")
        print("🔍 Buffer size before cleanup: \(outgoingAudioBuffer.count) bytes")
        print("🔍 Total buffer operations this session: \(bufferAnalyticsCount)")
        print("🔍 Total bytes buffered this session: \(totalBufferedBytes)")
        
        // ✅ PHASE 2: Enhanced memory management audit
        print("🧹 PHASE 2: Memory management audit during cleanup")
        let preCleanupSize = outgoingAudioBuffer.count
        
        outgoingAudioBuffer.removeAll(keepingCapacity: false)  // Force deallocation
        
        let postCleanupSize = outgoingAudioBuffer.count
        
        print("🧹 PHASE 2: Memory audit results:")
        print("🧹   - Buffer size: \(preCleanupSize) → \(postCleanupSize) bytes")
        print("🧹   - Memory properly deallocated: \(postCleanupSize == 0 ? "✅ YES" : "❌ NO")")
        
        if postCleanupSize > 0 {
            print("🚨 PHASE 2: WARNING - Buffer not properly cleared!")
        } else {
            print("✅ PHASE 2: Buffer memory completely deallocated")
        }
        
        print("🔍 Resetting buffer analytics for next session")
        
        // ✅ PHASE 2: Complete analytics reset with memory management
        bufferAnalyticsCount = 0
        totalBufferedBytes = 0
        bufferSizeHistory.removeAll(keepingCapacity: false)  // Force deallocation
        
        print("✅ Audio streaming fully stopped and cleaned up")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) async {
        // Simple gate: Don't send audio while AI is speaking (echo prevention)
        guard !isAISpeaking else {
            return
        }
        
        // Small buffer after AI stops to prevent tail pickup
        guard Date().timeIntervalSince(lastAISpeechTime) > 0.3 else {
            return
        }
        
        // The buffer is already converted to 16kHz from the installTap
        guard let channelData = buffer.int16ChannelData?[0] else { return }
        let dataPointer = UnsafeRawPointer(channelData)
        let audioData = Data(bytes: dataPointer, count: Int(buffer.frameLength) * 2)
        
        // Send ALL audio to Gemini - let the API's VAD handle speech detection
        // The API will automatically:
        // 1. Detect voice activity vs silence
        // 2. Handle interruptions
        // 3. Manage turn-taking
        await bufferOutgoingAudio(audioData)
    }
    
    private func bufferOutgoingAudio(_ audioData: Data) async {
        // ✅ CRITICAL FIX: Voice Activity Detection to prevent silent audio waste
        let audioVolume = calculateAudioVolumeFromData(audioData)
        let isVolumeAboveThreshold = audioVolume > voiceActivityThreshold
        
        // ✅ STRICTER VAD: Require consecutive frames above threshold to confirm speech
        if isVolumeAboveThreshold {
            consecutiveSpeechFrames += 1
        } else {
            consecutiveSpeechFrames = 0
        }
        
        let isCurrentlySpeaking = vadEnabled ? consecutiveSpeechFrames >= minConsecutiveFrames : true
        
        // Update voice activity state
        if isCurrentlySpeaking && !isUserSpeaking {
            isUserSpeaking = true
            lastVoiceActivityTime = Date()
            silenceTimer?.invalidate()
            print("🎤 VAD: User started speaking (volume: \(String(format: "%.4f", audioVolume)), frames: \(consecutiveSpeechFrames))")
        } else if isCurrentlySpeaking {
            lastVoiceActivityTime = Date()
            print("🎤 VAD: User continues speaking (volume: \(String(format: "%.4f", audioVolume)), frames: \(consecutiveSpeechFrames))")
        }
        
        // Handle silence detection
        if !isCurrentlySpeaking && isUserSpeaking {
            print("🔇 VAD: Silence detected (volume: \(String(format: "%.4f", audioVolume)), frames: \(consecutiveSpeechFrames)) - starting silence timer")
            startSilenceTimer()
        }
        
        // ✅ CRITICAL: Only buffer audio if user is actually speaking or VAD is disabled
        guard !vadEnabled || isUserSpeaking else {
            print("🚫 VAD: Blocking silent/noise audio chunk - saving tokens! (vol: \(String(format: "%.4f", audioVolume)))")
            return
        }
        
        // ✅ PHASE 1: Enhanced buffer monitoring before processing
        bufferAnalyticsCount += 1
        totalBufferedBytes += audioData.count
        
        print("🔍 === LESSON VIEW BUFFER ANALYSIS ===")
        print("🔍 Buffer operation #\(bufferAnalyticsCount)")
        print("🔍 Incoming audio chunk: \(audioData.count) bytes")
        print("🔍 Current buffer size BEFORE append: \(outgoingAudioBuffer.count) bytes")
        
        outgoingAudioBuffer.append(audioData)
        
        print("🔍 Current buffer size AFTER append: \(outgoingAudioBuffer.count) bytes")
        print("🔍 Total bytes buffered this session: \(totalBufferedBytes)")
        print("🔍 Average chunk size: \(totalBufferedBytes / bufferAnalyticsCount) bytes")
        
        // ✅ Track buffer size patterns
        bufferSizeHistory.append(outgoingAudioBuffer.count)
        if bufferSizeHistory.count > 100 {  // Keep last 100 measurements
            bufferSizeHistory.removeFirst()
        }
        
        let maxBufferSize = bufferSizeHistory.max() ?? 0
        let avgBufferSize = bufferSizeHistory.reduce(0, +) / max(bufferSizeHistory.count, 1)
        print("🔍 Buffer size stats - Current: \(outgoingAudioBuffer.count), Max: \(maxBufferSize), Avg: \(avgBufferSize)")
        
        let now = Date()
        let timeSinceLastSend = now.timeIntervalSince(lastAudioSendTime)
        
        // Send if buffer is large enough OR if it's been too long since last send
        // ✅ LATENCY OPTIMIZATION: Consider high priority mode for faster transmission
        let isHighPriorityActive = liveClient.isHighPriorityMode()
        let priorityModeSend = isHighPriorityActive && outgoingAudioBuffer.count >= 1024 // 1KB minimum for priority mode
        
        let shouldSend = outgoingAudioBuffer.count >= audioBufferTargetSize || 
                        timeSinceLastSend >= maxAudioSendInterval ||
                        priorityModeSend
        
        print("🔍 Send decision - Buffer: \(outgoingAudioBuffer.count)/\(audioBufferTargetSize), Time: \(String(format: "%.3f", timeSinceLastSend))/\(maxAudioSendInterval), Priority: \(isHighPriorityActive), Should send: \(shouldSend)")
        
        if shouldSend && !outgoingAudioBuffer.isEmpty {
            // ✅ PHASE 2: Create isolated copy for transmission
            let dataToSend = Data(outgoingAudioBuffer)  // Defensive copy
            print("🔍 === PREPARING TO SEND ===")
            print("🔍 Data to send size: \(dataToSend.count) bytes")
            print("🔍 This will be sent to GeminiLiveClient.send(audioData:)")
            
            // ✅ PHASE 2: Immediate buffer clearing with validation
            print("🧹 PHASE 2: Clearing buffer before send to ensure isolation")
            let preCleanSize = outgoingAudioBuffer.count
            outgoingAudioBuffer.removeAll(keepingCapacity: false)  // Force deallocation
            print("🧹 PHASE 2: Buffer cleared - \(preCleanSize) → \(outgoingAudioBuffer.count) bytes")
            
            // ✅ PHASE 2: Validate buffer is truly clear
            if !outgoingAudioBuffer.isEmpty {
                print("🚨 PHASE 2: WARNING - Buffer not properly cleared!")
            } else {
                print("✅ PHASE 2: Buffer successfully cleared before transmission")
            }
            
            lastAudioSendTime = now
            
            print("📤 Sending batched audio: \(dataToSend.count) bytes")
            print("📤 isConversationActive: \(isConversationActive)")
            print("📤 liveClient.isConnected: \(liveClient.isConnected)")
            
            // ✅ PHASE 2: Send with clean isolated data
            await liveClient.send(audioData: dataToSend)
            
            // ✅ PHASE 2: Post-send validation
            print("🧹 PHASE 2: Post-send buffer state: \(outgoingAudioBuffer.count) bytes")
            if !outgoingAudioBuffer.isEmpty {
                print("🚨 PHASE 2: WARNING - Buffer contaminated after send!")
                outgoingAudioBuffer.removeAll(keepingCapacity: false)  // Force clean again
            }
        } else if outgoingAudioBuffer.count > 0 {
            print("🔍 Scheduling send for later - buffer not ready yet")
            // Schedule a send if we haven't sent in a while
            scheduleAudioSend()
        }
        
        print("🔍 === LESSON VIEW BUFFER ANALYSIS END ===")
    }
    
    private func scheduleAudioSend() {
        // Cancel existing timer
        audioSendTimer?.invalidate()
        
        // Schedule new timer
        audioSendTimer = Timer.scheduledTimer(withTimeInterval: maxAudioSendInterval, repeats: false) { _ in
            Task { @MainActor in
                if !self.outgoingAudioBuffer.isEmpty {
                    // ✅ PHASE 2: Create isolated copy for scheduled transmission
                    let dataToSend = Data(self.outgoingAudioBuffer)  // Defensive copy
                    
                    // ✅ PHASE 2: Clear buffer with validation
                    print("🧹 PHASE 2: Scheduled send - clearing buffer")
                    let preCleanSize = self.outgoingAudioBuffer.count
                    self.outgoingAudioBuffer.removeAll(keepingCapacity: false)
                    print("🧹 PHASE 2: Scheduled buffer cleared - \(preCleanSize) → \(self.outgoingAudioBuffer.count) bytes")
                    
                    self.lastAudioSendTime = Date()
                    
                    print("📤 Sending scheduled audio: \(dataToSend.count) bytes")
                    await self.liveClient.send(audioData: dataToSend)
                    
                    // ✅ PHASE 2: Post-scheduled-send validation
                    if !self.outgoingAudioBuffer.isEmpty {
                        print("🚨 PHASE 2: WARNING - Buffer contaminated after scheduled send!")
                        self.outgoingAudioBuffer.removeAll(keepingCapacity: false)
                    }
                }
            }
        }
    }
    
    
    private func playAudioResponse(_ audioData: Data) async {
        let currentAudioHash = audioData.hashValue
        let currentTime = Date()
        let timestamp = currentTime.timeIntervalSince1970
        
        print("🔊 PLAYBACK ATTEMPT: \(audioData.count) bytes, hash: \(currentAudioHash), time: \(timestamp)")
        
        // 🔧 NEW: Skip the first audio chunk to prevent simultaneous playback
        audioChunkCount += 1
        
        if isNewAIResponse && audioChunkCount == 1 {
            print("⏭️ SKIPPING FIRST CHUNK: Discarding first audio chunk to prevent overlap (chunk #\(audioChunkCount))")
            isNewAIResponse = false // Reset the flag after handling the first chunk
            return
        }
        
        // Reset flag for subsequent chunks
        if isNewAIResponse {
            isNewAIResponse = false
        }
        
        print("✅ PLAYBACK PROCEEDING: Audio chunk #\(audioChunkCount) (hash: \(currentAudioHash))")
        
        await scheduleAudioChunk(audioData, hash: currentAudioHash)
    }
    
    private func scheduleAudioChunk(_ audioData: Data, hash: Int) async {
        // 🔧 IMPROVED: Track active chunks for throttling
        activeAudioChunkCount += 1
        
        // Mark AI as speaking (for echo prevention)
        isAISpeaking = true
        lastAISpeechTime = Date()
        
        guard validateAudioData(audioData) else {
            await finishAudioChunk(hash: hash)
            return
        }
        
        guard let playerNode = playbackPlayerNode else {
            print("❌ PLAYBACK FAILED: Player node is nil")
            await finishAudioChunk(hash: hash)
            return
        }
        
        guard let playbackEngine = playbackEngine else {
            print("❌ PLAYBACK FAILED: Playback engine is nil")
            await finishAudioChunk(hash: hash)
            return
        }
        
        // 🔍 DIAGNOSTIC: Check engine state when audio arrives
        print("🔍 ENGINE STATE ON PLAYBACK: Engine running: \(playbackEngine.isRunning), Node playing: \(playerNode.isPlaying)")
        
        if !playbackEngine.isRunning {
            print("⚠️ WARNING: Playback engine not running when audio chunk arrived!")
        }
        
        if !playerNode.isPlaying {
            print("⚠️ WARNING: Player node not playing when audio chunk arrived!")
        }
        
        // Set normal volume - echo cancellation handles feedback
        playerNode.volume = 1.0
        
        // Gemini returns 24kHz 16-bit mono PCM
        let geminiAudioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: true
        )!
        
        guard let targetFormat = cachedTargetFormat else {
            isAISpeaking = false
            return
        }
        
        // Create and fill source buffer
        let frameCount = UInt32(audioData.count / 2)
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: geminiAudioFormat, frameCapacity: frameCount) else {
            isAISpeaking = false
            return
        }
        
        sourceBuffer.frameLength = frameCount
        audioData.withUnsafeBytes { bytes in
            guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                  let channelData = sourceBuffer.int16ChannelData else { return }
            channelData[0].update(from: int16Pointer, count: Int(frameCount))
        }
        
        // Convert to target format
        let convertedFrameCount = AVAudioFrameCount(Double(frameCount) * targetFormat.sampleRate / geminiAudioFormat.sampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: convertedFrameCount),
              let converter = playbackConverter else {
            isAISpeaking = false
            return
        }
        
        var conversionError: NSError?
        let conversionStatus = converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        
        guard conversionStatus != .error else {
            print("❌ Audio conversion failed: \(conversionError?.localizedDescription ?? "Unknown")")
            isAISpeaking = false
            return
        }
        
        // ✅ Step 2.2: Send AI audio to speech recognition for transcript
        // Only if transcript is enabled and speech recognition is active
        // The AI only sends audio (not text) in AUDIO mode, so we need speech recognition to get transcripts
        if showTranscript && speechRecognitionService.isRecognizing {
            speechRecognitionService.processAIAudio(audioData, format: geminiAudioFormat)
            print("📝 AI audio sent to speech recognition for transcript")
        }
        
        // ✅ Enhanced volume update with adaptive tracking
        let volume = calculateAudioVolume(from: convertedBuffer)
        await MainActor.run {
            // Update volume with smoothing to prevent jarring changes
            let smoothedVolume = (self.currentAudioVolume * 0.3) + (volume * 0.7)
            self.currentAudioVolume = max(smoothedVolume, 0.1) // Ensure minimum movement during speech
            
            // Update tracking variables
            self.lastVolumeUpdate = Date()
            self.isActivelySpeaking = true
            
            // Update peak tracking for dynamic range
            if volume > self.peakVolume {
                self.peakVolume = volume
            }
        }
        print("🎵 ENHANCED AUDIO VOLUME: \(volume) -> smoothed: \(currentAudioVolume)")
        
        // ✅ Start enhanced volume monitoring while audio is playing
        await MainActor.run {
            self.startVolumeMonitoring()
        }
        
        // Schedule buffer with completion handler
        let scheduleTime = Date()
        playerNode.scheduleBuffer(convertedBuffer) {
            // Mark AI as finished speaking
            Task { @MainActor in
                let completionTime = Date()
                let playbackDuration = completionTime.timeIntervalSince(scheduleTime)
                await self.finishAudioChunk(hash: hash)
                print("🎵 AUDIO CHUNK FINISHED: Playback completed for hash: \(hash) (duration: \(String(format: "%.3f", playbackDuration))s)")
            }
        }
        
        print("✅ AUDIO SCHEDULED: Buffer queued for playback (hash: \(hash)) at \(scheduleTime.timeIntervalSince1970)")
    }
    
    // ✅ Enhanced completion tracking with better speaking state management
    private func finishAudioChunk(hash: Int) async {
        isAISpeaking = false
        lastAISpeechTime = Date()
        activeAudioChunkCount = max(0, activeAudioChunkCount - 1)
        
        // Mark that the next incoming audio will be a new AI response when no chunks are active
        if activeAudioChunkCount == 0 {
            isNewAIResponse = true
            audioChunkCount = 0 // Reset for next AI response
            print("🎵 AUDIO PLAYBACK COMPLETE: All chunks finished.")
            
            // ✅ ADD THIS LINE: Tell the speech recognizer to process its final buffer.
            speechRecognitionService.finalizeCurrentAudioProcessing()
            
            // ✅ Enhanced speaking state management
            await MainActor.run {
                self.isActivelySpeaking = false
                // Don't immediately stop volume monitoring - let it decay naturally
                // This prevents abrupt mouth closure
            }
            
            // Delayed cleanup to allow natural mouth movement completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.isActivelySpeaking && self.activeAudioChunkCount == 0 {
                    // Only stop if still not speaking after delay
                    self.stopVolumeMonitoring()
                }
            }
        } else {
            print("🎵 AUDIO CHUNK FINISHED: \(activeAudioChunkCount) chunks still active")
        }
    }
    
    // ✅ Enhanced volume calculation with frequency analysis for more natural mouth movement
    private func calculateAudioVolume(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        var peak: Float = 0.0
        var rmsSum: Float = 0.0
        
        // Analyze both average volume and peak values for more dynamic movement
        for i in 0..<frameLength {
            let sample = abs(channelData[i])
            sum += sample
            peak = max(peak, sample)
            rmsSum += sample * sample
        }
        
        let average = sum / Float(frameLength)
        let rms = sqrt(rmsSum / Float(frameLength))
        
        // Combine average and RMS for more responsive mouth movement
        let combinedVolume = (average * 0.7) + (rms * 0.3)
        
        // Dynamic amplification based on content (more sensitive to speech)
        var amplified = combinedVolume * 4.0
        
        // Add peak influence for consonants and sharp sounds
        if peak > average * 2.0 {
            amplified += peak * 0.5
        }
        
        // Ensure volume stays in reasonable range with better scaling
        let finalVolume = min(1.0, max(0.05, amplified)) // Minimum 0.05 to keep subtle movement
        
        print("🎵 ENHANCED VOLUME: avg=\(average), rms=\(rms), peak=\(peak), final=\(finalVolume)")
        return finalVolume
    }
    
    // ✅ CRITICAL FIX: Voice Activity Detection - Calculate volume from raw audio data
    private func calculateAudioVolumeFromData(_ audioData: Data) -> Float {
        guard audioData.count >= 2 else { return 0.0 } // Need at least 1 sample (2 bytes for 16-bit)
        
        // Convert Data to 16-bit PCM samples
        let sampleCount = audioData.count / 2 // 16-bit = 2 bytes per sample
        var sum: Float = 0.0
        var peak: Float = 0.0
        var rmsSum: Float = 0.0
        
        audioData.withUnsafeBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            for i in 0..<sampleCount {
                let sample = Float(samples[i]) / 32768.0 // Normalize to -1.0 to 1.0
                let absoluteSample = abs(sample)
                sum += absoluteSample
                peak = max(peak, absoluteSample)
                rmsSum += absoluteSample * absoluteSample
            }
        }
        
        let average = sampleCount > 0 ? sum / Float(sampleCount) : 0.0
        let rms = sampleCount > 0 ? sqrt(rmsSum / Float(sampleCount)) : 0.0
        
        // ✅ STRICTER VAD: Enhanced speech detection algorithm
        // Combine RMS and peak analysis for better speech vs noise discrimination
        let speechIndicator = (rms * 0.7) + (peak * 0.3)
        
        // Additional filtering: require sustained energy (not just brief spikes)
        let sustainedEnergy = average > 0.02 // Minimum sustained energy
        let significantPeak = peak > 0.03 // Meaningful peak level
        
        // Only return high values for likely speech patterns
        if sustainedEnergy && significantPeak {
            return min(1.0, speechIndicator * 2.0) // Amplify speech signals
        } else {
            return speechIndicator * 0.5 // Reduce noise signals
        }
    }
    
    // ✅ CRITICAL FIX: Start silence timer to stop sending after inactivity
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeoutInterval, repeats: false) { _ in
            Task { @MainActor in
                self.isUserSpeaking = false
                self.consecutiveSpeechFrames = 0 // Reset frame counter on silence timeout
                print("🔇 VAD: Silence timeout reached - user stopped speaking")
                print("💰 VAD: Audio transmission paused - saving tokens during silence")
                
                // 🎯 CRITICAL FIX: Send turn completion signal to AI
                print("🎯 SENDING TURN COMPLETION: User finished speaking - notifying AI")
                await self.liveClient.sendTurnComplete()  // Use dedicated turn completion function
            }
        }
    }
    
    // ✅ Enhanced volume monitoring with adaptive decay and better timing
    private func startVolumeMonitoring() {
        volumeUpdateTimer?.invalidate()
        
        volumeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            // 30 FPS for smoother animation
            DispatchQueue.main.async {
                let now = Date()
                let timeSinceLastUpdate = now.timeIntervalSince(self.lastVolumeUpdate)
                
                // Adaptive decay based on speaking state and time
                if self.isActivelySpeaking {
                    // Slower decay while actively speaking to maintain movement
                    if timeSinceLastUpdate > 0.1 { // 100ms without new audio
                        self.currentAudioVolume = max(0.15, self.currentAudioVolume * 0.95) // Keep minimum movement
                    }
                } else {
                    // Faster decay when not speaking
                    self.currentAudioVolume = max(0.0, self.currentAudioVolume * self.volumeDecayRate)
                }
                
                // Update peak tracking for more natural movement
                if self.currentAudioVolume > self.peakVolume {
                    self.peakVolume = self.currentAudioVolume
                } else {
                    self.peakVolume = max(0.0, self.peakVolume * 0.98) // Gradual peak decay
                }
                
                // Stop monitoring if volume has been very low for a while
                if self.currentAudioVolume < 0.02 && !self.isActivelySpeaking {
                    self.stopVolumeMonitoring()
                }
            }
        }
        
        print("🎵 ENHANCED volume monitoring started with adaptive decay")
    }
    
    // ✅ Enhanced stop volume monitoring with gradual closure
    private func stopVolumeMonitoring() {
        print("🎵 ENHANCED stopping volume monitoring - gradual mouth closure")
        
        // Don't immediately stop - allow gradual decay first
        volumeUpdateTimer?.invalidate()
        
        // Create a final decay timer for natural mouth closure
        volumeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            DispatchQueue.main.async {
                // Faster final decay to close mouth naturally
                self.currentAudioVolume = max(0.0, self.currentAudioVolume * 0.85)
                self.peakVolume = max(0.0, self.peakVolume * 0.9)
                
                // Stop when volume is very low
                if self.currentAudioVolume < 0.01 {
                    timer.invalidate()
                    self.volumeUpdateTimer = nil
                    self.currentAudioVolume = 0.0
                    self.peakVolume = 0.0
                    self.isActivelySpeaking = false
                    print("🎵 ENHANCED mouth animation fully stopped")
                }
            }
        }
    }
    
    
    private func scheduleDelayedPlayback() {
        // No longer needed with direct scheduling approach
        // Each audio chunk is played immediately when received
    }
    
    // MARK: - Security Validation
    
    private func validateAudioData(_ data: Data) -> Bool {
        // Check data size limits (prevent memory bombs)
        guard data.count <= 10_000_000 else { // 10MB max
            print("🚨 SECURITY: Audio data too large: \(data.count) bytes")
            return false
        }
        
        // Check for minimum reasonable size
        guard data.count >= 1000 else { // 1KB minimum
            print("🚨 SECURITY: Audio data too small: \(data.count) bytes")
            return false
        }
        
        // Validate audio format (basic header check for PCM data)
        let header = data.prefix(4)
        // For PCM audio, we expect reasonable values in the first few bytes
        // This is a basic sanity check to detect obvious corrupted data
        guard !header.allSatisfy({ $0 == 0 }) else {
            print("🚨 SECURITY: Audio data appears to be empty/corrupted")
            return false
        }
        
        return true
    }
    
    // MARK: - Security Validation Methods
    
    private func validateLessonInputs() -> Bool {
        print("📝 validateLessonInputs called")
        print("   Lesson ID: '\(lessonID)'")
        print("   Lesson Title: '\(lessonTitle)'")
        print("   Lesson Number: \(lessonNumber)")
        
        // Sanitize lesson title (remove potential injection attempts)
        let sanitizedTitle = lessonTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace || ".,!?-".contains($0) }
        
        guard !sanitizedTitle.isEmpty && sanitizedTitle.count <= 100 else {
            print("🚨 SECURITY: Invalid lesson title - sanitized: '\(sanitizedTitle)', length: \(sanitizedTitle.count)")
            return false
        }
        print("✅ Lesson title valid")
        
        // Validate lesson number bounds
        guard lessonNumber >= 1 && lessonNumber <= 1000 else {
            print("🚨 SECURITY: Invalid lesson number: \(lessonNumber)")
            return false
        }
        print("✅ Lesson number valid")
        
        // Validate lesson ID format
        let sanitizedID = lessonID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isLetter || $0.isNumber || "_-".contains($0) }
        
        guard !sanitizedID.isEmpty && sanitizedID.count <= 50 else {
            print("🚨 SECURITY: Invalid lesson ID - sanitized: '\(sanitizedID)', length: \(sanitizedID.count)")
            return false
        }
        print("✅ Lesson ID valid")
        
        return true
    }
    
    private func canStartConversation() -> Bool {
        // Rate limiting disabled - always return true to prevent conversation blocking
        return true
        // let timeSinceLastStart = Date().timeIntervalSince(lastConversationStart)
        // return timeSinceLastStart >= conversationRateLimit
    }
    
    private func validateAuthentication() -> Bool {
        print("🔐 validateAuthentication called")
        
        guard authService.isSignedIn else {
            print("🚨 SECURITY: User not authenticated - isSignedIn: \(authService.isSignedIn)")
            return false
        }
        print("✅ User is signed in")
        
        guard let currentUser = authService.currentUser else {
            print("🚨 SECURITY: No current user found")
            return false
        }
        print("✅ Current user exists: \(currentUser.uid)")
        
        // Validate user ID format (Firebase UID can be 20-128 characters alphanumeric)
        let userId = currentUser.uid
        let userIdPattern = "^[a-zA-Z0-9]{20,128}$"
        guard userId.range(of: userIdPattern, options: NSString.CompareOptions.regularExpression) != nil else {
            print("🚨 SECURITY: Invalid user ID format: \(userId) (length: \(userId.count))")
            return false
        }
        print("✅ User ID format valid: \(userId)")
        
        return true
    }
    
    // MARK: - Speech Recognition Integration (Steps 1.1-1.3)
    
    /// ✅ Step 1.2: Setup speech recognition callbacks for transcript processing
    /// ✅ Step 1.2: Setup speech recognition callbacks for transcript processing
    private func setupSpeechRecognitionCallbacks() {
        print("📝 Setting up speech recognition callbacks for transcript")
        
        // Handle partial transcript updates (real-time streaming)
        speechRecognitionService.onPartialTranscript = { (partialText: String) in
            Task { @MainActor in
                // A partial result is an incomplete update
                self.updateAITranscript(with: partialText, isFinal: false)
            }
        }
        
        // Handle final transcript completion
        speechRecognitionService.onFinalTranscript = { (finalText: String) in
            Task { @MainActor in
                // A final result marks the end of an utterance
                self.updateAITranscript(with: finalText, isFinal: true)
            }
        }
        
        // Handle speech recognition errors
        speechRecognitionService.onRecognitionError = { (error: Error) in
            Task { @MainActor in
                print("❌ Speech recognition error: \(error.localizedDescription)")
                // Don't show error to user unless critical - transcript is optional feature
            }
        }
        
        print("✅ Speech recognition callbacks configured")
    }
    
    /// ✅ Step 1.3: Start speech recognition when conversation begins
    private func startSpeechRecognitionForTranscript() async {
        // Only start if transcript is enabled by user
        guard showTranscript else {
            print("📝 Transcript disabled, skipping speech recognition")
            return
        }
        
        do {
            print("📝 Starting speech recognition for AI transcript")
            
            // ✅ Enhanced: Request permissions first
            let permissionGranted = await speechRecognitionService.requestPermissions()
            guard permissionGranted else {
                print("❌ Speech recognition permission denied")
                // Show user a brief message about transcript requiring permissions
                statusText = "Transcript requires microphone permission"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.statusText = "Conversation active - speak with \(self.currentAgent.name)"
                }
                return
            }
            
            // TODO: Make language configurable based on lesson/agent
            let language = getLanguageForAgent() 
            try await speechRecognitionService.startRecognition(language: language)
            
            // ✅ Step 4.2: Set domain-specific vocabulary for better recognition
            let vocabulary = getDomainVocabularyForLesson()
            speechRecognitionService.setDomainVocabulary(vocabulary)
            
            print("✅ Speech recognition started successfully for language: \(language)")
        } catch {
            print("❌ Failed to start speech recognition: \(error.localizedDescription)")
            // Continue conversation even if transcript fails - it's an optional feature
        }
    }
    
    /// Get appropriate language for speech recognition based on agent/lesson
    private func getLanguageForAgent() -> String {
        // ✅ Step 4.2: Language selection based on agent or lesson context
        switch currentAgent.id {
        case "phoenix": // Language Master
            return "en-US" // Could be dynamic based on lesson content
        case "master-storyteller": // Story Master
            return "en-US" 
        case "money-master": // Money Master - could be business English
            return "en-US"
        case "love-coach": // Love Coach
            return "en-US"
        case "power-player": // Power Player - could be professional English
            return "en-US"
        default:
            return "en-US"
        }
        
        // TODO: Make this fully configurable based on:
        // - User's preferred language
        // - Lesson's target language
        // - Agent's specialization
        // - Conversation context
    }
    
    /// ✅ Step 4.2: Get domain-specific vocabulary for current lesson
    private func getDomainVocabularyForLesson() -> [String] {
        var vocabulary: [String] = []
        
        // Add agent-specific vocabulary
        switch currentAgent.id {
        case "money-master":
            vocabulary += ["investment", "portfolio", "dividend", "stock", "bond", "asset", "liability", "capital", "revenue", "profit", "budget", "savings", "financial", "wealth", "income", "expense"]
        case "love-coach":
            vocabulary += ["relationship", "connection", "attraction", "chemistry", "compatibility", "intimacy", "communication", "trust", "commitment", "romance", "dating", "partnership", "emotional", "empathy"]
        case "power-player":
            vocabulary += ["leadership", "strategy", "negotiation", "influence", "authority", "decision", "management", "performance", "achievement", "success", "goal", "objective", "teamwork", "collaboration"]
        case "phoenix":
            vocabulary += ["language", "grammar", "vocabulary", "pronunciation", "fluency", "conversation", "dialogue", "expression", "communication", "speaking", "listening", "comprehension"]
        case "master-storyteller":
            vocabulary += ["narrative", "character", "plot", "storytelling", "imagination", "creativity", "dialogue", "scene", "chapter", "story", "fiction", "adventure", "journey", "hero"]
        default:
            break
        }
        
        // Add lesson-specific vocabulary based on title
        let lessonWords = lessonTitle.lowercased().components(separatedBy: .whitespacesAndNewlines)
        vocabulary += lessonWords.filter { $0.count > 3 } // Add significant words from lesson title
        
        // Add category-specific vocabulary
        if let categoryName = getPracticeCategoryFromAgent() {
            switch categoryName {
            case "money":
                vocabulary += ["business", "finance", "economy", "market", "trade", "commerce"]
            case "love":
                vocabulary += ["heart", "feeling", "emotion", "care", "affection", "bond"]
            case "power":
                vocabulary += ["strength", "control", "influence", "command", "authority"]
            case "language":
                vocabulary += ["word", "sentence", "phrase", "meaning", "understanding"]
            case "story":
                vocabulary += ["tale", "adventure", "mystery", "drama", "comedy"]
            default:
                break
            }
        }
        
        print("📝 Domain vocabulary set for \(currentAgent.name): \(vocabulary.count) terms")
        return vocabulary
    }
    
    /// ✅ Step 1.3: Stop speech recognition when conversation ends
    private func stopSpeechRecognitionForTranscript() {
        print("📝 Stopping speech recognition for transcript")
        speechRecognitionService.stopRecognition()
        print("✅ Speech recognition stopped")
    }
    
    private func sanitizeErrorMessage(_ message: String) -> String {
        // Remove potential sensitive information from error messages
        return message
            .replacingOccurrences(of: authService.currentUser?.uid ?? "", with: "[USER_ID]")
            .replacingOccurrences(of: authService.currentUser?.email ?? "", with: "[USER_EMAIL]")
            .prefix(200) // Limit error message length
            .description
    }
}

struct AgentView: View {
    let agentType: LessonAgentType
    let isActive: Bool
    let isSpeaking: Bool
    let audioVolume: Float
    
    var currentAgent: Agent {
        agentType.agent
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Agent face using BasicFace component
            BasicFace(
                agent: currentAgent,
                radius: 100,
                showGlow: isActive,
                isSpeaking: isSpeaking,
                externalAudioVolume: audioVolume
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
            
            // Agent info + status (lowered slightly)
            VStack(spacing: 10) {
                Text(currentAgent.name)
                    .font(.title2)
                    .fontWeight(.bold)

                // Status indicator
                HStack {
                    Circle()
                        .fill(isActive ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut, value: isActive)

                    Text(isActive ? "Active" : "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Simulation Agent View (for dynamically created agents)

struct SimulationAgentView: View {
    let agent: Agent
    let isActive: Bool
    let isSpeaking: Bool
    let audioVolume: Float
    
    var body: some View {
        VStack(spacing: 20) {
            // Agent face using BasicFace component
            BasicFace(
                agent: agent,
                radius: 100,
                showGlow: isActive,
                isSpeaking: isSpeaking,
                externalAudioVolume: audioVolume
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
            
            // Agent info + status (lowered slightly)
            VStack(spacing: 10) {
                Text(agent.name)
                    .font(.title2)
                    .fontWeight(.bold)

                // Status indicator
                HStack {
                    Circle()
                        .fill(isActive ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut, value: isActive)

                    Text(isActive ? "Active" : "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Congratulations View

struct CongratulationsView: View {
    let lessonTitle: String
    let agentName: String
    let xpEarned: Int
    let duration: TimeInterval
    let onContinue: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Celebration Icon
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
                    
                    Text("Congratulations!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Lesson Completion Info
                VStack(spacing: 16) {
                    Text("You completed:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(lessonTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("with \(agentName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Stats Cards
                HStack(spacing: 20) {
                    StatCard(
                        icon: "star.fill",
                        value: "\(xpEarned)",
                        label: "XP Earned",
                        color: .orange
                    )
                    
                    StatCard(
                        icon: "clock.fill",
                        value: formattedDuration,
                        label: "Duration",
                        color: .blue
                    )
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    onContinue()
                    dismiss()
                }) {
                    HStack {
                        Text("Continue Learning")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Lesson Complete")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onContinue()
                        dismiss()
                    }
                }
            }
#endif
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Session Monitoring Extension for 10-minute limit handling

extension LessonView {
    
    /// Start monitoring session to prevent 10-minute WebSocket disconnection
    private func startSessionMonitoring() {
        sessionTimer?.invalidate()
        
        // Schedule proactive refresh 8 minutes after starting
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionRefreshInterval, repeats: false) { _ in
            Task { @MainActor in
                await self.handleSessionRefresh()
            }
        }
        
        print("🔄 Session monitoring started - will refresh in \(sessionRefreshInterval/60) minutes")
    }
    
    /// Handle proactive session refresh before 10-minute limit
    private func handleSessionRefresh() async {
        guard isConversationActive,
              let startTime = conversationStartTime,
              !isRefreshing else { return }
        
        let sessionAge = Date().timeIntervalSince(startTime)
        
        print("🔄 Session refresh triggered - age: \(Int(sessionAge/60)) minutes")
        
        // Set refreshing flag to prevent concurrent refreshes
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Increment refresh counter
        sessionRefreshCount += 1
        
        // Show user-friendly message
        statusText = "Refreshing connection for optimal performance..."
        
        // Brief delay for UI feedback
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Restart the conversation seamlessly
        await refreshConversationSession()
    }
    
    /// Refresh conversation session using session resumption to preserve context
    private func refreshConversationSession() async {
        print("🔄 Refreshing conversation session with context preservation (refresh #\(sessionRefreshCount))")
        
        // Store current conversation state
        let wasActive = isConversationActive
        
        if wasActive {
            statusText = "Preserving conversation context..."
            
            // Use the enhanced session resumption from GeminiLiveClient
            // This will preserve the conversation context through Google's session resumption feature
            await liveClient.reconnectWithSessionResumption()
            
            // Check if reconnection was successful
            if liveClient.isConnected {
                // CRITICAL FIX: Stop existing audio engines before restarting to prevent conflicts
                print("🔄 Stopping existing audio engines before restart...")
                stopAudioStreaming()
                
                // Brief delay to ensure cleanup is complete
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                
                print("🔄 Restarting audio streaming after session refresh...")
                try? await startAudioStreaming()
                print("✅ Audio streaming restarted successfully")
                
                // Update status
                statusText = "Connected - conversation continues"
                
                print("✅ Session refreshed with context preservation")
                
            } else {
                // Fallback to manual restart if session resumption fails
                print("⚠️ Session resumption failed, falling back to manual restart")
                await fallbackSessionRestart()
            }
        }
    }
    
    /// Fallback method for manual session restart if resumption fails
    private func fallbackSessionRestart() async {
        print("🔄 Performing fallback session restart")
        
        let currentAgent = self.currentAgent
        let agentTypeString = getAgentTypeString()
        
        // Stop current conversation and clean up audio engines properly
        stopAudioStreaming()
        await liveClient.stop()
        
        // Brief pause to ensure complete cleanup
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Reset monitoring
        conversationStartTime = Date()
        startSessionMonitoring()
        startDisplayTimer() // Restart display timer
        
        // Create refreshed system prompt
        let systemPrompt: String
        if isSimulation {
            systemPrompt = createCleanSimulationPrompt(
                agent: currentAgent,
                enhancedContext: getEnhancedSimulationContext()
            )
        } else {
            systemPrompt = SystemInstructions.createForLesson(
                agent: currentAgent,
                user: GameProgressManager.shared.currentUser
            )
        }
        
        // Add refresh context to prompt
        let refreshedPrompt = systemPrompt + """
        
        [SESSION REFRESH: This is a continuation of our conversation. The connection was refreshed for optimal performance. Please continue naturally from where we left off.]
        """
        
        // Get voice preference
        let voiceToUse: String? = {
            if isSimulation && !characterVoice.isEmpty {
                return characterVoice
            } else if isSimulation && simulationAgent != nil {
                return simulationAgent!.voice.rawValue
            } else {
                return nil
            }
        }()
        
        do {
            // Restart the connection
            try await liveClient.start(
                systemPrompt: refreshedPrompt,
                agentType: agentTypeString,
                voiceName: voiceToUse,
                onAudioOut: { audioData in
                    Task { @MainActor in
                        await self.playAudioResponse(audioData)
                    }
                },
                onTextOut: { textChunk in
                    // DO NOTHING HERE. This prevents the server's transcript from interfering.
                }
            )
            
            // CRITICAL FIX: Restart audio streaming after WebSocket reconnection
            print("🔄 Restarting audio streaming after session refresh...")
            try await startAudioStreaming()
            print("✅ Audio streaming restarted successfully")
            
            // Update status
            statusText = "Connected - conversation continues"
            
            print("✅ Fallback session restart completed")
            
        } catch {
            print("❌ Fallback session restart failed: \(error)")
            statusText = "Connection refreshed - tap to continue"
            isConversationActive = false
        }
    }
    
    /// Stop session monitoring when conversation ends
    private func stopSessionMonitoring() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        conversationStartTime = nil
        sessionRefreshCount = 0
        print("🛑 Session monitoring stopped")
    }
    
    // MARK: - Display Timer Methods
    
    /// Start the display timer to update elapsed time
    private func startDisplayTimer() {
        displayTimer?.invalidate()
        elapsedTime = 0
        formattedElapsedTime = "00:00"
        
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateDisplayTimer()
            }
        }
        
        print("⏱️ Display timer started")
    }
    
    /// Update the display timer every second
    private func updateDisplayTimer() {
        guard let startTime = conversationStartTime else { return }
        
        elapsedTime = Date().timeIntervalSince(startTime)
        
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        formattedElapsedTime = String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Stop the display timer
    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
        elapsedTime = 0
        formattedElapsedTime = "00:00"
        print("⏱️ Display timer stopped")
    }
}
