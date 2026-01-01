// import Foundation
// import FirebaseFunctions
// import CryptoKit

// // MARK: - Rate Limiter (Security Implementation from MainAppPlan.md)
// class RateLimiter {
//     private var lastReques        // 1. Get ephemeral JWT from Cloud Function with system prompt, agent type and optional voice
//         let token = try await fetchToken(
//             systemPrompt: systemPrompt,
//             agentType: agentType,        guard let json = try? JSONSerialization.data(withJSONObject: frame, options: []),
//               let string = String(data: json, encoding: .utf8) else { 
//             print("❌ Failed to encode text frame")
//             return 
//         }
        
//         // 🔍 DEBUG: Monitor text message size for snowballing detection
//         let messageSize = string.count
//         print("🔍 DEBUG - Text message: '\(text)' → JSON: \(messageSize) chars")
        
//         // 🚨 SNOWBALL DETECTION: Alert if text message grows unexpectedly large
//         if messageSize > (text.count * 5) {  // Should be roughly 5x the text length
//             print("🚨 SNOWBALL ALERT: Text message JSON unusually large: \(messageSize) chars for '\(text)'")
//             print("🚨 This could indicate conversation history being sent with text!")
//         }
        
//         print("📤 Sending text message: \(text)")
        
//         do {
//             try await socket.send(.string(string))
//             print("✅ Text message sent successfully")
//         } catch {
//             print("❌ Failed to send text WebSocket message: \(error)")
//             // Mark as disconnected if sending fails
//             isConnected = false
//         }iceName: voiceName
//         )
//         print("✅ CORRECTED: Got token with embedded system prompt for constrained endpoint")
        
//         // ✅ Connect with session resumption support
//         try await connectWithSessionResumption(token: token)te = Date()
//     private var requestCount: Int = 0
//     private let maxRequestsPerMinute: Int = 1000 // Higher limit for audio streaming
//     private let minTimeBetweenRequests: TimeInterval = 0.05 // 50ms for real-time audio
    
//     // Separate tracking for different request types
//     private var a    // MARK: - Privat    private func fetchToken(systemPrompt: String, agentType: String = "money-master", voiceName: String? = nil) async throws -> String {
//         print("🔄 Fetching ephemeral token from Cloud Function for agent: \(agentType)")
//         if let voiceName = voiceName {
//             print("🎯 Requesting specific voice: \(voiceName)")
//         }
//         print("✅ CORRECTED: System prompt will be embedded in token for constrained endpoint")
        
//         let fn = Functions.functions().httpsCallable("getGeminiEphemeralToken")
        
//         do {
//             // ✅ CORRECTED: Re-add systemPrompt parameter - required for constrained endpoint
//             var parameters: [String: Any] = [
//                 "agentType": agentType,
//                 "systemPrompt": systemPrompt
//             ]private func fetchToken(systemPrompt: String, agentType: String = "money-master", voiceName: String? = nil) async throws -> String {
//         print("🔄 Fetching ephemeral token from Cloud Function for agent: \(agentType)")
//         if let voiceName = voiceName {
//             print("🎯 Requesting specific voice: \(voiceName)")
//         }
//         print("✅ CORRECTED: System prompt will be embedded in token for constrained endpoint")
        
//         let fn = Functions.functions().httpsCallable("getGeminiEphemeralToken")
        
//         do {
//             // ✅ CORRECTED: Re-add systemPrompt parameter - required for constrained endpoint
//             var parameters: [String: Any] = [
//                 "agentType": agentType,
//                 "systemPrompt": systemPrompt // This MUST be included for proper functioning
//             ]
            
//             // Add voice name if provided for direct voice selection
//             if let voiceName = voiceName {
//                 parameters["voiceName"] = voiceName
//             }t = 0
//     private var lastAudioRequestTime: Date = Date()
//     private let maxAudioRequestsPerSecond: Int = 20 // ~50ms intervals
    
//     func canMakeRequest() -> Bool {
//         let now = Date()
        
//         // Reset counter every minute
//         if now.timeIntervalSince(lastRequestTime) > 60 {
//             requestCount = 0
//         }
        
//         // Check rate limits
//         guard requestCount < maxRequestsPerMinute else {
//             print("🚨 SECURITY: Rate limit exceeded")
//             return false
//         }
        
//         guard now.timeIntervalSince(lastRequestTime) >= minTimeBetweenRequests else {
//             print("🚨 SECURITY: Request too frequent")
//             return false
//         }
        
//         requestCount += 1
//         lastRequestTime = now
//         return true
//     }
    
//     func canMakeAudioRequest() -> Bool {
//         let now = Date()
        
//         // Reset audio counter every second
//         if now.timeIntervalSince(lastAudioRequestTime) > 1.0 {
//             audioRequestCount = 0
//         }
        
//         // Check audio-specific rate limits
//         guard audioRequestCount < maxAudioRequestsPerSecond else {
//             print("🚨 SECURITY: Audio rate limit exceeded")
//             return false
//         }
        
//         // Allow faster audio requests (50ms minimum)
//         guard now.timeIntervalSince(lastAudioRequestTime) >= 0.05 else {
//             print("🚨 SECURITY: Audio request too frequent")
//             return false
//         }
        
//         audioRequestCount += 1
//         lastAudioRequestTime = now
//         return true
//     }
// }

// // MARK: - JSON frame models (simplified for minimal setup frame)
// // Only keeping the basic structures needed for system instruction

// // MARK: - TranscriptionMessage Model
// struct TranscriptionMessage: Identifiable, Codable {
//     let id = UUID()
//     let text: String
//     let timestamp: Date
//     let isUser: Bool
    
//     init(text: String, isUser: Bool) {
//         self.text = text
//         self.timestamp = Date()
//         self.isUser = isUser
//     }
// }

// // MARK: - Audio Constants
// let SAMPLE_RATE = 16000 // 16kHz sample rate for input audio

// // MARK: - Client
// import Foundation
// import AVFoundation
// import CryptoKit

// @MainActor
// class GeminiLiveClient: NSObject, ObservableObject {
    
//     // MARK: - Properties
//     @Published var isConnected = false
//     @Published var isConnecting = false
//     @Published var lastError: String?
//     @Published var transcriptionMessages: [TranscriptionMessage] = []
    
//     private var socket: URLSessionWebSocketTask?
//     private let encoder = JSONEncoder()
//     private var connectionCompletion: ((Result<Void, Error>) -> Void)?
    
//     private let speechSynthesizer = AVSpeechSynthesizer()
//     private var audioEngine: AVAudioEngine?
//     private var inputNode: AVAudioInputNode?
//     private var isRecordingEnabled = true
    
//     // Rate limiting
//     private var lastConversationStart: Date?
//     private let rateLimitInterval: TimeInterval = 30 // 30 seconds between conversations
//     private let rateLimiter = RateLimiter() // Add rate limiter instance
    
//     // Voice selection tracking
//     private var selectedVoice: String = "Aoede" // Default voice
    
//     // MARK: - Session Management (10-minute limit handling + Context Preservation)
//     private var sessionHandle: String?
//     private var connectionStartTime: Date?
//     private var reconnectionTimer: Timer?
//     private var conversationDuration: TimeInterval = 0
    
//     // Context preservation for seamless session resumption
//     private var originalSystemPrompt: String?
//     private var originalAgentType: String?
//     private var originalVoiceName: String?
//     private var onAudioOutCallback: ((Data) -> Void)?
//     private var onTextOutCallback: ((String) -> Void)?

//     /// Entry point with agent support and optional voice selection - ✅ CORRECTED: System prompt embedded in token for constrained endpoint
//     func start(systemPrompt: String, agentType: String = "money-master", voiceName: String? = nil, onAudioOut: @escaping (Data) -> Void, onTextOut: @escaping (String) -> Void) async throws {
//         lastError = nil
//         guard !isConnecting else { return }
//         isConnecting = true
//         defer { isConnecting = false }
        
//         // ✅ Store original parameters for session resumption
//         originalSystemPrompt = systemPrompt
//         originalAgentType = agentType
//         originalVoiceName = voiceName
//         onAudioOutCallback = onAudioOut
//         onTextOutCallback = onTextOut
        
//         // 1. Get ephemeral JWT from Cloud Function with agent type and optional voice
//         let token = try await fetchToken(
//             agentType: agentType, 
//             voiceName: voiceName
//         )
//         print("�️ Got token without embedded system prompt (optimization fix)")
        
//         // ✅ Connect and send system prompt as setup frame
//         try await connectWithSessionResumption(token: token, systemPrompt: systemPrompt)
        
//         // Record connection start time for session management
//         connectionStartTime = Date()
        
//         // Start session monitoring for 8-minute reconnections
//         startConnectionMonitoring()
        
//         isConnected = true
//         print("✅ Live API connection established with context preservation.")
        
//         Task {
//             await receiveLoop(onAudioOut: onAudioOut, onTextOut: onTextOut)
//         }
//     }
    
//     /// Connect to WebSocket with session resumption support
//     private func connectWithSessionResumption(token: String) async throws {
//         // Use constrained endpoint for tokens with embedded configurations
//         let urlString = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=\(token)"
        
//         print("🔧 Connecting to WebSocket URL with session resumption...")
//         print("🔄 Session handle: \(sessionHandle ?? "new session")")
        
//         guard let url = URL(string: urlString) else {
//             print("❌ Invalid URL created.")
//             throw URLError(.badURL)
//         }
        
//         var request = URLRequest(url: url)
//         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
//         // Connect to WebSocket
//         let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//         let task = session.webSocketTask(with: request)
//         socket = task
        
//         // Try to connect with timeout
//         _ = try await withTimeout(seconds: 15) {
//             try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
//                 self.connectionCompletion = { result in
//                     print("🔧 Connection completion called with result: \(result)")
//                     continuation.resume(with: result)
//                 }
//                 print("🔧 Starting WebSocket task...")
//                 task.resume()
//                 print("🔧 WebSocket task.resume() called, waiting for connection...")
//             }
//         }
        
//         print("✅ WebSocket connected successfully to CONSTRAINED endpoint.")
        
//         // Send setup frame with session resumption if available
//         let setupFrame: [String: Any]
//         if let handle = sessionHandle {
//             // Resume existing session with conversation history
//             setupFrame = [
//                 "setup": [
//                     "session_resumption": [
//                         "handle": handle
//                     ]
//                 ]
//             ]
//             print("🔄 Resuming session with handle: \(handle)")
//         } else {
//             // ✅ CORRECTED: New session with system prompt already embedded in token
//             // No setup frame needed for new sessions with constrained endpoint
//             setupFrame = ["setup": [:]]
//             print("🆕 Starting new session. System instruction is embedded in the token.")
//         }
        
//         guard let setupJson = try? JSONSerialization.data(withJSONObject: setupFrame, options: []),
//               let setupString = String(data: setupJson, encoding: .utf8) else { 
//             print("❌ Failed to encode setup frame")
//             throw URLError(.cannotParseResponse)
//         }
        
//         print("🔧 Sending setup frame...")
//         try await task.send(.string(setupString))
//         print("✅ Setup frame sent successfully.")

//         // ✅ CORRECTED: System instruction is embedded in token for constrained endpoint
//         // This follows the official recommendation for BidiGenerateContentConstrained endpoint
//         print("🎯 Official Implementation: System instruction embedded in ephemeral token (most secure and reliable)")
//         print("✅ No text priming - pure audio-only conversation experience")
//     }
    
//     // MARK: - Session Resumption & Context Preservation
    
//     /// Reconnect with session resumption to preserve conversation context (Public method)
//     func reconnectWithSessionResumption() async {
//         print("🔄 Reconnecting with session resumption to preserve context...")
        
//         // Store current session state
//         let savedHandle = sessionHandle
        
//         // Close current connection gracefully
//         await socket?.cancel(with: .normalClosure, reason: nil)
//         socket = nil
//         isConnected = false
        
//         // Brief delay before reconnection
//         try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
//         // Check if we have the original parameters for reconnection
//         guard let systemPrompt = originalSystemPrompt,
//               let agentType = originalAgentType,
//               let onAudioOut = onAudioOutCallback,
//               let onTextOut = onTextOutCallback else {
//             print("❌ Missing original parameters for session resumption")
//             lastError = "Connection lost. Please restart your conversation."
//             return
//         }
        
//         do {
//             // Get a new ephemeral token for the session
//             let newToken = try await fetchToken(
//                 systemPrompt: systemPrompt,
//                 agentType: agentType,
//                 voiceName: originalVoiceName
//             )
            
//             // Restore the saved session handle for context preservation
//             sessionHandle = savedHandle
            
//             // Reconnect with the new token and preserved session handle
//             try await connectWithSessionResumption(token: newToken)
            
//             // Reset connection tracking
//             connectionStartTime = Date()
//             isConnected = true
            
//             // Resume the receive loop
//             Task {
//                 await receiveLoop(onAudioOut: onAudioOut, onTextOut: onTextOut)
//             }
            
//             print("✅ Session resumption successful - conversation context preserved!")
//             lastError = nil
            
//         } catch {
//             print("❌ Session resumption failed: \(error)")
//             lastError = "Failed to resume session. Please restart your conversation."
            
//             // Reset session state
//             connectionStartTime = nil
//             sessionHandle = nil
//         }
//     }
    
//     // MARK: - WebSocket Message Handling
    
//     // Helper function to add timeout to async operations
//     private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
//         try await withThrowingTaskGroup(of: T.self) { group in
//             group.addTask {
//                 try await operation()
//             }
            
//             group.addTask {
//                 try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
//                 throw URLError(.timedOut)
//             }
            
//             guard let result = try await group.next() else {
//                 throw URLError(.timedOut)
//             }
            
//             group.cancelAll()
//             return result
//         }
//     }

//     /// Send text message to trigger AI response (for auto-greeting)
//     func sendTextMessage(_ text: String) async {
//         // 🔒 SECURITY: Rate limiting check
//         guard rateLimiter.canMakeRequest() else {
//             print("🚨 SECURITY: Text message blocked by rate limiter")
//             return
//         }
        
//         guard isConnected, let socket = socket else {
//             print("⚠️ Cannot send text - WebSocket not connected")
//             return
//         }
        
//         let frame = [
//             "clientContent": [
//                 "turns": [
//                     [
//                         "role": "user",
//                         "parts": [
//                             ["text": text]
//                         ]
//                     ]
//                 ],
//                 "turnComplete": true
//             ]
//         ]
        
//         guard let json = try? JSONSerialization.data(withJSONObject: frame, options: []),
//               let string = String(data: json, encoding: .utf8) else { 
//             print("❌ Failed to encode text frame")
//             return 
//         }
        
//         print("📤 Sending text message: \(text)")
        
//         do {
//             try await socket.send(.string(string))
//             print("✅ Text message sent successfully")
//         } catch {
//             print("❌ Failed to send text WebSocket message: \(error)")
//             // Mark as disconnected if sending fails
//             isConnected = false
//         }
//     }

//     /// Send raw 16 kHz Int16 mono PCM
//     func send(audioData: Data) async {
//         // 🔒 SECURITY: Audio-specific rate limiting check - DISABLED FOR TESTING
//         // guard rateLimiter.canMakeAudioRequest() else {
//         //     print("🚨 SECURITY: Audio request blocked by rate limiter")
//         //     return
//         // }
        
//         guard isConnected, let socket = socket else {
//             print("⚠️ Cannot send audio - WebSocket not connected")
//             return
//         }
        
//         // 🔍 DEBUG: Monitor what we're sending to detect snowballing
//         static var audioChunkCount = 0
//         audioChunkCount += 1
        
//         let base64 = audioData.base64EncodedString()
//         let frame = [
//             "realtimeInput": [
//                 "mediaChunks": [
//                     [
//                         "data": base64, 
//                         "mimeType": "audio/pcm;rate=\(SAMPLE_RATE)"
//                     ]
//                 ]
//             ]
//         ]
        
//         // 🔍 DEBUG: Log message size to detect token usage patterns
//         guard let json = try? JSONSerialization.data(withJSONObject: frame, options: []),
//               let string = String(data: json, encoding: .utf8) else { 
//             print("❌ Failed to encode audio frame")
//             return 
//         }
        
//         // 🔍 DEBUG: Log audio frame details to monitor for snowballing
//         let messageSize = string.count
//         let audioDataSize = audioData.count
//         print("🔍 DEBUG - Audio chunk #\(audioChunkCount): \(audioDataSize) bytes → JSON: \(messageSize) chars")
        
//         // 🚨 SNOWBALL DETECTION: Alert if message size grows unexpectedly
//         if messageSize > 1000 {  // Base64 audio should be ~700-800 chars typically
//             print("🚨 SNOWBALL ALERT: Audio message size unusually large: \(messageSize) chars")
//             print("🚨 This could indicate conversation history being sent with audio!")
//         }
        
//         print("📤 Sending audio frame: \(audioData.count) bytes")
        
//         do {
//             try await socket.send(.string(string))
//             print("✅ Audio frame sent successfully")
//         } catch {
//             print("❌ Failed to send audio WebSocket message: \(error)")
//             // Mark as disconnected if sending fails
//             isConnected = false
//         }
//     }

//     func stop() async {
//         await socket?.cancel(with: .normalClosure, reason: nil)
//         socket = nil
//         isConnected = false
//         reconnectionTimer?.invalidate()
//         reconnectionTimer = nil
//         connectionStartTime = nil
//         sessionHandle = nil
//     }
    
//     // MARK: - Session Management Methods
    
//     override init() {
//         super.init()
//         startConnectionMonitoring()
//     }
    
//     deinit {
//         reconnectionTimer?.invalidate()
//     }
    
//     private func startConnectionMonitoring() {
//         // Monitor connection and proactively reconnect before 10-minute limit
//         reconnectionTimer = Timer.scheduledTimer(withTimeInterval: 480, repeats: true) { [weak self] _ in
//             Task { @MainActor in
//                 await self?.proactiveReconnection()
//             }
//         }
//     }
    
//     private func proactiveReconnection() async {
//         guard isConnected,
//               let startTime = connectionStartTime else { return }
        
//         let connectionAge = Date().timeIntervalSince(startTime)
        
//         // Reconnect after 8 minutes (480 seconds) to avoid 10-minute limit
//         if connectionAge > 480 {
//             print("🔄 Proactive reconnection due to 10-minute limit approaching")
//             lastError = "Refreshing connection to maintain optimal performance..."
            
//             // Use the enhanced session resumption to preserve context
//             await reconnectWithSessionResumption()
//         }
//     }
    
//     private func handleGoAwayMessage(_ goAway: [String: Any]) async {
//         print("🚨 GoAway message received: \(goAway)")
        
//         // Extract time left from the message (typically in milliseconds)
//         let timeLeft = goAway["timeLeft"] as? Double ?? 5.0 // Default to 5 seconds
        
//         print("🚨 Server requesting disconnection in \(timeLeft) seconds")
        
//         // Proactively reconnect with 80% of the remaining time as buffer
//         let reconnectDelay = timeLeft * 0.8
        
//         DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) {
//             Task { @MainActor in
//                 print("🔄 Proactive reconnection triggered by GoAway message")
//                 await self.reconnectWithSessionResumption()
//             }
//         }
//     }

//     // MARK: - Private helpers
//     private func fetchToken(agentType: String = "money-master", voiceName: String? = nil) async throws -> String {
//         print("🔄 Fetching ephemeral token from Cloud Function for agent: \(agentType)")
//         if let voiceName = voiceName {
//             print("🎯 Requesting specific voice: \(voiceName)")
//         }
//         print("�️ System prompt will be sent separately in setup frame (token optimization fix)")
        
//         let fn = Functions.functions().httpsCallable("getGeminiEphemeralToken")
        
//         do {
//             // ✅ OPTIMIZED: Remove systemPrompt to prevent token overuse
//             var parameters: [String: Any] = [
//                 "agentType": agentType
//             ]
            
//             // Add voice name if provided for direct voice selection
//             if let voiceName = voiceName {
//                 parameters["voiceName"] = voiceName
//             }
            
//             let result = try await fn.call(parameters)
//             print("✅ Cloud Function response: \(result.data)")
            
//             guard let data = result.data as? [String: Any],
//                   let token = data["ephemeralToken"] as? String else {
//                 print("🛑 Invalid token response format: \(result.data)")
//                 throw URLError(.badServerResponse)
//             }
            
//             // Log enhanced voice selection information
//             if let voice = data["voice"] as? String {
//                 let voiceType = data["voiceType"] as? String ?? "unknown"
//                 let selectionMethod = data["selectionMethod"] as? String ?? "unknown"
//                 print("🎯 Selected voice: \(voice) (\(voiceType)) via \(selectionMethod) for agent: \(agentType)")
//                 selectedVoice = voice // Store the voice from token response
//             } else {
//                 print("⚠️ No voice specified in token response, using default: \(selectedVoice)")
//             }
            
//             // Log available voices for debugging
//             if let availableVoices = data["availableVoices"] as? [String: [String]] {
//                 let feminineCount = availableVoices["feminine"]?.count ?? 0
//                 let masculineCount = availableVoices["masculine"]?.count ?? 0
//                 print("📊 Available voices: \(feminineCount) feminine, \(masculineCount) masculine")
//             }
            
//             print("✅ Successfully got token: \(token.prefix(20))...")
//             return token
//         } catch {
//             print("🛑 Token fetch error: \(error)")
//             if let nsError = error as NSError? {
//                 print("🛑 Error domain: \(nsError.domain)")
//                 print("🛑 Error code: \(nsError.code)")
//                 print("🛑 Error info: \(nsError.userInfo)")
//             }
//             throw error
//         }
//     }

//     // MARK: - Character Priming (replaces setup frame approach)
//     // The priming approach works better with ephemeral tokens since
//     // system instructions in setup frames are ignored by the constrained endpoint

//     private func receiveLoop(onAudioOut: @escaping (Data) -> Void, onTextOut: @escaping (String) -> Void) async { // ✅ Step 1.3: Added onTextOut parameter
//         guard let task = socket else { return }
//         do {
//             while true {
//                 let message = try await task.receive()
//                 switch message {
//                 case .string(let text):
//                     print("📨 Received string WebSocket message: \(text.prefix(200))...")
//                     guard let data = text.data(using: .utf8),
//                           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { 
//                         print("⚠️ Failed to parse WebSocket message")
//                         continue 
//                     }
                    
//                     // Handle GoAway messages for proactive reconnection
//                     if let goAway = dict["goAway"] as? [String: Any] {
//                         print("🚨 Received GoAway message: \(goAway)")
//                         await handleGoAwayMessage(goAway)
//                         continue
//                     }
                    
//                     // Handle session resumption updates
//                     if let sessionUpdate = dict["sessionResumptionUpdate"] as? [String: Any] {
//                         print("🔄 Received session resumption update: \(sessionUpdate)")
                        
//                         // Store the new session handle for context preservation
//                         if let newHandle = sessionUpdate["newHandle"] as? String, !newHandle.isEmpty,
//                            let resumable = sessionUpdate["resumable"] as? Bool, resumable {
//                             sessionHandle = newHandle
//                             print("📱 Updated session handle for context preservation: \(newHandle)")
//                             print("✅ Session is resumable - conversation context will be preserved")
//                         } else {
//                             print("⚠️ Session not resumable or no handle provided")
//                             if let resumable = sessionUpdate["resumable"] as? Bool, !resumable {
//                                 print("❌ Session resumption is not available at this point")
//                             }
//                         }
                        
//                         // Log additional session resumption details
//                         if let lastConsumedIndex = sessionUpdate["lastConsumedClientMessageIndex"] as? Int {
//                             print("📊 Last consumed client message index: \(lastConsumedIndex)")
//                         }
                        
//                         continue
//                     }
                    
//                     // Check for different types of server messages
//                     if let serverContent = dict["serverContent"] as? [String: Any] {
//                         print("📋 Server content received: \(serverContent.keys)")
                        
//                         // ENHANCED DEBUGGING: Print the entire server response for transcript debugging
//                         if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
//                            let jsonString = String(data: jsonData, encoding: .utf8) {
//                             print("🔍 FULL SERVER RESPONSE:\n\(jsonString)")
//                         }
                        
//                         // Try to extract audio and text data
//                         if let modelTurn = serverContent["modelTurn"] as? [String: Any],
//                            let parts = modelTurn["parts"] as? [[String: Any]] {
//                             print("📋 Found \(parts.count) parts in modelTurn")
                            
//                             for (index, part) in parts.enumerated() {
//                                 print("📋 Part \(index) keys: \(part.keys)")
                                
//                                 // Check for audio data (existing logic)
//                                 if let inlineData = part["inlineData"] as? [String: Any],
//                                    let base64 = inlineData["data"] as? String,
//                                    let mimeType = inlineData["mimeType"] as? String,
//                                    mimeType.contains("audio") {
                                    
//                                     print("🎧 Audio MIME type: \(mimeType)")
                                    
//                                     // Verify the output format matches what LessonView expects
//                                     if mimeType.contains("rate=24000") || mimeType.contains("24000") {
//                                         if let pcm = Data(base64Encoded: base64) {
//                                             print("🔊 Received audio chunk: \(pcm.count) bytes (24kHz)")
//                                             onAudioOut(pcm)
//                                         } else {
//                                             print("❌ Failed to decode base64 audio data")
//                                         }
//                                     } else {
//                                         print("⚠️ Unexpected audio format: \(mimeType) - Expected 24kHz")
//                                         // Still try to play it, but log the mismatch
//                                         if let pcm = Data(base64Encoded: base64) {
//                                             print("🔊 Received audio chunk: \(pcm.count) bytes (unknown rate)")
//                                             onAudioOut(pcm)
//                                         }
//                                     }
//                                 }
                                
//                                 // ✅ Step 1.3: Check for text data with enhanced debugging
//                                 if let transcript = part["text"] as? String {
//                                     print("🎯 TRANSCRIPT FOUND! Content: '\(transcript)'")
//                                     onTextOut(transcript)
//                                 } else {
//                                     print("📝 No 'text' field found in part \(index). Available keys: \(part.keys)")
//                                     // Check for other possible text field names
//                                     if let altText = part["transcript"] as? String {
//                                         print("🎯 FOUND ALTERNATIVE 'transcript' field: '\(altText)'")
//                                         onTextOut(altText)
//                                     } else if let altText = part["content"] as? String {
//                                         print("🎯 FOUND ALTERNATIVE 'content' field: '\(altText)'")
//                                         onTextOut(altText)
//                                     }
//                                 }
//                             }
//                         }
//                     } else {
//                         print("📋 Non-audio message received: \(dict.keys)")
//                     }
                    
//                 case .data(let data):
//                     print("📨 Received binary WebSocket message: \(data.count) bytes")
//                     // Try to parse binary data as JSON
//                     if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                         print("📋 Parsed binary message: \(dict.keys)")
                        
//                         // Same audio and text extraction logic for binary messages
//                         if let serverContent = dict["serverContent"] as? [String: Any] {
//                             print("📋 Server content in binary message: \(serverContent.keys)")
                            
//                             // Enhanced debugging: Log binary message metadata only
//                             #if DEBUG
//                             if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
//                                let jsonString = String(data: jsonData, encoding: .utf8) {
//                                 print("🔍 Binary response: \(jsonString.count) chars, keys: \(dict.keys.sorted())")
//                             }
//                             #endif
                            
//                             if let modelTurn = serverContent["modelTurn"] as? [String: Any],
//                                let parts = modelTurn["parts"] as? [[String: Any]] {
//                                 print("📋 Found \(parts.count) parts in binary modelTurn")
                                
//                                 for (index, part) in parts.enumerated() {
//                                     print("📋 Binary part \(index) keys: \(part.keys)")
                                    
//                                     // Check for audio data (existing logic)
//                                     if let inlineData = part["inlineData"] as? [String: Any],
//                                        let base64 = inlineData["data"] as? String,
//                                        let mimeType = inlineData["mimeType"] as? String,
//                                        mimeType.contains("audio") {
                                        
//                                         print("🎧 Audio MIME type from binary: \(mimeType)")
                                        
//                                         // Verify the output format matches what LessonView expects
//                                         if mimeType.contains("rate=24000") || mimeType.contains("24000") {
//                                             if let pcm = Data(base64Encoded: base64) {
//                                                 print("🔊 Received audio chunk from binary: \(pcm.count) bytes (24kHz)")
//                                                 onAudioOut(pcm)
//                                             } else {
//                                                 print("❌ Failed to decode base64 audio data from binary")
//                                             }
//                                         } else {
//                                             print("⚠️ Unexpected audio format from binary: \(mimeType) - Expected 24kHz")
//                                             // Still try to play it, but log the mismatch
//                                             if let pcm = Data(base64Encoded: base64) {
//                                                 print("🔊 Received audio chunk from binary: \(pcm.count) bytes (unknown rate)")
//                                                 onAudioOut(pcm)
//                                             }
//                                         }
//                                     }
                                    
//                                     // ✅ Step 1.3: Check for text data in binary messages with enhanced debugging
//                                     if let transcript = part["text"] as? String {
//                                         print("🎯 TRANSCRIPT FOUND IN BINARY! Content: '\(transcript)'")
//                                         onTextOut(transcript)
//                                     } else {
//                                         print("📝 No 'text' field found in binary part \(index). Available keys: \(part.keys)")
//                                         // Check for other possible text field names
//                                         if let altText = part["transcript"] as? String {
//                                             print("🎯 FOUND ALTERNATIVE 'transcript' field in binary: '\(altText)'")
//                                             onTextOut(altText)
//                                         } else if let altText = part["content"] as? String {
//                                             print("🎯 FOUND ALTERNATIVE 'content' field in binary: '\(altText)'")
//                                             onTextOut(altText)
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     } else {
//                         print("❌ Failed to parse binary message as JSON")
//                     }
                    
//                 @unknown default:
//                     print("📨 Received unknown WebSocket message type")
//                     break
//                 }
//             }
//         } catch {
//             await MainActor.run {
//                 isConnected = false
//                 lastError = error.localizedDescription
//             }
//         }
//     }
// }

// // MARK: - URLSessionWebSocketDelegate
// extension GeminiLiveClient: URLSessionWebSocketDelegate {
//     nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
//         Task { @MainActor in
//             print("✅ WebSocket didOpenWithProtocol called!")
//             print("✅ Protocol: \(protocolName ?? "none")")
//             print("✅ Task state: \(webSocketTask.state)")
//             connectionCompletion?(.success(()))
//             connectionCompletion = nil
//         }
//     }
    
//     nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
//         Task { @MainActor in
//             print("🔌 WebSocket closed with code: \(closeCode.rawValue)")
            
//             // Provide specific information about close codes
//             switch closeCode {
//             case .normalClosure:
//                 print("🔌 Normal closure (1000)")
//             case .goingAway:
//                 print("🔌 Going away (1001) - Server is shutting down")
//             case .protocolError:
//                 print("🔌 Protocol error (1002)")
//             case .unsupportedData:
//                 print("🔌 Unsupported data (1003)")
//             case .invalidFramePayloadData:
//                 print("🔌 Invalid frame payload (1007)")
//             case .policyViolation:
//                 print("🔌 Policy violation (1008)")
//             case .messageTooBig:
//                 print("🔌 Message too big (1009)")
//             case .internalServerError:
//                 print("🔌 Internal server error (1011) - Service currently unavailable")
//             default:
//                 print("🔌 Close code: \(closeCode.rawValue)")
//             }
            
//             isConnected = false
//             isConnecting = false
            
//             if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
//                 print("🔌 Close reason: \(reasonString)")
//             }
            
//             // If this was an unexpected closure due to 10-minute limit, show helpful message
//             if closeCode.rawValue == 1011 {
//                 print("🔌 This appears to be the 10-minute connection limit")
//                 lastError = "Connection was refreshed due to Google's 10-minute limit. This is normal behavior."
//             }
//         }
//     }
    
//     nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//         Task { @MainActor in
//             if let error = error {
//                 print("❌ WebSocket task completed with error: \(error)")
//                 print("❌ Error details: \(error.localizedDescription)")
                
//                 // Provide more specific error information
//                 if let urlError = error as? URLError {
//                     print("❌ URLError code: \(urlError.code.rawValue)")
//                     print("❌ URLError description: \(urlError.localizedDescription)")
//                 }
                
//                 if let nsError = error as NSError? {
//                     print("❌ NSError domain: \(nsError.domain)")
//                     print("❌ NSError code: \(nsError.code)")
//                     print("❌ NSError userInfo: \(nsError.userInfo)")
//                 }
                
//                 lastError = error.localizedDescription
//                 connectionCompletion?(.failure(error))
//                 connectionCompletion = nil
//                 isConnected = false
//                 isConnecting = false
//             } else {
//                 print("✅ WebSocket task completed successfully")
//             }
//         }
//     }
    
//     nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//         print("🔐 Received authentication challenge: \(challenge.protectionSpace.authenticationMethod)")
//         // Accept the server certificate for Google's servers
//         completionHandler(.performDefaultHandling, nil)
//     }
// }
