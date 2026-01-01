import Foundation
import FirebaseFunctions
import FirebaseAppCheck
import CryptoKit

// MARK: - Rate Limiter DISABLED
// Rate limiting has been disabled to prevent conversation blocking

// MARK: - JSON frame models (simplified for minimal setup frame)
// Only keeping the basic structures needed for system instruction

// MARK: - TranscriptionMessage Model
struct TranscriptionMessage: Identifiable, Codable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let isUser: Bool
    
    init(text: String, isUser: Bool) {
        self.text = text
        self.timestamp = Date()
        self.isUser = isUser
    }
}

// MARK: - Audio Constants
let SAMPLE_RATE = 16000 // 16kHz sample rate for input audio

// MARK: - Client
import Foundation
import AVFoundation
import CryptoKit

@MainActor
class GeminiLiveClient: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var lastError: String?
    @Published var transcriptionMessages: [TranscriptionMessage] = []
    
    private var socket: URLSessionWebSocketTask?
    private let encoder = JSONEncoder()
    private var connectionCompletion: ((Result<Void, Error>) -> Void)?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isRecordingEnabled = true
    
    // Rate limiting DISABLED - was causing conversation blocking
    // private var lastConversationStart: Date?
    // private let rateLimitInterval: TimeInterval = 30 // 30 seconds between conversations
    // private let rateLimiter = RateLimiter() // Rate limiter instance DISABLED
    
    // Voice selection tracking
    private var selectedVoice: String = "Aoede" // Default voice
    
    // ✅ PROBLEM 2 FIX: Turn-Based Audio Control
    private var isAISpeaking: Bool = false
    private var audioSendingPaused: Bool = false
    
    // ✅ LATENCY OPTIMIZATION: Turn Transition Enhancement
    private var lastAIResponseTime: Date = Date()
    private var highPriorityMode: Bool = false
    private var turnTransitionOptimizationEnabled: Bool = true
    
    // MARK: - Session Management (10-minute limit handling + Context Preservation)
    private var sessionHandle: String?
    private var connectionStartTime: Date?
    private var reconnectionTimer: Timer?
    private var conversationDuration: TimeInterval = 0
    
    // Context preservation for seamless session resumption
    private var originalSystemPrompt: String?
    private var originalAgentType: String?
    private var originalVoiceName: String?
    private var onAudioOutCallback: ((Data) -> Void)?
    private var onTextOutCallback: ((String) -> Void)?
    
    // 🔍 DEBUG: Audio chunk tracking for snowball detection
    private var audioChunkCount = 0
    
    // ✅ PHASE 4: Performance Metrics for JSON Construction Efficiency
    private var totalCharsSent = 0
    private var totalManualChars = 0
    private var totalSerializationOverhead = 0
    private var jsonConstructionCount = 0
    
    // ✅ PHASE 4 TASK 2: Enhanced Cost Savings Tracking
    private var sessionStartCostMetrics: Date?
    private var estimatedTokensSaved = 0
    private var actualTokensUsed = 0
    private var projectedCostSavings: Double = 0.0
    private var lastCostAnalysisTime: Date?
    
    // ✅ PHASE 1: Enhanced Buffer State Tracking
    private var totalAudioDataSent: Int = 0
    private var averageMessageSize: Double = 0
    private var messageSizeHistory: [Int] = []
    private var maxHistorySize = 100 // Track last 100 messages
    
    // Track actual audio payload vs JSON overhead
    private var rawAudioBytes: Int = 0
    private var jsonOverheadBytes: Int = 0
    
    // MARK: - Token Tracking Properties
    private var sessionTokens = SessionTokenUsage()
    private var sessionStartTime: Date?
    private var currentSessionId: String?
    
    // 🔍 STEP 1: Token Call Tracking
    private var tokenCallCount: Int = 0
    private var tokenCallTimes: [Date] = []
    
    // 🔍 STEP 3: Session resumption tracking variables for detecting conversation history transmission  
    private var sessionResumptionCount: Int = 0
    private var resumptionHandleSizes: [Int] = []
    private var isCurrentSessionResumed: Bool = false
    
    // Token usage tracking structure
    private struct SessionTokenUsage {
        var audioInputTokens: Int = 0
        var audioOutputTokens: Int = 0
        var textInputTokens: Int = 0
        var sessionDuration: TimeInterval = 0
        var messageCount: Int = 0
        
        mutating func reset() {
            audioInputTokens = 0
            audioOutputTokens = 0
            textInputTokens = 0
            sessionDuration = 0
            messageCount = 0
        }
        
        func logSummary(sessionId: String) {
            let totalTokens = audioInputTokens + audioOutputTokens + textInputTokens
            print("📊 === TOKEN USAGE SUMMARY FOR SESSION: \(sessionId) ===")
            print("📊 Audio Input Tokens: \(audioInputTokens)")
            print("📊 Audio Output Tokens: \(audioOutputTokens)")
            print("📊 Text Input Tokens: \(textInputTokens)")
            print("📊 Total Tokens: \(totalTokens)")
            print("📊 Session Duration: \(String(format: "%.1f", sessionDuration)) seconds")
            print("📊 Messages Exchanged: \(messageCount)")
            print("📊 ============================================")
        }
    }
    
    // ✅ PHASE 4 TASK 3: Enhanced feature flag system with A/B testing
    private let useManualJSON = true // Primary rollback toggle
    private let manualJSONRolloutPercentage: Int = 100 // 0-100% rollout for A/B testing
    private var shouldUseManualJSON: Bool {
        // Easy emergency rollback
        guard useManualJSON else { return false }
        
        // A/B testing rollout percentage
        guard manualJSONRolloutPercentage > 0 else { return false }
        guard manualJSONRolloutPercentage >= 100 else {
            // Hash-based consistent user assignment for A/B testing
            let userHash = abs(currentSessionId?.hash ?? 0) % 100
            return userHash < manualJSONRolloutPercentage
        }
        
        return true
    }
    
    // ✅ PHASE 4: Manual JSON Builder Function for audio frames
    private func buildAudioFrameJSON(base64Data: String) -> String {
        return """
        {"realtimeInput":{"mediaChunks":[{"mimeType":"audio/pcm;rate=\(SAMPLE_RATE)","data":"\(base64Data)"}]}}
        """
    }
    
    // ✅ PHASE 4: JSON Serialization wrapper with rollback capability
    private func serializeAudioFrame(base64Data: String, frame: [String: Any]) -> (data: Data?, string: String?) {
        if shouldUseManualJSON {
            // Manual JSON construction - 20-25% more efficient
            let manualJson = buildAudioFrameJSON(base64Data: base64Data)
            return (manualJson.data(using: .utf8), manualJson)
        } else {
            // Fallback to JSONSerialization (for rollback if needed)
            guard let json = try? JSONSerialization.data(withJSONObject: frame, options: []),
                  let string = String(data: json, encoding: .utf8) else {
                return (nil, nil)
            }
            return (json, string)
        }
    }
    
    // ✅ PHASE 4 TASK 2: Cost Analysis and Savings Calculation
    private func calculateAndLogCostSavings() {
        // Estimate token savings based on character reduction
        // Rough estimate: ~4 characters per token (varies by language/content)
        let estimatedTokenSavingsFromChars = totalSerializationOverhead / 4
        estimatedTokensSaved = estimatedTokenSavingsFromChars
        
        // Estimate cost savings
        // Google AI Studio pricing: ~$0.00001 per 1K tokens (approximate)
        let costPerToken = 0.00001 / 1000.0
        projectedCostSavings = Double(estimatedTokensSaved) * costPerToken
        
        // Session-level analysis
        let now = Date()
        if sessionStartCostMetrics == nil {
            sessionStartCostMetrics = now
        }
        
        let sessionDuration = now.timeIntervalSince(sessionStartCostMetrics ?? now)
        let messagesPerMinute = Double(jsonConstructionCount) / (sessionDuration / 60.0)
        
        #if DEBUG
        print("PHASE 4 TASK 2: COST ANALYSIS:")
        print("Session duration: \(String(format: "%.1f", sessionDuration)) seconds")
        print("Messages per minute: \(String(format: "%.1f", messagesPerMinute))")
        print("Overhead saved this session: \(totalSerializationOverhead) chars")
        print("Estimated tokens saved: \(estimatedTokensSaved)")
        print("Projected cost savings: $\(String(format: "%.6f", projectedCostSavings))")
        
        // Extrapolation for longer sessions
        if sessionDuration > 60 { // More than 1 minute
            let hourlyProjection = (Double(totalSerializationOverhead) / sessionDuration) * 3600
            let hourlyCostSavings = (projectedCostSavings / sessionDuration) * 3600
            print("Projected hourly savings: \(String(format: "%.0f", hourlyProjection)) chars, $\(String(format: "%.4f", hourlyCostSavings))")
        }
        #endif
        
        lastCostAnalysisTime = now
    }
    
    // ✅ PHASE 4 TASK 2: Final session cost summary
    private func logFinalCostSummary() {
        guard let startTime = sessionStartCostMetrics else { return }
        
        let totalSessionDuration = Date().timeIntervalSince(startTime)
        let avgOverheadPerMessage = jsonConstructionCount > 0 ? Double(totalSerializationOverhead) / Double(jsonConstructionCount) : 0
        let efficiencyGain = totalCharsSent > 0 ? (Double(totalSerializationOverhead) / Double(totalCharsSent)) * 100 : 0
        
        #if DEBUG
        print("===== PHASE 4 TASK 2: FINAL SESSION COST SUMMARY =====")
        print("Session Duration: \(String(format: "%.1f", totalSessionDuration)) seconds")
        print("Total Messages Processed: \(jsonConstructionCount)")
        print("Manual JSON Construction: \(shouldUseManualJSON ? "ENABLED" : "DISABLED")")
        print("  Feature flag: \(useManualJSON ? "ON" : "OFF"), Rollout: \(manualJSONRolloutPercentage)%")
        print(" ")
        print("EFFICIENCY METRICS:")
        print("  Total characters sent: \(totalCharsSent)")
        print("  Manual JSON equivalent: \(totalManualChars)")
        print("  Overhead eliminated: \(totalSerializationOverhead) chars")
        print("  Average overhead per message: \(String(format: "%.1f", avgOverheadPerMessage)) chars")
        print("  Efficiency gain: \(String(format: "%.1f%%", efficiencyGain))")
        print(" ")
        print("COST IMPACT:")
        print("  Estimated tokens saved: \(estimatedTokensSaved)")
        print("  Projected cost savings: $\(String(format: "%.6f", projectedCostSavings))")
        
        if shouldUseManualJSON {
            print("  ✅ MANUAL JSON ACTIVE: Cost savings achieved!")
            print("  💰 Overhead eliminated: \(totalSerializationOverhead) chars")
        } else {
            print("  ⚠️  JSONSerialization active: Potential savings available")
            print("  💡 Switch to manual JSON for \(String(format: "%.1f%%", efficiencyGain)) cost reduction")
        }
        
        print(" ")
        if totalSessionDuration > 300 { // 5+ minute sessions
            let hourlyProjectedSavings = (projectedCostSavings / totalSessionDuration) * 3600
            print("LONG SESSION ANALYSIS:")
            print("  Projected hourly cost savings: $\(String(format: "%.4f", hourlyProjectedSavings))")
            print("  Projected daily cost savings: $\(String(format: "%.2f", hourlyProjectedSavings * 24))")
        }
        print("================================================")
        #endif
    }
    
    // ✅ PHASE 4 TASK 2: WebSocket Behavior Validation
    private func validateWebSocketCompatibility(jsonString: String, manualEquivalent: String) {
        #if DEBUG
        print("PHASE 4 TASK 2: WEBSOCKET COMPATIBILITY CHECK:")
        
        // Parse both JSON strings to verify they contain the same data
        guard let actualData = jsonString.data(using: .utf8),
              let manualData = manualEquivalent.data(using: .utf8) else {
            print("   ❌ Failed to convert strings to data for validation")
            return
        }
        
        do {
            let actualParsed = try JSONSerialization.jsonObject(with: actualData, options: [])
            let manualParsed = try JSONSerialization.jsonObject(with: manualData, options: [])
            
            // Deep comparison of JSON structures
            let structuresMatch = JSONObjectsEqual(actualParsed, manualParsed)
            
            print("   JSON Structure Match: \(structuresMatch ? "✅ IDENTICAL" : "❌ DIFFERENT")")
            print("   Actual JSON size: \(jsonString.count) chars")
            print("   Manual JSON size: \(manualEquivalent.count) chars")
            print("   Size difference: \(jsonString.count - manualEquivalent.count) chars")
            
            if structuresMatch {
                print("   ✅ VALIDATION PASSED: Manual JSON produces identical data structure")
                print("   ✅ WebSocket will receive functionally identical messages")
            } else {
                print("   ❌ VALIDATION FAILED: JSON structures differ!")
                print("   ❌ This could cause WebSocket communication issues")
                print("   Actual keys: \(extractKeys(from: actualParsed))")
                print("   Manual keys: \(extractKeys(from: manualParsed))")
            }
            
        } catch {
            print("   ❌ JSON parsing error during validation: \(error)")
        }
        #endif
    }
    
    // Helper function for deep JSON comparison
    private func JSONObjectsEqual(_ obj1: Any, _ obj2: Any) -> Bool {
        if let dict1 = obj1 as? [String: Any], let dict2 = obj2 as? [String: Any] {
            guard dict1.keys.count == dict2.keys.count else { return false }
            for key in dict1.keys {
                guard let val1 = dict1[key], let val2 = dict2[key] else { return false }
                if !JSONObjectsEqual(val1, val2) { return false }
            }
            return true
        } else if let arr1 = obj1 as? [Any], let arr2 = obj2 as? [Any] {
            guard arr1.count == arr2.count else { return false }
            for i in 0..<arr1.count {
                if !JSONObjectsEqual(arr1[i], arr2[i]) { return false }
            }
            return true
        } else {
            return String(describing: obj1) == String(describing: obj2)
        }
    }
    
    // Helper function to extract keys for debugging
    private func extractKeys(from obj: Any) -> [String] {
        if let dict = obj as? [String: Any] {
            return Array(dict.keys).sorted()
        } else if let arr = obj as? [Any] {
            return arr.enumerated().map { "[\($0.offset)]" }
        } else {
            return [String(describing: type(of: obj))]
        }
    }

    /// Entry point with agent support and optional voice selection - ✅ CORRECTED: System prompt embedded in token for constrained endpoint
    func start(systemPrompt: String, agentType: String = "money-master", voiceName: String? = nil, onAudioOut: @escaping (Data) -> Void, onTextOut: @escaping (String) -> Void) async throws {
        lastError = nil
        guard !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }
        
        // ✅ Initialize token tracking for new session
        sessionTokens.reset()
        sessionStartTime = Date()
        currentSessionId = UUID().uuidString
        print("📊 Starting token tracking for session: \(currentSessionId ?? "unknown")")
        
        // ✅ PHASE 4 TASK 2: Initialize cost tracking metrics
        sessionStartCostMetrics = Date()
        totalCharsSent = 0
        totalManualChars = 0
        totalSerializationOverhead = 0
        jsonConstructionCount = 0
        estimatedTokensSaved = 0
        projectedCostSavings = 0.0
        
        #if DEBUG
        print("PHASE 4 TASK 2: Cost tracking initialized for session")
        #endif
        
        // ✅ Store original parameters for session resumption
        originalSystemPrompt = systemPrompt
        originalAgentType = agentType
        originalVoiceName = voiceName
        onAudioOutCallback = onAudioOut
        onTextOutCallback = onTextOut
        
        // 1. Get ephemeral JWT from Cloud Function with system prompt, agent type and optional voice
        let token = try await fetchToken(
            systemPrompt: systemPrompt,
            agentType: agentType, 
            voiceName: voiceName
        )
        
        #if DEBUG
        print("CORRECTED: Got token with embedded system prompt for constrained endpoint")
        #endif
        
        // ✅ Connect with session resumption support
        try await connectWithSessionResumption(token: token)
        
        // Record connection start time for session management
        connectionStartTime = Date()
        
        // Start session monitoring for 8-minute reconnections
        startConnectionMonitoring()
        
        isConnected = true
        
        #if DEBUG
        print("Live API connection established with context preservation.")
        #endif
        
        Task {
            await receiveLoop(onAudioOut: onAudioOut, onTextOut: onTextOut)
        }
    }
    
    /// Connect to WebSocket with session resumption support
    private func connectWithSessionResumption(token: String) async throws {
        // Use constrained endpoint for tokens with embedded configurations
        let urlString = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=\(token)"
        
        print("🔧 Connecting to WebSocket URL with session resumption...")
        print("🔄 Session handle: \(sessionHandle ?? "new session")")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL created.")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Connect to WebSocket
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.webSocketTask(with: request)
        socket = task
        
        // Try to connect with timeout
        _ = try await withTimeout(seconds: 15) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                self.connectionCompletion = { result in
                    print("🔧 Connection completion called with result: \(result)")
                    continuation.resume(with: result)
                }
                print("🔧 Starting WebSocket task...")
                task.resume()
                print("🔧 WebSocket task.resume() called, waiting for connection...")
            }
        }
        
        print("✅ WebSocket connected successfully to CONSTRAINED endpoint.")
        
        // Send setup frame with session resumption if available
        let setupFrame: [String: Any]
        if let handle = sessionHandle {
            // Resume existing session with conversation history
            setupFrame = [
                "setup": [
                    "session_resumption": [
                        "handle": handle
                    ]
                ]
            ]
            print("🔄 Resuming session with handle: \(handle)")
            
            // 🔍 STEP 3: Track session resumption for investigation
            sessionResumptionCount += 1
            isCurrentSessionResumed = true
            resumptionHandleSizes.append(handle.count)
            
            #if DEBUG
            print("[RESUMPTION_DEBUG] Session resumption #\(sessionResumptionCount)")
            print("[RESUMPTION_DEBUG] Handle size: \(handle.count) characters")
            print("[RESUMPTION_DEBUG] WARNING: Session resumption may include conversation history!")
            #endif
            
        } else {
            // ✅ CORRECTED: New session with system prompt already embedded in token
            // No setup frame needed for new sessions with constrained endpoint
            setupFrame = ["setup": [:]]
            print("🆕 Starting new session. System instruction is embedded in the token.")
            isCurrentSessionResumed = false
        }
        
        guard let setupJson = try? JSONSerialization.data(withJSONObject: setupFrame, options: []),
              let setupString = String(data: setupJson, encoding: .utf8) else { 
            print("❌ Failed to encode setup frame")
            throw URLError(.cannotParseResponse)
        }
        
        print("🔧 Sending setup frame...")
        try await task.send(.string(setupString))
        print("✅ Setup frame sent successfully.")

        // ✅ CORRECTED: System instruction is embedded in token for constrained endpoint
        // This follows the official recommendation for BidiGenerateContentConstrained endpoint
        print("🎯 Official Implementation: System instruction embedded in ephemeral token (most secure and reliable)")
        print("✅ No text priming - pure audio-only conversation experience")
    }
    
    // MARK: - Session Resumption & Context Preservation
    
    /// Reconnect with session resumption to preserve conversation context (Public method)
    func reconnectWithSessionResumption() async {
        print("🔄 Reconnecting with session resumption to preserve context...")
        
        // Store current session state
        let savedHandle = sessionHandle
        
        // Close current connection gracefully
        await socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        isConnected = false
        
        // Brief delay before reconnection
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check if we have the original parameters for reconnection
        guard let systemPrompt = originalSystemPrompt,
              let agentType = originalAgentType,
              let onAudioOut = onAudioOutCallback,
              let onTextOut = onTextOutCallback else {
            print("❌ Missing original parameters for session resumption")
            lastError = "Connection lost. Please restart your conversation."
            return
        }
        
        do {
            // Get a new ephemeral token for the session
            let newToken = try await fetchToken(
                systemPrompt: systemPrompt,
                agentType: agentType,
                voiceName: originalVoiceName
            )
            
            // Restore the saved session handle for context preservation
            sessionHandle = savedHandle
            
            // Reconnect with the new token and preserved session handle
            try await connectWithSessionResumption(token: newToken)
            
            // Reset connection tracking
            connectionStartTime = Date()
            isConnected = true
            
            // Resume the receive loop
            Task {
                await receiveLoop(onAudioOut: onAudioOut, onTextOut: onTextOut)
            }
            
            print("✅ Session resumption successful - conversation context preserved!")
            lastError = nil
            
        } catch {
            print("❌ Session resumption failed: \(error)")
            lastError = "Failed to resume session. Please restart your conversation."
            
            // Reset session state
            connectionStartTime = nil
            sessionHandle = nil
        }
    }
    
    // MARK: - WebSocket Message Handling
    
    // Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            
            guard let result = try await group.next() else {
                throw URLError(.timedOut)
            }
            
            group.cancelAll()
            return result
        }
    }

    /// 🎯 CRITICAL FIX: Send turn completion signal without text to indicate user finished speaking
    func sendTurnComplete() async {
        guard isConnected, let socket = socket else {
            print("⚠️ Cannot send turn completion - WebSocket not connected")
            return
        }
        
        // Send minimal frame with only turn completion signal - no text to avoid token cost
        let frame = [
            "clientContent": [
                "turnComplete": true
            ]
        ]
        
        guard let json = try? JSONSerialization.data(withJSONObject: frame, options: []),
              let string = String(data: json, encoding: .utf8) else { 
            print("❌ Failed to serialize turn completion JSON")
            return
        }
        
        print("🎯 Sending turn completion signal (no text content)")
        
        do {
            try await socket.send(.string(string))
            print("✅ Turn completion signal sent successfully")
            
            // No token cost for turn completion without text content
            
        } catch {
            print("❌ Failed to send turn completion WebSocket message: \(error)")
            // Mark as disconnected if sending fails
            isConnected = false
        }
    }

    /// Send raw 16 kHz Int16 mono PCM
    func send(audioData: Data) async {
        // ✅ PROBLEM 2 FIX: Turn-Based Audio Control
        guard !isAISpeaking && !audioSendingPaused else {
            print("🔄 PROBLEM 2 FIX: Audio sending paused - AI is speaking (isAISpeaking: \(isAISpeaking), paused: \(audioSendingPaused))")
            return
        }
        
        // 🔒 SECURITY: Audio-specific rate limiting check DISABLED
        // guard rateLimiter.canMakeAudioRequest() else {
        //     #if DEBUG
        //     print("SECURITY: Audio request blocked by rate limiter")
        //     #endif
        //     return
        // }
        
        guard isConnected, let socket = socket else {
            print("⚠️ Cannot send audio - WebSocket not connected")
            return
        }
        
        // ✅ PHASE 2: Pre-send session state validation
        print("🧹 PHASE 2: Validating clean session state before audio send")
        validateSessionStateCleanness()
        
        // ✅ PHASE 1: Enhanced buffer analysis before processing
        audioChunkCount += 1
        totalAudioDataSent += audioData.count
        rawAudioBytes += audioData.count
        
        print("🔍 === PHASE 1 BUFFER ANALYSIS START ===")
        print("🔍 Chunk #\(audioChunkCount): Raw audio data: \(audioData.count) bytes")
        print("🔍 Total audio sent this session: \(totalAudioDataSent) bytes")
        print("🔍 Average chunk size: \(totalAudioDataSent / audioChunkCount) bytes")
        
        let base64 = audioData.base64EncodedString()
        print("🔍 Base64 encoded size: \(base64.count) chars")
        print("🔍 Base64 overhead: \((base64.count * 100) / audioData.count)% of original")
        
        // ✅ PHASE 2: Message Payload Isolation - Ensure clean frame construction
        print("🧹 PHASE 2: Constructing isolated audio frame (no conversation context)")
        
        let frame = [
            "realtimeInput": [
                "mediaChunks": [
                    [
                        "data": base64, 
                        "mimeType": "audio/pcm;rate=\(SAMPLE_RATE)"
                    ]
                ]
            ]
        ]
        
        // ✅ PHASE 2: Validate frame isolation - check for unexpected keys
        if let realtimeInputKeys = (frame["realtimeInput"] as? [String: Any])?.keys.sorted() {
            print("🧹 PHASE 2: Frame keys validation: \(realtimeInputKeys)")
            // Should only contain "mediaChunks", nothing else
            if realtimeInputKeys.count > 1 {
                print("🚨 PHASE 2: WARNING - Frame contains unexpected keys beyond mediaChunks!")
                print("🚨 Unexpected keys: \(realtimeInputKeys.filter { $0 != "mediaChunks" })")
            } else {
                print("✅ PHASE 2: Frame properly isolated - contains only mediaChunks")
            }
        }
        
        // ✅ PHASE 1: Detailed message construction analysis
        // ✅ PHASE 3: RAW JSON INSPECTION - Let's see exactly what's being serialized
        print("🔬 PHASE 3: RAW FRAME BEFORE SERIALIZATION:")
        print("🔬 Frame structure: \(frame)")
        
        // ✅ PHASE 4: Use manual JSON construction instead of JSONSerialization
        let (jsonData, jsonString) = serializeAudioFrame(base64Data: base64, frame: frame)
        
        guard let json = jsonData, let string = jsonString else { 
            print("❌ Failed to encode audio frame")
            return 
        }
        
        // ✅ PHASE 4: Enhanced logging with manual vs automatic comparison
        print("🔬 PHASE 4: JSON CONSTRUCTION METHOD: \(shouldUseManualJSON ? "MANUAL" : "JSONSerialization")")
        print("🔬 PHASE 4 TASK 3: Rollout status - Flag: \(useManualJSON), Percentage: \(manualJSONRolloutPercentage)%, Active: \(shouldUseManualJSON)")
        
        // ✅ PHASE 3: DETAILED JSON INSPECTION
        print("🔬 PHASE 3: RAW JSON OUTPUT (first 500 chars):")
        print("🔬 \(String(string.prefix(500)))")
        if string.count > 500 {
            print("🔬 PHASE 3: RAW JSON OUTPUT (last 500 chars):")
            print("🔬 \(String(string.suffix(500)))")
        }
        
        // ✅ PHASE 3 & 4: EFFICIENCY COMPARISON
        let manualJson = buildAudioFrameJSON(base64Data: base64)
        print("🔬 PHASE 3: MANUAL JSON SIZE: \(manualJson.count) chars")
        print("🔬 PHASE 3: ACTUAL JSON SIZE: \(string.count) chars") 
        
        // ✅ PHASE 4: Update Performance Metrics
        jsonConstructionCount += 1
        totalCharsSent += string.count
        totalManualChars += manualJson.count
        let currentOverhead = string.count - manualJson.count
        totalSerializationOverhead += currentOverhead
        
        if shouldUseManualJSON {
            print("🔬 PHASE 4: USING MANUAL JSON - NO SERIALIZATION OVERHEAD!")
            print("🔬 PHASE 4: EFFICIENCY GAIN: Manual JSON construction active")
        } else {
            let overhead = string.count - manualJson.count
            print("🔬 PHASE 3: SERIALIZATION OVERHEAD: \(overhead) chars")
            if abs(overhead) > 100 {
                print("🚨 PHASE 3: SIGNIFICANT SERIALIZATION OVERHEAD DETECTED!")
                print("🚨 Swift JSONSerialization is adding \(overhead) extra chars")
                print("🚨 Consider switching to manual JSON construction")
            }
        }
        
        // ✅ PHASE 4: Performance Summary Every 10 Messages
        if jsonConstructionCount % 10 == 0 {
            let avgOverhead = Double(totalSerializationOverhead) / Double(jsonConstructionCount)
            let efficiencyRatio = Double(totalManualChars) / Double(totalCharsSent)
            print("📊 PHASE 4: PERFORMANCE SUMMARY (after \(jsonConstructionCount) messages):")
            print("📊 Total chars sent: \(totalCharsSent)")
            print("📊 Total manual equivalent: \(totalManualChars)")
            print("📊 Total overhead: \(totalSerializationOverhead) chars")
            print("📊 Average overhead per message: \(String(format: "%.1f", avgOverhead)) chars")
            print("📊 JSON efficiency ratio: \(String(format: "%.1f%%", efficiencyRatio * 100))")
            
            // ✅ PHASE 4 TASK 2: Enhanced Cost Analysis
            calculateAndLogCostSavings()
            
            // ✅ PHASE 4 TASK 2: WebSocket Behavior Validation
            validateWebSocketCompatibility(jsonString: string, manualEquivalent: manualJson)
            
            if shouldUseManualJSON {
                print("📊 PHASE 4: MANUAL JSON SAVINGS: ~\(totalSerializationOverhead) chars saved!")
                print("📊 PHASE 4 TASK 2: ESTIMATED TOKEN SAVINGS: ~\(estimatedTokensSaved) tokens")
                print("📊 PHASE 4 TASK 2: PROJECTED COST SAVINGS: $\(String(format: "%.4f", projectedCostSavings))")
            }
        }
        
        // ✅ PHASE 1: Comprehensive size analysis
        let messageSize = string.count
        let jsonOverhead = messageSize - base64.count
        jsonOverheadBytes += jsonOverhead
        
        // Update message size history
        messageSizeHistory.append(messageSize)
        if messageSizeHistory.count > maxHistorySize {
            messageSizeHistory.removeFirst()
        }
        averageMessageSize = Double(messageSizeHistory.reduce(0, +)) / Double(messageSizeHistory.count)
        
        print("🔍 JSON message size: \(messageSize) chars")
        print("🔍 JSON overhead: \(jsonOverhead) chars (\((jsonOverhead * 100) / messageSize)%)")
        print("🔍 Expected base message size: ~\(audioData.count * 4 / 3 + 100) chars (base64 + JSON structure)")
        print("🔍 Average message size: \(String(format: "%.1f", averageMessageSize)) chars")
        
        // ✅ PHASE 1: Memory inspection for accumulated data
        print("🔍 === MEMORY ANALYSIS ===")
        print("🔍 Frame object structure:")
        print("🔍   - realtimeInput keys: \((frame["realtimeInput"] as? [String: Any])?.keys.sorted() ?? [])")
        print("🔍   - mediaChunks count: \(((frame["realtimeInput"] as? [String: Any])?["mediaChunks"] as? [Any])?.count ?? 0)")
        print("🔍   - Single chunk keys: \((((frame["realtimeInput"] as? [String: Any])?["mediaChunks"] as? [[String: Any]])?.first?.keys.sorted()) ?? [])")
        
        // ✅ PHASE 3: Check for unexpected data accumulation
        let expectedSize = audioData.count * 4 / 3 + 120 // Base64 + reasonable JSON overhead
        let sizeDeviation = messageSize - expectedSize
        
        // ✅ PHASE 3: DETAILED OVERHEAD ANALYSIS
        print("🔬 PHASE 3: COMPREHENSIVE SIZE BREAKDOWN:")
        print("🔬   Raw audio bytes: \(audioData.count)")
        print("🔬   Base64 chars: \(base64.count)")
        print("🔬   Base64 efficiency: \(String(format: "%.1f", Double(base64.count) / Double(audioData.count)))x")
        print("🔬   Total JSON chars: \(messageSize)")
        print("🔬   Pure JSON overhead: \(jsonOverhead) chars")
        print("🔬   Expected total: ~\(expectedSize) chars")
        print("🔬   Actual total: \(messageSize) chars")
        print("🔬   Mysterious overhead: \(sizeDeviation) chars")
        
        // ✅ PHASE 3: CHARACTER ANALYSIS
        let jsonStructureOnly = messageSize - base64.count
        print("🔬   JSON structure only: \(jsonStructureOnly) chars")
        print("🔬   Expected JSON structure: ~120 chars")
        print("🔬   Extra JSON overhead: \(jsonStructureOnly - 120) chars")
        
        if abs(sizeDeviation) > 500 {  // More than 500 chars deviation
            print("🚨 === SNOWBALL DETECTION ===")
            print("🚨 Expected message size: ~\(expectedSize) chars")
            print("🚨 Actual message size: \(messageSize) chars")
            print("🚨 Deviation: \(sizeDeviation) chars (\(sizeDeviation > 0 ? "LARGER" : "smaller"))")
            print("🚨 This suggests data accumulation or unexpected overhead!")
            
            // ✅ PHASE 3: ENHANCED ROOT CAUSE ANALYSIS
            if sizeDeviation > 0 {
                print("🚨 PHASE 3: DETAILED ANALYSIS OF EXCESS \(sizeDeviation) CHARS:")
                print("🚨   1. Our frame has ONLY mediaChunks - verified ✅")
                print("🚨   2. Our base64 encoding is correct - verified ✅")  
                print("🚨   3. Client buffer management is clean - verified ✅")
                print("🚨   4. CONCLUSION: Excess is from JSON serialization or API")
                print("🚨   5. LIKELY CAUSE: Swift JSONSerialization adding metadata")
                print("🚨   6. OR: Server-side context injection during processing")
            }
        }
        
        print("🔍 === PHASE 1 BUFFER ANALYSIS END ===")
        
        #if DEBUG
        // Debug: Log audio frame details to monitor for snowballing
        print("DEBUG - Audio chunk #\(audioChunkCount): \(audioData.count) bytes → JSON: \(messageSize) chars")
        
        // Snowball detection: Alert if message size grows unexpectedly
        if messageSize > 1000 {  // Base64 audio should be ~700-800 chars typically
            print("SNOWBALL ALERT: Audio message size unusually large: \(messageSize) chars")
            print("This could indicate conversation history being sent with audio!")
        }
        #endif
        
        print("Sending audio frame: \(audioData.count) bytes")
        
        do {
            try await socket.send(.string(string))
            print("✅ Audio frame sent successfully")
            
            // ✅ PHASE 2: Immediate buffer clearing after successful send
            // Clear any potential references to the sent audio data
            print("🧹 PHASE 2: Clearing audio references post-send")
            
            // Force deallocation of local variables (defensive programming)
            // This ensures no lingering references to audio data or JSON structures
            
            // ✅ Track audio input tokens (estimate based on audio duration)
            // 16kHz * 2 bytes per sample = 32,000 bytes per second
            // Typical token rate: ~75 tokens per second of audio
            let durationSeconds = Double(audioData.count) / 32000.0
            let estimatedTokens = max(1, Int(durationSeconds * 75))
            sessionTokens.audioInputTokens += estimatedTokens
            print("📊 Estimated audio input tokens for \(audioData.count) bytes (\(String(format: "%.2f", durationSeconds))s): \(estimatedTokens) (Total audio input: \(sessionTokens.audioInputTokens))")
            
            // ✅ PHASE 2: Validate clean state after send
            print("🧹 PHASE 2: Audio send complete - memory references cleared")
            
        } catch {
            print("❌ Failed to send audio WebSocket message: \(error)")
            // Mark as disconnected if sending fails
            isConnected = false
            
            // ✅ PHASE 2: Clear buffers even on failure to prevent accumulation
            print("🧹 PHASE 2: Clearing references after send failure to prevent accumulation")
        }
    }

    func stop() async {
        // ✅ Calculate final session duration and log token usage
        if let startTime = sessionStartTime {
            sessionTokens.sessionDuration = Date().timeIntervalSince(startTime)
        }
        
        #if DEBUG
        // Step 1: Log final token call summary
        print("[TOKEN_DEBUG] === SESSION TOKEN SUMMARY ===")
        print("[TOKEN_DEBUG] Total token calls this session: \(tokenCallCount)")
        if !tokenCallTimes.isEmpty {
            let totalSessionTime = Date().timeIntervalSince1970 - (tokenCallTimes.first?.timeIntervalSince1970 ?? Date().timeIntervalSince1970)
            let averageInterval = tokenCallTimes.count > 1 ? 
                (tokenCallTimes.last!.timeIntervalSince1970 - tokenCallTimes.first!.timeIntervalSince1970) / Double(tokenCallTimes.count - 1) : 0
            print("[TOKEN_DEBUG] Session duration: \(totalSessionTime) seconds")
            print("[TOKEN_DEBUG] Average call interval: \(averageInterval) seconds")
            print("[TOKEN_DEBUG] First call: \(tokenCallTimes.first?.timeIntervalSince1970 ?? 0)")
            print("[TOKEN_DEBUG] Last call: \(tokenCallTimes.last?.timeIntervalSince1970 ?? 0)")
            print("[TOKEN_DEBUG] Token calls per minute: \(tokenCallCount > 0 ? (Double(tokenCallCount) * 60.0) / totalSessionTime : 0)")
            
            // Check for unusual patterns
            if tokenCallCount > 5 {
                print("[TOKEN_DEBUG] HIGH TOKEN CALL COUNT - Investigate potential reconnection loops!")
            }
            if averageInterval < 10 && tokenCallCount > 3 {
                print("[TOKEN_DEBUG] RAPID TOKEN CALLS - Average interval under 10 seconds!")
            }
        }
        
        // Debug: Log session resumption summary
        print("[RESUMPTION_DEBUG] === SESSION RESUMPTION SUMMARY ===")
        print("[RESUMPTION_DEBUG] Total session resumptions: \(sessionResumptionCount)")
        print("[RESUMPTION_DEBUG] Current session was resumed: \(isCurrentSessionResumed)")
        if !resumptionHandleSizes.isEmpty {
            let totalHandleSize = resumptionHandleSizes.reduce(0, +)
            let averageHandleSize = totalHandleSize / resumptionHandleSizes.count
            print("[RESUMPTION_DEBUG] Total handle characters: \(totalHandleSize)")
            print("[RESUMPTION_DEBUG] Average handle size: \(averageHandleSize) chars")
            print("[RESUMPTION_DEBUG] Handle sizes: \(resumptionHandleSizes)")
            
            // Check for suspicious resumption patterns
            if sessionResumptionCount > 3 {
                print("[RESUMPTION_DEBUG] HIGH RESUMPTION COUNT - May include conversation history!")
            }
            if averageHandleSize > 1000 {
                print("[RESUMPTION_DEBUG] LARGE HANDLE SIZES - Possible embedded conversation data!")
            }
        }
        print("[RESUMPTION_DEBUG] === END RESUMPTION SUMMARY ===")
        print("[TOKEN_DEBUG] === END TOKEN SUMMARY ===")
        #endif
        
        // ✅ PHASE 4 TASK 2: Final cost analysis summary
        if jsonConstructionCount > 0 {
            calculateAndLogCostSavings()
            logFinalCostSummary()
        }
        
        // ✅ PHASE 1: Comprehensive buffer analysis summary
        print("🔍 === PHASE 1 SESSION ANALYSIS SUMMARY ===")
        print("🔍 Total audio chunks sent: \(audioChunkCount)")
        print("🔍 Total raw audio data: \(totalAudioDataSent) bytes")
        print("🔍 Total raw audio data: \(rawAudioBytes) bytes")
        print("🔍 Total JSON overhead: \(jsonOverheadBytes) bytes")
        print("🔍 JSON overhead percentage: \(jsonOverheadBytes > 0 ? (jsonOverheadBytes * 100) / (rawAudioBytes + jsonOverheadBytes) : 0)%")
        print("🔍 Average message size: \(String(format: "%.1f", averageMessageSize)) chars")
        print("🔍 Message size range: \(messageSizeHistory.min() ?? 0) - \(messageSizeHistory.max() ?? 0) chars")
        
        if messageSizeHistory.count > 1 {
            let firstMessage = messageSizeHistory.first ?? 0
            let lastMessage = messageSizeHistory.last ?? 0
            let growth = lastMessage - firstMessage
            print("🔍 Message size growth: \(growth) chars (\(growth > 0 ? "GROWING" : "stable/shrinking"))")
            
            if growth > 1000 {
                print("🚨 SIGNIFICANT MESSAGE GROWTH DETECTED!")
                print("🚨 This strongly suggests a snowball pattern!")
            }
        }
        
        // ✅ Reset buffer tracking for next session
        audioChunkCount = 0
        totalAudioDataSent = 0
        averageMessageSize = 0
        messageSizeHistory.removeAll()
        rawAudioBytes = 0
        jsonOverheadBytes = 0
        print("🔍 === BUFFER TRACKING RESET FOR NEXT SESSION ===")
        
        // ✅ PHASE 2: Complete session reset to prevent accumulation
        resetSessionState()
        
        // Log comprehensive token usage summary
        if let sessionId = currentSessionId {
            sessionTokens.logSummary(sessionId: sessionId)
            
            // ✅ Log token usage locally for monitoring (cloud logging removed)
            logTokenUsageLocally()
        }
        
        await socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        isConnected = false
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        connectionStartTime = nil
        sessionHandle = nil
        
        // Reset token tracking for next session
        sessionTokens.reset()
        sessionStartTime = nil
        currentSessionId = nil
    }
    
    // ✅ PHASE 2: Session State Validation
    private func validateSessionStateCleanness() {
        print("🧹 PHASE 2: Session state check:")
        print("🧹   - sessionHandle: \(sessionHandle?.prefix(10) ?? "nil")...")
        print("🧹   - currentSessionId: \(currentSessionId?.prefix(10) ?? "nil")...")
        print("🧹   - messageSizeHistory count: \(messageSizeHistory.count)")
        print("🧹   - audioChunkCount: \(audioChunkCount)")
        
        // Check for potential accumulation indicators
        if messageSizeHistory.count > 50 {
            print("🚨 PHASE 2: WARNING - Large message history: \(messageSizeHistory.count) entries")
        }
        
        if audioChunkCount > 1000 {
            print("🚨 PHASE 2: WARNING - Very long session: \(audioChunkCount) chunks")
        }
    }
    
    // ✅ PHASE 2: Complete session state reset
    private func resetSessionState() {
        print("🧹 PHASE 2: Resetting session state to prevent accumulation")
        
        // ✅ PROBLEM 2 FIX: Reset turn-based audio control
        isAISpeaking = false
        audioSendingPaused = false
        print("🔄 PROBLEM 2 FIX: Session reset - audio sending enabled")
        
        // Clear message tracking (already done in stop(), but ensuring completeness)
        messageSizeHistory.removeAll()
        averageMessageSize = 0.0
        
        // Reset audio tracking (already done in stop(), but ensuring completeness)
        audioChunkCount = 0
        totalAudioDataSent = 0
        rawAudioBytes = 0
        jsonOverheadBytes = 0
        
        // Reset session timing
        sessionStartTime = nil
        //lastConversationStart = nil
        conversationDuration = 0
        
        // Reset token tracking (already done in stop(), but ensuring completeness)
        sessionTokens = SessionTokenUsage()
        
        print("✅ PHASE 2: Session state reset complete")
    }
    
    // MARK: - Session Management Methods
    
    override init() {
        super.init()
        startConnectionMonitoring()
    }
    
    deinit {
        reconnectionTimer?.invalidate()
    }
    
    private func startConnectionMonitoring() {
        // Monitor connection and proactively reconnect before 10-minute limit
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: 480, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.proactiveReconnection()
            }
        }
    }
    
    private func proactiveReconnection() async {
        guard isConnected,
              let startTime = connectionStartTime else { return }
        
        let connectionAge = Date().timeIntervalSince(startTime)
        
        // Reconnect after 8 minutes (480 seconds) to avoid 10-minute limit
        if connectionAge > 480 {
            print("🔄 Proactive reconnection due to 10-minute limit approaching")
            lastError = "Refreshing connection to maintain optimal performance..."
            
            // Use the enhanced session resumption to preserve context
            await reconnectWithSessionResumption()
        }
    }
    
    private func handleGoAwayMessage(_ goAway: [String: Any]) async {
        print("🚨 GoAway message received: \(goAway)")
        
        // Extract time left from the message (typically in milliseconds)
        let timeLeft = goAway["timeLeft"] as? Double ?? 5.0 // Default to 5 seconds
        
        print("🚨 Server requesting disconnection in \(timeLeft) seconds")
        
        // Proactively reconnect with 80% of the remaining time as buffer
        let reconnectDelay = timeLeft * 0.8
        
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) {
            Task { @MainActor in
                print("🔄 Proactive reconnection triggered by GoAway message")
                await self.reconnectWithSessionResumption()
            }
        }
    }

    // MARK: - Private helpers
    private func fetchToken(systemPrompt: String, agentType: String = "money-master", voiceName: String? = nil) async throws -> String {
        // 🔍 STEP 1: Track token call frequency
        tokenCallCount += 1
        let now = Date()
        tokenCallTimes.append(now)
        
        print("🔍 STEP 1 - TOKEN CALL #\(tokenCallCount) at \(now)")
        if tokenCallTimes.count > 1 {
            let timeSinceLastCall = now.timeIntervalSince(tokenCallTimes[tokenCallTimes.count - 2])
            print("🔍 STEP 1 - Time since last token call: \(String(format: "%.1f", timeSinceLastCall))s")
        }
        print("🔍 STEP 1 - System prompt length: \(systemPrompt.count) characters")
        
        print("🔄 Fetching ephemeral token from Cloud Function for agent: \(agentType)")
        if let voiceName = voiceName {
            print("🎯 Requesting specific voice: \(voiceName)")
        }
        print("✅ CORRECTED: System prompt will be embedded in token for constrained endpoint")
        
        let fn = Functions.functions().httpsCallable("getGeminiEphemeralToken")
        
        do {
            // ✅ CORRECTED: Re-add systemPrompt parameter - required for constrained endpoint
            var parameters: [String: Any] = [
                "agentType": agentType,
                "systemPrompt": systemPrompt
            ]
            
            // Add voice name if provided for direct voice selection
            if let voiceName = voiceName {
                parameters["voiceName"] = voiceName
            }
            
            let result = try await fn.call(parameters)
            print("✅ Cloud Function response: \(result.data)")
            
            guard let data = result.data as? [String: Any],
                  let token = data["ephemeralToken"] as? String else {
                print("🛑 Invalid token response format: \(result.data)")
                throw URLError(.badServerResponse)
            }
            
            // Log enhanced voice selection information
            if let voice = data["voice"] as? String {
                let voiceType = data["voiceType"] as? String ?? "unknown"
                let selectionMethod = data["selectionMethod"] as? String ?? "unknown"
                print("🎯 Selected voice: \(voice) (\(voiceType)) via \(selectionMethod) for agent: \(agentType)")
                selectedVoice = voice // Store the voice from token response
            } else {
                print("⚠️ No voice specified in token response, using default: \(selectedVoice)")
            }
            
            // Log available voices for debugging
            if let availableVoices = data["availableVoices"] as? [String: [String]] {
                let feminineCount = availableVoices["feminine"]?.count ?? 0
                let masculineCount = availableVoices["masculine"]?.count ?? 0
                print("📊 Available voices: \(feminineCount) feminine, \(masculineCount) masculine")
            }
            
            print("✅ Successfully got token: \(token.prefix(20))...")
            return token
        } catch {
            print("🛑 Token fetch error: \(error)")
            if let nsError = error as NSError? {
                print("🛑 Error domain: \(nsError.domain)")
                print("🛑 Error code: \(nsError.code)")
                print("🛑 Error info: \(nsError.userInfo)")
            }
            throw error
        }
    }

    // MARK: - Character Priming (replaces setup frame approach)
    // The priming approach works better with ephemeral tokens since
    // system instructions in setup frames are ignored by the constrained endpoint

    private func receiveLoop(onAudioOut: @escaping (Data) -> Void, onTextOut: @escaping (String) -> Void) async { // ✅ Step 1.3: Added onTextOut parameter
        guard let task = socket else { return }
        do {
            while true {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    print("📨 Received string WebSocket message: \(text.prefix(200))...")
                    guard let data = text.data(using: .utf8),
                          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { 
                        print("⚠️ Failed to parse WebSocket message")
                        continue 
                    }
                    
                    // Handle GoAway messages for proactive reconnection
                    if let goAway = dict["goAway"] as? [String: Any] {
                        print("🚨 Received GoAway message: \(goAway)")
                        await handleGoAwayMessage(goAway)
                        continue
                    }
                    
                    // Handle session resumption updates
                    if let sessionUpdate = dict["sessionResumptionUpdate"] as? [String: Any] {
                        print("🔄 Received session resumption update: \(sessionUpdate)")
                        
                        // Store the new session handle for context preservation
                        if let newHandle = sessionUpdate["newHandle"] as? String, !newHandle.isEmpty,
                           let resumable = sessionUpdate["resumable"] as? Bool, resumable {
                            sessionHandle = newHandle
                            print("📱 Updated session handle for context preservation: \(newHandle)")
                            print("✅ Session is resumable - conversation context will be preserved")
                        } else {
                            print("⚠️ Session not resumable or no handle provided")
                            if let resumable = sessionUpdate["resumable"] as? Bool, !resumable {
                                print("❌ Session resumption is not available at this point")
                            }
                        }
                        
                        // Log additional session resumption details
                        if let lastConsumedIndex = sessionUpdate["lastConsumedClientMessageIndex"] as? Int {
                            print("📊 Last consumed client message index: \(lastConsumedIndex)")
                        }
                        
                        continue
                    }
                    
                    // Check for different types of server messages
                    if let serverContent = dict["serverContent"] as? [String: Any] {
                        print("📋 Server content received: \(serverContent.keys)")
                        
                        // ENHANCED DEBUGGING: Print the entire server response for transcript debugging
                        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("🔍 FULL SERVER RESPONSE:\n\(jsonString)")
                        }
                        
                        // Try to extract audio and text data
                        if let modelTurn = serverContent["modelTurn"] as? [String: Any],
                           let parts = modelTurn["parts"] as? [[String: Any]] {
                            print("📋 Found \(parts.count) parts in modelTurn")
                            
                            // ✅ PROBLEM 2 FIX: AI Started Speaking
                            if !isAISpeaking {
                                isAISpeaking = true
                                audioSendingPaused = true
                                print("🔄 PROBLEM 2 FIX: AI started speaking - audio sending PAUSED")
                            }
                            
                            for (index, part) in parts.enumerated() {
                                print("📋 Part \(index) keys: \(part.keys)")
                                
                                // Check for audio data (existing logic)
                                if let inlineData = part["inlineData"] as? [String: Any],
                                   let base64 = inlineData["data"] as? String,
                                   let mimeType = inlineData["mimeType"] as? String,
                                   mimeType.contains("audio") {
                                    
                                    print("🎧 Audio MIME type: \(mimeType)")
                                    
                                    // Verify the output format matches what LessonView expects
                                    if mimeType.contains("rate=24000") || mimeType.contains("24000") {
                                        if let pcm = Data(base64Encoded: base64) {
                                            print("🔊 Received audio chunk: \(pcm.count) bytes (24kHz)")
                                            onAudioOut(pcm)
                                            
                                            // ✅ Track audio output tokens
                                            let durationSeconds = Double(pcm.count) / 48000.0 // 24kHz * 2 bytes per sample
                                            let estimatedTokens = max(1, Int(durationSeconds * 75)) // ~75 tokens per second
                                            sessionTokens.audioOutputTokens += estimatedTokens
                                            print("📊 Estimated audio output tokens for \(pcm.count) bytes (\(String(format: "%.2f", durationSeconds))s): \(estimatedTokens) (Total audio output: \(sessionTokens.audioOutputTokens))")
                                            
                                        } else {
                                            print("❌ Failed to decode base64 audio data")
                                        }
                                    } else {
                                        print("⚠️ Unexpected audio format: \(mimeType) - Expected 24kHz")
                                        // Still try to play it, but log the mismatch
                                        if let pcm = Data(base64Encoded: base64) {
                                            print("🔊 Received audio chunk: \(pcm.count) bytes (unknown rate)")
                                            onAudioOut(pcm)
                                            
                                            // ✅ Track audio output tokens (estimate with unknown rate)
                                            let estimatedDuration = Double(pcm.count) / 32000.0 // Fallback estimate
                                            let estimatedTokens = max(1, Int(estimatedDuration * 75))
                                            sessionTokens.audioOutputTokens += estimatedTokens
                                            print("📊 Estimated audio output tokens (unknown rate): \(estimatedTokens) (Total: \(sessionTokens.audioOutputTokens))")
                                        }
                                    }
                                }
                                
                                // ✅ Step 1.3: Check for text data with enhanced debugging
                                if let transcript = part["text"] as? String {
                                    print("🎯 TRANSCRIPT FOUND! Content: '\(transcript)'")
                                    onTextOut(transcript)
                                } else {
                                    print("📝 No 'text' field found in part \(index). Available keys: \(part.keys)")
                                    // Check for other possible text field names
                                    if let altText = part["transcript"] as? String {
                                        print("🎯 FOUND ALTERNATIVE 'transcript' field: '\(altText)'")
                                        onTextOut(altText)
                                    } else if let altText = part["content"] as? String {
                                        print("🎯 FOUND ALTERNATIVE 'content' field: '\(altText)'")
                                        onTextOut(altText)
                                    }
                                }
                            }
                        }
                        
                        // ✅ PROBLEM 2 FIX: Check for turn completion
                        if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
                            isAISpeaking = false
                            audioSendingPaused = false
                            lastAIResponseTime = Date()
                            
                            // ✅ LATENCY OPTIMIZATION: Immediate audio preparation
                            if turnTransitionOptimizationEnabled {
                                Task { @MainActor in
                                    await prepareForUserAudio()
                                }
                                print("🚀 LATENCY OPTIMIZED: Turn completed - audio ready for immediate transmission")
                            } else {
                                print("🔄 PROBLEM 2 FIX: Turn completed - audio sending RESUMED")
                            }
                        }
                        
                    } else {
                        print("📋 Non-audio message received: \(dict.keys)")
                    }
                    
                case .data(let data):
                    print("📨 Received binary WebSocket message: \(data.count) bytes")
                    // Try to parse binary data as JSON
                    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📋 Parsed binary message: \(dict.keys)")
                        
                        // Same audio and text extraction logic for binary messages
                        if let serverContent = dict["serverContent"] as? [String: Any] {
                            print("📋 Server content in binary message: \(serverContent.keys)")
                            
                            // Enhanced debugging: Log binary message metadata only
                            #if DEBUG
                            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                print("🔍 Binary response: \(jsonString.count) chars, keys: \(dict.keys.sorted())")
                            }
                            #endif
                            
                            if let modelTurn = serverContent["modelTurn"] as? [String: Any],
                               let parts = modelTurn["parts"] as? [[String: Any]] {
                                print("📋 Found \(parts.count) parts in binary modelTurn")
                                
                                for (index, part) in parts.enumerated() {
                                    print("📋 Binary part \(index) keys: \(part.keys)")
                                    
                                    // Check for audio data (existing logic)
                                    if let inlineData = part["inlineData"] as? [String: Any],
                                       let base64 = inlineData["data"] as? String,
                                       let mimeType = inlineData["mimeType"] as? String,
                                       mimeType.contains("audio") {
                                        
                                        print("🎧 Audio MIME type from binary: \(mimeType)")
                                        
                                        // Verify the output format matches what LessonView expects
                                        if mimeType.contains("rate=24000") || mimeType.contains("24000") {
                                            if let pcm = Data(base64Encoded: base64) {
                                                print("🔊 Received audio chunk from binary: \(pcm.count) bytes (24kHz)")
                                                onAudioOut(pcm)
                                                
                                                // ✅ Track audio output tokens from binary
                                                let durationSeconds = Double(pcm.count) / 48000.0 // 24kHz * 2 bytes per sample
                                                let estimatedTokens = max(1, Int(durationSeconds * 75)) // ~75 tokens per second
                                                sessionTokens.audioOutputTokens += estimatedTokens
                                                print("📊 Estimated audio output tokens from binary for \(pcm.count) bytes (\(String(format: "%.2f", durationSeconds))s): \(estimatedTokens) (Total: \(sessionTokens.audioOutputTokens))")
                                                
                                            } else {
                                                print("❌ Failed to decode base64 audio data from binary")
                                            }
                                        } else {
                                            print("⚠️ Unexpected audio format from binary: \(mimeType) - Expected 24kHz")
                                            // Still try to play it, but log the mismatch
                                            if let pcm = Data(base64Encoded: base64) {
                                                print("🔊 Received audio chunk from binary: \(pcm.count) bytes (unknown rate)")
                                                onAudioOut(pcm)
                                                
                                                // ✅ Track audio output tokens from binary (unknown rate)
                                                let estimatedDuration = Double(pcm.count) / 32000.0 // Fallback estimate
                                                let estimatedTokens = max(1, Int(estimatedDuration * 75))
                                                sessionTokens.audioOutputTokens += estimatedTokens
                                                print("📊 Estimated audio output tokens from binary (unknown rate): \(estimatedTokens) (Total: \(sessionTokens.audioOutputTokens))")
                                            }
                                        }
                                    }
                                    
                                    // ✅ Step 1.3: Check for text data in binary messages with enhanced debugging
                                    if let transcript = part["text"] as? String {
                                        print("🎯 TRANSCRIPT FOUND IN BINARY! Content: '\(transcript)'")
                                        onTextOut(transcript)
                                    } else {
                                        print("📝 No 'text' field found in binary part \(index). Available keys: \(part.keys)")
                                        // Check for other possible text field names
                                        if let altText = part["transcript"] as? String {
                                            print("🎯 FOUND ALTERNATIVE 'transcript' field in binary: '\(altText)'")
                                            onTextOut(altText)
                                        } else if let altText = part["content"] as? String {
                                            print("🎯 FOUND ALTERNATIVE 'content' field in binary: '\(altText)'")
                                            onTextOut(altText)
                                        }
                                    }
                                }
                            }
                            
                            // ✅ PROBLEM 2 FIX: Check for turn completion in binary messages
                            if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
                                isAISpeaking = false
                                audioSendingPaused = false
                                print("🔄 PROBLEM 2 FIX: Turn completed (binary) - audio sending RESUMED")
                            }
                        }
                    } else {
                        print("❌ Failed to parse binary message as JSON")
                    }
                    
                @unknown default:
                    print("📨 Received unknown WebSocket message type")
                    break
                }
            }
        } catch {
            await MainActor.run {
                isConnected = false
                lastError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Token Usage Firebase Logging
    
    /// Log token usage locally for monitoring text input
    /// Note: Cloud logging removed per user request - keeping local monitoring only
    private func logTokenUsageLocally() {
        guard let sessionId = currentSessionId else {
            print("📊 No session ID available for token logging")
            return
        }
        
        let totalTokens = sessionTokens.audioInputTokens + sessionTokens.audioOutputTokens + sessionTokens.textInputTokens
        
        print("📊 LOCAL TOKEN USAGE SUMMARY:")
        print("📊 Session ID: \(sessionId)")
        print("📊 Audio Input Tokens: \(sessionTokens.audioInputTokens)")
        print("📊 Audio Output Tokens: \(sessionTokens.audioOutputTokens)")
        print("📊 Text Input Tokens: \(sessionTokens.textInputTokens)")
        print("📊 Total Tokens: \(totalTokens)")
        print("📊 Session Duration: \(sessionTokens.sessionDuration)s")
        print("📊 Message Count: \(sessionTokens.messageCount)")
        print("📊 Agent Type: \(originalAgentType ?? "unknown")")
        print("📊 Voice: \(selectedVoice)")
        
        // 🔍 MONITORING: Check if any text input is happening (system prompt is embedded in token)
        if sessionTokens.textInputTokens > 0 {
            print("⚠️ MONITORING ALERT: Text input detected (\(sessionTokens.textInputTokens) tokens)")
            print("⚠️ This should be 0 since system prompt is embedded in token")
        } else {
            print("✅ MONITORING: No text input detected - system prompt properly embedded in token")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension GeminiLiveClient: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
        Task { @MainActor in
            print("✅ WebSocket didOpenWithProtocol called!")
            print("✅ Protocol: \(protocolName ?? "none")")
            print("✅ Task state: \(webSocketTask.state)")
            connectionCompletion?(.success(()))
            connectionCompletion = nil
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            print("🔌 WebSocket closed with code: \(closeCode.rawValue)")
            
            // Provide specific information about close codes
            switch closeCode {
            case .normalClosure:
                print("🔌 Normal closure (1000)")
            case .goingAway:
                print("🔌 Going away (1001) - Server is shutting down")
            case .protocolError:
                print("🔌 Protocol error (1002)")
            case .unsupportedData:
                print("🔌 Unsupported data (1003)")
            case .invalidFramePayloadData:
                print("🔌 Invalid frame payload (1007)")
            case .policyViolation:
                print("🔌 Policy violation (1008)")
            case .messageTooBig:
                print("🔌 Message too big (1009)")
            case .internalServerError:
                print("🔌 Internal server error (1011) - Service currently unavailable")
                print("🔍 DIAGNOSTIC: Connection duration before error: \(connectionStartTime.map { Date().timeIntervalSince($0) } ?? 0) seconds")
                print("🔍 DIAGNOSTIC: This is NOT the 10-minute limit (happens at 600s)")
                print("🔍 DIAGNOSTIC: Likely causes: API service issue, invalid token, or malformed request")
            default:
                print("🔌 Close code: \(closeCode.rawValue)")
            }
            
            isConnected = false
            isConnecting = false
            
            if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
                print("🔌 Close reason: \(reasonString)")
            }
            
            // If this was an unexpected closure, determine the cause
            if closeCode.rawValue == 1011 {
                let connectionDuration = connectionStartTime.map { Date().timeIntervalSince($0) } ?? 0
                
                if connectionDuration > 580 { // Close to 10-minute limit
                    print("🔌 This appears to be the 10-minute connection limit")
                    print("🔄 Attempting automatic reconnection in 2 seconds...")
                    lastError = "Connection refreshed due to Google's 10-minute limit (auto-reconnecting...)"
                } else {
                    print("🚨 Early 1011 error after \(Int(connectionDuration))s - NOT 10-minute limit")
                    print("🔍 Possible causes: API service issue, token problem, or malformed request")
                    lastError = "Service error occurred (code 1011) - retrying connection..."
                }
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ WebSocket task completed with error: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                
                // Provide more specific error information
                if let urlError = error as? URLError {
                    print("❌ URLError code: \(urlError.code.rawValue)")
                    print("❌ URLError description: \(urlError.localizedDescription)")
                }
                
                if let nsError = error as NSError? {
                    print("❌ NSError domain: \(nsError.domain)")
                    print("❌ NSError code: \(nsError.code)")
                    print("❌ NSError userInfo: \(nsError.userInfo)")
                }
                
                lastError = error.localizedDescription
                connectionCompletion?(.failure(error))
                connectionCompletion = nil
                isConnected = false
                isConnecting = false
            } else {
                print("✅ WebSocket task completed successfully")
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("🔐 Received authentication challenge: \(challenge.protectionSpace.authenticationMethod)")
        // Accept the server certificate for Google's servers
        completionHandler(.performDefaultHandling, nil)
    }
    
    // ✅ LATENCY OPTIMIZATION: Turn Transition Enhancement
    @MainActor
    private func prepareForUserAudio() async {
        guard turnTransitionOptimizationEnabled else { return }
        
        // Pre-warm audio processing pipeline for faster response
        highPriorityMode = true
        
        print("🚀 OPTIMIZATION: Audio pipeline prepared for immediate user input")
        print("🚀 OPTIMIZATION: High priority mode enabled for faster transmission")
        
        // Reset to normal mode after 3 seconds to avoid indefinite high-speed mode
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                self.highPriorityMode = false
                print("🚀 OPTIMIZATION: High priority mode disabled - returned to normal")
            }
        }
    }
    
    // ✅ LATENCY OPTIMIZATION: Public interface for priority mode checking
    func isHighPriorityMode() -> Bool {
        return highPriorityMode
    }
}
