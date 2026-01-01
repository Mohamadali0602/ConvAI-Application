//
//  AssetManager.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - Asset Management Strategy
class AssetManager: ObservableObject {
    static let shared = AssetManager()
    
    @Published var isLoadingAssets = false
    @Published var loadingProgress: Double = 0.0
    
    private var imageCache: [String: PlatformImage] = [:]
    private var stringCache: [String: [String: String]] = [:]
    private let cacheQueue = DispatchQueue(label: "asset.cache.queue", qos: .utility)
    
    private init() {}
    
    // MARK: - Asset Loading Strategy
    
    /// Load essential assets first (for immediate UI responsiveness)
    func loadEssentialAssets() async {
        await withTaskGroup(of: Void.self) { group in
            // Load critical UI strings
            group.addTask { await self.loadCriticalStrings() }
            
            // Load essential images
            group.addTask { await self.loadEssentialImages() }
            
            // Load user's current language assets
            group.addTask { await self.loadCurrentLanguageAssets() }
        }
    }
    
    /// Load additional assets in background (for smooth experience)
    func loadAdditionalAssets() async {
        await withTaskGroup(of: Void.self) { group in
            // Load remaining language strings
            group.addTask { await self.loadAllLanguageStrings() }
            
            // Load conversation assets
            group.addTask { await self.loadConversationAssets() }
            
            // Load level-specific content
            group.addTask { await self.loadLevelAssets() }
        }
    }
    
    // MARK: - Specific Asset Loading
    
    private func loadCriticalStrings() async {
        let currentLang = UserDefaults.standard.string(forKey: "currentLanguage") ?? "en"
        let criticalKeys = ["loading", "welcome_title", "error", "retry", "continue"]
        
        await MainActor.run {
            isLoadingAssets = true
            loadingProgress = 0.1
        }
        
        // Load only critical strings for immediate UI
        let criticalStrings = loadStringsForKeys(criticalKeys, language: currentLang)
        
        await MainActor.run {
            stringCache[currentLang] = criticalStrings
            loadingProgress = 0.3
        }
    }
    
    private func loadEssentialImages() async {
        let essentialImages = [
            "app_logo",
            "loading_animation",
            "error_icon",
            "success_icon"
        ]
        
        await MainActor.run {
            for imageName in essentialImages {
                #if canImport(UIKit)
                if let image = UIImage(named: imageName) {
                    imageCache[imageName] = image
                }
                #elseif canImport(AppKit)
                if let image = NSImage(named: imageName) {
                    imageCache[imageName] = image
                }
                #endif
            }
            loadingProgress = 0.5
        }
    }
    
    private func loadCurrentLanguageAssets() async {
        let currentLang = UserDefaults.standard.string(forKey: "currentLanguage") ?? "en"
        
        // Load all strings for current language
        let allStrings = loadAllStringsForLanguage(currentLang)
        
        await MainActor.run {
            stringCache[currentLang] = allStrings
            loadingProgress = 0.7
        }
    }
    
    private func loadAllLanguageStrings() async {
        let supportedLanguages = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh", "ar"]
        
        for (index, language) in supportedLanguages.enumerated() {
            if stringCache[language] == nil {
                let strings = loadAllStringsForLanguage(language)
                
                await MainActor.run {
                    stringCache[language] = strings
                    loadingProgress = 0.7 + (0.2 * Double(index) / Double(supportedLanguages.count))
                }
            }
        }
    }
    
    private func loadConversationAssets() async {
        // Load conversation-specific assets
        let conversationImages = [
            "conversation_background",
            "ai_avatar_speaking",
            "ai_avatar_listening",
            "microphone_active",
            "microphone_inactive"
        ]
        
        await MainActor.run {
            for imageName in conversationImages {
                #if canImport(UIKit)
                if let image = UIImage(named: imageName) {
                    imageCache[imageName] = image
                }
                #elseif canImport(AppKit)
                if let image = NSImage(named: imageName) {
                    imageCache[imageName] = image
                }
                #endif
            }
        }
    }
    
    private func loadLevelAssets() async {
        // Load level-specific images and animations
        let levelAssets = [
            "level_1_badge",
            "level_2_badge",
            "level_3_badge",
            "level_4_badge",
            "level_5_badge",
            "completion_animation",
            "progress_ring"
        ]
        
        await MainActor.run {
            for asset in levelAssets {
                #if canImport(UIKit)
                if let image = UIImage(named: asset) {
                    imageCache[asset] = image
                }
                #elseif canImport(AppKit)
                if let image = NSImage(named: asset) {
                    imageCache[asset] = image
                }
                #endif
            }
            loadingProgress = 1.0
            isLoadingAssets = false
        }
    }
    
    // MARK: - Cache Management
    
    func getImage(named name: String) -> PlatformImage? {
        if let cachedImage = imageCache[name] {
            return cachedImage
        }
        
        // If not cached, load from bundle and cache
        #if canImport(UIKit)
        if let image = UIImage(named: name) {
            imageCache[name] = image
            return image
        }
        #elseif canImport(AppKit)
        if let image = NSImage(named: name) {
            imageCache[name] = image
            return image
        }
        #endif
        
        return nil
    }
    
    func getString(key: String, language: String) -> String? {
        return stringCache[language]?[key]
    }
    
    func clearCache() {
        cacheQueue.async {
            self.imageCache.removeAll()
            self.stringCache.removeAll()
        }
    }
    
    func preloadLanguageAssets(for language: String) async {
        guard stringCache[language] == nil else { return }
        
        let strings = loadAllStringsForLanguage(language)
        
        await MainActor.run {
            stringCache[language] = strings
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadStringsForKeys(_ keys: [String], language: String) -> [String: String] {
        var result: [String: String] = [:]
        
        // Load from embedded strings
        let embeddedStrings = getEmbeddedStrings(for: language)
        
        for key in keys {
            if let value = embeddedStrings[key] {
                result[key] = value
            }
        }
        
        return result
    }
    
    private func loadAllStringsForLanguage(_ language: String) -> [String: String] {
        return getEmbeddedStrings(for: language)
    }
    
    private func getEmbeddedStrings(for languageCode: String) -> [String: String] {
        // Return basic embedded strings for AssetManager
        switch languageCode {
        case "es":
            return [
                "loading": "Cargando...",
                "welcome_title": "Bienvenido a ConvAI",
                "continue": "Continuar",
                "error": "Error",
                "retry": "Reintentar"
            ]
        case "fr":
            return [
                "loading": "Chargement...",
                "welcome_title": "Bienvenue à ConvAI",
                "continue": "Continuer",
                "error": "Erreur",
                "retry": "Réessayer"
            ]
        case "de":
            return [
                "loading": "Laden...",
                "welcome_title": "Willkommen bei ConvAI",
                "continue": "Weiter",
                "error": "Fehler",
                "retry": "Erneut versuchen"
            ]
        default: // English
            return [
                "loading": "Loading...",
                "welcome_title": "Welcome to ConvAI",
                "continue": "Continue",
                "error": "Error",
                "retry": "Retry"
            ]
        }
    }
}

// MARK: - Asset Loading States
enum AssetLoadingState {
    case notStarted
    case loadingEssential
    case essentialComplete
    case loadingAdditional
    case complete
    case failed(Error)
}
