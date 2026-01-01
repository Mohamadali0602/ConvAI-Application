//
//  LoadingScreen.swift
//  ConvAI
//
//  Created by Mohamad Ali on 28/07/2025.
//

import SwiftUI

// MARK: - Floating Sparkle Data Structure
struct FloatingSparkle: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let opacity: CGFloat
    let animationDelay: Double
}

struct LoadingScreen: View {
    @State private var fillProgress: CGFloat = 0.0
    @State private var showSparkle = false
    @State private var sparkleOpacity = 0.0
    @State private var sparkleScale = 0.5
    @State private var isAnimationComplete = false
    @State private var waveOffset: CGFloat = 0.0
    
    // New magical animations
    @State private var floatingSparkles: [FloatingSparkle] = []
    @State private var pulseGlow = false
    
    let onCompletion: () -> Void
    
    // Colors from design specification
    let backgroundColor = Color(red: 0.78, green: 0.36, blue: 0.17) // #C75D2C
    let outlineColor = Color(red: 0.95, green: 0.91, blue: 0.86) // #F3E9DC
    let fillColor = Color(red: 0.97, green: 0.70, blue: 0.35) // #F8B259
    
    init(onCompletion: @escaping () -> Void = {}) {
        self.onCompletion = onCompletion
    }
    
    // Custom font with fallbacks
    private func satoshiFont(size: CGFloat) -> Font {
        // Try different Satoshi font names that might be available
        let fontNames = [
            "Satoshi Variable",
            "Satoshi-Variable", 
            "SatoshiVariable",
            "Satoshi-Black",
            "Satoshi Black",
            "Satoshi"
        ]
        
        for fontName in fontNames {
            let customFont = Font.custom(fontName, size: size)
            // We can't easily test font availability in SwiftUI, so we'll return the first one
            // If it doesn't work, iOS will fall back to system font
            return customFont
        }
        
        // Fallback to system font if none of the custom fonts work
        return .system(size: size, weight: .black, design: .rounded)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()
                
                // Floating sparkles throughout the screen
                ForEach(floatingSparkles) { sparkle in
                    FloatingSparkleView(sparkle: sparkle, screenSize: geometry.size)
                }
                
                // Main CONVAI text with liquid fill animation
                VStack {
                    Spacer()
                    
                    ZStack {
                        // Magical glow effect behind text
                        Text("CONVAI")
                            .font(satoshiFont(size: 72))
                            .fontWeight(.black)
                            .foregroundColor(fillColor.opacity(pulseGlow ? 0.3 : 0.1))
                            .blur(radius: 20)
                            .scaleEffect(pulseGlow ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseGlow)
                        
                        // Base text for stroke effect
                        Text("CONVAI")
                            .font(satoshiFont(size: 72))
                            .fontWeight(.black)
                            .foregroundColor(.clear)
                            .background(
                                Text("CONVAI")
                                    .font(satoshiFont(size: 72))
                                    .fontWeight(.black)
                                    .foregroundColor(outlineColor)
                                    .blur(radius: 0.5)
                            )
                            .overlay(
                                Text("CONVAI")
                                    .font(satoshiFont(size: 72))
                                    .fontWeight(.black)
                                    .foregroundColor(outlineColor)
                                    .offset(x: -1, y: -1)
                            )
                            .overlay(
                                Text("CONVAI")
                                    .font(satoshiFont(size: 72))
                                    .fontWeight(.black)
                                    .foregroundColor(outlineColor)
                                    .offset(x: 1, y: -1)
                            )
                            .overlay(
                                Text("CONVAI")
                                    .font(satoshiFont(size: 72))
                                    .fontWeight(.black)
                                    .foregroundColor(outlineColor)
                                    .offset(x: -1, y: 1)
                            )
                            .overlay(
                                Text("CONVAI")
                                    .font(satoshiFont(size: 72))
                                    .fontWeight(.black)
                                    .foregroundColor(outlineColor)
                                    .offset(x: 1, y: 1)
                            )
                        
                        // Hollow center (background color)
                        Text("CONVAI")
                            .font(satoshiFont(size: 72))
                            .fontWeight(.black)
                            .foregroundColor(backgroundColor)
                        
                        // Liquid fill layer - EXACT same text, same font, same everything
                        Text("CONVAI")
                            .font(satoshiFont(size: 72))
                            .fontWeight(.black)
                            .foregroundColor(fillColor)
                            .mask(
                                GeometryReader { textGeometry in
                                    VStack(spacing: 0) {
                                        Spacer()
                                        
                                        // Wave shape at the top of the fill
                                        if fillProgress > 0.02 && fillProgress < 0.98 {
                                            WaveShape(
                                                amplitude: 4,
                                                frequency: 3,
                                                phase: waveOffset
                                            )
                                            .fill(Color.black)
                                            .frame(height: 12)
                                        }
                                        
                                        // Main fill rectangle
                                        Rectangle()
                                            .fill(Color.black)
                                            .frame(height: max(0, textGeometry.size.height * fillProgress - 6))
                                    }
                                }
                            )
                        
                        // Sparkle animation positioned at the end of "I"
                        if showSparkle {
                            HStack {
                                Spacer()
                                VStack {
                                    SparkleView()
                                        .opacity(sparkleOpacity)
                                        .scaleEffect(sparkleScale)
                                    Spacer()
                                }
                                .padding(.trailing, 15)
                                .padding(.top, -25)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
        .onChange(of: isAnimationComplete) { _, complete in
            if complete {
                // Navigate to next screen after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onCompletion()
                    print("🎉 Loading animation complete! Ready to navigate to main app.")
                }
            }
        }
    }
    
    private func startLoadingAnimation() {
        // Start magical background effects immediately
        startBackgroundAnimations()
        
        // Create some immediate sparkles for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            createFloatingSparkle()
        }
        
        // Start wave animation immediately for continuous liquid effect
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            waveOffset = .pi * 4
        }
        
        // Start background glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseGlow = true
        }
        
        // Start fill animation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 2.0)) {
                fillProgress = 1.0
            }
            
            // Trigger sparkle animation after fill completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showSparkle = true
                withAnimation(.easeOut(duration: 0.2)) {
                    sparkleOpacity = 1.0
                    sparkleScale = 1.2
                }
                
                // Scale back and fade out sparkle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        sparkleScale = 1.0
                        sparkleOpacity = 0.0
                    }
                    
                    // Wait much longer before completing - total 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isAnimationComplete = true
                    }
                }
            }
        }
    }
    
    private func startBackgroundAnimations() {
        // Create floating sparkles more frequently
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            createFloatingSparkle()
        }
        
        print("🌟 Started background animations - sparkles every 0.5s")
    }
    
    private func createFloatingSparkle() {
        let screenWidth: CGFloat = 400 // Approximate iPhone width
        let screenHeight: CGFloat = 800 // Approximate iPhone height
        
        let sparkle = FloatingSparkle(
            id: UUID(),
            x: CGFloat.random(in: 50...screenWidth - 50),
            y: CGFloat.random(in: 100...screenHeight - 200),
            scale: CGFloat.random(in: 0.5...1.2),
            opacity: CGFloat.random(in: 0.6...1.0),
            animationDelay: Double.random(in: 0...1)
        )
        floatingSparkles.append(sparkle)
        
        // Remove sparkle after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            floatingSparkles.removeAll { $0.id == sparkle.id }
        }
    }
}

// MARK: - Floating Sparkle View

struct FloatingSparkleView: View {
    let sparkle: FloatingSparkle
    let screenSize: CGSize
    @State private var isAnimating = false
    @State private var rotation = 0.0
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color(red: 0.97, green: 0.70, blue: 0.35))
            .scaleEffect(sparkle.scale * (isAnimating ? 1.3 : 0.8))
            .opacity(sparkle.opacity * (isAnimating ? 1.0 : 0.5))
            .rotationEffect(.degrees(rotation))
            .position(x: sparkle.x, y: sparkle.y)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + sparkle.animationDelay) {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                    
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

// MARK: - Wave Shape for Liquid Effect
struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * frequency * .pi * 2 + phase)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the path to create a filled shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sparkle Animation View
struct SparkleView: View {
    @State private var rotation = 0.0
    @State private var pulseScale = 1.0
    
    var body: some View {
        ZStack {
            // Main bright sparkle
            ZStack {
                // Outer glow
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.97, green: 0.70, blue: 0.35).opacity(0.6))
                    .blur(radius: 4)
                    .scaleEffect(1.5)
                
                // Main sparkle
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.97, green: 0.70, blue: 0.35))
            }
            .scaleEffect(pulseScale)
            .rotationEffect(.degrees(rotation))
            
            // Additional small sparkles around the main one
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.97, green: 0.70, blue: 0.35))
                    .frame(width: 2, height: 2)
                    .offset(
                        x: cos(Double(index) * .pi / 4) * 25,
                        y: sin(Double(index) * .pi / 4) * 25
                    )
                    .scaleEffect(pulseScale * 0.8)
                    .opacity(0.8)
            }
            
            // Additional tiny sparkles for extra magic
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 1, height: 1)
                    .offset(
                        x: cos(Double(index) * .pi / 2 + .pi / 4) * 15,
                        y: sin(Double(index) * .pi / 2 + .pi / 4) * 15
                    )
                    .scaleEffect(pulseScale)
                    .opacity(0.9)
            }
        }
        .onAppear {
            // Quick scale up with rotation
            withAnimation(.easeOut(duration: 0.15)) {
                pulseScale = 1.3
                rotation = 90
            }
            
            // Scale back down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    pulseScale = 1.0
                    rotation = 180
                }
            }
        }
    }
}

// MARK: - Preview
struct LoadingScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreen {
            print("Loading completed!")
        }
    }
}
