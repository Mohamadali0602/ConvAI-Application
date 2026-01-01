//
//  PerformanceOptimizer.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

// import SwiftUI
// import Foundation

// // MARK: - Performance Optimization Manager
// class PerformanceOptimizer: ObservableObject {
//     static let shared = PerformanceOptimizer()
    
//     @Published var isOptimizing = false
//     @Published var memoryUsage: Double = 0.0
//     @Published var frameRate: Double = 60.0
    
//     private let memoryThreshold: Double = 100.0 // MB
//     private let frameRateThreshold: Double = 55.0
    
//     private var memoryTimer: Timer?
//     private var performanceTimer: Timer?
    
//     private init() {
//         startMonitoring()
//     }
    
//     // MARK: - Performance Monitoring
    
//     func startMonitoring() {
//         memoryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
//             self.updateMemoryUsage()
//         }
        
//         performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//             self.optimizeIfNeeded()
//         }
//     }
    
//     func stopMonitoring() {
//         memoryTimer?.invalidate()
//         performanceTimer?.invalidate()
//     }
    
//     private func updateMemoryUsage() {
//         let usage = getMemoryUsage()
//         DispatchQueue.main.async {
//             self.memoryUsage = usage
//         }
//     }
    
//     private func optimizeIfNeeded() {
//         if memoryUsage > memoryThreshold || frameRate < frameRateThreshold {
//             performOptimization()
//         }
//     }
    
//     // MARK: - Optimization Strategies
    
//     private func performOptimization() {
//         guard !isOptimizing else { return }
        
//         DispatchQueue.main.async {
//             self.isOptimizing = true
//         }
        
//         Task {
//             // 1. Clear unnecessary caches
//             await clearOldCaches()
            
//             // 2. Compress images in memory
//             await compressImages()
            
//             // 3. Clean up unused language assets
//             await cleanupUnusedLanguageAssets()
            
//             // 4. Optimize animation performance
//             await optimizeAnimations()
            
//             await MainActor.run {
//                 self.isOptimizing = false
//             }
//         }
//     }
    
//     // MARK: - Cache Management
    
//     private func clearOldCaches() async {
//         let assetManager = AssetManager.shared
        
//         // Clear image cache if memory usage is high
//         if memoryUsage > memoryThreshold * 1.5 {
//             assetManager.clearCache()
//         }
//     }
    
//     private func compressImages() async {
//         // Compress images based on device capabilities
//         let deviceCapability = getDeviceCapability()
        
//         switch deviceCapability {
//         case .low:
//             await compressAllImages(quality: 0.5)
//         case .medium:
//             await compressAllImages(quality: 0.7)
//         case .high:
//             await compressAllImages(quality: 0.9)
//         }
//     }
    
//     private func cleanupUnusedLanguageAssets() async {
//         let currentLanguage = LocalizationManager.shared.currentUILanguage
//         let targetLanguage = "en" // Replace with actual target language logic
        
//         // Keep only current UI language and target language assets
//         let languagesToKeep = [currentLanguage, targetLanguage]
        
//         // This would clean up other language assets from memory
//         // Implementation depends on your asset structure
//     }
    
//     private func optimizeAnimations() async {
//         // Reduce animation complexity on lower-end devices
//         let deviceCapability = getDeviceCapability()
        
//         await MainActor.run {
//             switch deviceCapability {
//             case .low:
//                 // Disable complex animations
//                 AnimationSettings.shared.enableComplexAnimations = false
//                 AnimationSettings.shared.animationDuration = 0.2
//             case .medium:
//                 // Medium animations
//                 AnimationSettings.shared.enableComplexAnimations = true
//                 AnimationSettings.shared.animationDuration = 0.3
//             case .high:
//                 // Full animations
//                 AnimationSettings.shared.enableComplexAnimations = true
//                 AnimationSettings.shared.animationDuration = 0.6
//             }
//         }
//     }
    
//     // MARK: - Device Capability Detection
    
//     enum DeviceCapability {
//         case low, medium, high
//     }
    
//     private func getDeviceCapability() -> DeviceCapability {
//         let processInfo = ProcessInfo.processInfo
        
//         // Check available memory
//         let physicalMemory = processInfo.physicalMemory
//         let memoryGB = Double(physicalMemory) / (1024 * 1024 * 1024)
        
//         if memoryGB < 3.0 {
//             return .low
//         } else if memoryGB < 6.0 {
//             return .medium
//         } else {
//             return .high
//         }
//     }
    
//     // MARK: - Memory Utilities
    
//     private func getMemoryUsage() -> Double {
//         var taskInfo = mach_task_basic_info()
//         var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
//         let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
//             $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
//                 task_info(mach_task_self_,
//                          task_flavor_t(MACH_TASK_BASIC_INFO),
//                          $0,
//                          &count)
//             }
//         }
        
//         if kerr == KERN_SUCCESS {
//             return Double(taskInfo.resident_size) / (1024 * 1024) // Convert to MB
//         } else {
//             return 0.0
//         }
//     }
    
//     private func compressAllImages(quality: Double) async {
//         // This would compress cached images
//         // Implementation depends on your image caching strategy
//     }
// }

// // MARK: - Animation Settings
// class AnimationSettings: ObservableObject {
//     static let shared = AnimationSettings()
    
//     @Published var enableComplexAnimations = true
//     @Published var animationDuration: Double = 0.6
//     @Published var enableParticleEffects = true
//     @Published var enableBlurEffects = true
    
//     private init() {}
    
//     func getSpringAnimation() -> Animation {
//         if enableComplexAnimations {
//             return .spring(response: animationDuration, dampingFraction: 0.8)
//         } else {
//             return .easeInOut(duration: animationDuration * 0.5)
//         }
//     }
    
//     func getEaseAnimation() -> Animation {
//         return .easeInOut(duration: animationDuration)
//     }
// }

// // MARK: - Memory-Efficient Image Loading
// struct OptimizedImageView: View {
//     let imageName: String
//     let size: CGSize
//     let compressionQuality: Double
    
//     @StateObject private var assetManager = AssetManager.shared
//     @State private var optimizedImage: PlatformImage?
    
//     init(imageName: String, size: CGSize = CGSize(width: 100, height: 100), compressionQuality: Double = 0.8) {
//         self.imageName = imageName
//         self.size = size
//         self.compressionQuality = compressionQuality
//     }
    
//     var body: some View {
//         Group {
//             if let image = optimizedImage {
//                 #if canImport(UIKit)
//                 Image(uiImage: image)
//                     .resizable()
//                     .aspectRatio(contentMode: .fit)
//                 #elseif canImport(AppKit)
//                 Image(nsImage: image)
//                     .resizable()
//                     .aspectRatio(contentMode: .fit)
//                 #endif
//             } else {
//                 // Placeholder while loading
//                 RoundedRectangle(cornerRadius: 8)
//                     .fill(Color.gray.opacity(0.3))
//                     .overlay(
//                         ProgressView()
//                             .scaleEffect(0.8)
//                     )
//             }
//         }
//         .frame(width: size.width, height: size.height)
//         .onAppear {
//             loadOptimizedImage()
//         }
//     }
    
//     private func loadOptimizedImage() {
//         Task {
//             if let cachedImage = assetManager.getImage(named: imageName) {
//                 let compressed = await compressImage(cachedImage, quality: compressionQuality, targetSize: size)
                
//                 await MainActor.run {
//                     optimizedImage = compressed
//                 }
//             }
//         }
//     }
    
//     private func compressImage(_ image: PlatformImage, quality: Double, targetSize: CGSize) async -> PlatformImage? {
//         #if canImport(UIKit)
//         return await withCheckedContinuation { continuation in
//             DispatchQueue.global(qos: .utility).async {
//                 let renderer = UIGraphicsImageRenderer(size: targetSize)
//                 let compressedImage = renderer.image { _ in
//                     image.draw(in: CGRect(origin: .zero, size: targetSize))
//                 }
                
//                 if let data = compressedImage.jpegData(compressionQuality: quality),
//                    let finalImage = UIImage(data: data) {
//                     continuation.resume(returning: finalImage)
//                 } else {
//                     continuation.resume(returning: image)
//                 }
//             }
//         }
//         #else
//         return image // AppKit implementation would go here
//         #endif
//     }
// }

// // MARK: - Performance-Aware Loading States
// struct PerformantLoadingView: View {
//     @StateObject private var performanceOptimizer = PerformanceOptimizer.shared
//     @StateObject private var animationSettings = AnimationSettings.shared
    
//     let title: String
//     let progress: Double
    
//     var body: some View {
//         VStack(spacing: 20) {
//             // Adaptive loading animation
//             Group {
//                 if animationSettings.enableComplexAnimations {
//                     complexLoadingAnimation
//                 } else {
//                     simpleLoadingAnimation
//                 }
//             }
            
//             Text(title)
//                 .font(.headline)
//                 .foregroundColor(.white)
            
//             // Progress bar
//             ProgressView(value: progress)
//                 .tint(.white)
//                 .background(Color.white.opacity(0.3))
//                 .frame(width: 200)
//         }
//         .animation(animationSettings.getEaseAnimation(), value: progress)
//     }
    
//     private var complexLoadingAnimation: some View {
//         ZStack {
//             ForEach(0..<3) { index in
//                 Circle()
//                     .stroke(Color.white.opacity(0.3), lineWidth: 2)
//                     .frame(width: 60 + CGFloat(index * 20))
//                     .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2 + Double(index)) * 0.1)
//             }
            
//             Image(systemName: "bubble.left.and.bubble.right.fill")
//                 .font(.title)
//                 .foregroundColor(.white)
//         }
//     }
    
//     private var simpleLoadingAnimation: some View {
//         ProgressView()
//             .scaleEffect(1.5)
//             .tint(.white)
//     }
// }

// // MARK: - Memory Warning Handler
// struct MemoryWarningHandler: ViewModifier {
//     @StateObject private var performanceOptimizer = PerformanceOptimizer.shared
    
//     func body(content: Content) -> some View {
//         content
//             .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
//                 handleMemoryWarning()
//             }
//     }
    
//     private func handleMemoryWarning() {
//         // Immediate memory cleanup
//         AssetManager.shared.clearCache()
        
//         // Reduce animation quality
//         AnimationSettings.shared.enableComplexAnimations = false
//         AnimationSettings.shared.enableParticleEffects = false
//     }
// }

// extension View {
//     func handleMemoryWarnings() -> some View {
//         self.modifier(MemoryWarningHandler())
//     }
// }
