//
//  LanguageSwitcher.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import SwiftUI

// MARK: - Language Switcher Button
struct LanguageSwitcherButton: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showLanguageSheet = false
    
    var body: some View {
        Button(action: {
            showLanguageSheet = true
        }) {
            HStack(spacing: 8) {
                // Current language flag
                if let currentLang = SupportedUILanguages.getLanguage(localizationManager.currentUILanguage) {
                    Text(currentLang.flag)
                        .font(.title3)
                    
                    Text(currentLang.nativeName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
            )
        }
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSelectionSheet()
        }
    }
}

// MARK: - Language Selection Sheet
struct LanguageSelectionSheet: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("choose_language".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("interface_language".localized)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Language Grid
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(SupportedUILanguages.allLanguages, id: \.code) { language in
                                LanguageCard(
                                    language: language,
                                    isSelected: localizationManager.currentUILanguage == language.code
                                ) {
                                    selectLanguage(language.code)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("done".localized) {
                    dismiss()
                }
                .foregroundColor(.white)
            )
        }
        .environment(\.layoutDirection, localizationManager.layoutDirection)
    }
    
    private func selectLanguage(_ languageCode: String) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            localizationManager.changeUILanguage(to: languageCode)
        }
        
        // Small delay before dismissing to show selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Language Card
struct LanguageCard: View {
    let language: UILanguageInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 32))
                
                // Language name
                VStack(spacing: 4) {
                    Text(language.nativeName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                    
                    Text(language.name)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Compact Language Switcher
struct CompactLanguageSwitcher: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingPicker = false
    
    var body: some View {
        Menu {
            ForEach(SupportedUILanguages.allLanguages, id: \.code) { language in
                Button(action: {
                    localizationManager.changeUILanguage(to: language.code)
                }) {
                    HStack {
                        Text(language.flag)
                        Text(language.nativeName)
                        if localizationManager.currentUILanguage == language.code {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if let currentLang = SupportedUILanguages.getLanguage(localizationManager.currentUILanguage) {
                    Text(currentLang.flag)
                        .font(.title3)
                    
                    Text(currentLang.code.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Preview
struct LanguageSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LanguageSwitcherButton()
            CompactLanguageSwitcher()
        }
        .padding()
        .background(Color.black)
    }
}
