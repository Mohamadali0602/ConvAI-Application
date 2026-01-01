import Foundation
import Speech
import AVFoundation
#if canImport(UIKit)
import UIKit // For background task support
#endif

// MARK: - ✅ Step 5.1: Recognition Mode and Pronunciation Models
enum RecognitionMode {
    case aiTranscription    // For transcribing AI speech
    case userPronunciation  // For assessing user pronunciation
}

struct PronunciationResult: Identifiable, Codable {
    let id: String
    let targetText: String
    let recognizedText: String
    let overallScore: Double // 0.0 to 1.0
    let wordScores: [WordPronunciationScore]
    let feedback: PronunciationFeedback
    let timestamp: Date

    init(id: String = UUID().uuidString, targetText: String, recognizedText: String, overallScore: Double, wordScores: [WordPronunciationScore], feedback: PronunciationFeedback, timestamp: Date = Date()) {
        self.id = id
        self.targetText = targetText
        self.recognizedText = recognizedText
        self.overallScore = overallScore
        self.wordScores = wordScores
        self.feedback = feedback
        self.timestamp = timestamp
    }
}

struct WordPronunciationScore: Codable {
    let word: String
    let targetPhonemes: String
    let recognizedPhonemes: String
    let accuracy: Double // 0.0 to 1.0
    let confidence: Float
    let suggestions: [String]
}

struct PronunciationFeedback: Codable {
    let overallMessage: String
    let strengths: [String]
    let improvements: [String]
    let specificTips: [String]
    let practiceWords: [String]
}

struct PronunciationSession {
    let id: String
    let targetText: String
    let startTime: Date
    var endTime: Date?
    var results: [PronunciationResult]
    var attemptCount: Int
    
    init(targetText: String) {
        self.id = UUID().uuidString
        self.targetText = targetText
        self.startTime = Date()
        self.results = []
        self.attemptCount = 0
    }
    
    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    var averageAccuracy: Double {
        guard !results.isEmpty else { return 0.0 }
        return results.reduce(0) { $0 + $1.overallScore } / Double(results.count)
    }
    
    var strongPhonemes: [String] {
        guard !results.isEmpty else { return [] }
        return results.flatMap { result in
            result.wordScores.compactMap { word in
                word.accuracy > 0.8 ? word.targetPhonemes : nil
            }
        }
    }
    
    var weakPhonemes: [String] {
        guard !results.isEmpty else { return [] }
        return results.flatMap { result in
            result.wordScores.compactMap { word in
                word.accuracy < 0.6 ? word.targetPhonemes : nil
            }
        }
    }
    
    func calculateImprovementTrend() -> Double {
        guard results.count >= 2 else { return 0.0 }
        let recent = results.suffix(3).map { $0.overallScore }
        let earlier = results.prefix(results.count - 3).map { $0.overallScore }
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.isEmpty ? 0 : earlier.reduce(0, +) / Double(earlier.count)
        
        return recentAvg - earlierAvg
    }
    
    mutating func addAttempt(recognizedText: String, score: Double, wordScores: [WordPronunciationScore]) {
        let result = PronunciationResult(
            targetText: targetText,
            recognizedText: recognizedText,
            overallScore: score,
            wordScores: wordScores,
            feedback: PronunciationFeedback(
                overallMessage: generateOverallMessage(score: score),
                strengths: [],
                improvements: [],
                specificTips: [],
                practiceWords: []
            ),
            timestamp: Date()
        )
        results.append(result)
        attemptCount += 1
    }
    
    private func generateOverallMessage(score: Double) -> String {
        switch score {
        case 0.9...1.0:
            return "Excellent pronunciation!"
        case 0.7..<0.9:
            return "Good pronunciation with room for improvement."
        case 0.5..<0.7:
            return "Fair pronunciation. Keep practicing!"
        default:
            return "Keep practicing to improve your pronunciation."
        }
    }
}

struct RecognitionMetrics {
    var transcriptionLatency: TimeInterval = 0
    var processingTime: TimeInterval = 0
    var memoryUsage: Int = 0
    var recognitionCount: Int = 0
    var errorCount: Int = 0
    var startTime: Date = Date()
    var totalProcessingTime: TimeInterval = 0
    var audioChunksProcessed: Int = 0
    var recognitionErrors: Int = 0
    
    mutating func recordTranscription(latency: TimeInterval, processingTime: TimeInterval) {
        transcriptionLatency = latency
        self.processingTime = processingTime
        recognitionCount += 1
    }
    
    mutating func recordError() {
        errorCount += 1
        recognitionErrors += 1
    }
    
    mutating func reset() {
        transcriptionLatency = 0
        processingTime = 0
        memoryUsage = 0
        recognitionCount = 0
        errorCount = 0
        startTime = Date()
        totalProcessingTime = 0
        audioChunksProcessed = 0
        recognitionErrors = 0
    }
    
    mutating func recordChunk() {
        recognitionCount += 1
        audioChunksProcessed += 1
    }
    
    var averageLatency: TimeInterval {
        guard audioChunksProcessed > 0 else { return 0 }
        return totalProcessingTime / TimeInterval(audioChunksProcessed)
    }
}

struct PronunciationProgress {
    let wordsPracticed: Int
    let averageAccuracy: Double
    let improvementTrend: Double // Positive = improving, negative = declining
    let sessionDuration: TimeInterval
    let strongPhonemes: [String]
    let weakPhonemes: [String]
}

/// Service for real-time speech recognition of AI audio responses
/// Designed to work with existing LessonView audio playback system
@MainActor
final class SpeechRecognitionService: NSObject, ObservableObject {
    
    // MARK: - Configuration
    /// Emergency flag to disable speech recognition if causing crashes
    private let speechRecognitionEnabled = true // Set to false to disable entirely
    
    // MARK: - Public Interface
    @Published var isRecognizing = false
    @Published var lastError: String?
    @Published var recognitionPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // Recognition callbacks
    var onPartialTranscript: ((String) -> Void)?
    var onFinalTranscript: ((String) -> Void)?
    var onRecognitionError: ((Error) -> Void)?
    
    // ✅ Step 5.1: Pronunciation exercise callbacks
    var onPronunciationResult: ((PronunciationResult) -> Void)?
    var onPronunciationProgress: ((PronunciationProgress) -> Void)?
    
    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Audio buffer management for real-time processing
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioMixerNode?
    
    // Recognition configuration
    private var currentLanguage: String = "en-US"
    private var confidenceThreshold: Float = 0.1 // Lower threshold for AI-generated speech (was 0.3)
    
    // ✅ Step 4.2: Language Support Configuration
    private var supportedLanguages: [String: String] = [
        "en-US": "English (US)",
        "en-GB": "English (UK)",
        "es-US": "Spanish (US)",
        "es-ES": "Spanish (Spain)",
        "fr-FR": "French (France)",
        "de-DE": "German (Germany)",
        "it-IT": "Italian (Italy)",
        "pt-BR": "Portuguese (Brazil)",
        "zh-CN": "Chinese (Simplified)",
        "ja-JP": "Japanese",
        "ko-KR": "Korean",
        "ar-SA": "Arabic (Saudi Arabia)"
    ]
    
    private var domainSpecificVocabulary: [String] = [] // Custom vocabulary for lessons
    
    // State management
    private var partialTranscript = ""
    private var isProcessingAudio = false
    
    // Audio accumulation for better AI speech recognition
    private var audioAccumulationBuffer = Data()
    private var lastAudioTime = Date()
    private let audioAccumulationTimeout: TimeInterval = 0.5 // 500ms buffer window
    private let minAudioBufferSize = 4000 // Minimum bytes before processing
    
    // ✅ Step 4.3: Performance Optimization Properties
    private var audioBufferQueue = DispatchQueue(label: "speechRecognition.audioBuffer", qos: .userInitiated)
    private var recognitionMetrics = RecognitionMetrics()
    #if canImport(UIKit)
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    #endif
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    // ✅ Step 5.1: Pronunciation Exercise Properties
    private var recognitionMode: RecognitionMode = .aiTranscription
    private var targetText: String = ""
    private var pronunciationSession: PronunciationSession?
    private var phoneticAnalyzer = PhoneticAnalyzer()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    deinit {
        // Clean up resources synchronously
        recognitionTask?.cancel()
        audioEngine?.stop()
        if let engine = audioEngine, engine.inputNode.numberOfInputs > 0 {
            engine.inputNode.removeTap(onBus: 0)
        }
        
        // Stop memory pressure monitoring
        memoryPressureSource?.cancel()
        memoryPressureSource = nil
        
        #if canImport(UIKit)
        // End background task if active
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        }
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Request speech recognition permissions
    func requestPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.recognitionPermissionStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    /// Start speech recognition for AI audio transcription
    @MainActor
    func startRecognition(language: String = "en-US") async throws {
        // Safety check: disable speech recognition if flag is set
        guard speechRecognitionEnabled else {
            print("⚠️ Speech recognition disabled for stability")
            return
        }
        
        guard !isRecognizing else { return }
        
        // Ensure permissions
        if recognitionPermissionStatus != .authorized {
            let granted = await requestPermissions()
            guard granted else {
                throw SpeechRecognitionError.permissionDenied
            }
        }
        
        // Setup recognizer for specified language
        currentLanguage = language
        setupSpeechRecognizer()
        
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        // Configure request for real-time transcription
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false // Use cloud for better accuracy
        
        // ✅ For AI transcription, add more tolerance for different speech patterns
        if recognitionMode == .aiTranscription {
            // Add contextual strings that might help with AI speech recognition
            recognitionRequest.contextualStrings = [
                "artificial intelligence", "AI", "assistant", "conversation", 
                "learning", "practice", "lesson", "skill", "coaching"
            ]
        }
        
        // Start recognition task
        isRecognizing = true
        lastError = nil
        partialTranscript = ""
        
        // ✅ Step 4.3: Initialize performance monitoring
        recognitionMetrics.reset()
        recognitionMetrics.startTime = Date()
        startMemoryPressureMonitoring()
        startBackgroundTask()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }
        
        print("✅ Speech recognition started for language: \(language)")
    }
    
    /// Stop speech recognition
    @MainActor
    func stopRecognition() {
        guard isRecognizing else { return }
        
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        
        recognitionTask = nil
        recognitionRequest = nil
        
        isRecognizing = false
        isProcessingAudio = false
        
        // ✅ Step 4.3: Stop performance monitoring
        stopMemoryPressureMonitoring()
        endBackgroundTask()
        logPerformanceMetrics()
        
        print("✅ Speech recognition stopped")
    }
    
    /// Process AI audio data for transcription
    /// This method integrates with LessonView's existing playAudioResponse system
    func processAIAudio(_ audioData: Data, format: AVAudioFormat) {
        // Safety check: disable speech recognition if flag is set
        guard speechRecognitionEnabled else {
            // Silently return - don't log to avoid spam
            return
        }
        
        guard isRecognizing,
              let recognitionRequest = recognitionRequest else { 
            print("📝 Speech recognition not active or no request available")
            return 
        }
        
        print("📝 Processing AI audio: \(audioData.count) bytes, format: \(format.sampleRate)Hz")
        
        // ✅ Accumulate audio for better recognition results
        audioAccumulationBuffer.append(audioData)
        lastAudioTime = Date()
        
        // Process accumulated audio if we have enough data or timeout
        let shouldProcess = audioAccumulationBuffer.count >= minAudioBufferSize || 
                           Date().timeIntervalSince(lastAudioTime) > audioAccumulationTimeout
        
        if shouldProcess {
            let dataToProcess = audioAccumulationBuffer
            audioAccumulationBuffer.removeAll()
            
            print("📝 Processing accumulated audio: \(dataToProcess.count) bytes")
            
            // ✅ Step 4.3: Process audio on background queue for performance
            audioBufferQueue.async { [weak self] in
                guard let self = self else { return }
                
                // Process audio on background thread
                let processedBuffer = self.processAudioForRecognition(dataToProcess, format: format)
                
                // Send to speech recognizer on main queue
                Task { @MainActor in
                    guard let recognitionRequest = self.recognitionRequest,
                          let buffer = processedBuffer else { return }
                    
                    print("📝 Sending \(buffer.frameLength) frames (\(dataToProcess.count) bytes) to speech recognizer")
                    recognitionRequest.append(buffer)
                    
                    // Update metrics
                    self.recognitionMetrics.recordChunk()
                    self.isProcessingAudio = true
                }
            }
        }
    }
    
    /// Process accumulated AI audio data (background thread)
    nonisolated private func processAudioForRecognition(_ audioData: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Create optimal format for speech recognition (16kHz mono)
        guard let recognitionFormat = Self.createOptimalRecognitionFormat() else {
            print("❌ Failed to create recognition format")
            return nil
        }
        
        // Create source buffer from AI audio (24kHz)
        let sourceFrameCount = UInt32(audioData.count / MemoryLayout<Int16>.size)
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: sourceFrameCount) else {
            print("❌ Failed to create source audio buffer")
            return nil
        }
        
        sourceBuffer.frameLength = sourceFrameCount
        
        // Copy audio data to source buffer
        audioData.withUnsafeBytes { bytes in
            guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                  let channelData = sourceBuffer.int16ChannelData else { 
                print("❌ Failed to access audio buffer data")
                return 
            }
            channelData[0].update(from: int16Pointer, count: Int(sourceFrameCount))
        }
        
        // Convert from 24kHz to 16kHz for speech recognition
        guard let converter = AVAudioConverter(from: format, to: recognitionFormat) else {
            print("❌ Failed to create audio converter from \(format.sampleRate)Hz to \(recognitionFormat.sampleRate)Hz")
            return nil
        }
        
        // Calculate target frame count (convert from 24kHz to 16kHz)
        let targetFrameCount = AVAudioFrameCount(Double(sourceFrameCount) * recognitionFormat.sampleRate / format.sampleRate)
        guard let targetBuffer = AVAudioPCMBuffer(pcmFormat: recognitionFormat, frameCapacity: targetFrameCount) else {
            print("❌ Failed to create target audio buffer")
            return nil
        }
        
        // Perform conversion
        var conversionError: NSError?
        let conversionStatus = converter.convert(to: targetBuffer, error: &conversionError) { _, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        
        guard conversionStatus != .error else {
            print("❌ Audio conversion failed: \(conversionError?.localizedDescription ?? "Unknown error")")
            return nil
        }
        
        // ✅ Step 2.2: Audio preprocessing for better recognition on converted audio
        guard let convertedData = self.extractAudioData(from: targetBuffer) else {
            print("❌ Failed to extract audio data from converted buffer")
            return nil
        }
        
        let preprocessedData = self.preprocessAudioForRecognition(convertedData, format: recognitionFormat)
        
        // Create final buffer with preprocessed data
        let finalFrameCount = UInt32(preprocessedData.count / MemoryLayout<Int16>.size)
        guard let finalBuffer = AVAudioPCMBuffer(pcmFormat: recognitionFormat, frameCapacity: finalFrameCount) else {
            print("❌ Failed to create final audio buffer")
            return nil
        }
        
        finalBuffer.frameLength = finalFrameCount
        
        // Copy preprocessed data to final buffer
        preprocessedData.withUnsafeBytes { bytes in
            guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                  let channelData = finalBuffer.int16ChannelData else { return }
            channelData[0].update(from: int16Pointer, count: Int(finalFrameCount))
        }
        
        return finalBuffer
    }
    
    /// ✅ ADD THIS FUNCTION: Forces the processing of any remaining audio in the buffer.
    /// This is used to ensure the final words of an AI's turn are transcribed.
    func finalizeCurrentAudioProcessing() {
        // Only proceed if there's actually audio data left to process.
        guard !audioAccumulationBuffer.isEmpty else {
            print("📝 Finalize audio: Buffer is empty, nothing to do.")
            return
        }
        
        print("📝 Finalizing audio processing: flushing \(audioAccumulationBuffer.count) bytes.")
        
        let dataToProcess = audioAccumulationBuffer
        audioAccumulationBuffer.removeAll() // Clear the buffer immediately
        
        // Use the same background queue processing as the main processAIAudio method.
        audioBufferQueue.async { [weak self] in
            guard let self = self else { return }
            
            // We need a format to process the buffer. Let's assume the standard Gemini format.
            // This is a safe assumption as all AI audio comes in this format.
            let format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 24000,
                channels: 1,
                interleaved: true
            )!
            
            let processedBuffer = self.processAudioForRecognition(dataToProcess, format: format)
            
            // Send the final processed buffer to the speech recognizer on the main thread.
            Task { @MainActor in
                guard let recognitionRequest = self.recognitionRequest,
                      let buffer = processedBuffer else { return }
                
                print("📝 Sending final \(buffer.frameLength) frames to speech recognizer.")
                recognitionRequest.append(buffer)
                self.recognitionMetrics.recordChunk()
            }
        }
    }
    
    /// Update recognition language (useful for multi-language conversations)
    func setLanguage(_ language: String) {
        guard language != currentLanguage else { return }
        
        // ✅ Step 4.2: Validate language support
        guard supportedLanguages.keys.contains(language) else {
            print("❌ Unsupported language: \(language)")
            return
        }
        
        currentLanguage = language
        
        // Restart recognition with new language if currently active
        if isRecognizing {
            Task { @MainActor in
                stopRecognition()
                try? await startRecognition(language: language)
            }
        }
        
        print("📝 Language changed to: \(supportedLanguages[language] ?? language)")
    }
    
    /// ✅ Step 4.2: Set domain-specific vocabulary for better recognition
    func setDomainVocabulary(_ vocabulary: [String]) {
        domainSpecificVocabulary = vocabulary
        print("📝 Domain vocabulary set: \(vocabulary.count) terms")
    }
    
    /// ✅ Step 4.2: Get available languages
    func getAvailableLanguages() -> [String: String] {
        return supportedLanguages
    }
    
    /// ✅ Step 5.2: Detect language automatically (basic implementation)
    func detectLanguage(from text: String) -> String? {
        // Basic language detection using common words
        let languageIndicators: [String: [String]] = [
            "en-US": ["the", "and", "is", "it", "you", "that", "he", "was", "for", "on"],
            "es-ES": ["el", "la", "de", "que", "y", "es", "en", "un", "se", "no"],
            "fr-FR": ["le", "de", "et", "à", "un", "il", "être", "et", "en", "avoir"],
            "de-DE": ["der", "die", "und", "in", "den", "von", "zu", "das", "mit", "sich"],
            "it-IT": ["il", "di", "che", "e", "la", "per", "un", "in", "è", "con"],
            "pt-BR": ["o", "de", "e", "do", "a", "em", "um", "para", "é", "com"]
        ]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var languageScores: [String: Int] = [:]
        
        for (language, indicators) in languageIndicators {
            let matches = words.filter { indicators.contains($0) }.count
            languageScores[language] = matches
        }
        
        return languageScores.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - ✅ Step 5.1: Bidirectional Recognition Methods
    
    /// Start pronunciation exercise mode with target text
    func startPronunciationExercise(targetText: String, language: String = "en-US") async throws {
        self.targetText = targetText
        self.recognitionMode = .userPronunciation
        
        // Create new pronunciation session
        pronunciationSession = PronunciationSession(targetText: targetText)
        
        // Configure recognition for pronunciation assessment
        try await startRecognition(language: language)
        
        // Set pronunciation-specific parameters
        configurePronunciationRecognition()
        
        print("📝 Started pronunciation exercise for: '\(targetText)'")
    }
    
    /// Switch back to AI transcription mode
    func switchToTranscriptionMode(language: String = "en-US") async throws {
        recognitionMode = .aiTranscription
        targetText = ""
        
        if pronunciationSession != nil {
            pronunciationSession!.endTime = Date()
            logPronunciationSession(pronunciationSession!)
        }
        pronunciationSession = nil
        
        // Restart recognition with transcription parameters
        if isRecognizing {
            stopRecognition()
            try await startRecognition(language: language)
        }
        
        print("📝 Switched to AI transcription mode")
    }
    
    /// Process user audio for pronunciation assessment
    func processUserAudio(_ audioData: Data, format: AVAudioFormat) {
        guard recognitionMode == .userPronunciation,
              let recognitionRequest = recognitionRequest else { return }
        
        // Process on background queue for performance
        audioBufferQueue.async { [weak self] in
            guard let self = self else { return }
            
            let startTime = Date()
            
            // Apply pronunciation-specific preprocessing
            let preprocessedData = self.preprocessAudioForPronunciation(audioData, format: format)
            
            // Create audio buffer
            let frameCount = UInt32(preprocessedData.count / MemoryLayout<Int16>.size)
            guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("❌ Failed to create pronunciation audio buffer")
                return
            }
            
            audioBuffer.frameLength = frameCount
            
            // Copy audio data to buffer
            preprocessedData.withUnsafeBytes { bytes in
                guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                      let channelData = audioBuffer.int16ChannelData else { return }
                channelData[0].update(from: int16Pointer, count: Int(frameCount))
            }
            
            // Send buffer to speech recognizer
            DispatchQueue.main.async {
                recognitionRequest.append(audioBuffer)
                
                // Update metrics
                self.recognitionMetrics.recordChunk()
                self.recognitionMetrics.totalProcessingTime += Date().timeIntervalSince(startTime)
                
                self.isProcessingAudio = true
            }
        }
    }
    
    /// Get current pronunciation session progress
    func getPronunciationProgress() -> PronunciationProgress? {
        guard let session = pronunciationSession else { return nil }
        
        return PronunciationProgress(
            wordsPracticed: session.attemptCount,
            averageAccuracy: session.averageAccuracy,
            improvementTrend: session.calculateImprovementTrend(),
            sessionDuration: Date().timeIntervalSince(session.startTime),
            strongPhonemes: session.strongPhonemes,
            weakPhonemes: session.weakPhonemes
        )
    }
    
    // MARK: - Private Methods
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
        speechRecognizer?.delegate = self
        
        // Check initial permission status
        recognitionPermissionStatus = SFSpeechRecognizer.authorizationStatus()
        
        print("📝 Speech recognizer setup for language: \(currentLanguage)")
        print("📝 Recognizer available: \(speechRecognizer?.isAvailable ?? false)")
        print("📝 Permission status: \(recognitionPermissionStatus.rawValue)")
    }
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        var isFinal = false
        var transcript = ""
        
        if let result = result {
            transcript = result.bestTranscription.formattedString
            isFinal = result.isFinal
            
            // Filter by confidence for better quality
            let segments = result.bestTranscription.segments
            let averageConfidence = segments.isEmpty ? 1.0 : segments.map { $0.confidence }.reduce(0, +) / Float(segments.count)
            
            // For AI transcription, be more lenient with confidence - AI speech patterns differ from human speech
            let shouldAcceptTranscript = recognitionMode == .aiTranscription ? 
                (averageConfidence >= 0.05 || transcript.trimmingCharacters(in: .whitespacesAndNewlines).count > 2) : // Very low threshold for AI speech
                (averageConfidence >= confidenceThreshold) // Normal threshold for user pronunciation
            
            if shouldAcceptTranscript {
                print("📝 Accepting transcript with confidence: \(averageConfidence) - '\(transcript)'")
                
                // ✅ Step 4.1: Apply transcript enhancements
                let enhancedTranscript = enhanceTranscript(transcript, segments: segments, confidence: averageConfidence)
                
                // ✅ Step 5.1: Handle different recognition modes
                switch recognitionMode {
                case .aiTranscription:
                    handleTranscriptionResult(enhancedTranscript, isFinal: isFinal, segments: segments, confidence: averageConfidence)
                case .userPronunciation:
                    handlePronunciationResult(enhancedTranscript, targetText: targetText, isFinal: isFinal, segments: segments, confidence: averageConfidence)
                }
            } else {
                print("📝 Low confidence transcript ignored: \(averageConfidence) for '\(transcript)'")
            }
        }
        
        if let error = error {
            print("❌ Speech recognition error: \(error)")
            lastError = error.localizedDescription
            onRecognitionError?(error)
            
            // ✅ Step 4.3: Track error metrics
            recognitionMetrics.recordError()
            
            // Handle specific error cases
            if let nsError = error as NSError? {
                switch nsError.code {
                case 203: // Speech recognition service unavailable
                    print("📝 Speech recognition service temporarily unavailable")
                case 216: // Speech recognition request cancelled
                    print("📝 Speech recognition cancelled")
                case 1110, 1700: // No speech detected (different iOS versions/contexts)
                    // This is common with AI audio chunks - don't spam logs
                    print("📝 No speech detected in audio chunk")
                    // Don't call onRecognitionError for this common case
                    return
                default:
                    break
                }
            }
        }
        
        // Stop if final result or error
        if isFinal || error != nil {
            isProcessingAudio = false
        }
    }
    
    /// Handle transcription results (AI speech)
    private func handleTranscriptionResult(_ transcript: String, isFinal: Bool, segments: [SFTranscriptionSegment], confidence: Float) {
        if isFinal {
            onFinalTranscript?(transcript)
            partialTranscript = ""
            print("📝 Final transcript: \(transcript) (confidence: \(confidence))")
        } else {
            partialTranscript = transcript
            onPartialTranscript?(transcript)
            print("📝 Partial transcript: \(transcript) (confidence: \(confidence))")
            
            // Enhanced sentence boundary detection
            if detectSentenceBoundary(transcript) {
                print("📝 Sentence boundary detected, treating as final")
                onFinalTranscript?(transcript)
                partialTranscript = ""
            }
        }
    }
    
    /// ✅ Step 5.2: Handle pronunciation assessment results
    private func handlePronunciationResult(_ recognizedText: String, targetText: String, isFinal: Bool, segments: [SFTranscriptionSegment], confidence: Float) {
        guard isFinal else {
            // Send partial progress updates for real-time feedback
            if let progress = getPronunciationProgress() {
                onPronunciationProgress?(progress)
            }
            return
        }
        
        // Perform pronunciation assessment
        let pronunciationResult = assessPronunciation(
            targetText: targetText,
            recognizedText: recognizedText,
            segments: segments,
            confidence: confidence
        )
        
        // Update pronunciation session
        pronunciationSession?.addAttempt(
            recognizedText: recognizedText,
            score: pronunciationResult.overallScore,
            wordScores: pronunciationResult.wordScores
        )
        
        // Send result to callback
        onPronunciationResult?(pronunciationResult)
        
        print("📝 Pronunciation result: \(pronunciationResult.overallScore * 100)% accuracy")
        print("📝 Target: '\(targetText)' | Recognized: '\(recognizedText)'")
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            print("📝 Speech recognizer availability changed: \(available)")
            if !available && isRecognizing {
                stopRecognition()
                lastError = "Speech recognition service became unavailable"
            }
        }
    }
}

// MARK: - Error Types
enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case requestCreationFailed
    case audioEngineError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .recognizerUnavailable:
            return "Speech recognizer unavailable for this language"
        case .requestCreationFailed:
            return "Failed to create speech recognition request"
        case .audioEngineError:
            return "Audio engine configuration error"
        }
    }
}

// MARK: - Audio Format Utilities
extension SpeechRecognitionService {
    
    /// Create optimal audio format for speech recognition
    nonisolated static func createOptimalRecognitionFormat() -> AVAudioFormat? {
        return AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000, // 16kHz is optimal for speech recognition
            channels: 1,
            interleaved: true
        )
    }
    
    /// Extract audio data from PCM buffer
    nonisolated private func extractAudioData(from buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.int16ChannelData else { 
            print("❌ Failed to access channel data from audio buffer")
            return nil 
        }
        
        let frameCount = Int(buffer.frameLength)
        let data = Data(bytes: channelData[0], count: frameCount * MemoryLayout<Int16>.size)
        print("📝 Extracted \(data.count) bytes from audio buffer")
        return data
    }
    
    /// ✅ Step 2.2: Audio preprocessing for enhanced recognition accuracy
    nonisolated private func preprocessAudioForRecognition(_ audioData: Data, format: AVAudioFormat) -> Data {
        // Disable audio normalization to prevent crashes - return original data
        // This may reduce recognition accuracy but prevents app crashes
        print("📝 Audio preprocessing: returning original data (normalization disabled for stability)")
        return audioData
    }
    
    /// Normalize audio volume for consistent recognition
    nonisolated private func normalizeAudioVolume(_ audioData: Data) -> Data {
        // Safety check for minimum data size
        guard audioData.count >= 2, audioData.count % 2 == 0 else { 
            print("⚠️ Invalid audio data size for normalization: \(audioData.count) bytes")
            return audioData 
        }
        
        // Use safer approach to extract samples
        var samples = [Int16]()
        let sampleCount = audioData.count / MemoryLayout<Int16>.size
        
        // Safely extract Int16 samples from Data
        samples.reserveCapacity(sampleCount)
        for i in stride(from: 0, to: audioData.count - 1, by: 2) {
            let byte1 = audioData[i]
            let byte2 = audioData[i + 1]
            let sample = Int16(byte1) | (Int16(byte2) << 8)
            samples.append(sample)
        }
        
        // Find peak amplitude safely
        guard !samples.isEmpty else { return audioData }
        let maxSample = samples.map { abs($0) }.max() ?? 1
        guard maxSample > 0 else { return audioData }
        
        // Normalize to 80% of max range for speech recognition
        let targetMax: Int16 = Int16(Double(Int16.max) * 0.8)
        let gain = Double(targetMax) / Double(maxSample)
        
        // Apply gain only if needed (avoid amplifying already loud audio)
        if gain > 0.5 && gain < 2.0 {
            for i in 0..<samples.count {
                let normalizedSample = Double(samples[i]) * gain
                samples[i] = Int16(max(min(normalizedSample, Double(Int16.max)), Double(Int16.min)))
            }
        }
        
        // Convert samples back to Data safely
        var resultData = Data()
        resultData.reserveCapacity(samples.count * 2)
        for sample in samples {
            let byte1 = UInt8(sample & 0xFF)
            let byte2 = UInt8((sample >> 8) & 0xFF)
            resultData.append(byte1)
            resultData.append(byte2)
        }
        
        return resultData
    }
    
    /// Convert audio format if needed for speech recognition
    func convertAudioForRecognition(_ audioData: Data, from sourceFormat: AVAudioFormat) -> (Data, AVAudioFormat)? {
        // If source format is already optimal, return as-is
        let optimalFormat = Self.createOptimalRecognitionFormat()
        guard let targetFormat = optimalFormat else { return nil }
        
        if sourceFormat.sampleRate == targetFormat.sampleRate &&
           sourceFormat.channelCount == targetFormat.channelCount &&
           sourceFormat.commonFormat == targetFormat.commonFormat {
            return (audioData, sourceFormat)
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            print("❌ Failed to create audio converter for speech recognition")
            return nil
        }
        
        // Convert audio data
        let frameCount = UInt32(audioData.count / MemoryLayout<Int16>.size)
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount),
              let targetBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else {
            return nil
        }
        
        sourceBuffer.frameLength = frameCount
        audioData.withUnsafeBytes { bytes in
            guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress,
                  let channelData = sourceBuffer.int16ChannelData else { return }
            channelData[0].update(from: int16Pointer, count: Int(frameCount))
        }
        
        var conversionError: NSError?
        let status = converter.convert(to: targetBuffer, error: &conversionError) { _, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        
        guard status != .error else {
            print("❌ Audio conversion failed: \(conversionError?.localizedDescription ?? "Unknown")")
            return nil
        }
        
        // Extract converted data
        guard let channelData = targetBuffer.int16ChannelData else { return nil }
        let convertedData = Data(bytes: channelData[0], count: Int(targetBuffer.frameLength) * MemoryLayout<Int16>.size)
        
        return (convertedData, targetFormat)
    }
    
    /// ✅ Step 2.3: Enhanced sentence boundary detection
    private func detectSentenceBoundary(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for explicit sentence endings
        let sentenceEnders = [".", "!", "?", "。", "！", "？"] // Include some international punctuation
        if sentenceEnders.contains(where: { trimmedText.hasSuffix($0) }) {
            return true
        }
        
        // Check for natural pause indicators
        let pauseIndicators = [" - ", " -- ", "...", " and ", " but ", " so "]
        if pauseIndicators.contains(where: { trimmedText.contains($0) }) && trimmedText.count > 20 {
            return true
        }
        
        // Check for length-based completion (very long sentences should be broken up)
        if trimmedText.count > 150 {
            return true
        }
        
        return false
    }
    
    // MARK: - ✅ Step 4.1: Transcript Enhancement Methods
    
    /// Enhance transcript with automatic punctuation, capitalization, and formatting
    private func enhanceTranscript(_ text: String, segments: [SFTranscriptionSegment], confidence: Float) -> String {
        var enhanced = text
        
        // Apply enhancements in order
        enhanced = applyAutomaticPunctuation(enhanced)
        enhanced = applySmartCapitalization(enhanced)
        enhanced = applyCertaintyFormatting(enhanced, segments: segments)
        
        return enhanced
    }
    
    /// ✅ Step 4.1: Automatic punctuation insertion
    private func applyAutomaticPunctuation(_ text: String) -> String {
        var result = text
        
        // Add periods to sentences that clearly end but don't have punctuation
        let sentences = result.components(separatedBy: ". ")
        var enhancedSentences: [String] = []
        
        for (index, sentence) in sentences.enumerated() {
            var enhancedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // If it's the last sentence and doesn't end with punctuation, add a period
            if index == sentences.count - 1 && !enhancedSentence.isEmpty {
                let lastChar = String(enhancedSentence.last ?? " ")
                if ![".", "!", "?", ","].contains(lastChar) {
                    // Check if it looks like a complete thought
                    if enhancedSentence.count > 3 && isCompleteSentence(enhancedSentence) {
                        enhancedSentence += "."
                    }
                }
            }
            
            enhancedSentences.append(enhancedSentence)
        }
        
        result = enhancedSentences.joined(separator: ". ")
        
        // Add commas for natural pauses (basic heuristic)
        result = addNaturalCommas(result)
        
        return result
    }
    
    /// ✅ Step 4.1: Smart capitalization for proper nouns and sentence beginnings
    private func applySmartCapitalization(_ text: String) -> String {
        var result = text
        
        // Capitalize first letter of sentences
        result = capitalizeSentenceBeginnings(result)
        
        // Capitalize common proper nouns (basic set - can be expanded)
        result = capitalizeProperNouns(result)
        
        return result
    }
    
    /// ✅ Step 4.1: Apply formatting based on recognition certainty
    private func applyCertaintyFormatting(_ text: String, segments: [SFTranscriptionSegment]) -> String {
        // For now, return the text as-is
        // Future: Could add markers for low-confidence words
        // Example: [uncertain] word [/uncertain] for words with <0.5 confidence
        return text
    }
    
    // MARK: - Helper Methods for Transcript Enhancement
    
    private func isCompleteSentence(_ sentence: String) -> Bool {
        let words = sentence.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        // Must have at least 2 words to be a sentence
        guard words.count >= 2 else { return false }
        
        // Check for common sentence patterns
        let commonStarters = ["i", "you", "he", "she", "it", "we", "they", "this", "that", "there", "here"]
        let firstWord = words[0].lowercased()
        
        if commonStarters.contains(firstWord) {
            return true
        }
        
        // Check for question words
        let questionWords = ["what", "when", "where", "why", "how", "who", "which"]
        if questionWords.contains(firstWord) {
            return true
        }
        
        return words.count >= 3 // If 3+ words, likely a sentence
    }
    
    private func addNaturalCommas(_ text: String) -> String {
        var result = text
        
        // Basic comma insertion patterns
        let commaPatterns = [
            " and ": " and ", // Keep existing
            " but ": ", but ",
            " so ": ", so ",
            " however ": ", however, ",
            " therefore ": ", therefore, "
        ]
        
        for (pattern, replacement) in commaPatterns {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return result
    }
    
    private func capitalizeSentenceBeginnings(_ text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        let capitalizedSentences = sentences.map { sentence in
            guard !sentence.isEmpty else { return sentence }
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return sentence }
            return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        }
        return capitalizedSentences.joined(separator: ". ")
    }
    
    private func capitalizeProperNouns(_ text: String) -> String {
        var result = text
        
        // Common proper nouns and names (expandable list)
        let properNouns = [
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december",
            "america", "american", "europe", "european", "asia", "asian",
            "english", "spanish", "french", "german", "chinese", "japanese",
            "apple", "google", "microsoft", "amazon", "facebook", "twitter",
            "new york", "los angeles", "london", "paris", "tokyo"
        ]
        
        for noun in properNouns {
            let pattern = "\\b\(noun)\\b"
            let capitalized = noun.capitalized
            result = result.replacingOccurrences(
                of: pattern,
                with: capitalized,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return result
    }
    
    // MARK: - ✅ Step 4.3: Performance Optimization Methods
    
    /// Start memory pressure monitoring for battery optimization
    private func startMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)
        memoryPressureSource?.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        memoryPressureSource?.resume()
    }
    
    /// Stop memory pressure monitoring
    @MainActor
    private func stopMemoryPressureMonitoring() {
        memoryPressureSource?.cancel()
        memoryPressureSource = nil
    }
    
    /// Handle memory pressure by reducing recognition quality temporarily
    private func handleMemoryPressure() {
        print("📝 Memory pressure detected, optimizing speech recognition")
        
        // Temporarily increase confidence threshold to reduce processing
        confidenceThreshold = min(confidenceThreshold + 0.1, 0.8)
        
        // Schedule reset after pressure subsides
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.confidenceThreshold = max(self?.confidenceThreshold ?? 0.3 - 0.1, 0.3)
            print("📝 Memory pressure subsided, restored normal recognition quality")
        }
    }
    
    /// Start background task to continue recognition when app goes to background
    @MainActor
    private func startBackgroundTask() {
        #if canImport(UIKit)
        endBackgroundTask() // End any existing task
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "SpeechRecognition") { [weak self] in
            self?.endBackgroundTask()
        }
        #endif
    }
    
    /// End background task
    @MainActor
    private func endBackgroundTask() {
        #if canImport(UIKit)
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
        #endif
    }
    
    /// Log performance metrics for debugging and optimization
    private func logPerformanceMetrics() {
        let metrics = recognitionMetrics
        print("📊 Speech Recognition Performance Metrics:")
        print("   Audio chunks processed: \(metrics.audioChunksProcessed)")
        print("   Average latency: \(String(format: "%.1f", metrics.averageLatency * 1000))ms")
        print("   Total processing time: \(String(format: "%.1f", metrics.totalProcessingTime))s")
        print("   Recognition errors: \(metrics.recognitionErrors)")
        
        let sessionDuration = Date().timeIntervalSince(metrics.startTime)
        print("   Session duration: \(String(format: "%.1f", sessionDuration))s")
        print("   Processing efficiency: \(String(format: "%.1f", (metrics.totalProcessingTime / sessionDuration) * 100))%")
    }
    
    /// Get current performance metrics
    func getPerformanceMetrics() -> RecognitionMetrics {
        return recognitionMetrics
    }
    
    /// ✅ Step 4.3: Intelligent buffering to reduce latency
    private func optimizeBufferSize(for audioData: Data) -> Data {
        // For very small chunks, accumulate before processing
        // For very large chunks, split into optimal sizes
        let optimalChunkSize = 4096 // 4KB chunks work well for real-time processing
        
        if audioData.count < 1024 {
            // Too small, could accumulate but for real-time we'll process anyway
            return audioData
        } else if audioData.count > optimalChunkSize * 2 {
            // Too large, return first optimal chunk
            return audioData.prefix(optimalChunkSize)
        }
        
        return audioData
    }
    
    // MARK: - ✅ Step 5.2: Pronunciation Assessment Methods
    
    /// Configure speech recognition for pronunciation assessment
    private func configurePronunciationRecognition() {
        // Increase confidence threshold for pronunciation accuracy
        confidenceThreshold = 0.5
        
        // Set domain vocabulary to target text words
        let targetWords = targetText.components(separatedBy: .whitespacesAndNewlines)
        setDomainVocabulary(targetWords)
        
        print("📝 Configured pronunciation recognition for: \(targetWords)")
    }
    
    /// Apply pronunciation-specific audio preprocessing
    nonisolated private func preprocessAudioForPronunciation(_ audioData: Data, format: AVAudioFormat) -> Data {
        // Disable audio normalization to prevent crashes - return original data
        // This may reduce pronunciation accuracy but prevents app crashes
        print("📝 Pronunciation preprocessing: returning original data (normalization disabled for stability)")
        return audioData
    }
    
    /// Apply pronunciation-specific audio filtering
    nonisolated private func applyPronunciationFiltering(_ audioData: Data) -> Data {
        // Basic implementation - could be enhanced with more sophisticated filtering
        return audioData
    }
    
    /// ✅ Step 5.2: Assess pronunciation accuracy
    private func assessPronunciation(targetText: String, recognizedText: String, segments: [SFTranscriptionSegment], confidence: Float) -> PronunciationResult {
        
        // Calculate overall similarity
        let overallScore = phoneticAnalyzer.calculateSimilarity(target: targetText, recognized: recognizedText)
        
        // Calculate word-level scores
        let wordScores = calculateWordPronunciationScores(
            targetText: targetText,
            recognizedText: recognizedText,
            segments: segments
        )
        
        // Generate feedback
        let feedback = generatePronunciationFeedback(
            targetText: targetText,
            recognizedText: recognizedText,
            overallScore: overallScore,
            wordScores: wordScores
        )
        
        return PronunciationResult(
            targetText: targetText,
            recognizedText: recognizedText,
            overallScore: overallScore,
            wordScores: wordScores,
            feedback: feedback,
            timestamp: Date()
        )
    }
    
    /// Calculate pronunciation scores for individual words
    private func calculateWordPronunciationScores(targetText: String, recognizedText: String, segments: [SFTranscriptionSegment]) -> [WordPronunciationScore] {
        let targetWords = targetText.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let recognizedWords = recognizedText.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        var wordScores: [WordPronunciationScore] = []
        
        for (index, targetWord) in targetWords.enumerated() {
            let recognizedWord = index < recognizedWords.count ? recognizedWords[index] : ""
            let confidence = index < segments.count ? segments[index].confidence : 0.0
            
            let accuracy = phoneticAnalyzer.calculateWordSimilarity(target: targetWord, recognized: recognizedWord)
            
            let suggestions = generatePronunciationSuggestions(
                targetWord: targetWord,
                recognizedWord: recognizedWord,
                accuracy: accuracy
            )
            
            let wordScore = WordPronunciationScore(
                word: targetWord,
                targetPhonemes: phoneticAnalyzer.getPhonemes(for: targetWord),
                recognizedPhonemes: phoneticAnalyzer.getPhonemes(for: recognizedWord),
                accuracy: accuracy,
                confidence: confidence,
                suggestions: suggestions
            )
            
            wordScores.append(wordScore)
        }
        
        return wordScores
    }
    
    /// Generate pronunciation feedback
    private func generatePronunciationFeedback(targetText: String, recognizedText: String, overallScore: Double, wordScores: [WordPronunciationScore]) -> PronunciationFeedback {
        
        var strengths: [String] = []
        var improvements: [String] = []
        var specificTips: [String] = []
        var practiceWords: [String] = []
        
        // Analyze word scores for feedback
        for wordScore in wordScores {
            if wordScore.accuracy > 0.8 {
                strengths.append("Excellent pronunciation of '\(wordScore.word)'")
            } else if wordScore.accuracy < 0.5 {
                improvements.append("Work on pronunciation of '\(wordScore.word)'")
                practiceWords.append(wordScore.word)
                specificTips.append(contentsOf: wordScore.suggestions)
            }
        }
        
        let overallMessage = generateOverallMessage(score: overallScore)
        
        return PronunciationFeedback(
            overallMessage: overallMessage,
            strengths: strengths,
            improvements: improvements,
            specificTips: specificTips,
            practiceWords: practiceWords
        )
    }
    
    /// Generate overall pronunciation message
    private func generateOverallMessage(score: Double) -> String {
        switch score {
        case 0.9...1.0:
            return "Excellent pronunciation! You sound very natural."
        case 0.8..<0.9:
            return "Great job! Your pronunciation is very clear."
        case 0.7..<0.8:
            return "Good pronunciation with room for improvement."
        case 0.6..<0.7:
            return "Fair pronunciation. Keep practicing to improve clarity."
        case 0.5..<0.6:
            return "Pronunciation needs work. Focus on individual sounds."
        default:
            return "Keep practicing! Pronunciation improves with repetition."
        }
    }
    
    /// Generate pronunciation suggestions for specific words
    private func generatePronunciationSuggestions(targetWord: String, recognizedWord: String, accuracy: Double) -> [String] {
        var suggestions: [String] = []
        
        if accuracy < 0.5 {
            suggestions.append("Try speaking more slowly and clearly")
            suggestions.append("Focus on each syllable: \(phoneticAnalyzer.syllabify(targetWord))")
            
            // Add specific phonetic guidance
            let problematicSounds = phoneticAnalyzer.findProblematicSounds(target: targetWord, recognized: recognizedWord)
            for sound in problematicSounds {
                suggestions.append("Practice the '\(sound)' sound")
            }
        }
        
        return suggestions
    }
    
    /// Log completed pronunciation session
    private func logPronunciationSession(_ session: PronunciationSession) {
        print("📊 Pronunciation Session Complete:")
        print("   Target text: \(session.targetText)")
        print("   Attempts: \(session.attemptCount)")
        print("   Average accuracy: \(String(format: "%.1f", session.averageAccuracy * 100))%")
        print("   Duration: \(String(format: "%.1f", session.duration))s")
        print("   Improvement: \(String(format: "%.1f", session.calculateImprovementTrend() * 100))%")
    }
}

// MARK: - ✅ Step 5.3: PhoneticAnalyzer Class

class PhoneticAnalyzer {
    
    // Simple phoneme mapping for common sounds
    private let phoneticMap: [Character: String] = [
        "a": "æ", "e": "ɛ", "i": "ɪ", "o": "ɔ", "u": "ʌ",
        "b": "b", "c": "k", "d": "d", "f": "f", "g": "g",
        "h": "h", "j": "dʒ", "k": "k", "l": "l", "m": "m",
        "n": "n", "p": "p", "q": "k", "r": "r", "s": "s",
        "t": "t", "v": "v", "w": "w", "x": "ks", "y": "j", "z": "z"
    ]
    
    /// Calculate phonetic similarity between target and recognized text
    func calculateSimilarity(target: String, recognized: String) -> Double {
        let targetPhonemes = getPhonemes(for: target)
        let recognizedPhonemes = getPhonemes(for: recognized)
        
        return calculateLevenshteinSimilarity(targetPhonemes, recognizedPhonemes)
    }
    
    /// Calculate similarity for individual words
    func calculateWordSimilarity(target: String, recognized: String) -> Double {
        let targetPhonemes = getPhonemes(for: target)
        let recognizedPhonemes = getPhonemes(for: recognized)
        
        if targetPhonemes.isEmpty && recognizedPhonemes.isEmpty {
            return 1.0
        }
        
        return calculateLevenshteinSimilarity(targetPhonemes, recognizedPhonemes)
    }
    
    /// Convert text to phonetic representation
    func getPhonemes(for text: String) -> String {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.compactMap { phoneticMap[$0] }.joined()
    }
    
    /// Break word into syllables (simplified)
    func syllabify(_ word: String) -> String {
        // Simple syllable breaking - could be enhanced
        let vowels = Set("aeiou")
        var syllables: [String] = []
        var currentSyllable = ""
        
        for char in word.lowercased() {
            currentSyllable.append(char)
            if vowels.contains(char) && currentSyllable.count > 1 {
                syllables.append(currentSyllable)
                currentSyllable = ""
            }
        }
        
        if !currentSyllable.isEmpty {
            if let lastSyllable = syllables.last {
                syllables[syllables.count - 1] = lastSyllable + currentSyllable
            } else {
                syllables.append(currentSyllable)
            }
        }
        
        return syllables.joined(separator: "-")
    }
    
    /// Find problematic sounds between target and recognized words
    func findProblematicSounds(target: String, recognized: String) -> [String] {
        let targetPhonemes = Array(getPhonemes(for: target))
        let recognizedPhonemes = Array(getPhonemes(for: recognized))
        
        var problematic: [String] = []
        let maxLength = max(targetPhonemes.count, recognizedPhonemes.count)
        
        for i in 0..<maxLength {
            let targetSound = i < targetPhonemes.count ? String(targetPhonemes[i]) : ""
            let recognizedSound = i < recognizedPhonemes.count ? String(recognizedPhonemes[i]) : ""
            
            if targetSound != recognizedSound && !targetSound.isEmpty {
                problematic.append(targetSound)
            }
        }
        
        return Array(Set(problematic)) // Remove duplicates
    }
    
    /// Calculate Levenshtein similarity between two strings
    private func calculateLevenshteinSimilarity(_ str1: String, _ str2: String) -> Double {
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)
        
        if maxLength == 0 {
            return 1.0
        }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let arr1 = Array(str1)
        let arr2 = Array(str2)
        let m = arr1.count
        let n = arr2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dp[i][0] = i
        }
        
        for j in 0...n {
            dp[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                if arr1[i-1] == arr2[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
                }
            }
        }
        
        return dp[m][n]
    }
}

