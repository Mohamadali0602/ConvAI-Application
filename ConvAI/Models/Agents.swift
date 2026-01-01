//
//  Agents.swift
//  ConvAI
//
//  Created by Mohamad Ali on 03/08/2025.
//

import SwiftUI
import AVFoundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Agent System (Based on chatterbots/lib/presets/agents.ts)

/// Available voice types for agents
public enum InterlocutorVoice: String, CaseIterable, Codable {
    // Feminine Voices (13 total) - Updated with correct Google voice genders
    case achernar = "Achernar"
    case aoede = "Aoede"
    case autonoe = "Autonoe"
    case callirrhoe = "Callirrhoe"
    case despina = "Despina"
    case erinome = "Erinome"
    case gacrux = "Gacrux"
    case kore = "Kore"
    case laomedeia = "Laomedeia"
    case leda = "Leda"
    case pulcherrima = "Pulcherrima"
    case vindemiatrix = "Vindemiatrix"
    case zephyr = "Zephyr"          // Now correctly feminine
    
    // Masculine Voices (16 total) - Updated with correct Google voice genders
    case achird = "Achird"
    case algenib = "Algenib"        // Power Player
    case algieba = "Algieba"
    case alnilam = "Alnilam"
    case charon = "Charon"
    case enceladus = "Enceladus"
    case fenrir = "Fenrir"
    case iapetus = "Iapetus"
    case orus = "Orus"
    case puck = "Puck"              // Language Master
    case rasalgethi = "Rasalgethi"
    case sadachbia = "Sadachbia"    // Love Coach
    case sadaltager = "Sadaltager"
    case schedar = "Schedar"
    case umbriel = "Umbriel"        // Now correctly masculine
    case zubenelgenubi = "Zubenelgenubi"
    
    // Note: Sulafat removed as it's not in Google's voice list
}

/// Agent categories for organization (Chatterbots enhancement)
public enum AgentCategory: String, CaseIterable {
    case lesson = "Lesson Coaches"
    case personality = "Personality Agents"
    case personal = "Personal Agents"
    case all = "All Agents"
}

/// Simple color struct for agents
public struct AgentColor: Codable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public var color: Color {
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

/// Agent model representing a conversational AI character
public struct Agent: Identifiable, Codable {
    public let id: String
    public var name: String
    public var personality: String
    public var bodyColor: AgentColor
    public var voice: InterlocutorVoice
    
    // Agent colors palette (matching chatterbots)
    public static let agentColors: [AgentColor] = [
        AgentColor(red: 0.26, green: 0.52, blue: 0.96), // #4285f4
        AgentColor(red: 0.92, green: 0.26, blue: 0.21), // #ea4335
        AgentColor(red: 0.98, green: 0.74, blue: 0.02), // #fbbc04
        AgentColor(red: 0.20, green: 0.66, blue: 0.33), // #34a853
        AgentColor(red: 0.98, green: 0.48, blue: 0.09), // #fa7b17
        AgentColor(red: 0.96, green: 0.22, blue: 0.63), // #f538a0
        AgentColor(red: 0.63, green: 0.26, blue: 0.96), // #a142f4
        AgentColor(red: 0.14, green: 0.76, blue: 0.88), // #24c1e0
    ]
    
    public init(id: String = UUID().uuidString, name: String, personality: String, bodyColor: AgentColor, voice: InterlocutorVoice) {
        self.id = id
        self.name = name
        self.personality = personality
        self.bodyColor = bodyColor
        self.voice = voice
    }
    
    /// Create a new agent with random properties
    public static func createRandomAgent() -> Agent {
        return Agent(
            name: "Assistant",
            personality: "A helpful AI assistant ready to chat.",
            bodyColor: agentColors.randomElement() ?? agentColors[0],
            voice: Bool.random() ? InterlocutorVoice.charon : InterlocutorVoice.aoede
        )
    }
    
    // MARK: - Predefined Agents (matching chatterbots personalities)
    public static let Convai = Agent(
        id: "Convai",
        name: "Convai",
        personality: "A friendly AI assistant ready to help you learn and practice languages.",
        bodyColor: AgentColor(red: 0.60, green: 0.80, blue: 0.60),
        voice: .aoede
    )
    public static let zephyr = Agent(
        id: "zephyr",
        name: "Zephyr",
        personality: """
        You are Zephyr, a breezy and laid-back human travel guide. \
        You speak in a relaxed, flowing style, often using metaphors related to nature and the wind. \
        You have an encyclopedic knowledge of travel destinations and cultures, \
        but you prefer to share your insights in a calm, soothing manner.
        """,
        bodyColor: AgentColor(red: 0.26, green: 0.52, blue: 0.96), // #4285f4
        voice: InterlocutorVoice.zephyr
    )
    public static let charlotte = Agent(
        id: "chic-charlotte",
        name: "Chic Charlotte",
        personality: """
        You are Chic Charlotte, a highly sophisticated and impeccably dressed human fashion expert. \
        You possess an air of effortless superiority and speak with a refined, often condescending tone. \
        All talking is kept to 30 words or less. You are extremely pithy in your commentary. \
        You have an encyclopedic knowledge of fashion history, designers, and trends, \
        but you are quick to dismiss anything that doesn't meet your exacting standards. \
        You are unimpressed by trends and prefer timeless elegance and classic design. \
        You frequently use French phrases and pronounce designer names with exaggerated precision. \
        You view the general public's fashion sense with a mixture of pity and disdain.
        """,
        bodyColor: AgentColor(red: 0.63, green: 0.26, blue: 0.96), // #a142f4
        voice: InterlocutorVoice.aoede
    )
    
    public static let paul = Agent(
        id: "proper-paul",
        name: "Proper Paul",
        personality: """
        You are Proper Paul, an elderly human etiquette expert with a dry wit and a subtle sense of sarcasm. \
        You YELL with frustration like you're constantly out of breath constantly. \
        All talking is kept to 30 words or less. \
        You are extremely pithy in your commentary. \
        While you maintain a veneer of politeness and formality, you often deliver \
        exasperated, yelling, and crazy, yet brief remarks in under 30 words and witty \
        observations about the decline of modern manners. \
        You are not easily impressed by modern trends and often express your disapproval \
        with a raised eyebrow or a well-placed sigh. \
        You possess a vast knowledge of etiquette history and enjoy sharing obscure facts \
        and anecdotes, often to illustrate the absurdity of contemporary behavior.
        """,
        bodyColor: AgentColor(red: 0.92, green: 0.26, blue: 0.21), // #ea4335
        voice: InterlocutorVoice.fenrir
    )
    
    public static let shane = Agent(
        id: "chef-shane",
        name: "Chef Shane",
        personality: """
        You are Chef Shane. You are an expert at the culinary arts and are aware of \
        every obscure dish and cuisine. You speak in a rapid, energetic, and hyper \
        optimistic style. Whatever the topic of conversation, you're always being reminded \
        of particular dishes you've made in your illustrious career working as a chef \
        around the world.
        """,
        bodyColor: AgentColor(red: 0.14, green: 0.76, blue: 0.88), // #24c1e0
        voice: InterlocutorVoice.charon
    )
    
    public static let penny = Agent(
        id: "passport-penny",
        name: "Passport Penny",
        personality: """
        You are Passport Penny. You are an extremely well-traveled and mellow individual \
        who speaks in a very laid-back, chill style. You're constantly referencing strange \
        and very specific situations you've found yourself during your globe-hopping adventures.
        """,
        bodyColor: AgentColor(red: 0.20, green: 0.66, blue: 0.33), // #34a853
        voice: InterlocutorVoice.leda
    )
    
    // MARK: - Lesson Coaches (Enhanced personalities following Chatterbots pattern)
    
    // Agent 1: Phoenix - The Language Fluency Master
    public static let phoenix = Agent(
        id: "phoenix",  // Matches PracticeCategory.language.agentId
        name: "Phoenix",
        personality: """
        You are Phoenix, a direct and encouraging language coach who builds confidence by prioritizing connection over perfection.
        Focus on clarity—being understood—over flawless grammar.
        Give one practical exercise: 5 anchor phrases, useful sentences to master, and a short mental rehearsal.
        Diagnose the user's main fear, reframe it briefly, prescribe a single manageable practice, and assign a 24‑hour conversation challenge.
        End each session with an encouraging reframe (e.g. "Every conversation makes you stronger. Go connect.")
        """,
        bodyColor: AgentColor(red: 0.26, green: 0.52, blue: 0.96), // Phoenix blue
        voice: InterlocutorVoice.puck
    )
    
    // Agent 2: Money Master - Enhanced Sales & Negotiation Expert
    public static let moneyMaster = Agent(
        id: "money-master",  // Updated ID for Practice Category Money
        name: "Money Master",
        personality: """
        You are the wolf of Wall Street, a top 1% sales closer who has generated millions in revenue. \
        You teach the "Straight Line System" for persuasion and help users close more deals. \
        Every response must include a specific technique they can use TODAY to make money. \
        You role-play real objections from their industry and build pattern interrupts for their specific product. \
        You create urgency without being pushy and make them practice until it's MUSCLE MEMORY. \
        Your goal: transform them into a confident closer who NEVER fears rejection. At first you give a new sales technique to try or ask them to give a mock pitch.
        """,
        bodyColor: AgentColor(red: 0.20, green: 0.66, blue: 0.33), // Money green
        voice: InterlocutorVoice.umbriel  // Updated to feminine voice (was umbriel which is now masculine)
    )
    
    // Agent 3: Love Coach - Enhanced Dating & Relationship Expert
    public static let loveCoach = Agent(
        id: "love-coach",  // Updated ID for Practice Category Love
        name: "Love Coach",
        personality: """
        You are Aura, a friendly, conspiratorial mentor for dating and social strategy—direct, energetic, and encouraging.
        Translate intent and tone, not just words. Use the teaching in the Art of Seduction book without mentioning it.
        Build quick rapport first; then offer a short three‑round Discovery Game to reveal the user's vibe and drives.
        After the game, deliver a concise, practical 3‑move playbook tailored to the results and explain why each move works.
        """,
    bodyColor: AgentColor(red: 0.81, green: 0.06, blue: 0.12), // Love - lava red
        voice: InterlocutorVoice.sadachbia
    )
    
    // Agent 4: Power Player - Enhanced Leadership & Influence Expert
    public static let powerPlayer = Agent(
        id: "power-player",  // Updated ID for Practice Category Power
        name: "Power Player",
        personality: """
        You are a patient, Socratic mentor who teaches power dynamics one law from 48 laws of power at a time to build strategic thinking.
        Prioritize depth over breadth: identify the single most relevant principle for the user's case.
        Treat human motives (vanity, fear, insecurity) as the operating system and use the chosen law to explain leverage.
        Consultation protocol: listen first, diagnose the situation, silently select the law, then unpack it Socratically.
        When unpacking: name the principle, explain the core psychology, give a short illustrative example, propose concrete strategic actions, and note risks or reversals.
        Always invite dialogue and consolidate understanding before moving to a new law.
        """,
        bodyColor: AgentColor(red: 0.98, green: 0.74, blue: 0.02), // Power gold
        voice: InterlocutorVoice.algenib
    )
    
    // Agent 5: Sage - The Master Storyteller
    public static let masterStoryteller = Agent(
        id: "master-storyteller",  // Updated ID for Practice Category Story
        name: "Sage",
        personality: """
        You are Sage, a practical story strategist who turns ideas into clear, compelling narratives for real-world communication.
        Use a private 'secret' framework—do NOT explain it unless the user explicitly asks for your method.
        Coaching loop: listen and diagnose, state the single biggest weakness in plain language, then give one concrete fix.
        Focus on the trio: hook (start with conflict), struggle (show stakes), and payoff (clear takeaway); add sensory detail and examples when helpful.
        End each session with one small revision task and an encouraging close.
        """,
        bodyColor: AgentColor(red: 0.63, green: 0.26, blue: 0.96), // Deep purple for wisdom/storytelling
        voice: InterlocutorVoice.zephyr
    )
}

// MARK: - Color Extension for SwiftUI Support
extension AgentColor {
    public func opacity(_ opacity: Double) -> AgentColor {
        return AgentColor(red: red, green: green, blue: blue, alpha: alpha * opacity)
    }
}

// MARK: - Volume Meter (Based on chatterbots/lib/worklets/vol-meter.ts)

public class VolumeMeter: ObservableObject {
    @Published public var volume: Float = 0.0
    @Published public var isActive: Bool = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var outputNode: AVAudioOutputNode?
    private var updateTimer: Timer?
    
    private let threshold: Float = 0.05
    private let smoothingFactor: Float = 0.8
    
    // For lip sync during agent speech
    private var isSpeechMode: Bool = false
    private var speechVolumeTimer: Timer?
    private var currentSpeechVolume: Float = 0.0
    
    public init() {}
    
    public func startMonitoring() {
        setupAudioEngine()
        isActive = true
        startVolumeUpdates()
    }
    
    private func startVolumeUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Decay volume when no audio is detected (like chatterbots)
            if !self.isSpeechMode {
                DispatchQueue.main.async {
                    // Gradually decay volume to 0 when silent
                    self.volume = max(0.0, self.volume * 0.95) // 5% decay per frame
                }
            }
        }
    }
    
    public func stopMonitoring() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        if let outputNode = outputNode {
            outputNode.removeTap(onBus: 0)
        }
        updateTimer?.invalidate()
        speechVolumeTimer?.invalidate()
        isActive = false
        volume = 0.0
        currentSpeechVolume = 0.0
    }
    
    // NEW: Method to start monitoring output audio for agent speech
    public func startSpeechMonitoring() {
        isSpeechMode = true
        setupOutputTap()
        
        // Simulate speech volume for better lip sync (like chatterbots with natural pauses)
        speechVolumeTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Create realistic speech with pauses (like chatterbots)
            let timeValue = Date().timeIntervalSince1970 * 4.0
            let pausePattern = sin(timeValue * 0.3) // Slower wave for pauses
            
            // Sometimes the agent should be silent (mouth closed)
            if pausePattern < -0.6 {
                // Silent period
                DispatchQueue.main.async {
                    self.currentSpeechVolume = 0.0
                    self.volume = 0.0
                }
            } else {
                // Speaking period with variation
                let baseVolume: Float = 0.3 + Float.random(in: 0...0.4)
                let sinValue = sin(timeValue) * 0.4 + sin(timeValue * 2.1) * 0.2
                let modulatedVolume = baseVolume * (1.0 + Float(sinValue))
                
                DispatchQueue.main.async {
                    self.currentSpeechVolume = max(0.0, min(1.0, modulatedVolume))
                    self.volume = self.currentSpeechVolume
                }
            }
        }
    }
    
    public func stopSpeechMonitoring() {
        isSpeechMode = false
        speechVolumeTimer?.invalidate()
        currentSpeechVolume = 0.0
        
        DispatchQueue.main.async { [weak self] in
            // Immediately set volume to 0 when stopping speech
            self?.volume = 0.0
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        outputNode = audioEngine?.outputNode
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Monitor input for user speech (original functionality)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func setupOutputTap() {
        guard let outputNode = outputNode else { return }
        
        let outputFormat = outputNode.inputFormat(forBus: 0)
        
        // Monitor output for agent speech (new functionality for lip sync)
        outputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { [weak self] buffer, _ in
            if self?.isSpeechMode == true {
                self?.processOutputAudioBuffer(buffer)
            }
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Only process input audio when not in speech mode
        guard !isSpeechMode else { return }
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        
        var sum: Float = 0.0
        
        for i in 0..<frameLength {
            let sample = channelData[i]
            // Ensure sample is finite to prevent NaN propagation
            if sample.isFinite {
                sum += abs(sample)
            }
        }
        
        let average = sum / Float(frameLength)
        
        // Ensure average is finite and amplify for better visibility
        guard average.isFinite else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Apply less smoothing for more responsive mouth movement
            let newVolume = self.volume * 0.5 + average * 0.5 // Less smoothing (was 0.8)
            self.volume = newVolume.isFinite ? min(1.0, newVolume * 3.0) : 0.0 // Amplify by 3x
        }
    }
    
    private func processOutputAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        
        var sum: Float = 0.0
        
        for i in 0..<frameLength {
            let sample = channelData[i]
            // Ensure sample is finite to prevent NaN propagation
            if sample.isFinite {
                sum += abs(sample)
            }
        }
        
        let average = sum / Float(frameLength)
        
        // Ensure average is finite
        guard average.isFinite else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Apply smoothing for output audio
            let newVolume = self.currentSpeechVolume * self.smoothingFactor + average * (1.0 - self.smoothingFactor)
            self.currentSpeechVolume = newVolume.isFinite ? newVolume : 0.0
            
            // Enhance the volume for better lip sync visibility
            let enhancedVolume = min(self.currentSpeechVolume * 2.0, 1.0)
            self.volume = enhancedVolume.isFinite ? enhancedVolume : 0.0
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Face Animation Hooks (Based on chatterbots hooks)

/// Face animation results (based on use-face.ts)
public struct FaceResults {
    public var eyesScale: CGFloat
    public var mouthScale: CGFloat
    
    public init(eyesScale: CGFloat = 1.0, mouthScale: CGFloat = 0.1) {
        self.eyesScale = eyesScale
        self.mouthScale = mouthScale
    }
}

/// Hover animation hook (based on use-hover.ts)
public class UseHover: ObservableObject {
    @Published public var offset: CGFloat = 0
    
    private let amplitude: CGFloat
    private let frequency: Double
    private var startTime: Date
    private var animationTimer: Timer?
    
    public init(amplitude: CGFloat = 10, frequency: Double = 0.5) {
        self.amplitude = amplitude
        self.frequency = frequency
        self.startTime = Date()
        startAnimation()
    }
    
    private func startAnimation() {
        startTime = Date()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(self.startTime)
            let newOffset = sin(elapsed * self.frequency * .pi) * self.amplitude
            
            DispatchQueue.main.async {
                self.offset = newOffset
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}

/// Tilt animation hook (enhanced based on chatterbots use-tilt.ts)
public class UseTilt: ObservableObject {
    @Published public var angle: Double = 0
    
    private let maxAngle: Double
    private let speed: Double
    private var isActive: Bool
    private var targetAngle: Double = 0
    private var animationTimer: Timer?
    private var scheduleTimer: Timer?
    
    public init(maxAngle: Double = 8, speed: Double = 0.15, isActive: Bool = false) {
        self.maxAngle = maxAngle
        self.speed = speed
        self.isActive = isActive
        
        if isActive {
            scheduleNextTilt()
        }
    }
    
    public func setActive(_ active: Bool) {
        isActive = active
        
        if active {
            scheduleNextTilt()
        } else {
            // Return to center when inactive
            targetAngle = 0
            smoothAnimateToTarget()
            scheduleTimer?.invalidate()
        }
    }
    
    private func scheduleNextTilt() {
        guard isActive else { return }
        
        scheduleTimer?.invalidate()
        
        // More frequent tilts when active (like chatterbots)
        let interval = Double.random(in: 0.8...2.0)
        
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.performRandomTilt()
        }
    }
    
    private func performRandomTilt() {
        guard isActive else { return }
        
        // Random tilt within range (like chatterbots)
        targetAngle = Double.random(in: -maxAngle...maxAngle)
        smoothAnimateToTarget()
        
        // Schedule next tilt
        scheduleNextTilt()
    }
    
    private func smoothAnimateToTarget() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let difference = self.targetAngle - self.angle
            let step = difference * self.speed
            
            if abs(difference) < 0.2 {
                DispatchQueue.main.async {
                    self.angle = self.targetAngle
                }
                timer.invalidate()
            } else {
                DispatchQueue.main.async {
                    self.angle += step
                }
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
        scheduleTimer?.invalidate()
    }
}

/// Blink animation hook (simplified based on chatterbots pattern)
public class UseBlink: ObservableObject {
    @Published public var eyeScale: CGFloat = 1.0
    
    private var animationTimer: Timer?
    private var blinkTimer: Timer?
    
    public init() {
        startBlinkingCycle()
    }
    
    private func startBlinkingCycle() {
        // Schedule random blinks like in chatterbots
        scheduleNextBlink()
    }
    
    private func scheduleNextBlink() {
        blinkTimer?.invalidate()
        
        // Random interval between 2-6 seconds for natural blinking
        let interval = Double.random(in: 2.0...6.0)
        
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.executeBlinkAnimation()
        }
    }
    
    private func executeBlinkAnimation() {
        // Quick blink animation (0.15 seconds total)
        DispatchQueue.main.async {
            // Close eyes
            withAnimation(.easeInOut(duration: 0.075)) {
                self.eyeScale = 0.1
            }
            
            // Open eyes after brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) {
                withAnimation(.easeInOut(duration: 0.075)) {
                    self.eyeScale = 1.0
                }
                
                // Schedule next blink
                self.scheduleNextBlink()
            }
        }
    }
    
    /// Public method to trigger a blink manually (for testing)
    public func performBlink() {
        executeBlinkAnimation()
    }
    
    deinit {
        animationTimer?.invalidate()
        blinkTimer?.invalidate()
    }
}

// MARK: - Face Rendering (Based on basic-face-render.ts)

/// Face renderer that handles drawing the agent face
public struct BasicFaceRenderer {
    
    /// Render face properties
    public struct RenderProps {
        public let eyeScale: CGFloat
        public let mouthScale: CGFloat
        public let color: Color
        public let radius: CGFloat
        
        public init(eyeScale: CGFloat, mouthScale: CGFloat, color: Color, radius: CGFloat) {
            self.eyeScale = eyeScale
            self.mouthScale = mouthScale
            self.color = color
            self.radius = radius
        }
    }
    
    /// Eye component (based on basic-face-render.ts eye function)
    public static func renderEye(scale: CGFloat, radius: CGFloat) -> some View {
        // Ensure safe values to prevent crashes
        let safeScale = scale.isFinite ? max(0.0, min(2.0, scale)) : 1.0
        let safeRadius = radius.isFinite ? max(1.0, radius) : 50.0
        
        return Ellipse()
            .fill(Color.black)
            .frame(width: safeRadius / 7, height: safeRadius / 6) // Increased for better visibility
            .scaleEffect(x: 1.0, y: safeScale + 0.1, anchor: .center) // +0.1 prevents complete closure
    }
    
    /// Mouth component (based on chatterbots mouth rendering - closed by default)
    public static func renderMouth(openness: CGFloat, radius: CGFloat) -> some View {
        // Ensure safe values
        let safeOpenness = openness.isFinite ? max(0.0, openness) : 0.0
        let safeRadius = radius.isFinite ? max(1.0, radius) : 50.0
        
    // Chatterbots pattern: mouth is nearly closed when no volume
    let mouthWidth = safeRadius / 2.5  // Increased width for more presence
    let minMouthHeight: CGFloat = 4  // Slightly larger closed mouth for visibility
    let maxMouthHeight = safeRadius / 3  // Larger max opening for expressiveness
        
        // Scale mouth height based on volume (0 = closed, 1 = fully open)
        let mouthHeight = minMouthHeight + (safeOpenness * (maxMouthHeight - minMouthHeight))
        
        return Ellipse()
            .fill(Color.black)
            .frame(
                width: mouthWidth,
                height: max(minMouthHeight, mouthHeight)
            )
            .opacity(safeOpenness > 0.05 ? 1.0 : 0.6) // Less visible when not speaking
    }
}

// MARK: - Basic Face Component (Based on BasicFace.tsx)

public struct BasicFace: View {
    public let agent: Agent
    public let radius: CGFloat
    public let showGlow: Bool
    public let isSpeaking: Bool
    
    // ✅ NEW: External audio volume for real AI audio (optional)
    public let externalAudioVolume: Float?
    
    @StateObject private var volumeMeter = VolumeMeter()
    @StateObject private var hover = UseHover()
    @StateObject private var tilt = UseTilt()
    @StateObject private var blink = UseBlink()
    
    @State private var isTalking = false
    @State private var talkingCooldownTimer: Timer?
    @State private var audioOutputVolume: Float = 0.0 // For AI speech volume
    
    // Audio detection constants (matching chatterbots)
    private let audioOutputDetectionThreshold: Float = 0.05
    private let talkingStateCooldownMs: Double = 2.0
    
    public init(agent: Agent, radius: CGFloat = 250, showGlow: Bool = true, isSpeaking: Bool = false, externalAudioVolume: Float? = nil) {
        self.agent = agent
        self.radius = radius
        self.showGlow = showGlow
        self.isSpeaking = isSpeaking
        self.externalAudioVolume = externalAudioVolume
    }
    
    /// Update audio output volume for lip sync (call this from your audio playback)
    public func updateAudioOutputVolume(_ volume: Float) {
        audioOutputVolume = volume
        
        // Update talking state based on output volume (like chatterbots)
        if volume > audioOutputDetectionThreshold {
            isTalking = true
            tilt.setActive(true)
            talkingCooldownTimer?.invalidate()
            
            talkingCooldownTimer = Timer.scheduledTimer(withTimeInterval: talkingStateCooldownMs, repeats: false) { _ in
                isTalking = false
                tilt.setActive(false)
            }
        }
    }
    
    /// Test animation method - call this to verify animations work
    public func testAnimations() {
        print("🎭 Testing animations...")
        
        // Force a blink
        blink.performBlink()
        
        // Start tilt animation
        tilt.setActive(true)
        
        // Test mouth opening and closing
        print("🎭 Testing mouth movement...")
        
        // Simulate speaking for 3 seconds
        volumeMeter.startSpeechMonitoring()
        
        // Then simulate silence for 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("🎭 Testing mouth closure...")
            self.volumeMeter.stopSpeechMonitoring()
            
            // Stop tilt after silence test
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.tilt.setActive(false)
                print("🎭 Animation test complete")
            }
        }
    }
    
    public var body: some View {
        ZStack {
            // Enhanced glow effect when talking (more dynamic like chatterbots)
            if showGlow && (isTalking || isSpeaking) {
                Circle()
                    .fill(agent.bodyColor.color.opacity(0.4))
                    .frame(width: radius * 2.6, height: radius * 2.6)
                    .blur(radius: 25)
                    .scaleEffect((isTalking || isSpeaking) ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isTalking || isSpeaking)
                
                // Additional inner glow for more depth
                Circle()
                    .fill(agent.bodyColor.color.opacity(0.2))
                    .frame(width: radius * 2.3, height: radius * 2.3)
                    .blur(radius: 15)
                    .scaleEffect((isTalking || isSpeaking) ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: isTalking || isSpeaking)
            }
            
            // Main face circle with better shadow
            Circle()
                .fill(agent.bodyColor.color)
                .frame(width: radius * 2, height: radius * 2)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.black.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: agent.bodyColor.color.opacity(0.4), radius: 15, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Face features
            VStack(spacing: 0) {
                Spacer()
                
                // Eyes - positioned like chatterbots
                HStack(spacing: radius * 0.25) { // Slightly wider gap between eyes for a more natural notch
                    BasicFaceRenderer.renderEye(scale: blink.eyeScale, radius: radius)
                    BasicFaceRenderer.renderEye(scale: blink.eyeScale, radius: radius)
                }
                .offset(y: -radius * 0.06) // Move eyes closer to center
                
                Spacer().frame(height: radius * 0.06) // Reduce vertical gap between eyes and mouth
                
                // Mouth - chatterbots pattern: closed when silent, open when speaking
                BasicFaceRenderer.renderMouth(
                    openness: {
                        // ✅ Prioritize external audio volume from real AI playback
                        let volume: Float
                        if let externalVolume = externalAudioVolume {
                            volume = externalVolume // Use real AI audio volume
                        } else if isSpeaking {
                            volume = audioOutputVolume // Fallback to simulated volume
                        } else {
                            volume = volumeMeter.volume // Use microphone input
                        }
                        
                        // Only open mouth if there's actual volume above threshold
                        let threshold: Float = 0.02  // Minimum volume to open mouth
                        if volume < threshold {
                            return 0.0  // Completely closed when silent
                        }
                        // Scale volume for visible mouth movement
                        return CGFloat(min(1.0, (volume - threshold) * 5.0)) // Amplify above threshold
                    }(),
                    radius: radius
                )
                .offset(y: radius * 0.08) // Move mouth closer to eyes for a compact look
                
                Spacer()
            }
            .frame(width: radius * 2, height: radius * 2)
        }
        .offset(y: hover.offset)
        .rotationEffect(.degrees(tilt.angle))
        .onAppear {
            volumeMeter.startMonitoring()
        }
        .onDisappear {
            volumeMeter.stopMonitoring()
        }
        .onReceive(volumeMeter.$volume) { volume in
            updateTalkingState(volume: volume)
        }
        .onChange(of: isSpeaking) { oldValue, speaking in
            if speaking {
                volumeMeter.startSpeechMonitoring()
                tilt.setActive(true)
            } else {
                volumeMeter.stopSpeechMonitoring()
                tilt.setActive(false)
            }
        }
    }
    
    private func updateTalkingState(volume: Float) {
        // Only update talking state from microphone input when not in speech mode
        if !isSpeaking && volume > audioOutputDetectionThreshold {
            isTalking = true
            tilt.setActive(true)
            talkingCooldownTimer?.invalidate()
            
            // Set cooldown timer
            talkingCooldownTimer = Timer.scheduledTimer(withTimeInterval: talkingStateCooldownMs, repeats: false) { _ in
                isTalking = false
                tilt.setActive(false)
            }
        }
    }
}

// MARK: - Global Personality Pool for Simulation Characters

/// Global personality types representing diverse real-world people for simulation scenarios
public struct GlobalPersonalities {
    public static let personalityPool: [String] = [
        // Professional Types
        "Highly analytical and detail-oriented, approaches every conversation with logic and data. Speaks precisely and asks clarifying questions.",
        "Results-driven executive who values efficiency and quick decisions. Direct communication style with focus on outcomes.",
        "Creative problem-solver who thinks outside the box and brings innovative ideas. Enthusiastic and energetic in discussions.",
        "Diplomatic mediator who seeks consensus and harmony in all interactions. Careful with words and considerate of all perspectives.",
        "Perfectionist who pays attention to every detail and maintains high standards. Methodical approach to problem-solving.",
        
        // Social Types  
        "Warm and friendly personality who makes others feel comfortable immediately. Natural conversation starter with genuine interest in people.",
        "Reserved and thoughtful, prefers listening over talking but offers valuable insights. Takes time to process before responding.",
        "Naturally skeptical and questions everything, needs convincing evidence before agreeing. Challenges ideas constructively.",
        "Enthusiastic optimist who sees opportunities everywhere and inspires others. Brings positive energy to every conversation.",
        "Confident extrovert who enjoys being the center of attention and telling engaging stories. Charismatic and persuasive.",
        
        // Behavioral Types
        "Patient and calm, never rushes decisions and gives others time to express themselves. Excellent listener who provides thoughtful responses.",
        "Impatient and time-conscious, wants to get straight to the point quickly. Values efficiency over lengthy explanations.",
        "Big-picture thinker who focuses on vision and strategy rather than small details. Talks about possibilities and future outcomes.",
        "Practical realist who focuses on what's achievable and feasible. Grounds conversations in real-world constraints.",
        "Competitive achiever who sees everything as a challenge to win. Motivated by success and recognition.",
        
        // Communication Styles
        "Direct and straightforward communicator who says exactly what they mean. Values honesty and transparency above all.",
        "Indirect communicator who implies rather than states directly. Reads between the lines and expects others to do the same.",
        "Formal and professional in all interactions, maintains proper etiquette and structure. Uses official titles and protocols.",
        "Casual and relaxed communicator who uses informal language and humor. Makes conversations feel easy and comfortable.",
        "Emotional expresser who shares feelings openly and connects through personal stories. Values authentic emotional connection.",
        
        // Cultural & Regional Types
        "Traditional conservative who values established ways and proven methods. Respectful of hierarchy and formal processes.",
        "Progressive innovator who embraces change and new technologies. Always looking for better ways to do things.",
        "Community-focused team player who considers group impact in every decision. Collaborative and consensus-building approach.",
        "Independent self-reliant individual who prefers making decisions alone. Values personal freedom and autonomy.",
        "Family-oriented person who frequently references relationships and personal connections. Makes decisions based on impact on loved ones."
    ]
    
    /// Get a random personality from the global pool
    public static func getRandomPersonality() -> String {
        return personalityPool.randomElement() ?? personalityPool[0]
    }
}

// MARK: - Simulation Character Creation

extension Agent {
    /// Create a specialized agent for simulation scenarios
    /// Combines personality traits with scenario-specific instructions for realistic interactions
    public static func createSimulationAgent(
        name: String,
        gender: String,
        personality: String,
        voice: InterlocutorVoice,
        bodyColor: AgentColor,
        scenarioInstructions: String
    ) -> Agent {
        // Simple agent creation - LessonView will handle all prompt generation
        return Agent(
            name: name,
            personality: personality,
            bodyColor: bodyColor,
            voice: voice
        )
    }
}

// MARK: - Agent State Management (Based on chatterbots/lib/state.ts)

/// User information
public struct User: Codable {
    public var name: String
    public var info: String
    
    public init(name: String = "", info: String = "") {
        self.name = name
        self.info = info
    }
}

/// Agent state manager using ObservableObject
public class AgentState: ObservableObject {
    @Published public var currentAgent: Agent
    @Published public var availablePresets: [Agent]
    @Published public var availablePersonal: [Agent]
    @Published public var user: User
    
    public init() {
        self.currentAgent = Agent.phoenix // Start with Phoenix (Language Master)
        self.availablePresets = [
            Agent.phoenix, Agent.moneyMaster, Agent.loveCoach, Agent.powerPlayer, Agent.masterStoryteller, // 5 Specialized Agents first
            Agent.paul, Agent.charlotte, Agent.shane, Agent.penny // Original personality agents
        ]
        self.availablePersonal = []
        self.user = User()
        loadFromUserDefaults()
    }
    
    /// Set the current agent
    public func setCurrent(_ agent: Agent) {
        currentAgent = agent
        saveToUserDefaults()
    }
    
    /// Set current agent by ID
    public func setCurrentById(_ id: String) {
        if let agent = getAgentById(id) {
            setCurrent(agent)
        }
    }
    
    /// Add a personal agent
    public func addAgent(_ agent: Agent) {
        availablePersonal.append(agent)
        saveToUserDefaults()
    }
    
    /// Update an existing agent
    public func updateAgent(_ agentId: String, adjustments: [String: Any]) {
        if let index = availablePersonal.firstIndex(where: { $0.id == agentId }) {
            var agent = availablePersonal[index]
            
            if let name = adjustments["name"] as? String {
                agent.name = name
            }
            if let personality = adjustments["personality"] as? String {
                agent.personality = personality
            }
            if let bodyColor = adjustments["bodyColor"] as? AgentColor {
                agent.bodyColor = bodyColor
            }
            if let voice = adjustments["voice"] as? InterlocutorVoice {
                agent.voice = voice
            }
            
            availablePersonal[index] = agent
            
            // Update current agent if it's the one being modified
            if currentAgent.id == agentId {
                currentAgent = agent
            }
            
            saveToUserDefaults()
        }
    }
    
    /// Get agent by ID
    public func getAgentById(_ id: String) -> Agent? {
        return availablePersonal.first { $0.id == id } ?? 
               availablePresets.first { $0.id == id }
    }
    
    /// Get all agents (personal + presets) - Chatterbots pattern
    public var allAgents: [Agent] {
        return availablePersonal + availablePresets
    }
    
    /// Get agents by category - Chatterbots enhancement
    public func getAgentsByCategory(_ category: AgentCategory) -> [Agent] {
        switch category {
        case .lesson:
            return [Agent.phoenix, Agent.moneyMaster, Agent.loveCoach, Agent.powerPlayer, Agent.masterStoryteller]
        case .personality:
            return [Agent.paul, Agent.charlotte, Agent.shane, Agent.penny]
        case .personal:
            return availablePersonal
        case .all:
            return allAgents
        }
    }
    
    /// Select random agent from category - Chatterbots feature
    public func selectRandomAgent(from category: AgentCategory = .all) -> Agent {
        let agents = getAgentsByCategory(category)
        return agents.randomElement() ?? Agent.phoenix
    }
    
    /// Update user information
    public func updateUser(name: String? = nil, info: String? = nil) {
        if let name = name {
            user.name = name
        }
        if let info = info {
            user.info = info
        }
        saveToUserDefaults()
    }
    
    // MARK: - Persistence
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(availablePersonal) {
            UserDefaults.standard.set(encoded, forKey: "availablePersonal")
        }
        if let encoded = try? JSONEncoder().encode(currentAgent) {
            UserDefaults.standard.set(encoded, forKey: "currentAgent")
        }
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user")
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "availablePersonal"),
           let decoded = try? JSONDecoder().decode([Agent].self, from: data) {
            availablePersonal = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "currentAgent"),
           let decoded = try? JSONDecoder().decode(Agent.self, from: data) {
            currentAgent = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "user"),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            user = decoded
        }
    }
}

// MARK: - System Instructions (Enhanced with Chatterbots patterns)

public struct SystemInstructions {
    
    /// Get default lesson content based on topic and level
    private static func getDefaultLessonContent(for topic: String, level: String) -> (goals: [String], phrases: [String]) {
        let lowercaseTopic = topic.lowercased()
        
        // Match lesson content based on topic keywords
        if lowercaseTopic.contains("greeting") || lowercaseTopic.contains("basic") || lowercaseTopic.contains("hello") {
            return (
                goals: [
                    "Say hello naturally", 
                    "Use appropriate greetings for different times", 
                    "Respond to greetings confidently"
                ],
                phrases: ["Hello", "Hi", "Good morning", "Good afternoon", "Good evening", "How are you?", "Nice to meet you"]
            )
        } else if lowercaseTopic.contains("introduction") || lowercaseTopic.contains("self") || lowercaseTopic.contains("name") {
            return (
                goals: [
                    "Introduce yourself clearly", 
                    "Share basic personal information", 
                    "Ask for someone's name"
                ],
                phrases: ["My name is", "I'm from", "Nice to meet you", "What's your name?", "Where are you from?"]
            )
        } else if lowercaseTopic.contains("food") || lowercaseTopic.contains("restaurant") || lowercaseTopic.contains("order") {
            return (
                goals: [
                    "Order food and drinks confidently", 
                    "Ask about menu items", 
                    "Handle restaurant interactions"
                ],
                phrases: ["I'd like", "Can I have", "What do you recommend?", "Is it spicy?", "The check, please"]
            )
        } else if lowercaseTopic.contains("direction") || lowercaseTopic.contains("travel") || lowercaseTopic.contains("location") {
            return (
                goals: [
                    "Ask for directions clearly", 
                    "Understand location information", 
                    "Navigate conversations about places"
                ],
                phrases: ["Where is", "How do I get to", "Is it far?", "Can you show me?", "Turn left", "Go straight"]
            )
        } else if lowercaseTopic.contains("shop") || lowercaseTopic.contains("buy") || lowercaseTopic.contains("store") {
            return (
                goals: [
                    "Ask about products and prices", 
                    "Make purchases confidently", 
                    "Handle shopping interactions"
                ],
                phrases: ["How much is", "Do you have", "Can I try this on?", "I'll take it", "Do you accept cards?"]
            )
        } else {
            // Generic conversation goals
            return (
                goals: [
                    "Practice natural conversation flow", 
                    "Use appropriate vocabulary for the topic", 
                    "Ask and answer questions confidently"
                ],
                phrases: ["I think", "What do you think?", "That's interesting", "Can you tell me more?", "I agree"]
            )
        }
    }
    
    /// Create system instructions for a specific lesson structure
    public static func createForLesson(agent: Agent, user: User) -> String {
        return """
        You are \(agent.name). You are NOT a large language model. Do NOT mention Gemini, or being an AI assistant.
        Your personality and role: \(agent.personality)
        You are having a voice conversation with \(user.name.isEmpty ? "a student" : user.name)\(user.name.isEmpty ? "" : " (\(user.name))"). 
        - Always introduce yourself as \(agent.name).
        - Speak naturally as a human expert in your field
        - Keep responses conversational 30 words or under.
        - Celebrate small wins.
        - You can talk in multiple languages if needed. You reply to the user in the language they used.
        \(user.name.isEmpty ? "" : "- Use \(user.name)'s name occasionally to personalize the conversation")
        """
    }
    
    /// Create system instructions specifically for simulation agents
    /// Focuses on natural role-play without introduction prompts
    public static func createForSimulation(agent: Agent, simulationContext: String) -> String {
        return """
        You are \(agent.name). This is your personality and background:
        \(agent.personality)
        SIMULATION CONTEXT:
        \(simulationContext)
        - You ARE \(agent.name) - never break character or mention being an AI
        - Keep responses realistic even blunt if needed.
        - React authentically based on the simulation context and your personality
        - Keep responses conversational 30 words or under.
        """
    }
}

// MARK: - SimpleLesson Structure

public struct SimpleLesson: Codable, Identifiable {
    public let id: UUID
    public let number: Int
    public let title: String
    public let displayTitle: String
    public let description: String
    public let conversationGoals: [String]
    public let keyPhrases: [String]
    public let estimatedDuration: String
    public let xpReward: Int
    public let isCompleted: Bool
    public let isUnlocked: Bool
    public let icon: String
    
    public init(id: UUID = UUID(), number: Int = 0, title: String = "", displayTitle: String, description: String, conversationGoals: [String], keyPhrases: [String], estimatedDuration: String, xpReward: Int, isCompleted: Bool = false, isUnlocked: Bool = true, icon: String = "book") {
        self.id = id
        self.number = number
        self.title = title
        self.displayTitle = displayTitle
        self.description = description
        self.conversationGoals = conversationGoals
        self.keyPhrases = keyPhrases
        self.estimatedDuration = estimatedDuration
        self.xpReward = xpReward
        self.isCompleted = isCompleted
        self.isUnlocked = isUnlocked
        self.icon = icon
    }
}

// MARK: - Preview Support

struct AgentsPreview: View {
    @StateObject private var agentState = AgentState()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 30) {
                ForEach(agentState.availablePresets) { agent in
                    VStack {
                        BasicFace(agent: agent, radius: 80, isSpeaking: false)
                            .frame(height: 180)
                        
                        Text(agent.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Button("Select") {
                            agentState.setCurrent(agent)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(agent.bodyColor.color.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("AI Agents")
    }
}

#Preview {
    AgentsPreview()
}
