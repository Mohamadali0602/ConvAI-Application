//
//  CoachView.swift
//  ConvAI
//

import SwiftUI
import AVFoundation
import AudioToolbox
import Foundation

/// Main coaching screen: real-time streaming audio conversation with Gemini Live API
struct CoachView: View {
    // MARK: - DAY 1 - HOUR 1: Lesson Context Integration
    let lesson: SimpleLesson?
    let session: ConversationSession?
    let onConversationComplete: ((ConversationSession) -> Void)?
    
    @EnvironmentObject var auth: EnhancedAuthenticationService
    @StateObject private var liveClient = GeminiLiveClient()
    @StateObject private var agentState = AgentState() // Add agent state for animated face
    @State private var isStreaming = false
    @State private var isConnecting = false
    @State private var lastCoachingResponse: String?
    @State private var errorMessage: String?
    @State private var statusText = "Ready for live speech coaching"
    
    // MARK: - Session Management (DAY 1 - HOUR 3)
    @State private var currentSession: ConversationSession?
    
    // Audio components for streaming
    @State private var audioEngine: AVAudioEngine?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackEngine: AVAudioEngine?
    @State private var playbackPlayerNode: AVAudioPlayerNode?
    @State private var audioBuffer: Data = Data()
    @State private var lastPlaybackTime: Date = Date()
    @State private var isPlayingAudio = false
    @State private var pendingPlaybackTimer: Timer?
    @State private var isMicMuted = false
    
    // Enhanced audio volume tracking for better face animation
    @State private var currentAudioOutputVolume: Float = 0.0
    @State private var volumeUpdateTimer: Timer?
    
    // Audio buffering for efficient transmission
    @State private var outgoingAudioBuffer = Data()
    @State private var audioSendTimer: Timer?
    @State private var lastAudioSendTime = Date()
    private let audioBufferTargetSize = 4096 // 4KB chunks for more efficient sending
    private let maxAudioSendInterval: TimeInterval = 0.1 // Maximum 100ms between sends
    
    // MARK: - Initializers (DAY 1 - HOUR 1)
    init(lesson: SimpleLesson? = nil, session: ConversationSession? = nil, onConversationComplete: ((ConversationSession) -> Void)? = nil) {
        self.lesson = lesson
        self.session = session
        self.onConversationComplete = onConversationComplete
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                if !auth.isSignedIn {
                    // Authentication Screen
                    AuthGateView()
                        .environmentObject(auth)
                } else {
                    // Main Coaching Interface
                    VStack(spacing: 32) {
                        // Header with lesson and user info
                        VStack(spacing: 8) {
                            if let lesson = lesson {
                                // Lesson-specific header (DAY 1 - HOUR 1)
                                Text(lesson.displayTitle)
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)
                                
                                Text(lesson.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                // Default header
                                Text("AI Speech Coach")
                                    .font(.largeTitle.bold())
                            }
                            
                        }
                        
                        Text(statusText)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Streaming Button
                        VStack(spacing: 20) {
                            Button(action: toggleStreaming) {
                                ZStack {
                                    Circle()
                                        .fill(isStreaming ? Color.red : (liveClient.isConnected ? Color.green : Color.blue))
                                        .frame(width: 120, height: 120)
                                        .scaleEffect(isStreaming ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isStreaming)
                                    
                                    Image(systemName: isStreaming ? "mic.fill" : (liveClient.isConnected ? "phone.connection" : "mic"))
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(isConnecting)
                            
                            Text(getButtonText())
                                .font(.headline)
                                .foregroundColor(isStreaming ? .red : (liveClient.isConnected ? .green : .blue))
                            
                            // Test Audio Button
                            Button("🔊 Test Audio") {
                                testAudioOutput()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        // Connection status
                        if isConnecting {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Connecting to AI coach...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.top)
                            }
                        }
                        
                        // Response area
                        if let response = lastCoachingResponse {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("AI Coach Feedback")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button("Clear") {
                                        clearLastResponse()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                
                                ScrollView {
                                    Text(response)
                                        .font(.body)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                                .frame(maxHeight: 150)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Error message
                        if let error = errorMessage ?? liveClient.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        Button("Sign Out") {
                            auth.signOut()
                        }
                        .foregroundColor(.red)
                        .padding(.bottom)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if lesson != nil {
                        // Show back button for lesson-specific conversations (DAY 1 - HOUR 1)
                        Button(action: {
                            // Stop streaming if active and complete session
                            if isStreaming {
                                stopStreaming()
                            } else if var session = currentSession {
                                // Complete session even if user exits early
                                session.completeSession()
                                onConversationComplete?(session)
                                currentSession = nil
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.primary)
                        }
                    } else {
                        // Show close button for standalone coach view
                        Button(action: {
                            if isStreaming {
                                stopStreaming()
                            }
                            // No callback needed for standalone mode
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                setupAudioSession()
                setupPlaybackEngine()
            }
        }
    }
    
    // MARK: - Live Streaming Methods
        
        private func setupAudioSession() {
#if os(iOS)
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
                try audioSession.setActive(true)
                
                print("🔊 Audio session setup:")
                print("   Category: \(audioSession.category)")
                print("   Output route: \(audioSession.currentRoute.outputs.map { $0.portName }.joined(separator: ", "))")
                print("   Input route: \(audioSession.currentRoute.inputs.map { $0.portName }.joined(separator: ", "))")
                
            } catch {
                errorMessage = "Audio setup failed: \(error.localizedDescription)"
                print("❌ Audio session setup failed: \(error)")
            }
#endif
        }
        
        private func setupPlaybackEngine() {
            print("🎵 Setting up persistent playback engine")
            
            playbackEngine = AVAudioEngine()
            playbackPlayerNode = AVAudioPlayerNode()
            
            guard let engine = playbackEngine, let playerNode = playbackPlayerNode else {
                print("❌ Failed to create playback engine components")
                return
            }
            
            engine.attach(playerNode)
            
            // Get output format and create compatible format
            let outputFormat = engine.outputNode.inputFormat(forBus: 0)
            print("🎵 Playback engine output format: \(outputFormat.sampleRate)Hz, \(outputFormat.channelCount) channels")
            
            let playbackFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: outputFormat.sampleRate,
                channels: outputFormat.channelCount,
                interleaved: false
            )!
            
            engine.connect(playerNode, to: engine.outputNode, format: playbackFormat)
            
            do {
                try engine.start()
                playerNode.play()
                playerNode.volume = 1.0
                print("✅ Persistent playback engine started successfully")
            } catch {
                print("❌ Failed to start playback engine: \(error)")
            }
        }
        
        private func toggleStreaming() {
            if isStreaming {
                stopStreaming()
            } else {
                Task {
                    await startStreaming()
                }
            }
        }
        
        private func startStreaming() async {
            guard !isStreaming, !isConnecting else { return }
            
            isConnecting = true
            errorMessage = nil
            statusText = "Connecting to AI coach..."
            
            // MARK: - DAY 1 - HOUR 3: Session Management - Start Session
            if let session = session, currentSession == nil {
                currentSession = session
                print("🎯 Started conversation session: \(session.lessonTitle)")
            }
            
            do {
                // Start the Live API connection with coaching prompt
                let coachingPrompt = """
            You are Vinh Giang's AI speech coach. Listen to the user's speech and provide:
            1. ONE concise tip (≤5 seconds of advice) for improvement
            2. Re-speak a specific portion with improved delivery
            Be encouraging, supportive, and focus on practical improvements.
            Respond with audio when possible.
            """
                
                let agentTypeString = "coach"
                try await liveClient.start(
                    systemPrompt: coachingPrompt,  
                    agentType: agentTypeString,
                    onAudioOut: { audioData in
                        Task { @MainActor in
                            await self.playAudioResponse(audioData)
                        }
                    },
                    onTextOut: { textChunk in
                        Task { @MainActor in
                            // Lightweight handling: log transcript chunks for now
                            print("📝 Transcript chunk (coach): \(textChunk)")
                        }
                    }
                )
                
                // Start audio streaming to Live API
                try await startAudioStreaming()
                
                isStreaming = true
                isConnecting = false
                statusText = "Live coaching active - speak naturally"
                
            } catch {
                isConnecting = false
                errorMessage = "Failed to start live coaching: \(error.localizedDescription)"
                statusText = "Ready for live speech coaching"
            }
        }
        
        private func stopStreaming() {
            guard isStreaming else { return }
            
            stopAudioStreaming()
            
            // Clean up audio state
            pendingPlaybackTimer?.invalidate()
            pendingPlaybackTimer = nil
            audioBuffer = Data()
            isPlayingAudio = false
            isMicMuted = false // Reset microphone muting
            
            // MARK: - DAY 1 - HOUR 3: Session Management - Complete Session
            if var session = currentSession {
                session.completeSession()
                print("🎯 Completed conversation session: \(session.lessonTitle)")
                print("🎯 Session duration: \(session.duration) seconds")
                print("🎯 XP earned: \(session.xpEarned)")
                
                // Call completion callback
                onConversationComplete?(session)
                currentSession = nil
            }
            
            Task {
                await liveClient.stop()
            }
            
            isStreaming = false
            statusText = "Ready for live speech coaching"
        }
        
        private func startAudioStreaming() async throws {
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Gemini 2.5 native audio model expects:
            // INPUT: 16kHz mono PCM for microphone data
            let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 16000,
                channels: 1,
                interleaved: false
            )!
            
            guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
                throw URLError(.cannotCreateFile)
            }
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                Task { @MainActor in
                    await self.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
                }
            }
            
            try audioEngine.start()
        }
        
        private func stopAudioStreaming() {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine = nil
            
            // Clean up audio buffering
            audioSendTimer?.invalidate()
            audioSendTimer = nil
            outgoingAudioBuffer.removeAll()
        }
        
        private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat) async {
            // Don't process microphone input while AI is speaking to prevent feedback
            guard !isMicMuted else {
                print("🔇 Microphone muted - skipping audio processing")
                return
            }
            
            // Convert to target format
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: 1024)!
            
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            if status == .error {
                print("❌ Audio conversion error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            // Get PCM data
            guard let channelData = convertedBuffer.int16ChannelData?[0] else { return }
            let dataPointer = UnsafeRawPointer(channelData)
            let audioData = Data(bytes: dataPointer, count: Int(convertedBuffer.frameLength) * 2)
            
            // 🔒 SECURITY: Validate outgoing audio data
            guard validateAudioData(audioData) else {
                print("🚨 SECURITY: Invalid outgoing audio data rejected")
                return
            }
            
            // Add to outgoing buffer for efficient batching
            await bufferOutgoingAudio(audioData)
        }
        
        private func bufferOutgoingAudio(_ audioData: Data) async {
            outgoingAudioBuffer.append(audioData)
            
            let now = Date()
            let timeSinceLastSend = now.timeIntervalSince(lastAudioSendTime)
            
            // Send if buffer is large enough OR if it's been too long since last send
            let shouldSend = outgoingAudioBuffer.count >= audioBufferTargetSize || 
                            timeSinceLastSend >= maxAudioSendInterval
            
            if shouldSend && !outgoingAudioBuffer.isEmpty {
                let dataToSend = outgoingAudioBuffer
                outgoingAudioBuffer.removeAll()
                lastAudioSendTime = now
                
                print("📤 Sending batched audio: \(dataToSend.count) bytes")
                
                // Send the batched audio data
                await liveClient.send(audioData: dataToSend)
            } else if outgoingAudioBuffer.count > 0 {
                // Schedule a send if we haven't sent in a while
                scheduleAudioSend()
            }
        }
        
        private func scheduleAudioSend() {
            // Cancel existing timer
            audioSendTimer?.invalidate()
            
            // Schedule new timer
            audioSendTimer = Timer.scheduledTimer(withTimeInterval: maxAudioSendInterval, repeats: false) { _ in
                Task { @MainActor in
                    if !self.outgoingAudioBuffer.isEmpty {
                        let dataToSend = self.outgoingAudioBuffer
                        self.outgoingAudioBuffer.removeAll()
                        self.lastAudioSendTime = Date()
                        
                        print("📤 Sending scheduled audio: \(dataToSend.count) bytes")
                        await self.liveClient.send(audioData: dataToSend)
                    }
                }
            }
        }
        
        private func playAudioResponse(_ audioData: Data) async {
            print("🔊 playAudioResponse called with \(audioData.count) bytes")
            
            // 🔒 SECURITY: Validate audio data before processing
            guard validateAudioData(audioData) else {
                print("🚨 SECURITY: Invalid audio data rejected")
                return
            }
            
            // Always accumulate audio data
            audioBuffer.append(audioData)
            lastPlaybackTime = Date()
            
            print("📦 Audio buffer now has \(audioBuffer.count) bytes total")
            
            // Be more conservative with chunk sizes for better quality
            if !isPlayingAudio {
                // Use larger buffer for better audio quality (0.3 seconds)
                // 24kHz output * 2 bytes per sample * 0.3 seconds = 14,400 bytes
                let minBufferSize = Int(24000 * 2 * 0.3) // 0.3 seconds of 24kHz 16-bit mono audio
                
                if audioBuffer.count >= minBufferSize {
                    await playAccumulatedAudio()
                } else {
                    // Slightly longer delay for better quality chunks
                    scheduleDelayedPlayback()
                }
            }
            // If already playing, audio will be picked up automatically when current chunk finishes
        }
        
        private func scheduleDelayedPlayback() {
            // Cancel any existing timer
            pendingPlaybackTimer?.invalidate()
            
            // Balanced delay for quality vs responsiveness
            pendingPlaybackTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                Task { @MainActor in
                    // Play if we have any audio and aren't currently playing
                    if !self.isPlayingAudio && !self.audioBuffer.isEmpty {
                        await self.playAccumulatedAudio()
                    }
                }
            }
        }
        
        private func playAccumulatedAudio() async {
            guard !audioBuffer.isEmpty && !isPlayingAudio else { return }
            
            isPlayingAudio = true
            
            // Mute microphone to prevent feedback loop
            isMicMuted = true
            print("🔇 Muting microphone during AI speech")
            
            // Use larger chunks for better audio quality (1 second max)
            let chunkSize = min(audioBuffer.count, Int(24000 * 2 * 1.0)) // Max 1 second per chunk
            let dataToPlay = audioBuffer.prefix(chunkSize)
            audioBuffer.removeFirst(chunkSize)
            
            print("🎵 Playing accumulated audio: \(dataToPlay.count) bytes (buffer remaining: \(audioBuffer.count) bytes)")
            
            // Gemini 2.5 native audio model outputs:
            // OUTPUT: 24kHz 16-bit mono PCM audio
            guard let audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 24000,
                channels: 1,
                interleaved: false
            ) else {
                print("❌ Failed to create audio format")
                isPlayingAudio = false
                isMicMuted = false
                return
            }
            
            let frameCount = UInt32(dataToPlay.count / 2) // 2 bytes per Int16 sample
            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
                print("❌ Failed to create audio buffer")
                isPlayingAudio = false
                isMicMuted = false
                return
            }
            
            sourceBuffer.frameLength = frameCount
            
            // Copy audio data to buffer
            dataToPlay.withUnsafeBytes { bytes in
                guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                      let channelData = sourceBuffer.int16ChannelData else { return }
                channelData[0].update(from: int16Pointer, count: Int(frameCount))
            }
            
            // Use the persistent playback engine
            guard let engine = playbackEngine, let playerNode = playbackPlayerNode else {
                print("❌ Playback engine not available")
                isPlayingAudio = false
                isMicMuted = false
                return
            }
            
            // Get the target format for the engine
            let outputFormat = engine.outputNode.inputFormat(forBus: 0)
            let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: outputFormat.sampleRate,
                channels: outputFormat.channelCount,
                interleaved: false
            )!
            
            // Convert the audio to the target format
            guard let converter = AVAudioConverter(from: audioFormat, to: targetFormat) else {
                print("❌ Failed to create audio converter")
                isPlayingAudio = false
                isMicMuted = false
                return
            }
            
            let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: AVAudioFrameCount(Double(frameCount) * outputFormat.sampleRate / audioFormat.sampleRate)
            )!
            
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return sourceBuffer
            }
            
            if status == .error {
                print("❌ Audio conversion error: \(error?.localizedDescription ?? "Unknown")")
                isPlayingAudio = false
                isMicMuted = false
                return
            }
            
            // Schedule the buffer for playback
            print("🎵 Scheduling \(convertedBuffer.frameLength) frames for playback")
            playerNode.scheduleBuffer(convertedBuffer) {
                Task { @MainActor in
                    print("✅ Audio chunk playback completed")
                    self.isPlayingAudio = false
                    
                    // Continue with next chunk if available
                    if !self.audioBuffer.isEmpty {
                        print("🔄 Immediately continuing with next audio chunk")
                        await self.playAccumulatedAudio()
                    } else {
                        // No more audio - unmute microphone after a brief delay
                        print("🎙️ Unmuting microphone - AI finished speaking")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isMicMuted = false
                        }
                    }
                }
            }
            
            print("✅ Audio chunk scheduled successfully")
            
        }
        
        private func tryAlternativePlayback(_ audioData: Data) async {
            print("🔄 Trying alternative audio playback methods")
            
            // Try different sample rates that Gemini might use
            let sampleRates: [Double] = [16000, 22050, 24000, 44100, 48000]
            
            for sampleRate in sampleRates {
                print("🎵 Attempting playback at \(sampleRate)Hz")
                
                guard let audioFormat = AVAudioFormat(
                    commonFormat: .pcmFormatInt16,
                    sampleRate: sampleRate,
                    channels: 1,
                    interleaved: false
                ) else { continue }
                
                let frameCount = UInt32(audioData.count / 2)
                guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { continue }
                
                audioBuffer.frameLength = frameCount
                
                audioData.withUnsafeBytes { bytes in
                    guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                          let channelData = audioBuffer.int16ChannelData else { return }
                    channelData[0].update(from: int16Pointer, count: Int(frameCount))
                }
                
                do {
                    let audioEngine = AVAudioEngine()
                    let playerNode = AVAudioPlayerNode()
                    
                    audioEngine.attach(playerNode)
                    
                    // Get output format and create compatible format
                    let outputFormat = audioEngine.outputNode.inputFormat(forBus: 0)
                    let compatibleFormat = AVAudioFormat(
                        commonFormat: .pcmFormatFloat32,
                        sampleRate: outputFormat.sampleRate,
                        channels: outputFormat.channelCount,
                        interleaved: false
                    )!
                    
                    audioEngine.connect(playerNode, to: audioEngine.outputNode, format: compatibleFormat)
                    
                    try audioEngine.start()
                    playerNode.play()
                    
                    // Convert if needed
                    if audioFormat.channelCount != outputFormat.channelCount {
                        guard let converter = AVAudioConverter(from: audioFormat, to: compatibleFormat) else { continue }
                        
                        let convertedBuffer = AVAudioPCMBuffer(
                            pcmFormat: compatibleFormat,
                            frameCapacity: AVAudioFrameCount(Double(frameCount) * outputFormat.sampleRate / sampleRate)
                        )!
                        
                        var error: NSError?
                        let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                            outStatus.pointee = .haveData
                            return audioBuffer
                        }
                        
                        if status == .error { continue }
                        
                        playerNode.scheduleBuffer(convertedBuffer, completionHandler: nil)
                    } else {
                        playerNode.scheduleBuffer(audioBuffer, completionHandler: nil)
                    }
                    
                    print("✅ Successfully played audio at \(sampleRate)Hz")
                    return
                    
                } catch {
                    print("❌ Failed at \(sampleRate)Hz: \(error)")
                    continue
                }
            }
            
            print("❌ All audio playback attempts failed")
        }
        
        private func getButtonText() -> String {
            if isConnecting {
                return "Connecting..."
            } else if isStreaming {
                return "Streaming... Tap to stop"
            } else if liveClient.isConnected {
                return "Connected - Tap to start streaming"
            } else {
                return "Tap to connect and stream"
            }
        }
        
        private func clearLastResponse() {
            lastCoachingResponse = nil
            errorMessage = nil
        }
        
        private func testAudioOutput() {
            print("🔊 Testing audio output...")
            
            // Play a system sound first
            AudioServicesPlaySystemSound(1016) // This is a standard system sound
            
            // Also try generating a simple tone
            Task {
                await generateTestTone()
            }
        }
        
        // 🔒 SECURITY: Audio Data Validation (As specified in MainAppPlan.md)
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
        
        private func generateTestTone() async {
            print("🎵 Generating test tone...")
            
            let sampleRate: Double = 48000
            let frequency: Double = 440 // A note
            let duration: Double = 1.0
            let frameCount = UInt32(sampleRate * duration)
            
            guard let audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 2,
                interleaved: false
            ) else {
                print("❌ Failed to create test audio format")
                return
            }
            
            guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
                print("❌ Failed to create test audio buffer")
                return
            }
            
            audioBuffer.frameLength = frameCount
            
            // Generate sine wave
            guard let leftChannel = audioBuffer.floatChannelData?[0],
                  let rightChannel = audioBuffer.floatChannelData?[1] else {
                print("❌ Failed to get test channel data")
                return
            }
            
            for i in 0..<Int(frameCount) {
                let sample = Float(sin(2.0 * Double.pi * frequency * Double(i) / sampleRate)) * 0.5
                leftChannel[i] = sample
                rightChannel[i] = sample
            }
            
            // Play the test tone
            do {
                let audioEngine = AVAudioEngine()
                let playerNode = AVAudioPlayerNode()
                
                audioEngine.attach(playerNode)
                audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFormat)
                
                try audioEngine.start()
                playerNode.play()
                playerNode.volume = 0.8
                
                playerNode.scheduleBuffer(audioBuffer) {
                    print("✅ Test tone playback completed")
                }
                
                print("✅ Test tone started successfully")
                
            } catch {
                print("❌ Failed to play test tone: \(error)")
            }
        }
}
