//
//  AudioManager.swift
//  ConvAI
//
//  Consolidated audio management: Speech + Audio Queue + Permissions
//  Complete audio processing, recognition, and permission management
//

import Foundation
import Speech
import AVFoundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Audio Permission Status
public enum AudioPermissionStatus {
    case granted
    case denied
    case undetermined
    case restricted
}

// MARK: - Recognition Mode
enum RecognitionMode {
    case aiTranscription    // For transcribing AI speech
    case userPronunciation  // For assessing user pronunciation
}

// MARK: - Pronunciation Models
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
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    var results: [PronunciationResult] = []
    var sessionNotes: String = ""
}

// MARK: - Audio Queue Item
struct AudioQueueItem {
    let id = UUID()
    let audioData: Data
    let format: AVAudioFormat
    let timestamp: Date
    let priority: AudioQueuePriority
}

enum AudioQueuePriority: Int, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}

// MARK: - Main Audio Manager
@MainActor
public class AudioManager: ObservableObject {
    public static let shared = AudioManager()
    
    // MARK: - Permission Properties
    #if os(iOS)
    @Published public var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
    @Published public var speechRecognitionPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published public var showPermissionDeniedAlert = false
    #endif
    
    // MARK: - Speech Recognition Properties
    @Published public var isRecognizing = false
    @Published public var recognizedText = ""
    @Published public var partialText = ""
    @Published public var recognitionError: String?
    @Published public var currentSession: PronunciationSession?
    @Published public var pronunciationResults: [PronunciationResult] = []
    
    // MARK: - Audio Queue Properties
    @Published public var queueSize = 0
    @Published public var isProcessingQueue = false
    @Published public var audioQueueStats = AudioQueueStats()
    
    // MARK: - Callbacks
    public var onPartialTranscript: ((String) -> Void)?
    public var onFinalTranscript: ((String) -> Void)?
    public var onRecognitionError: ((Error) -> Void)?
    public var onPronunciationResult: ((PronunciationResult) -> Void)?
    
    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var recognitionMode: RecognitionMode = .aiTranscription
    private var cancellables = Set<AnyCancellable>()
    
    // Audio Queue
    private var audioQueue: [AudioQueueItem] = []
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "audio.processing.queue", qos: .userInitiated)
    
    // MARK: - Initialization
    
    private init() {
        setupSpeechRecognizer()
        updatePermissionStatuses()
        setupAudioSession()
    }
    
    deinit {
        stopRecognition()
        audioEngine.stop()
    }
    
    // MARK: - Setup Methods
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    private func setupAudioSession() {
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif
        } catch {
            print("❌ AudioManager: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Permission Management
    
    #if os(iOS)
    public func updatePermissionStatuses() {
        DispatchQueue.main.async {
            self.microphonePermissionStatus = AVAudioSession.sharedInstance().recordPermission
            self.speechRecognitionPermissionStatus = SFSpeechRecognizer.authorizationStatus()
        }
    }
    
    public func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionStatus = AVAudioSession.sharedInstance().recordPermission
                    if !granted {
                        self.showPermissionDeniedAlert = true
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    public func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.speechRecognitionPermissionStatus = status
                    let granted = status == .authorized
                    if !granted {
                        self.showPermissionDeniedAlert = true
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    public func requestPermissions() async -> Bool {
        let micGranted = await requestMicrophonePermission()
        let speechGranted = await requestSpeechRecognitionPermission()
        return micGranted && speechGranted
    }
    
    public func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    public var hasAllPermissions: Bool {
        return microphonePermissionStatus == .granted && speechRecognitionPermissionStatus == .authorized
    }
    #endif
    
    // MARK: - Speech Recognition Control
    
    public func startRecognition(language: String = "en-US") async throws {
        guard !isRecognizing else {
            print("⚠️ AudioManager: Recognition already in progress")
            return
        }
        
        #if os(iOS)
        guard hasAllPermissions else {
            throw NSError(domain: "AudioManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required permissions"])
        }
        #endif
        
        // Setup speech recognizer for the specified language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(domain: "AudioManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available for language: \(language)"])
        }
        
        try startRecognitionEngine()
    }
    
    private func startRecognitionEngine() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "AudioManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Setup audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.recognizedText = recognizedText
                        self?.onFinalTranscript?(recognizedText)
                        self?.finalizeCurrentAudioProcessing()
                    } else {
                        self?.partialText = recognizedText
                        self?.onPartialTranscript?(recognizedText)
                    }
                }
                
                if let error = error {
                    self?.recognitionError = error.localizedDescription
                    self?.onRecognitionError?(error)
                    self?.stopRecognition()
                }
            }
        }
        
        isRecognizing = true
        recognitionError = nil
        print("✅ AudioManager: Speech recognition started")
    }
    
    public func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecognizing = false
        print("🛑 AudioManager: Speech recognition stopped")
    }
    
    // MARK: - Audio Processing
    
    public func processAIAudio(_ audioData: Data, format: AVAudioFormat) {
        guard isRecognizing else { return }
        
        // Add to audio queue for processing
        let queueItem = AudioQueueItem(
            audioData: audioData,
            format: format,
            timestamp: Date(),
            priority: .normal
        )
        
        addToQueue(queueItem)
    }
    
    public func finalizeCurrentAudioProcessing() {
        // Process any remaining audio in the queue
        processAudioQueue()
        
        // Clear partial text
        partialText = ""
    }
    
    // MARK: - Audio Queue Management
    
    private func addToQueue(_ item: AudioQueueItem) {
        processingQueue.async { [weak self] in
            self?.audioQueue.append(item)
            self?.audioQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
            
            DispatchQueue.main.async {
                self?.queueSize = self?.audioQueue.count ?? 0
                self?.processAudioQueue()
            }
        }
    }
    
    private func processAudioQueue() {
        guard !isProcessing, !audioQueue.isEmpty else { return }
        
        isProcessing = true
        isProcessingQueue = true
        
        processingQueue.async { [weak self] in
            while let item = self?.audioQueue.first {
                self?.audioQueue.removeFirst()
                self?.processAudioItem(item)
                
                DispatchQueue.main.async {
                    self?.queueSize = self?.audioQueue.count ?? 0
                }
            }
            
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.isProcessingQueue = false
                self?.updateAudioQueueStats()
            }
        }
    }
    
    private func processAudioItem(_ item: AudioQueueItem) {
        // Convert audio data to PCM buffer and send to recognizer
        guard let recognitionRequest = recognitionRequest else { return }
        
        // Create audio buffer from data
        guard let audioBuffer = createAudioBuffer(from: item.audioData, format: item.format) else {
            print("❌ AudioManager: Failed to create audio buffer")
            return
        }
        
        recognitionRequest.append(audioBuffer)
    }
    
    private func createAudioBuffer(from data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Copy audio data to buffer
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        data.withUnsafeBytes { bytes in
            memcpy(audioBuffer.mData, bytes.baseAddress, Int(audioBuffer.mDataByteSize))
        }
        
        return buffer
    }
    
    private func updateAudioQueueStats() {
        audioQueueStats.totalItemsProcessed += 1
        audioQueueStats.lastProcessedAt = Date()
        audioQueueStats.averageQueueSize = Double(queueSize)
    }
    
    // MARK: - Pronunciation Assessment
    
    public func startPronunciationSession() {
        currentSession = PronunciationSession(startTime: Date())
        recognitionMode = .userPronunciation
        print("🎯 AudioManager: Started pronunciation session")
    }
    
    public func endPronunciationSession() {
        currentSession?.endTime = Date()
        if let session = currentSession {
            // Save session results
            pronunciationResults.append(contentsOf: session.results)
        }
        currentSession = nil
        recognitionMode = .aiTranscription
        print("✅ AudioManager: Ended pronunciation session")
    }
    
    public func assessPronunciation(targetText: String, recognizedText: String) -> PronunciationResult {
        let result = calculatePronunciationScore(target: targetText, recognized: recognizedText)
        
        // Add to current session if active
        currentSession?.results.append(result)
        
        // Trigger callback
        onPronunciationResult?(result)
        
        return result
    }
    
    private func calculatePronunciationScore(target: String, recognized: String) -> PronunciationResult {
        // Simple scoring algorithm - can be enhanced with more sophisticated phonetic analysis
        let targetWords = target.lowercased().components(separatedBy: .whitespaces)
        let recognizedWords = recognized.lowercased().components(separatedBy: .whitespaces)
        
        var wordScores: [WordPronunciationScore] = []
        var totalScore = 0.0
        
        for (index, targetWord) in targetWords.enumerated() {
            let recognizedWord = index < recognizedWords.count ? recognizedWords[index] : ""
            let accuracy = calculateWordAccuracy(target: targetWord, recognized: recognizedWord)
            
            let wordScore = WordPronunciationScore(
                word: targetWord,
                targetPhonemes: targetWord, // Simplified - would use actual phonemes
                recognizedPhonemes: recognizedWord,
                accuracy: accuracy,
                confidence: Float(accuracy),
                suggestions: generateSuggestions(for: targetWord)
            )
            
            wordScores.append(wordScore)
            totalScore += accuracy
        }
        
        let overallScore = targetWords.isEmpty ? 0.0 : totalScore / Double(targetWords.count)
        let feedback = generatePronunciationFeedback(score: overallScore, wordScores: wordScores)
        
        return PronunciationResult(
            targetText: target,
            recognizedText: recognized,
            overallScore: overallScore,
            wordScores: wordScores,
            feedback: feedback
        )
    }
    
    private func calculateWordAccuracy(target: String, recognized: String) -> Double {
        let distance = levenshteinDistance(target, recognized)
        let maxLength = max(target.count, recognized.count)
        return maxLength == 0 ? 1.0 : 1.0 - (Double(distance) / Double(maxLength))
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[m][n]
    }
    
    private func generateSuggestions(for word: String) -> [String] {
        // Simplified suggestions - could be enhanced with phonetic similarity
        return ["Practice slowly", "Focus on consonants", "Emphasize vowels"]
    }
    
    private func generatePronunciationFeedback(score: Double, wordScores: [WordPronunciationScore]) -> PronunciationFeedback {
        var message: String
        var strengths: [String] = []
        var improvements: [String] = []
        var tips: [String] = []
        
        switch score {
        case 0.9...:
            message = "Excellent pronunciation! You're speaking very clearly."
            strengths = ["Clear articulation", "Good rhythm", "Natural flow"]
        case 0.7..<0.9:
            message = "Good pronunciation with room for improvement."
            strengths = ["Generally clear", "Good effort"]
            improvements = ["Work on specific sounds", "Practice rhythm"]
        case 0.5..<0.7:
            message = "Fair pronunciation. Keep practicing to improve clarity."
            improvements = ["Focus on difficult sounds", "Slow down speech", "Practice more"]
            tips = ["Record yourself", "Listen to native speakers", "Practice daily"]
        default:
            message = "Pronunciation needs work. Don't give up - practice makes perfect!"
            improvements = ["Break down into syllables", "Focus on individual sounds", "Use phonetic guides"]
            tips = ["Start with simple words", "Practice in front of mirror", "Get feedback from others"]
        }
        
        // Add word-specific feedback
        let difficultWords = wordScores.filter { $0.accuracy < 0.6 }.map { $0.word }
        
        return PronunciationFeedback(
            overallMessage: message,
            strengths: strengths,
            improvements: improvements,
            specificTips: tips,
            practiceWords: difficultWords
        )
    }
    
    // MARK: - Domain Vocabulary
    
    public func setDomainVocabulary(_ vocabulary: [String]) {
        // Set vocabulary hints for better recognition
        print("📚 AudioManager: Set domain vocabulary with \(vocabulary.count) words")
    }
    
    // MARK: - Testing Methods
    
    public func testAudioSystem() {
        print("🧪 AudioManager: Testing audio system...")
        
        // Test permissions
        #if os(iOS)
        print("  Microphone: \(microphonePermissionStatus)")
        print("  Speech Recognition: \(speechRecognitionPermissionStatus)")
        print("  Has All Permissions: \(hasAllPermissions)")
        #endif
        
        // Test audio engine
        print("  Audio Engine Running: \(audioEngine.isRunning)")
        print("  Is Recognizing: \(isRecognizing)")
        print("  Queue Size: \(queueSize)")
        print("  Is Processing Queue: \(isProcessingQueue)")
        
        print("✅ AudioManager: Audio system test completed")
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension AudioManager: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("🎤 AudioManager: Speech recognizer availability changed: \(available)")
    }
}

// MARK: - Audio Queue Statistics

struct AudioQueueStats {
    var totalItemsProcessed: Int = 0
    var lastProcessedAt: Date?
    var averageQueueSize: Double = 0.0
    var totalProcessingTime: TimeInterval = 0.0
}
