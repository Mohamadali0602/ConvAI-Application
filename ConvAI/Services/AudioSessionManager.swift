import AVFoundation

final class AudioSessionManager: ObservableObject {
    private let engine   = AVAudioEngine()
    private let player   = AVAudioPlayerNode()
    var onMicBuffer: ((Data) -> Void)?

    // 1. Use Float32 for engine compatibility, Int16 for data processing
    static let engineFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate   : 24000,
        channels     : 1,
        interleaved  : false
    )!
    
    static let dataFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate   : 16000,
        channels     : 1,
        interleaved  : true
    )!

    init() { setup() }

    func start() throws {
        print("🎤 Starting AudioSessionManager...")
        #if os(iOS)
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                        mode: .default,
                                                        options: [.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)
        print("✅ Audio session configured successfully")
        #endif
        try engine.start()
        print("✅ Audio engine started successfully")
    }

    func stop() { 
        print("🛑 Stopping AudioSessionManager...")
        engine.stop() 
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        print("✅ Audio session stopped")
    }

    // MARK: - Internal setup
    private func setup() {
        print("🔧 Setting up AudioSessionManager...")
        // Mic → 16 kHz Int16 via converter for Gemini
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        print("📱 Input format: \(inputFormat)")
        guard let converter = AVAudioConverter(from: inputFormat, to: Self.dataFormat) else {
            print("❌ Failed to create audio converter")
            return
        }
        print("✅ Audio converter created successfully")
        
        engine.inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputFormat
        ) { [weak self] buffer, _ in
            print("🎙️ Audio tap triggered: \(buffer.frameLength) frames")
            
            let targetFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / inputFormat.sampleRate)
            guard let outBuf = AVAudioPCMBuffer(pcmFormat: Self.dataFormat, frameCapacity: targetFrameCount) else { 
                print("❌ Failed to create output buffer")
                return 
            }
            
            var error: NSError?
            converter.convert(to: outBuf, error: &error) { _, status in
                status.pointee = .haveData
                return buffer
            }
            
            if let error = error {
                print("❌ Conversion error: \(error)")
                return
            }
            
            guard let int16Data = outBuf.int16ChannelData?[0] else { 
                print("❌ Failed to get int16 channel data")
                return 
            }
            
            let data = Data(bytes: int16Data, count: Int(outBuf.frameLength) * 2)
            print("🔄 Converted audio: \(data.count) bytes (from \(buffer.frameLength) frames)")
            
            DispatchQueue.main.async { 
                self?.onMicBuffer?(data) 
            }
        }
        print("✅ Audio input tap installed successfully")

        // Speaker - Use Float32 for engine compatibility
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: Self.engineFormat)
        print("✅ Audio output setup complete")
    }

    func play(data: Data) {
        guard let buffer = data.toPCMBuffer() else { return }
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buffer)
    }
}

extension Data {
    func toPCMBuffer() -> AVAudioPCMBuffer? {
        let frameCapacity = AVAudioFrameCount(count / 2)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: AudioSessionManager.engineFormat,
            frameCapacity: frameCapacity
        ) else { return nil }
        buffer.frameLength = buffer.frameCapacity

        // Convert Int16 data to Float32 for engine
        self.withUnsafeBytes { src in
            let srcPtr = src.bindMemory(to: Int16.self)
            guard let destPtr = buffer.floatChannelData?[0] else { return }
            
            for i in 0..<Int(frameCapacity) {
                destPtr[i] = Float(srcPtr[i]) / 32767.0 // Convert Int16 to Float32
            }
        }
        return buffer
    }
}

/// Audio levels for UI visualization
struct AudioLevels {
    let inputLevel: Double
    let outputLevel: Double
    
    init(inputLevel: Double = 0.0, outputLevel: Double = 0.0) {
        self.inputLevel = max(0.0, min(1.0, inputLevel))
        self.outputLevel = max(0.0, min(1.0, outputLevel))
    }
}