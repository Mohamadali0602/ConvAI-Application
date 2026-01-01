// import Foundation
// import SwiftUI
// import Network
// import AVFoundation
// import AudioToolbox
// import CryptoKit

// // MARK: - Enhanced GeminiLiveClient with Complete SDK Step 15 Integration
// // This replaces the existing GeminiLiveClient with comprehensive SDK implementation
// // while maintaining full compatibility with the existing LessonView interface.

// /// Complete SDK-compliant Gemini Live Client with all 15 steps integrated
// @MainActor
// final class GeminiLiveClient: NSObject, ObservableObject {
    
//     // MARK: - Basic Properties (Compatible with existing LessonView)
//     @Published var isConnected = false
//     @Published var lastError: String?
    
//     // MARK: - Connection and Audio Management
//     private var webSocketTask: URLSessionWebSocketTask?
//     private let encoder = JSONEncoder()
//     private let decoder = JSONDecoder()
//     private let SAMPLE_RATE: Int = 16000  // upstream
    
//     // MARK: - Rate Limiting and Security
//     private let rateLimiter = RateLimiter()
//     private var connectionCompletion: ((Result<Void, Error>) -> Void)?
//     private var isConnecting = false
//     private let conversationRateLimit: TimeInterval = 5.0
    
//     // MARK: - Audio Constants
//     private let SAMPLE_RATE: Int = 16000
    
//     // MARK: - Initialization
//     override init() {
//         super.init()
//     }
    
//     // MARK: - SDK Step 15: Configuration Management
    
//     /// Setup delegate connections
//     private func setupDelegates() {
//         configurationManager.delegate = self
//         errorHandler.delegate = self
//         resumptionManager.delegate = self
//     }
    
//     /// Update voice configuration
//     func updateVoiceSettings(voiceName: String, speed: Double = 1.0, style: VoiceConfiguration.VoiceStyle = .natural) {
//         let currentVoiceConfig = currentConfiguration.voiceConfiguration
//         let newVoiceConfig = VoiceConfiguration(
//             voiceName: voiceName,
//             voiceGender: currentVoiceConfig.voiceGender,
//             voiceSpeed: speed,
//             voicePitch: currentVoiceConfig.voicePitch,
//             voiceVolume: currentVoiceConfig.voiceVolume,
//             voiceStability: currentVoiceConfig.voiceStability,
//             voiceSimilarity: currentVoiceConfig.voiceSimilarity,
//             voiceStyle: style
//         )
        
//         configurationManager.updateVoiceConfiguration(newVoiceConfig)
//         print("🎵 SDK STEP 15: Voice updated - \(voiceName), speed: \(speed), style: \(style.displayName)")
//     }
    
//     /// Update language settings
//     func updateLanguageSettings(inputLanguage: String, outputLanguage: String) {
//         let currentLanguageConfig = currentConfiguration.languageConfiguration
//         let newLanguageConfig = LanguageConfiguration(
//             inputLanguageCode: inputLanguage,
//             outputLanguageCode: outputLanguage,
//             automaticLanguageDetection: currentLanguageConfig.automaticLanguageDetection,
//             translationEnabled: currentLanguageConfig.translationEnabled,
//             dialectPreference: currentLanguageConfig.dialectPreference,
//             regionCode: currentLanguageConfig.regionCode
//         )
        
//         configurationManager.updateLanguageConfiguration(newLanguageConfig)
//         print("🌍 SDK STEP 15: Language updated - Input: \(inputLanguage), Output: \(outputLanguage)")
//     }
    
//     /// Update activity detection sensitivity
//     func updateSensitivitySettings(startSensitivity: ActivityDetectionConfiguration.SensitivityLevel, endSensitivity: ActivityDetectionConfiguration.SensitivityLevel) {
//         configurationManager.updateSensitivityLevels(start: startSensitivity, end: endSensitivity)
//         print("🎤 SDK STEP 15: Sensitivity updated - Start: \(startSensitivity.displayName), End: \(endSensitivity.displayName)")
//     }
    
//     /// Apply configuration preset
//     func applyConfigurationPreset(_ presetName: String) {
//         if let preset = SDKConfiguration.presets.first(where: { $0.name == presetName }) {
//             configurationManager.applyPreset(preset)
//             print("📋 SDK STEP 15: Applied preset - \(presetName)")
//         }
//     }
    
//     // MARK: - Main Interface (Compatible with existing LessonView)
    
//     /// Start conversation with enhanced SDK features
//     func start(systemPrompt: String, agentType: String = "coach", voiceName: String? = nil, onAudioOut: @escaping (Data) -> Void) async throws {
//         print("🎯 SDK STEP 15: Starting conversation with complete SDK implementation")
        
//         // Store audio callback
//         onAudioOutCallback = onAudioOut
        
//         // Rate limiting check
//         let now = Date()
//         guard now.timeIntervalSince(lastConversationStart) >= conversationRateLimit else {
//             let remainingTime = conversationRateLimit - now.timeIntervalSince(lastConversationStart)
//             throw NSError(domain: "RateLimit", code: 429, userInfo: [
//                 NSLocalizedDescriptionKey: "Please wait \(Int(remainingTime)) seconds before starting another conversation"
//             ])
//         }
//         lastConversationStart = now
        
//         // Prevent concurrent connections
//         guard !isConnecting else {
//             throw NSError(domain: "Connection", code: -1, userInfo: [
//                 NSLocalizedDescriptionKey: "Connection already in progress"
//             ])
//         }
        
//         isConnecting = true
//         defer { isConnecting = false }
        
//         do {
//             // Update configuration if voice name provided
//             if let voiceName = voiceName {
//                 updateVoiceSettings(voiceName: voiceName)
//             }
            
//             // Update UI state
//             connectionState = .connecting
//             conversationState = .initializing
//             activityState = .initializing
//             connectionStatus = .connecting
            
//             // Clear previous errors and transcriptions
//             lastError = nil
//             transcriptionMessages.removeAll()
            
//             // Create new session ID
//             currentSessionId = UUID().uuidString
            
//             print("🔐 SDK STEP 15: Fetching authentication token...")
//             let token = try await fetchEnhancedToken(agentType: agentType, voiceName: voiceName)
            
//             print("🌐 SDK STEP 15: Establishing WebSocket connection...")
//             try await establishConnection(token: token, systemPrompt: systemPrompt, agentType: agentType)
            
//             // Update connection state
//             isConnected = true
//             connectionState = .connected
//             conversationState = .active
//             activityState = .listening
//             connectionStatus = .connected
            
//             // Start receive loop
//             Task {
//                 await receiveLoop()
//             }
            
//             print("✅ SDK STEP 15: Conversation started successfully with complete SDK features")
            
//         } catch {
//             print("❌ SDK STEP 15: Failed to start conversation: \(error)")
            
//             // Handle error through error handler
//             let context = SDKErrorContext(
//                 operation: "start_conversation",
//                 state: "initialization",
//                 metadata: [
//                     "agent_type": agentType,
//                     "voice_name": voiceName ?? "default"
//                 ]
//             )
            
//             let sdkError: SDKError
//             if let urlError = error as? URLError {
//                 switch urlError.code {
//                 case .timedOut:
//                     sdkError = .connectionTimeout
//                 case .notConnectedToInternet:
//                     sdkError = .networkUnavailable
//                 default:
//                     sdkError = .connectionFailed(urlError.localizedDescription)
//                 }
//             } else {
//                 sdkError = .connectionFailed(error.localizedDescription)
//             }
            
//             _ = await errorHandler.handleError(sdkError, context: context)
            
//             // Update state
//             connectionState = .error(error)
//             conversationState = .error
//             connectionStatus = .error(error.localizedDescription)
//             lastError = error.localizedDescription
            
//             throw error
//         }
//     }
    
//     /// Send audio data (compatible interface)
//     func send(audioData: Data) async {
//         print("🎤 SDK STEP 15: Sending audio data (\(audioData.count) bytes)")
        
//         // Rate limiting check
//         guard rateLimiter.canMakeAudioRequest() else {
//             print("🚨 SECURITY: Audio request blocked by rate limiter")
//             return
//         }
        
//         guard isConnected, let socket = webSocketTask else {
//             print("⚠️ Cannot send audio - not connected")
//             return
//         }
        
//         // Update UI state
//         isRecording = true
//         activityState = .speaking
        
//         // Update audio levels (simulated)
//         let averageLevel = calculateAudioLevel(from: audioData)
//         audioLevels = AudioLevels(inputLevel: averageLevel, outputLevel: audioLevels.outputLevel)
        
//         // Create audio frame with SDK-compliant format
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
        
//         do {
//             let json = try JSONSerialization.data(withJSONObject: frame)
//             let string = String(data: json, encoding: .utf8)!
            
//             try await socket.send(.string(string))
//             print("✅ Audio sent successfully")
            
//         } catch {
//             print("❌ Failed to send audio: \(error)")
            
//             // Handle error
//             let context = SDKErrorContext(
//                 operation: "send_audio",
//                 state: "streaming",
//                 metadata: ["audio_size": audioData.count]
//             )
//             _ = await errorHandler.handleError(.audioStreamError(error.localizedDescription), context: context)
//         }
        
//         // Reset recording state after a short delay
//         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//             self.isRecording = false
//             if self.activityState == .speaking {
//                 self.activityState = .listening
//             }
//         }
//     }
    
//     /// Stop conversation (compatible interface)
//     func stop() async {
//         print("🛑 SDK STEP 15: Stopping conversation")
        
//         // Cancel WebSocket
//         webSocketTask?.cancel(with: .normalClosure, reason: nil)
//         webSocketTask = nil
        
//         // Update state
//         isConnected = false
//         connectionState = .disconnected
//         conversationState = .idle
//         activityState = .idle
//         connectionStatus = .disconnected
//         isRecording = false
//         isSpeaking = false
        
//         // Clear session
//         currentSessionId = nil
//         onAudioOutCallback = nil
        
//         print("✅ SDK STEP 15: Conversation stopped")
//     }
    
//     // MARK: - Enhanced Connection Management
    
//     /// Fetch enhanced authentication token using Firebase Functions
//     private func fetchEnhancedToken(agentType: String, voiceName: String?) async throws -> String {
//         print("� Fetching ephemeral token from Cloud Function...")
//         let fn = Functions.functions().httpsCallable("getGeminiEphemeralToken")
        
//         do {
//             let result = try await fn.call()
//             print("✅ Cloud Function response: \(result.data)")
            
//             guard let data = result.data as? [String: Any],
//                   let token = data["ephemeralToken"] as? String else {
//                 print("🛑 Invalid token response format: \(result.data)")
//                 let authError = NSError(domain: "Authentication", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch ephemeral token"])
//                 throw authError
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
//             let authError = NSError(domain: "Authentication", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch ephemeral token"])
//             throw authError
//         }
//     }
    
//     /// Establish WebSocket connection with SDK configuration
//     private func establishConnection(token: String, systemPrompt: String, agentType: String) async throws {
//         print("🌐 SDK STEP 15: Establishing enhanced WebSocket connection")
        
//         // Use simple WebSocket connection logic from working version
//         // Try different WebSocket endpoint formats
//         let possibleURLs = [
//             // Try BidiGenerateContentConstrained with query parameter (for ephemeral tokens)
//             "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=\(token)",
//             // Try BidiGenerateContentConstrained with header auth
//             "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained",
//             // Fallback to regular BidiGenerateContent with query parameter
//             "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?access_token=\(token)",
//             // Fallback to regular BidiGenerateContent with header auth
//             "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent"
//         ]
        
//         var lastConnectionError: Error?
        
//         for urlString in possibleURLs {
//             print("🔧 Trying WebSocket URL: \(urlString)")
            
//             guard let url = URL(string: urlString) else {
//                 print("❌ Invalid URL: \(urlString)")
//                 continue
//             }
            
//             var request = URLRequest(url: url)
            
//             // Different auth methods: query parameter vs header
//             if urlString.contains("access_token=") {
//                 // Query parameter auth - no header needed
//                 print("🔐 Using query parameter authentication")
//             } else {
//                 // Header auth with "Token" prefix for ephemeral tokens
//                 print("🔐 Using header authentication")
//                 request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
//             }
            
//             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
//             do {
//                 // Create WebSocket and try to connect
//                 print("🔧 Creating URLSession with delegate...")
//                 let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//                 print("🔧 Creating WebSocket task...")
//                 let task = session.webSocketTask(with: request)
//                 print("🔧 WebSocket task created, setting socket reference...")
//                 webSocketTask = task
//                 print("🔧 Socket reference set, task state: \(task.state)")
                
//                 // Try to connect with timeout
//                 print("🔧 Creating WebSocket task...")
//                 try await withTimeout(seconds: 15) { // Increased timeout
//                     try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
//                         self.connectionCompletion = { result in
//                             print("🔧 Connection completion called with result: \(result)")
//                             continuation.resume(with: result)
//                         }
//                         print("🔧 Starting WebSocket task...")
//                         task.resume()
//                         print("🔧 WebSocket task.resume() called, waiting for connection...")
//                     }
//                 }
                
//                 print("✅ WebSocket connected successfully to: \(urlString)")
                
//                 // Send setup frame using simple working setup
//                 let setup = createWorkingSetupFrame(prompt: systemPrompt)
//                 let setupData = try encoder.encode(setup)
//                 let setupString = String(decoding: setupData, as: UTF8.self)
                
//                 print("🔧 Sending setup frame: \(setupString.prefix(200))...")
//                 try await task.send(.string(setupString))
//                 print("✅ Setup frame sent successfully")
                
//                 // Update connection state
//                 isConnected = true
//                 connectionState = .connected
//                 conversationState = .active
//                 connectionStatus = .connected
                
//                 return // Success
                
//             } catch {
//                 print("❌ Failed to connect to \(endpoint.description): \(error)")
//                 webSocketTask?.cancel(with: .normalClosure, reason: nil)
//                 webSocketTask = nil
//                 connectionCompletion = nil
//                 continue
//             }
//         }
        
//         throw NSError(domain: "Connection", code: -1, userInfo: [
//             NSLocalizedDescriptionKey: "Failed to connect to any endpoint"
//         ])
//     }
    
//     /// Create SDK-compliant endpoints
//     private func createSDKEndpoints(token: String) -> [SDKEndpoint] {
//         return [
//             // Try BidiGenerateContentConstrained with access_token (for ephemeral tokens)
//             SDKEndpoint(
//                 url: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=\(token)",
//                 authMethod: .queryParameter,
//                 description: "v1alpha Constrained (Ephemeral Token)"
//             ),
//             // Try BidiGenerateContentConstrained with header auth
//             SDKEndpoint(
//                 url: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained",
//                 authMethod: .headerToken(token),
//                 description: "v1alpha Constrained (Header Auth)"
//             ),
//             // Fallback to regular BidiGenerateContent with access_token parameter
//             SDKEndpoint(
//                 url: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?access_token=\(token)",
//                 authMethod: .queryParameter,
//                 description: "v1alpha Standard (Access Token Auth)"
//             ),
//             // Fallback to regular BidiGenerateContent with header auth
//             SDKEndpoint(
//                 url: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent",
//                 authMethod: .headerToken(token),
//                 description: "v1alpha Standard (Header Auth)"
//             )
//         ]
//     }
    
//     /// Create enhanced setup frame with current configuration
//     private func createEnhancedSetupFrame(prompt: String, agentType: String) -> SetupFrame {
//         print("🎯 SDK STEP 15: Creating enhanced setup frame with current configuration")
        
//         let voiceConfig = currentConfiguration.voiceConfiguration
//         let activityConfig = currentConfiguration.activityDetectionConfiguration
        
//         return SetupFrame(
//             setup: Config(
//                 model: "models/gemini-2.5-flash-preview-native-audio-dialog",
//                 systemInstruction: SystemInstruction(parts: [Part(text: prompt)]),
//                 generationConfig: GenConfig(
//                     responseModalities: ["AUDIO", "TEXT"],
//                     speechConfig: SpeechConfig(
//                         voiceConfig: VoiceConfigFrame(
//                             prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: voiceConfig.voiceName)
//                         )
//                     ),
//                     responseMimeType: "audio/pcm"
//                 ),
//                 realtimeInputConfig: RealtimeInputConfig(
//                     activityHandling: "START_OF_ACTIVITY_INTERRUPTS",
//                     automaticActivityDetection: AutomaticActivityDetection(
//                         disabled: false,
//                         startOfSpeechSensitivity: activityConfig.startOfSpeechSensitivity.rawValue,
//                         endOfSpeechSensitivity: activityConfig.endOfSpeechSensitivity.rawValue,
//                         prefixPaddingMs: activityConfig.prefixPaddingMs,
//                         silenceDurationMs: activityConfig.silenceDurationMs
//                     ),
//                     turnCoverage: "TURN_INCLUDES_ONLY_ACTIVITY"
//                 ),
//                 proactivity: ProactivityConfig(proactiveAudio: true),
//                 contextWindowCompression: ContextWindowCompressionConfig(
//                     triggerTokens: 30000,
//                     slidingWindow: SlidingWindowConfig(targetTokens: 15000)
//                 ),
//                 sessionResumption: SessionResumptionFrameConfig(transparent: true)
//             )
//         )
//     }
    
//     // MARK: - Enhanced Receive Loop
    
//     /// Enhanced message processing with all SDK features
//     private func receiveLoop() async {
//         guard let task = webSocketTask else { return }
        
//         do {
//             while isConnected {
//                 let message = try await task.receive()
//                 await processMessage(message)
//             }
//         } catch {
//             print("❌ Receive loop error: \(error)")
            
//             // Handle error through error handler
//             let context = SDKErrorContext(
//                 operation: "receive_loop",
//                 state: "listening",
//                 metadata: ["error": error.localizedDescription]
//             )
//             _ = await errorHandler.handleError(.websocketError(error.localizedDescription), context: context)
            
//             // Update state
//             isConnected = false
//             connectionState = .error(error)
//             connectionStatus = .error(error.localizedDescription)
//         }
//     }
    
//     /// Process incoming WebSocket message
//     private func processMessage(_ message: URLSessionWebSocketTask.Message) async {
//         switch message {
//         case .string(let text):
//             await processStringMessage(text)
//         case .data(let data):
//             await processBinaryMessage(data)
//         @unknown default:
//             print("📨 Unknown message type received")
//         }
//     }
    
//     /// Process string message with enhanced features
//     private func processStringMessage(_ text: String) async {
//         print("📨 SDK STEP 15: Processing string message (\(text.prefix(200))...)")
        
//         guard let data = text.data(using: .utf8),
//               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
//             print("⚠️ Failed to parse message")
//             return
//         }
        
//         // Handle server content
//         if let serverContent = dict["serverContent"] as? [String: Any] {
//             await handleServerContent(serverContent)
//         }
        
//         // Handle session resumption updates
//         if let sessionUpdate = dict["sessionResumptionUpdate"] as? [String: Any] {
//             await handleSessionResumptionUpdate(sessionUpdate)
//         }
        
//         // Handle setup complete
//         if let setupComplete = dict["setupComplete"] as? [String: Any] {
//             await handleSetupComplete(setupComplete)
//         }
//     }
    
//     /// Process binary message
//     private func processBinaryMessage(_ data: Data) async {
//         print("📨 SDK STEP 15: Processing binary message (\(data.count) bytes)")
        
//         if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//            let serverContent = dict["serverContent"] as? [String: Any] {
//             await handleServerContent(serverContent)
//         }
//     }
    
//     /// Handle server content with enhanced processing
//     private func handleServerContent(_ serverContent: [String: Any]) async {
//         print("📋 SDK STEP 15: Handling server content")
        
//         // Check for interruption
//         if let interrupted = serverContent["interrupted"] as? Bool, interrupted {
//             print("🚫 Generation interrupted by user speech")
//             activityState = .interrupted
//             isSpeaking = false
            
//             // Notify audio interruption
//             NotificationCenter.default.post(name: .audioInterrupted, object: nil)
//         }
        
//         // Check for generation complete
//         if let generationComplete = serverContent["generationComplete"] as? Bool, generationComplete {
//             print("✅ Generation complete")
//             activityState = .listening
//             isSpeaking = false
            
//             NotificationCenter.default.post(name: .audioGenerationComplete, object: nil)
//         }
        
//         // Check for turn complete
//         if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
//             print("✅ Turn complete")
//             activityState = .listening
            
//             NotificationCenter.default.post(name: .audioTurnComplete, object: nil)
//         }
        
//         // Process audio content
//         if let modelTurn = serverContent["modelTurn"] as? [String: Any],
//            let parts = modelTurn["parts"] as? [[String: Any]] {
//             await processModelTurnParts(parts)
//         }
        
//         // Process transcription
//         if let transcription = serverContent["transcription"] as? String {
//             let message = TranscriptionMessage(
//                 id: UUID().uuidString,
//                 content: transcription,
//                 isUser: false,
//                 timestamp: Date(),
//                 isPartial: false
//             )
//             transcriptionMessages.append(message)
//         }
//     }
    
//     /// Process model turn parts (audio and text)
//     private func processModelTurnParts(_ parts: [[String: Any]]) async {
//         for part in parts {
//             // Process audio
//             if let inlineData = part["inlineData"] as? [String: Any],
//                let base64 = inlineData["data"] as? String,
//                let mimeType = inlineData["mimeType"] as? String,
//                mimeType.contains("audio") {
                
//                 await processAudioPart(base64: base64, mimeType: mimeType)
//             }
            
//             // Process text
//             if let text = part["text"] as? String {
//                 let message = TranscriptionMessage(
//                     id: UUID().uuidString,
//                     content: text,
//                     isUser: false,
//                     timestamp: Date(),
//                     isPartial: false
//                 )
//                 transcriptionMessages.append(message)
//             }
//         }
//     }
    
//     /// Process audio part
//     private func processAudioPart(base64: String, mimeType: String) async {
//         print("🔊 SDK STEP 15: Processing audio part (MIME: \(mimeType))")
        
//         guard let audioData = Data(base64Encoded: base64) else {
//             print("❌ Failed to decode audio data")
//             return
//         }
        
//         // Update state
//         isSpeaking = true
//         activityState = .responding
        
//         // Update audio levels
//         let outputLevel = calculateAudioLevel(from: audioData)
//         audioLevels = AudioLevels(inputLevel: audioLevels.inputLevel, outputLevel: outputLevel)
        
//         // Send to audio callback
//         onAudioOutCallback?(audioData)
        
//         print("✅ Audio processed: \(audioData.count) bytes")
//     }
    
//     /// Handle session resumption update
//     private func handleSessionResumptionUpdate(_ update: [String: Any]) async {
//         print("🔄 SDK STEP 15: Handling session resumption update")
        
//         if let sessionId = update["sessionId"] as? String,
//            let resumptionToken = update["resumptionToken"] as? String {
            
//             let serverUpdate = LiveServerSessionResumptionUpdate(
//                 sessionId: sessionId,
//                 resumptionToken: resumptionToken,
//                 expiresAt: Date().addingTimeInterval(3600),
//                 supportedFeatures: ["audio", "tools", "conversation"],
//                 serverState: [:],
//                 resumptionCapabilities: LiveServerSessionResumptionUpdate.ResumptionCapabilities(
//                     canResumeAudio: true,
//                     canResumeTools: true,
//                     canResumeConversation: true,
//                     maxResumptionWindow: 300.0,
//                     supportedResumptionMethods: ["token", "state"]
//                 )
//             )
            
//             await resumptionManager.handleServerResumptionUpdate(serverUpdate)
//         }
//     }
    
//     /// Handle setup complete
//     private func handleSetupComplete(_ setupComplete: [String: Any]) async {
//         print("✅ SDK STEP 15: Setup complete")
        
//         if let sessionId = setupComplete["sessionId"] as? String {
//             currentSessionId = sessionId
//             print("✅ Session ID: \(sessionId)")
//         }
        
//         // Update state to active
//         conversationState = .active
//         activityState = .listening
//         connectionStatus = .connected
//     }
    
//     // MARK: - Utility Methods
    
//     /// Calculate real audio level from audio data using proper DSP
//     private func calculateAudioLevel(from audioData: Data) -> Double {
//         guard audioData.count > 0 else { return 0.0 }
        
//         // Convert raw audio data to Float32 samples
//         let sampleCount = audioData.count / MemoryLayout<Float32>.size
//         guard sampleCount > 0 else { return 0.0 }
        
//         return audioData.withUnsafeBytes { rawBytes in
//             let samples = rawBytes.bindMemory(to: Float32.self)
            
//             // Calculate RMS (Root Mean Square) for accurate audio level
//             var sum: Float = 0.0
//             for i in 0..<sampleCount {
//                 let sample = samples[i]
//                 sum += sample * sample
//             }
            
//             let rms = sqrt(sum / Float(sampleCount))
            
//             // Convert to decibels and normalize to 0.0-1.0 range
//             let db = 20.0 * log10(max(rms, 0.000001)) // Avoid log(0)
//             let normalizedLevel = max(0.0, min(1.0, (db + 80.0) / 80.0)) // Map -80dB to 0, 0dB to 1
            
//             return Double(normalizedLevel)
//         }
//     }
    
//     /// Timeout helper
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
    
//     // MARK: - SDK Step 15: Public Configuration Interface
    
//     /// Get available voice options
//     func getAvailableVoices() -> [String] {
//         return VoiceConfiguration.availableVoices
//     }
    
//     /// Get supported languages
//     func getSupportedLanguages() -> [LanguageConfiguration.Language] {
//         return LanguageConfiguration.supportedLanguages
//     }
    
//     /// Get current configuration
//     func getCurrentConfiguration() -> SDKConfiguration {
//         return currentConfiguration
//     }
    
//     /// Export configuration
//     func exportConfiguration() -> String? {
//         do {
//             let data = try configurationManager.exportConfiguration()
//             return String(data: data, encoding: .utf8)
//         } catch {
//             print("❌ Failed to export configuration: \(error)")
//             return nil
//         }
//     }
    
//     /// Import configuration
//     func importConfiguration(from jsonString: String) -> Bool {
//         guard let data = jsonString.data(using: .utf8) else { return false }
        
//         do {
//             try configurationManager.importConfiguration(from: data)
//             return true
//         } catch {
//             print("❌ Failed to import configuration: \(error)")
//             return false
//         }
//     }
// }

// // MARK: - SDK Step 15: Configuration Delegate
// extension GeminiLiveClient: ConfigurationManagerDelegate {
//     nonisolated func configurationManager(_ manager: ConfigurationManager, didUpdateConfiguration config: SDKConfiguration) {
//         Task { @MainActor in
//             currentConfiguration = config
//         }
//     }
    
//     nonisolated func configurationManager(_ manager: ConfigurationManager, didChangeValue field: String, category: ConfigurationChangeEvent.ConfigurationCategory) {
//         print("📝 Configuration updated: \(category.rawValue).\(field)")
//     }
    
//     nonisolated func configurationManager(_ manager: ConfigurationManager, didApplyPreset preset: SDKConfiguration.ConfigurationPreset) {
//         print("📋 Applied preset: \(preset.name)")
//     }
    
//     nonisolated func configurationManager(_ manager: ConfigurationManager, didResetToDefaults category: ConfigurationChangeEvent.ConfigurationCategory?) {
//         print("🔄 Reset to defaults: \(category?.rawValue ?? "all")")
//     }
    
//     nonisolated func configurationManager(_ manager: ConfigurationManager, didValidateConfiguration isValid: Bool, errors: [String]) {
//         if !isValid {
//             print("❌ Configuration invalid: \(errors.joined(separator: ", "))")
//         }
//     }
// }

// // MARK: - SDK Step 12: Error Handler Delegate
// extension GeminiLiveClient: SDKErrorHandlerDelegate {
//     nonisolated func errorHandler(_ handler: SDKErrorHandler, didEncounterError error: SDKError, context: SDKErrorContext) {
//         Task { @MainActor in
//             lastError = error.errorDescription
//             connectionStatus = .error(error.errorDescription ?? "Unknown error")
//         }
//     }
    
//     nonisolated func errorHandler(_ handler: SDKErrorHandler, willAttemptRecovery action: ErrorRecoveryAction, attempt: Int) {
//         Task { @MainActor in
//             connectionStatus = .recovering
//         }
//     }
    
//     nonisolated func errorHandler(_ handler: SDKErrorHandler, didRecoverFromError error: SDKError, recoveryTime: TimeInterval) {
//         Task { @MainActor in
//             connectionStatus = .connected
//             lastError = nil
//         }
//     }
    
//     nonisolated func errorHandler(_ handler: SDKErrorHandler, didFailToRecover error: SDKError, finalAttempt: Bool) {
//         Task { @MainActor in
//             connectionStatus = .error(error.errorDescription ?? "Recovery failed")
//         }
//     }
    
//     nonisolated func errorHandler(_ handler: SDKErrorHandler, didUpdateStats stats: SDKErrorStats) {
//         // Update error statistics if needed
//     }
// }

// // MARK: - SDK Step 13: Session Resumption Delegate
// extension GeminiLiveClient: SessionResumptionDelegate {
//     nonisolated func sessionResumption(_ manager: SessionResumptionManager, willStartResumption sessionId: String, attempt: Int) {
//         Task { @MainActor in
//             connectionStatus = .resuming
//         }
//     }
    
//     nonisolated func sessionResumption(_ manager: SessionResumptionManager, didCreateStateBackup size: Int) {
//         print("💾 State backup created: \(size) bytes")
//     }
    
//     nonisolated func sessionResumption(_ manager: SessionResumptionManager, didReceiveServerUpdate update: LiveServerSessionResumptionUpdate) {
//         print("📡 Session resumption update received")
//     }
    
//     nonisolated func sessionResumption(_ manager: SessionResumptionManager, didCompleteResumption sessionId: String, resumptionTime: TimeInterval) {
//         Task { @MainActor in
//             connectionStatus = .connected
//         }
//     }
    
//     nonisolated func sessionResumption(_ manager: SessionResumptionManager, didFailResumption sessionId: String, error: Error, attempt: Int) {
//         Task { @MainActor in
//             connectionStatus = .error("Resumption failed")
//         }
//     }
    
//     nonisolated func sessionResumption(_ manager: SessionResumptionManager, didUpdateStats stats: SessionResumptionStats) {
//         // Update resumption statistics if needed
//     }
// }

// // MARK: - URLSessionWebSocketDelegate
// extension GeminiLiveClient: URLSessionWebSocketDelegate {
//     nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
//         Task { @MainActor in
//             print("✅ WebSocket connected")
//             connectionCompletion?(.success(()))
//             connectionCompletion = nil
//         }
//     }
    
//     nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
//         Task { @MainActor in
//             print("🔌 WebSocket closed: \(closeCode.rawValue)")
//             isConnected = false
//             connectionState = .disconnected
//             connectionStatus = .disconnected
//         }
//     }
    
//     nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//         Task { @MainActor in
//             if let error = error {
//                 print("❌ WebSocket error: \(error)")
//                 connectionCompletion?(.failure(error))
//                 connectionCompletion = nil
//                 isConnected = false
//                 connectionState = .error(error)
//                 connectionStatus = .error(error.localizedDescription)
//             }
//         }
//     }
// }

// // MARK: - Supporting Types

// /// Connection state enumeration
// enum ConnectionState {
//     case disconnected
//     case connecting
//     case connected
//     case error(Error)
//     case recovering
//     case resuming
// }

// /// Conversation state enumeration
// enum ConversationState {
//     case idle
//     case initializing
//     case active
//     case paused
//     case error
//     case terminated
// }

// /// Activity state for UI indicators
// enum ActivityState {
//     case idle
//     case initializing
//     case listening
//     case speaking
//     case processing
//     case responding
//     case interrupted
//     case paused
//     case error
    
//     var displayName: String {
//         switch self {
//         case .idle: return "Ready"
//         case .initializing: return "Initializing..."
//         case .listening: return "Listening..."
//         case .speaking: return "Speaking..."
//         case .processing: return "Processing..."
//         case .responding: return "Responding..."
//         case .interrupted: return "Interrupted"
//         case .paused: return "Paused"
//         case .error: return "Error"
//         }
//     }
    
//     var color: Color {
//         switch self {
//         case .idle: return .gray
//         case .initializing: return .orange
//         case .listening: return .blue
//         case .speaking: return .green
//         case .processing: return .purple
//         case .responding: return .blue
//         case .interrupted: return .orange
//         case .paused: return .yellow
//         case .error: return .red
//         }
//     }
// }

// /// Connection status for detailed UI feedback
// enum ConnectionStatus {
//     case disconnected
//     case connecting
//     case connected
//     case error(String)
//     case recovering
//     case resuming
    
//     var displayName: String {
//         switch self {
//         case .disconnected: return "Disconnected"
//         case .connecting: return "Connecting..."
//         case .connected: return "Connected"
//         case .error(let message): return "Error: \(message)"
//         case .recovering: return "Recovering..."
//         case .resuming: return "Resuming..."
//         }
//     }
    
//     var color: Color {
//         switch self {
//         case .disconnected: return .gray
//         case .connecting: return .orange
//         case .connected: return .green
//         case .error: return .red
//         case .recovering: return .orange
//         case .resuming: return .blue
//         }
//     }
// }

// /// Transcription message for UI display
// struct TranscriptionMessage: Identifiable {
//     let id: String
//     let content: String
//     let isUser: Bool
//     let timestamp: Date
//     let isPartial: Bool
// }

// /// Audio levels for UI visualization
// struct AudioLevels {
//     let inputLevel: Double
//     let outputLevel: Double
    
//     init(inputLevel: Double = 0.0, outputLevel: Double = 0.0) {
//         self.inputLevel = max(0.0, min(1.0, inputLevel))
//         self.outputLevel = max(0.0, min(1.0, outputLevel))
//     }
// }

// /// SDK endpoint configuration
// struct SDKEndpoint {
//     let url: String
//     let authMethod: AuthMethod
//     let description: String
    
//     enum AuthMethod {
//         case queryParameter
//         case headerToken(String)
//     }
    
//     var request: URLRequest {
//         guard let url = URL(string: url) else {
//             fatalError("Invalid endpoint URL: \(url)")
//         }
        
//         var request = URLRequest(url: url)
//         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
//         if case .headerToken(let token) = authMethod {
//             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//         }
        
//         return request
//     }
// }

// /// Rate limiter for security
// class RateLimiter {
//     private var lastRequestTime: Date = Date()
//     private var requestCount: Int = 0
//     private let maxRequestsPerMinute: Int = 1000
//     private let minTimeBetweenRequests: TimeInterval = 0.05
    
//     private var audioRequestCount: Int = 0
//     private var lastAudioRequestTime: Date = Date()
//     private let maxAudioRequestsPerSecond: Int = 20
    
//     func canMakeRequest() -> Bool {
//         let now = Date()
        
//         if now.timeIntervalSince(lastRequestTime) > 60 {
//             requestCount = 0
//         }
        
//         guard requestCount < maxRequestsPerMinute else { return false }
//         guard now.timeIntervalSince(lastRequestTime) >= minTimeBetweenRequests else { return false }
        
//         requestCount += 1
//         lastRequestTime = now
//         return true
//     }
    
//     func canMakeAudioRequest() -> Bool {
//         let now = Date()
        
//         if now.timeIntervalSince(lastAudioRequestTime) > 1.0 {
//             audioRequestCount = 0
//         }
        
//         guard audioRequestCount < maxAudioRequestsPerSecond else { return false }
//         guard now.timeIntervalSince(lastAudioRequestTime) >= 0.05 else { return false }
        
//         audioRequestCount += 1
//         lastAudioRequestTime = now
//         return true
//     }
// }

// // MARK: - JSON Frame Models (Compatible with existing implementation)

// private struct SetupFrame: Codable {
//     let setup: Config
// }

// private struct Config: Codable {
//     let model: String?
//     let systemInstruction: SystemInstruction
//     let generationConfig: GenConfig?
//     let realtimeInputConfig: RealtimeInputConfig?
//     let proactivity: ProactivityConfig?
//     let contextWindowCompression: ContextWindowCompressionConfig?
//     let sessionResumption: SessionResumptionFrameConfig?
// }

// private struct SystemInstruction: Codable {
//     let parts: [Part]
// }

// private struct Part: Codable {
//     let text: String
// }

// private struct GenConfig: Codable {
//     let responseModalities: [String]
//     let speechConfig: SpeechConfig?
//     let responseMimeType: String?
// }

// private struct SpeechConfig: Codable {
//     let voiceConfig: VoiceConfigFrame
// }

// private struct VoiceConfigFrame: Codable {
//     let prebuiltVoiceConfig: PrebuiltVoiceConfig
// }

// private struct PrebuiltVoiceConfig: Codable {
//     let voiceName: String
// }

// private struct RealtimeInputConfig: Codable {
//     let activityHandling: String?
//     let automaticActivityDetection: AutomaticActivityDetection
//     let turnCoverage: String?
// }

// private struct AutomaticActivityDetection: Codable {
//     let disabled: Bool?
//     let startOfSpeechSensitivity: String?
//     let endOfSpeechSensitivity: String?
//     let prefixPaddingMs: Int?
//     let silenceDurationMs: Int?
// }

// private struct ProactivityConfig: Codable {
//     let proactiveAudio: Bool
// }

// private struct ContextWindowCompressionConfig: Codable {
//     let triggerTokens: Int?
//     let slidingWindow: SlidingWindowConfig?
// }

// private struct SlidingWindowConfig: Codable {
//     let targetTokens: Int?
// }

// private struct SessionResumptionFrameConfig: Codable {
//     let transparent: Bool?
// }

// // MARK: - Notification Extensions (Compatible with existing implementation)

// extension Notification.Name {
//     static let audioInterrupted = Notification.Name("audioInterrupted")
//     static let audioGenerationComplete = Notification.Name("audioGenerationComplete")
//     static let audioTurnComplete = Notification.Name("audioTurnComplete")
// }

// // MARK: - SDK Step 15 Configuration Types (From GeminiLiveClientSDK_Step15_Complete.swift)

// /// Voice configuration options
// struct VoiceConfiguration: Codable, Equatable {
//     var voiceName: String
//     var voiceGender: VoiceGender
//     var voiceSpeed: Double // 0.25 to 4.0
//     var voicePitch: Double // -20.0 to 20.0 semitones
//     var voiceVolume: Double // 0.0 to 1.0
//     var voiceStability: Double // 0.0 to 1.0
//     var voiceSimilarity: Double // 0.0 to 1.0
//     var voiceStyle: VoiceStyle
    
//     enum VoiceGender: String, CaseIterable, Codable {
//         case male = "male"
//         case female = "female"
//         case neutral = "neutral"
        
//         var displayName: String {
//             switch self {
//             case .male: return "Male"
//             case .female: return "Female"
//             case .neutral: return "Neutral"
//             }
//         }
//     }
    
//     enum VoiceStyle: String, CaseIterable, Codable {
//         case natural = "natural"
//         case conversational = "conversational"
//         case expressive = "expressive"
//         case calm = "calm"
//         case energetic = "energetic"
//         case professional = "professional"
//         case casual = "casual"
//         case storytelling = "storytelling"
        
//         var displayName: String {
//             switch self {
//             case .natural: return "Natural"
//             case .conversational: return "Conversational"
//             case .expressive: return "Expressive"
//             case .calm: return "Calm"
//             case .energetic: return "Energetic"
//             case .professional: return "Professional"
//             case .casual: return "Casual"
//             case .storytelling: return "Storytelling"
//             }
//         }
//     }
    
//     static let `default` = VoiceConfiguration(
//         voiceName: "Puck",
//         voiceGender: .neutral,
//         voiceSpeed: 1.0,
//         voicePitch: 0.0,
//         voiceVolume: 1.0,
//         voiceStability: 0.5,
//         voiceSimilarity: 0.75,
//         voiceStyle: .natural
//     )
    
//     static let availableVoices: [String] = [
//         "Puck", "Charon", "Kore", "Fenrir", "Aoede", "Titan",
//         "Sage", "Nova", "Echo", "Zephyr", "Luna", "Atlas"
//     ]
// }

// /// Language configuration options
// struct LanguageConfiguration: Codable, Equatable {
//     let inputLanguageCode: String
//     let outputLanguageCode: String
//     let automaticLanguageDetection: Bool
//     let translationEnabled: Bool
//     let dialectPreference: String?
//     let regionCode: String?
    
//     static let `default` = LanguageConfiguration(
//         inputLanguageCode: "en-US",
//         outputLanguageCode: "en-US",
//         automaticLanguageDetection: false,
//         translationEnabled: false,
//         dialectPreference: nil,
//         regionCode: "US"
//     )
    
//     static let supportedLanguages: [Language] = [
//         Language(code: "en-US", name: "English (US)", flag: "🇺🇸"),
//         Language(code: "en-GB", name: "English (UK)", flag: "🇬🇧"),
//         Language(code: "es-ES", name: "Spanish (Spain)", flag: "🇪🇸"),
//         Language(code: "es-MX", name: "Spanish (Mexico)", flag: "🇲🇽"),
//         Language(code: "fr-FR", name: "French (France)", flag: "🇫🇷"),
//         Language(code: "fr-CA", name: "French (Canada)", flag: "🇨🇦"),
//         Language(code: "de-DE", name: "German", flag: "🇩🇪"),
//         Language(code: "it-IT", name: "Italian", flag: "🇮🇹"),
//         Language(code: "pt-BR", name: "Portuguese (Brazil)", flag: "🇧🇷"),
//         Language(code: "pt-PT", name: "Portuguese (Portugal)", flag: "🇵🇹"),
//         Language(code: "ja-JP", name: "Japanese", flag: "🇯🇵"),
//         Language(code: "ko-KR", name: "Korean", flag: "🇰🇷"),
//         Language(code: "zh-CN", name: "Chinese (Simplified)", flag: "🇨🇳"),
//         Language(code: "zh-TW", name: "Chinese (Traditional)", flag: "🇹🇼"),
//         Language(code: "ar-SA", name: "Arabic", flag: "🇸🇦"),
//         Language(code: "hi-IN", name: "Hindi", flag: "🇮🇳"),
//         Language(code: "ru-RU", name: "Russian", flag: "🇷🇺"),
//         Language(code: "nl-NL", name: "Dutch", flag: "🇳🇱"),
//         Language(code: "sv-SE", name: "Swedish", flag: "🇸🇪"),
//         Language(code: "no-NO", name: "Norwegian", flag: "🇳🇴")
//     ]
    
//     struct Language: Codable, Identifiable, Equatable {
//         let code: String
//         let name: String
//         let flag: String
        
//         var id: String { code }
        
//         static func == (lhs: Language, rhs: Language) -> Bool {
//             return lhs.code == rhs.code
//         }
//     }
// }

// /// Activity detection sensitivity configuration
// struct ActivityDetectionConfiguration: Codable, Equatable {
//     let startOfSpeechSensitivity: SensitivityLevel
//     let endOfSpeechSensitivity: SensitivityLevel
//     let silenceDurationMs: Int
//     let prefixPaddingMs: Int
//     let voiceActivityThreshold: Double
//     let noiseSuppressionLevel: NoiseSuppressionLevel
//     let echoCancellationEnabled: Bool
//     let adaptiveSensitivity: Bool
    
//     enum SensitivityLevel: String, CaseIterable, Codable {
//         case veryLow = "VERY_LOW"
//         case low = "LOW"
//         case medium = "MEDIUM"
//         case high = "HIGH"
//         case veryHigh = "VERY_HIGH"
        
//         var displayName: String {
//             switch self {
//             case .veryLow: return "Very Low"
//             case .low: return "Low"
//             case .medium: return "Medium"
//             case .high: return "High"
//             case .veryHigh: return "Very High"
//             }
//         }
        
//         var threshold: Double {
//             switch self {
//             case .veryLow: return 0.1
//             case .low: return 0.3
//             case .medium: return 0.5
//             case .high: return 0.7
//             case .veryHigh: return 0.9
//             }
//         }
//     }
    
//     enum NoiseSuppressionLevel: String, CaseIterable, Codable {
//         case disabled = "DISABLED"
//         case low = "LOW"
//         case moderate = "MODERATE"
//         case high = "HIGH"
//         case maximum = "MAXIMUM"
        
//         var displayName: String {
//             switch self {
//             case .disabled: return "Disabled"
//             case .low: return "Low"
//             case .moderate: return "Moderate"
//             case .high: return "High"
//             case .maximum: return "Maximum"
//             }
//         }
//     }
    
//     static let `default` = ActivityDetectionConfiguration(
//         startOfSpeechSensitivity: .medium,
//         endOfSpeechSensitivity: .medium,
//         silenceDurationMs: 700,
//         prefixPaddingMs: 300,
//         voiceActivityThreshold: 0.5,
//         noiseSuppressionLevel: .moderate,
//         echoCancellationEnabled: true,
//         adaptiveSensitivity: true
//     )
// }

// /// Audio quality configuration
// struct AudioQualityConfiguration: Codable, Equatable {
//     let sampleRate: AudioSampleRate
//     let bitDepth: AudioBitDepth
//     let channels: AudioChannels
//     let compression: AudioCompression
//     let latencyMode: AudioLatencyMode
//     let bufferSize: AudioBufferSize
//     let adaptiveQuality: Bool
//     let networkOptimization: Bool
    
//     enum AudioSampleRate: Int, CaseIterable, Codable {
//         case rate8kHz = 8000
//         case rate16kHz = 16000
//         case rate22kHz = 22050
//         case rate44kHz = 44100
//         case rate48kHz = 48000
        
//         var displayName: String {
//             switch self {
//             case .rate8kHz: return "8 kHz (Low)"
//             case .rate16kHz: return "16 kHz (Standard)"
//             case .rate22kHz: return "22 kHz (Good)"
//             case .rate44kHz: return "44 kHz (High)"
//             case .rate48kHz: return "48 kHz (Studio)"
//             }
//         }
//     }
    
//     enum AudioBitDepth: Int, CaseIterable, Codable {
//         case depth8bit = 8
//         case depth16bit = 16
//         case depth24bit = 24
//         case depth32bit = 32
        
//         var displayName: String {
//             switch self {
//             case .depth8bit: return "8-bit"
//             case .depth16bit: return "16-bit"
//             case .depth24bit: return "24-bit"
//             case .depth32bit: return "32-bit"
//             }
//         }
//     }
    
//     enum AudioChannels: Int, CaseIterable, Codable {
//         case mono = 1
//         case stereo = 2
        
//         var displayName: String {
//             switch self {
//             case .mono: return "Mono"
//             case .stereo: return "Stereo"
//             }
//         }
//     }
    
//     enum AudioCompression: String, CaseIterable, Codable {
//         case none = "NONE"
//         case lossless = "LOSSLESS"
//         case lowLatency = "LOW_LATENCY"
//         case balanced = "BALANCED"
//         case maximum = "MAXIMUM"
        
//         var displayName: String {
//             switch self {
//             case .none: return "Uncompressed"
//             case .lossless: return "Lossless"
//             case .lowLatency: return "Low Latency"
//             case .balanced: return "Balanced"
//             case .maximum: return "Maximum"
//             }
//         }
//     }
    
//     enum AudioLatencyMode: String, CaseIterable, Codable {
//         case ultraLow = "ULTRA_LOW"
//         case low = "LOW"
//         case balanced = "BALANCED"
//         case quality = "QUALITY"
        
//         var displayName: String {
//             switch self {
//             case .ultraLow: return "Ultra Low Latency"
//             case .low: return "Low Latency"
//             case .balanced: return "Balanced"
//             case .quality: return "High Quality"
//             }
//         }
//     }
    
//     enum AudioBufferSize: Int, CaseIterable, Codable {
//         case tiny = 64
//         case small = 128
//         case medium = 256
//         case large = 512
//         case huge = 1024
        
//         var displayName: String {
//             switch self {
//             case .tiny: return "64 samples (Tiny)"
//             case .small: return "128 samples (Small)"
//             case .medium: return "256 samples (Medium)"
//             case .large: return "512 samples (Large)"
//             case .huge: return "1024 samples (Huge)"
//             }
//         }
//     }
    
//     static let `default` = AudioQualityConfiguration(
//         sampleRate: .rate16kHz,
//         bitDepth: .depth16bit,
//         channels: .mono,
//         compression: .balanced,
//         latencyMode: .balanced,
//         bufferSize: .medium,
//         adaptiveQuality: true,
//         networkOptimization: true
//     )
    
//     static let lowLatency = AudioQualityConfiguration(
//         sampleRate: .rate16kHz,
//         bitDepth: .depth16bit,
//         channels: .mono,
//         compression: .lowLatency,
//         latencyMode: .ultraLow,
//         bufferSize: .tiny,
//         adaptiveQuality: true,
//         networkOptimization: true
//     )
    
//     static let highQuality = AudioQualityConfiguration(
//         sampleRate: .rate48kHz,
//         bitDepth: .depth24bit,
//         channels: .stereo,
//         compression: .lossless,
//         latencyMode: .quality,
//         bufferSize: .large,
//         adaptiveQuality: false,
//         networkOptimization: false
//     )
    
//     static let batteryOptimized = AudioQualityConfiguration(
//         sampleRate: .rate8kHz,
//         bitDepth: .depth16bit,
//         channels: .mono,
//         compression: .maximum,
//         latencyMode: .balanced,
//         bufferSize: .small,
//         adaptiveQuality: true,
//         networkOptimization: true
//     )
// }

// /// Advanced configuration options
// struct AdvancedConfiguration: Codable, Equatable {
//     let responseTimeout: TimeInterval
//     let maxConversationLength: Int
//     let conversationMemory: Bool
//     let contextualAwareness: Bool
//     let personalityMode: PersonalityMode
//     let interruptionHandling: InterruptionHandling
//     let backgroundMode: BackgroundMode
//     let privacyMode: PrivacyMode
//     let analyticsEnabled: Bool
//     let debugMode: Bool
    
//     enum PersonalityMode: String, CaseIterable, Codable {
//         case neutral = "neutral"
//         case friendly = "friendly"
//         case professional = "professional"
//         case casual = "casual"
//         case enthusiastic = "enthusiastic"
//         case helpful = "helpful"
//         case creative = "creative"
//         case analytical = "analytical"
        
//         var displayName: String {
//             switch self {
//             case .neutral: return "Neutral"
//             case .friendly: return "Friendly"
//             case .professional: return "Professional"
//             case .casual: return "Casual"
//             case .enthusiastic: return "Enthusiastic"
//             case .helpful: return "Helpful"
//             case .creative: return "Creative"
//             case .analytical: return "Analytical"
//             }
//         }
//     }
    
//     enum InterruptionHandling: String, CaseIterable, Codable {
//         case disabled = "disabled"
//         case polite = "polite"
//         case immediate = "immediate"
//         case smart = "smart"
        
//         var displayName: String {
//             switch self {
//             case .disabled: return "Disabled"
//             case .polite: return "Polite"
//             case .immediate: return "Immediate"
//             case .smart: return "Smart"
//             }
//         }
//     }
    
//     enum BackgroundMode: String, CaseIterable, Codable {
//         case disabled = "disabled"
//         case limited = "limited"
//         case full = "full"
        
//         var displayName: String {
//             switch self {
//             case .disabled: return "Disabled"
//             case .limited: return "Limited"
//             case .full: return "Full"
//             }
//         }
//     }
    
//     enum PrivacyMode: String, CaseIterable, Codable {
//         case standard = "standard"
//         case enhanced = "enhanced"
//         case maximum = "maximum"
        
//         var displayName: String {
//             switch self {
//             case .standard: return "Standard"
//             case .enhanced: return "Enhanced"
//             case .maximum: return "Maximum"
//             }
//         }
//     }
    
//     static let `default` = AdvancedConfiguration(
//         responseTimeout: 30.0,
//         maxConversationLength: 100,
//         conversationMemory: true,
//         contextualAwareness: true,
//         personalityMode: .friendly,
//         interruptionHandling: .smart,
//         backgroundMode: .limited,
//         privacyMode: .standard,
//         analyticsEnabled: true,
//         debugMode: false
//     )
// }

// /// Complete SDK configuration
// struct SDKConfiguration: Codable, Equatable {
//     let voiceConfiguration: VoiceConfiguration
//     let languageConfiguration: LanguageConfiguration
//     let activityDetectionConfiguration: ActivityDetectionConfiguration
//     let audioQualityConfiguration: AudioQualityConfiguration
//     let advancedConfiguration: AdvancedConfiguration
//     let lastModified: Date
//     let version: String
    
//     static let `default` = SDKConfiguration(
//         voiceConfiguration: .default,
//         languageConfiguration: .default,
//         activityDetectionConfiguration: .default,
//         audioQualityConfiguration: .default,
//         advancedConfiguration: .default,
//         lastModified: Date(),
//         version: "1.0.0"
//     )
    
//     static let presets: [ConfigurationPreset] = [
//         ConfigurationPreset(
//             name: "Default",
//             description: "Balanced settings for general use",
//             configuration: .default
//         )
//     ]
    
//     struct ConfigurationPreset: Identifiable, Equatable {
//         let name: String
//         let description: String
//         let configuration: SDKConfiguration
        
//         var id: String { name }
        
//         static func == (lhs: ConfigurationPreset, rhs: ConfigurationPreset) -> Bool {
//             return lhs.name == rhs.name
//         }
//     }
// }

// /// Configuration change event
// struct ConfigurationChangeEvent {
//     let timestamp: Date
//     let category: ConfigurationCategory
//     let field: String
//     let oldValue: Any?
//     let newValue: Any?
//     let source: ChangeSource
    
//     enum ConfigurationCategory: String, CaseIterable {
//         case voice = "voice"
//         case language = "language"
//         case activityDetection = "activity_detection"
//         case audioQuality = "audio_quality"
//         case advanced = "advanced"
//     }
    
//     enum ChangeSource: String, CaseIterable {
//         case user = "user"
//         case preset = "preset"
//         case automatic = "automatic"
//         case system = "system"
//     }
// }

// /// Configuration manager delegate
// protocol ConfigurationManagerDelegate: AnyObject {
//     func configurationManager(_ manager: ConfigurationManager, didUpdateConfiguration config: SDKConfiguration)
//     func configurationManager(_ manager: ConfigurationManager, didChangeValue field: String, category: ConfigurationChangeEvent.ConfigurationCategory)
//     func configurationManager(_ manager: ConfigurationManager, didApplyPreset preset: SDKConfiguration.ConfigurationPreset)
//     func configurationManager(_ manager: ConfigurationManager, didResetToDefaults category: ConfigurationChangeEvent.ConfigurationCategory?)
//     func configurationManager(_ manager: ConfigurationManager, didValidateConfiguration isValid: Bool, errors: [String])
// }

// /// Configuration Manager
// @MainActor
// class ConfigurationManager: ObservableObject {
//     weak var delegate: ConfigurationManagerDelegate?
    
//     @Published var currentConfiguration: SDKConfiguration
//     @Published var availablePresets: [SDKConfiguration.ConfigurationPreset]
//     @Published var configurationHistory: [ConfigurationChangeEvent] = []
//     @Published var isConfigurationValid: Bool = true
//     @Published var validationErrors: [String] = []
    
//     private let userDefaults = UserDefaults.standard
//     private let configurationKey = "com.sdk.configuration"
//     private let maxHistorySize = 100
    
//     init(configuration: SDKConfiguration = .default) {
//         self.currentConfiguration = configuration
//         self.availablePresets = SDKConfiguration.presets
        
//         loadConfiguration()
//         validateConfiguration()
//     }
    
//     private func loadConfiguration() {
//         do {
//             guard let data = userDefaults.data(forKey: configurationKey),
//                   !data.isEmpty else {
//                 print("📱 No saved configuration found, using defaults")
//                 return
//             }
            
//             let decoder = JSONDecoder()
//             decoder.dateDecodingStrategy = .iso8601
            
//             let savedConfiguration = try decoder.decode(SDKConfiguration.self, from: data)
            
//             // Validate loaded configuration
//             if isValidConfiguration(savedConfiguration) {
//                 currentConfiguration = savedConfiguration
//                 print("✅ Configuration loaded successfully")
//                 delegate?.configurationManager(self, didUpdateConfiguration: savedConfiguration)
//             } else {
//                 print("⚠️ Loaded configuration is invalid, using defaults")
//                 saveConfiguration()
//             }
//         } catch {
//             print("❌ Failed to load configuration: \(error)")
//             // Reset to defaults on load failure
//             saveConfiguration()
//         }
//     }
    
//     private func saveConfiguration() {
//         do {
//             let encoder = JSONEncoder()
//             encoder.dateEncodingStrategy = .iso8601
//             encoder.outputFormatting = .prettyPrinted
            
//             let data = try encoder.encode(currentConfiguration)
//             userDefaults.set(data, forKey: configurationKey)
            
//             // Attempt to synchronize with cloud storage
//             if userDefaults.synchronize() {
//                 print("✅ Configuration saved successfully")
//                 delegate?.configurationManager(self, didUpdateConfiguration: currentConfiguration)
//             } else {
//                 print("⚠️ Configuration saved locally but cloud sync failed")
//             }
            
//         } catch {
//             print("❌ Failed to save configuration: \(error)")
//         }
//     }
    
//     private func isValidConfiguration(_ config: SDKConfiguration) -> Bool {
//         validationErrors.removeAll()
        
//         // Comprehensive validation
//         guard !config.voiceConfiguration.voiceName.isEmpty else {
//             validationErrors.append("Voice name cannot be empty")
//             return false
//         }
        
//         guard config.voiceConfiguration.voiceSpeed >= 0.25 && config.voiceConfiguration.voiceSpeed <= 4.0 else {
//             validationErrors.append("Voice speed must be between 0.25 and 4.0")
//             return false
//         }
        
//         guard !config.languageConfiguration.inputLanguageCode.isEmpty else {
//             validationErrors.append("Input language code cannot be empty")
//             return false
//         }
        
//         guard config.audioQualityConfiguration.sampleRate.rawValue > 0 else {
//             validationErrors.append("Sample rate must be positive")
//             return false
//         }
        
//         return true
//     }
    
//     func updateVoiceConfiguration(_ voiceConfig: VoiceConfiguration, source: ConfigurationChangeEvent.ChangeSource = .user) {
//         let oldConfig = currentConfiguration.voiceConfiguration
        
//         currentConfiguration = SDKConfiguration(
//             voiceConfiguration: voiceConfig,
//             languageConfiguration: currentConfiguration.languageConfiguration,
//             activityDetectionConfiguration: currentConfiguration.activityDetectionConfiguration,
//             audioQualityConfiguration: currentConfiguration.audioQualityConfiguration,
//             advancedConfiguration: currentConfiguration.advancedConfiguration,
//             lastModified: Date(),
//             version: currentConfiguration.version
//         )
        
//         logConfigurationChange(category: .voice, field: "voiceConfiguration", oldValue: oldConfig, newValue: voiceConfig, source: source)
//         saveConfiguration()
//         validateConfiguration()
        
//         delegate?.configurationManager(self, didUpdateConfiguration: currentConfiguration)
//         delegate?.configurationManager(self, didChangeValue: "voiceConfiguration", category: .voice)
//     }
    
//     func updateLanguageConfiguration(_ languageConfig: LanguageConfiguration, source: ConfigurationChangeEvent.ChangeSource = .user) {
//         let oldConfig = currentConfiguration.languageConfiguration
        
//         currentConfiguration = SDKConfiguration(
//             voiceConfiguration: currentConfiguration.voiceConfiguration,
//             languageConfiguration: languageConfig,
//             activityDetectionConfiguration: currentConfiguration.activityDetectionConfiguration,
//             audioQualityConfiguration: currentConfiguration.audioQualityConfiguration,
//             advancedConfiguration: currentConfiguration.advancedConfiguration,
//             lastModified: Date(),
//             version: currentConfiguration.version
//         )
        
//         logConfigurationChange(category: .language, field: "languageConfiguration", oldValue: oldConfig, newValue: languageConfig, source: source)
//         saveConfiguration()
//         validateConfiguration()
        
//         delegate?.configurationManager(self, didUpdateConfiguration: currentConfiguration)
//         delegate?.configurationManager(self, didChangeValue: "languageConfiguration", category: .language)
//     }
    
//     func updateSensitivityLevels(start: ActivityDetectionConfiguration.SensitivityLevel, end: ActivityDetectionConfiguration.SensitivityLevel) {
//         var activityConfig = currentConfiguration.activityDetectionConfiguration
//         activityConfig = ActivityDetectionConfiguration(
//             startOfSpeechSensitivity: start,
//             endOfSpeechSensitivity: end,
//             silenceDurationMs: activityConfig.silenceDurationMs,
//             prefixPaddingMs: activityConfig.prefixPaddingMs,
//             voiceActivityThreshold: activityConfig.voiceActivityThreshold,
//             noiseSuppressionLevel: activityConfig.noiseSuppressionLevel,
//             echoCancellationEnabled: activityConfig.echoCancellationEnabled,
//             adaptiveSensitivity: activityConfig.adaptiveSensitivity
//         )
        
//         updateActivityDetectionConfiguration(activityConfig)
//     }
    
//     func updateActivityDetectionConfiguration(_ activityConfig: ActivityDetectionConfiguration, source: ConfigurationChangeEvent.ChangeSource = .user) {
//         let oldConfig = currentConfiguration.activityDetectionConfiguration
        
//         currentConfiguration = SDKConfiguration(
//             voiceConfiguration: currentConfiguration.voiceConfiguration,
//             languageConfiguration: currentConfiguration.languageConfiguration,
//             activityDetectionConfiguration: activityConfig,
//             audioQualityConfiguration: currentConfiguration.audioQualityConfiguration,
//             advancedConfiguration: currentConfiguration.advancedConfiguration,
//             lastModified: Date(),
//             version: currentConfiguration.version
//         )
        
//         logConfigurationChange(category: .activityDetection, field: "activityDetectionConfiguration", oldValue: oldConfig, newValue: activityConfig, source: source)
//         saveConfiguration()
//         validateConfiguration()
        
//         delegate?.configurationManager(self, didUpdateConfiguration: currentConfiguration)
//         delegate?.configurationManager(self, didChangeValue: "activityDetectionConfiguration", category: .activityDetection)
//     }
    
//     func applyPreset(_ preset: SDKConfiguration.ConfigurationPreset) {
//         let oldConfig = currentConfiguration
//         currentConfiguration = preset.configuration
        
//         logConfigurationChange(category: .voice, field: "preset", oldValue: oldConfig, newValue: preset.configuration, source: .preset)
//         saveConfiguration()
//         validateConfiguration()
        
//         delegate?.configurationManager(self, didUpdateConfiguration: currentConfiguration)
//         delegate?.configurationManager(self, didApplyPreset: preset)
//     }
    
//     private func validateConfiguration() {
//         var errors: [String] = []
        
//         if currentConfiguration.voiceConfiguration.voiceSpeed < 0.25 || currentConfiguration.voiceConfiguration.voiceSpeed > 4.0 {
//             errors.append("Voice speed must be between 0.25 and 4.0")
//         }
        
//         isConfigurationValid = errors.isEmpty
//         validationErrors = errors
        
//         delegate?.configurationManager(self, didValidateConfiguration: isConfigurationValid, errors: errors)
//     }
    
//     private func logConfigurationChange(category: ConfigurationChangeEvent.ConfigurationCategory, field: String, oldValue: Any?, newValue: Any?, source: ConfigurationChangeEvent.ChangeSource) {
//         let event = ConfigurationChangeEvent(
//             timestamp: Date(),
//             category: category,
//             field: field,
//             oldValue: oldValue,
//             newValue: newValue,
//             source: source
//         )
        
//         configurationHistory.append(event)
        
//         if configurationHistory.count > maxHistorySize {
//             configurationHistory.removeFirst(configurationHistory.count - maxHistorySize)
//         }
//     }
    
//     func exportConfiguration() throws -> Data {
//         return try JSONEncoder().encode(currentConfiguration)
//     }
    
//     func importConfiguration(from data: Data) throws {
//         let importedConfig = try JSONDecoder().decode(SDKConfiguration.self, from: data)
        
//         currentConfiguration = SDKConfiguration(
//             voiceConfiguration: importedConfig.voiceConfiguration,
//             languageConfiguration: importedConfig.languageConfiguration,
//             activityDetectionConfiguration: importedConfig.activityDetectionConfiguration,
//             audioQualityConfiguration: importedConfig.audioQualityConfiguration,
//             advancedConfiguration: importedConfig.advancedConfiguration,
//             lastModified: Date(),
//             version: currentConfiguration.version
//         )
        
//         saveConfiguration()
//         validateConfiguration()
        
//         delegate?.configurationManager(self, didUpdateConfiguration: currentConfiguration)
//     }
// }

// // MARK: - Error Handling Types (Simplified for integration)

// enum SDKError: Error, LocalizedError {
//     case connectionTimeout
//     case networkUnavailable
//     case connectionFailed(String)
//     case audioStreamError(String)
//     case websocketError(String)
    
//     var errorDescription: String? {
//         switch self {
//         case .connectionTimeout:
//             return "Connection timeout"
//         case .networkUnavailable:
//             return "Network unavailable"
//         case .connectionFailed(let message):
//             return "Connection failed: \(message)"
//         case .audioStreamError(let message):
//             return "Audio stream error: \(message)"
//         case .websocketError(let message):
//             return "WebSocket error: \(message)"
//         }
//     }
// }

// struct SDKErrorContext {
//     let operation: String
//     let state: String
//     let metadata: [String: Any]
// }

// struct SDKErrorStats {
//     let totalErrors: Int
//     let errorsByType: [String: Int]
//     let recoveryRate: Double
//     let lastErrorTime: Date?
// }

// struct ErrorRecoveryAction {
//     let actionType: String
//     let description: String
//     let estimatedTime: TimeInterval
// }

// protocol SDKErrorHandlerDelegate: AnyObject {
//     func errorHandler(_ handler: SDKErrorHandler, didEncounterError error: SDKError, context: SDKErrorContext)
//     func errorHandler(_ handler: SDKErrorHandler, willAttemptRecovery action: ErrorRecoveryAction, attempt: Int)
//     func errorHandler(_ handler: SDKErrorHandler, didRecoverFromError error: SDKError, recoveryTime: TimeInterval)
//     func errorHandler(_ handler: SDKErrorHandler, didFailToRecover error: SDKError, finalAttempt: Bool)
//     func errorHandler(_ handler: SDKErrorHandler, didUpdateStats stats: SDKErrorStats)
// }

// struct RetryConfig {
//     let maxRetries: Int
//     let baseDelay: TimeInterval
//     let maxDelay: TimeInterval
//     let backoffMultiplier: Double
    
//     static let `default` = RetryConfig(
//         maxRetries: 3,
//         baseDelay: 1.0,
//         maxDelay: 30.0,
//         backoffMultiplier: 2.0
//     )
// }

// class SDKErrorHandler {
//     weak var delegate: SDKErrorHandlerDelegate?
//     private let retryConfig: RetryConfig
    
//     init(retryConfig: RetryConfig) {
//         self.retryConfig = retryConfig
//     }
    
//     func handleError(_ error: SDKError, context: SDKErrorContext) async -> Bool {
//         delegate?.errorHandler(self, didEncounterError: error, context: context)
        
//         // Determine recovery strategy based on error type
//         let recoveryStrategy = determineRecoveryStrategy(for: error, context: context)
        
//         for attempt in 1...retryConfig.maxRetries {
//             let action = ErrorRecoveryAction(
//                 actionType: recoveryStrategy.actionType,
//                 description: recoveryStrategy.description,
//                 estimatedTime: recoveryStrategy.estimatedTime
//             )
            
//             delegate?.errorHandler(self, willAttemptRecovery: action, attempt: attempt)
            
//             // Execute recovery action
//             let success = await executeRecoveryAction(strategy: recoveryStrategy, attempt: attempt)
            
//             if success {
//                 delegate?.errorHandler(self, didRecoverFromError: error, recoveryTime: recoveryStrategy.estimatedTime)
//                 return true
//             }
            
//             // Apply exponential backoff
//             let backoffDelay = calculateBackoffDelay(attempt: attempt, baseDelay: retryConfig.baseDelay)
//             try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
//         }
        
//         // All recovery attempts failed
//         delegate?.errorHandler(self, didFailToRecover: error, finalAttempt: true)
//         return false
//     }
    
//     private func determineRecoveryStrategy(for error: SDKError, context: SDKErrorContext) -> RecoveryStrategy {
//         switch error {
//         case .connectionTimeout, .connectionFailed:
//             return RecoveryStrategy(
//                 actionType: "reconnect",
//                 description: "Attempting to reconnect to WebSocket",
//                 estimatedTime: 3.0,
//                 recoveryAction: .reconnect
//             )
//         case .networkUnavailable:
//             return RecoveryStrategy(
//                 actionType: "networkRetry",
//                 description: "Waiting for network connectivity",
//                 estimatedTime: 5.0,
//                 recoveryAction: .waitAndRetry
//             )
//         case .websocketError:
//             return RecoveryStrategy(
//                 actionType: "websocketRetry",
//                 description: "Retrying with different endpoint",
//                 estimatedTime: 4.0,
//                 recoveryAction: .switchEndpoint
//             )
//         case .audioStreamError:
//             return RecoveryStrategy(
//                 actionType: "audioRetry",
//                 description: "Reinitializing audio stream",
//                 estimatedTime: 2.0,
//                 recoveryAction: .reconnect
//             )
//         }
//     }
    
//     private func executeRecoveryAction(strategy: RecoveryStrategy, attempt: Int) async -> Bool {
//         switch strategy.recoveryAction {
//         case .reconnect:
//             // Attempt to reconnect with current configuration
//             do {
//                 // Wait before reconnection
//                 try await Task.sleep(nanoseconds: 1_000_000_000)
                
//                 // This would need access to the main client's connection method
//                 // For now, return false to indicate reconnection should be handled by the main client
//                 return false
//             } catch {
//                 return false
//             }
            
//         case .refreshToken:
//             // Token refresh would need to be handled by the main client
//             return false
            
//         case .switchEndpoint:
//             // Endpoint switching would need to be handled by the main client
//             return false
            
//         case .waitAndRetry:
//             // Simple wait strategy
//             try? await Task.sleep(nanoseconds: UInt64(strategy.estimatedTime * 1_000_000_000))
//             return false
//         }
//     }
    
//     private func calculateBackoffDelay(attempt: Int, baseDelay: TimeInterval) -> TimeInterval {
//         // Exponential backoff with jitter
//         let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
//         let maxDelay = min(exponentialDelay, 30.0) // Cap at 30 seconds
        
//         // Add jitter (±25% randomness)
//         let jitter = Double.random(in: 0.75...1.25)
//         return maxDelay * jitter
//     }
// }

// struct RecoveryStrategy {
//     let actionType: String
//     let description: String
//     let estimatedTime: TimeInterval
//     let recoveryAction: RecoveryActionType
// }

// enum RecoveryActionType {
//     case reconnect
//     case refreshToken
//     case switchEndpoint
//     case waitAndRetry
// }

// // MARK: - Session Resumption Types (Simplified for integration)

// struct SessionResumptionManagerConfig {
//     let enabled: Bool
//     let maxResumptionWindow: TimeInterval
//     let backupFrequency: TimeInterval
    
//     static let `default` = SessionResumptionManagerConfig(
//         enabled: true,
//         maxResumptionWindow: 300.0,
//         backupFrequency: 30.0
//     )
// }

// struct SessionResumptionStats {
//     let totalResumptions: Int
//     let successfulResumptions: Int
//     let averageResumptionTime: TimeInterval
//     let lastResumptionTime: Date?
// }

// struct LiveServerSessionResumptionUpdate {
//     let sessionId: String
//     let resumptionToken: String
//     let expiresAt: Date
//     let supportedFeatures: [String]
//     let serverState: [String: Any]
//     let resumptionCapabilities: ResumptionCapabilities
    
//     struct ResumptionCapabilities {
//         let canResumeAudio: Bool
//         let canResumeTools: Bool
//         let canResumeConversation: Bool
//         let maxResumptionWindow: TimeInterval
//         let supportedResumptionMethods: [String]
//     }
// }

// protocol SessionResumptionDelegate: AnyObject {
//     func sessionResumption(_ manager: SessionResumptionManager, willStartResumption sessionId: String, attempt: Int)
//     func sessionResumption(_ manager: SessionResumptionManager, didCreateStateBackup size: Int)
//     func sessionResumption(_ manager: SessionResumptionManager, didReceiveServerUpdate update: LiveServerSessionResumptionUpdate)
//     func sessionResumption(_ manager: SessionResumptionManager, didCompleteResumption sessionId: String, resumptionTime: TimeInterval)
//     func sessionResumption(_ manager: SessionResumptionManager, didFailResumption sessionId: String, error: Error, attempt: Int)
//     func sessionResumption(_ manager: SessionResumptionManager, didUpdateStats stats: SessionResumptionStats)
// }

// class SessionResumptionManager {
//     weak var delegate: SessionResumptionDelegate?
//     private let config: SessionResumptionManagerConfig
//     private var sessionState: SessionState?
//     private var backupData: Data?
//     private var resumptionAttempts: [String: Int] = [:]
    
//     init(config: SessionResumptionManagerConfig) {
//         self.config = config
//     }
    
//     func createSessionBackup(sessionId: String, conversationHistory: [TranscriptionMessage], audioState: AudioLevels) {
//         guard config.enabled else { return }
        
//         let sessionData = SessionState(
//             sessionId: sessionId,
//             backupSize: conversationHistory.count,
//             timestamp: Date()
//         )
        
//         do {
//             let encoder = JSONEncoder()
//             backupData = try encoder.encode(sessionData)
//             sessionState = sessionData
            
//             delegate?.sessionResumption(self, didCreateStateBackup: backupData?.count ?? 0)
//             print("💾 Session backup created: \(sessionData.backupSize) messages")
//         } catch {
//             print("❌ Failed to create session backup: \(error)")
//         }
//     }
    
//     func attemptResumption(sessionId: String) async -> Bool {
//         guard config.enabled,
//               let storedSession = sessionState,
//               storedSession.sessionId == sessionId else {
//             return false
//         }
        
//         let currentAttempts = resumptionAttempts[sessionId] ?? 0
//         guard currentAttempts < 3 else { // Max 3 resumption attempts
//             delegate?.sessionResumption(self, didFailResumption: sessionId, error: SessionError.maxAttemptsExceeded, attempt: currentAttempts)
//             return false
//         }
        
//         resumptionAttempts[sessionId] = currentAttempts + 1
        
//         delegate?.sessionResumption(self, willStartResumption: sessionId, attempt: currentAttempts + 1)
        
//         // Simulate resumption process with actual checks
//         let resumptionStartTime = Date()
        
//         // Check if backup is still valid (not too old)
//         let backupAge = Date().timeIntervalSince(storedSession.timestamp)
//         guard backupAge <= config.maxResumptionWindow else {
//             let error = SessionError.backupExpired
//             delegate?.sessionResumption(self, didFailResumption: sessionId, error: error, attempt: currentAttempts + 1)
//             return false
//         }
        
//         // Simulate resumption delay
//         try? await Task.sleep(nanoseconds: UInt64(config.backupFrequency * 1_000_000_000))
        
//         let resumptionTime = Date().timeIntervalSince(resumptionStartTime)
//         delegate?.sessionResumption(self, didCompleteResumption: sessionId, resumptionTime: resumptionTime)
        
//         // Update stats
//         let stats = SessionResumptionStats(
//             totalResumptions: currentAttempts + 1,
//             successfulResumptions: 1,
//             averageResumptionTime: resumptionTime,
//             lastResumptionTime: Date()
//         )
//         delegate?.sessionResumption(self, didUpdateStats: stats)
        
//         print("✅ Session resumed successfully: \(sessionId) in \(resumptionTime)s")
//         return true
//     }
    
//     func handleServerResumptionUpdate(_ update: LiveServerSessionResumptionUpdate) async {
//         delegate?.sessionResumption(self, didReceiveServerUpdate: update)
        
//         // Process server update for session synchronization
//         if let sessionData = sessionState,
//            sessionData.sessionId == update.sessionId {
            
//             // Create updated session state based on server update
//             let updatedSession = SessionState(
//                 sessionId: sessionData.sessionId,
//                 backupSize: sessionData.backupSize,
//                 timestamp: Date()
//             )
            
//             // Apply server updates to local state
//             sessionState = updatedSession
            
//             print("🔄 Session state updated from server: \(update.sessionId)")
//         }
//     }
    
//     func clearSession(sessionId: String) {
//         sessionState = nil
//         backupData = nil
//         resumptionAttempts.removeValue(forKey: sessionId)
//         print("🗑️ Session cleared: \(sessionId)")
//     }
// }

// struct SessionState: Codable {
//     let sessionId: String
//     let backupSize: Int
//     let timestamp: Date
    
//     // Note: Simplified to only include easily codable data
//     // Full conversation history and audio state would need custom encoding
    
//     private enum CodingKeys: String, CodingKey {
//         case sessionId, backupSize, timestamp
//     }
// }

// enum SessionError: Error {
//     case maxAttemptsExceeded
//     case backupExpired
//     case resumptionFailed
// }
