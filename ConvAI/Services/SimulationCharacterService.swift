//
//  SimulationCharacterService.swift
//  ConvAI
//
//  Created by GitHub Copilot on 16/08/2025.
//

import Foundation

// Import AgentColor and GlobalPersonalities from Agents.swift
// These are defined in the main Agents model file

// MARK: - Character Gender
public enum CharacterGender: String, CaseIterable {
    case male = "male"
    case female = "female"
}

// MARK: - Character Voice
struct CharacterVoice {
    let voiceName: String
    let gender: CharacterGender
}

// MARK: - Enhanced Character Profile with Body Color and Personality
public struct CharacterProfile {
    public let name: String
    public let gender: CharacterGender
    public let voice: String
    public let categoryName: String
    public let bodyColor: AgentColor  // Added body color
    public let personality: String    // Added personality
    
    public init(name: String, gender: CharacterGender, voice: String, categoryName: String, bodyColor: AgentColor, personality: String) {
        self.name = name
        self.gender = gender
        self.voice = voice
        self.categoryName = categoryName
        self.bodyColor = bodyColor
        self.personality = personality
    }
}

// MARK: - Simulation Character Service
class SimulationCharacterService: ObservableObject {
    static let shared = SimulationCharacterService()
    
    init() {}  // Made public so it can be instantiated
    
    // MARK: - Available Voices
    private let availableVoices: [CharacterVoice] = [
        // Feminine Voices (13 total) - updated to match authoritative list
        CharacterVoice(voiceName: "Achernar", gender: .female),
        CharacterVoice(voiceName: "Aoede", gender: .female),
        CharacterVoice(voiceName: "Autonoe", gender: .female),
        CharacterVoice(voiceName: "Callirrhoe", gender: .female),
        CharacterVoice(voiceName: "Despina", gender: .female),
        CharacterVoice(voiceName: "Erinome", gender: .female),
        CharacterVoice(voiceName: "Gacrux", gender: .female),
        CharacterVoice(voiceName: "Kore", gender: .female),
        CharacterVoice(voiceName: "Laomedeia", gender: .female),
        CharacterVoice(voiceName: "Leda", gender: .female),
        CharacterVoice(voiceName: "Pulcherrima", gender: .female),
        CharacterVoice(voiceName: "Vindemiatrix", gender: .female),
        CharacterVoice(voiceName: "Zephyr", gender: .female),
        
        // Masculine Voices (16 total)
        CharacterVoice(voiceName: "Achird", gender: .male),
        CharacterVoice(voiceName: "Algenib", gender: .male),
        CharacterVoice(voiceName: "Algieba", gender: .male),
        CharacterVoice(voiceName: "Alnilam", gender: .male),
        CharacterVoice(voiceName: "Charon", gender: .male),
        CharacterVoice(voiceName: "Enceladus", gender: .male),
        CharacterVoice(voiceName: "Fenrir", gender: .male),
        CharacterVoice(voiceName: "Iapetus", gender: .male),
        CharacterVoice(voiceName: "Orus", gender: .male),
        CharacterVoice(voiceName: "Puck", gender: .male),
        CharacterVoice(voiceName: "Rasalgethi", gender: .male),
        CharacterVoice(voiceName: "Sadachbia", gender: .male),
        CharacterVoice(voiceName: "Sadaltager", gender: .male),
        CharacterVoice(voiceName: "Schedar", gender: .male),
        CharacterVoice(voiceName: "Umbriel", gender: .male),
        CharacterVoice(voiceName: "Zubenelgenubi", gender: .male)
    ]
    
    // MARK: - Name Pools (2-3 names per voice)
    
    // Female Names (39 names for 13 female voices = 3 names per voice)
    private let femaleNames: [String] = [
        // Professional/Business Names
        "Sarah Chen", "Emily Rodriguez", "Rachel Kim", "Linda Patterson", "Maria Gonzalez",
        "Jessica Wang", "Amanda Foster", "Nicole Thompson", "Michelle Davis", "Jennifer Lee",
        "Angela Martinez", "Diana Wilson", "Christina Brown", "Stephanie Garcia", "Rebecca Miller",
        "Laura Anderson", "Catherine Moore", "Sandra Taylor", "Karen Jackson", "Lisa White",
        "Nancy Harris", "Betty Clark", "Helen Lewis", "Dorothy Robinson", "Ruth Walker",
        "Sharon Hall", "Deborah Allen", "Donna Young", "Carol King", "Susan Wright",
        
        // International Names for Diversity
        "Aisha Mohammed", "Yuki Tanaka", "Fatima Zahra", "Nia Osei", "Olga Ivanova",
        "Isabella Rossi", "Sofia Mendes", "Amara Diop", "Leila Haddad"
    ]
    
    // Male Names (48 names for 16 male voices = 3 names per voice)
    private let maleNames: [String] = [
        // Professional/Business Names
        "Marcus Weber", "David Harrison", "Michael Thompson", "William Foster", "Robert Patterson",
        "James Wilson", "John Anderson", "Christopher Davis", "Matthew Garcia", "Anthony Miller",
        "Mark Johnson", "Steven Brown", "Paul Jones", "Andrew Moore", "Joshua Taylor", 
        "Kenneth Jackson", "Daniel White", "Brian Harris", "Edward Clark", "Ronald Lewis",
        "Timothy Robinson", "Jason Walker", "Jeffrey Hall", "Ryan Allen", "Jacob Young",
        "Gary King", "Nicholas Wright", "Eric Hill", "Jonathan Scott", "Stephen Green",
        
        // International Names for Diversity
        "Javier Morales", "Li Wei", "Ahmed Khan", "Kofi Mensah", "Nikolai Petrov",
        "Samuel Johnson", "Lucas Moretti", "Tomasz Nowak", "Juan Carlos", "Elias Haddad",
        "Kenji Sato", "Ibrahim Suleiman", "Theo van Dijk", "Mateo Alvarez", "Viktor Petrov",
        "Hassan Ali", "Raj Patel", "Carlos Mendoza"
    ]
    
    // MARK: - Voice to Name Mapping
    private lazy var voiceToNameMapping: [String: [String]] = {
        var mapping: [String: [String]] = [:]
        
        // Map female voices to female names (3 names per voice)
        let femaleVoices = availableVoices.filter { $0.gender == .female }
        for (index, voice) in femaleVoices.enumerated() {
            let startIndex = index * 3
            let endIndex = min(startIndex + 3, femaleNames.count)
            mapping[voice.voiceName] = Array(femaleNames[startIndex..<endIndex])
        }
        
        // Map male voices to male names (3 names per voice)
        let maleVoices = availableVoices.filter { $0.gender == .male }
        for (index, voice) in maleVoices.enumerated() {
            let startIndex = index * 3
            let endIndex = min(startIndex + 3, maleNames.count)
            mapping[voice.voiceName] = Array(maleNames[startIndex..<endIndex])
        }
        
        return mapping
    }()
    
    // MARK: - Character Selection Logic
    
    /// Get random character for simulation based on user gender and category
    public func getRandomCharacter(for categoryName: String, userGender: CharacterGender? = nil) -> CharacterProfile {
        // If user gender is not provided, try to get it from UserDefaults
        let userGenderToUse = userGender ?? getUserGender()
        
        // Determine target gender for character selection
        let targetGender = determineTargetGender(for: categoryName, userGender: userGenderToUse)
        
        // Get voices of the target gender
        let targetVoices = availableVoices.filter { $0.gender == targetGender }
        
        // Select a random voice
        guard let randomVoice = targetVoices.randomElement() else {
            // Fallback to first available voice if no match
            let fallbackVoice = availableVoices.first!
            let fallbackNames = voiceToNameMapping[fallbackVoice.voiceName]!
            return CharacterProfile(
                name: fallbackNames.randomElement()!,
                gender: fallbackVoice.gender,
                voice: fallbackVoice.voiceName,
                categoryName: categoryName,
                bodyColor: Agent.agentColors.randomElement() ?? Agent.agentColors[0],
                personality: GlobalPersonalities.getRandomPersonality()
            )
        }
        
        // Get names for this voice
        let availableNames = voiceToNameMapping[randomVoice.voiceName]!
        let selectedName = availableNames.randomElement()!
        
        // Get random body color for diversity
        let randomBodyColor = Agent.agentColors.randomElement() ?? Agent.agentColors[0]
        
        // Get random personality for realistic interactions
        let randomPersonality = GlobalPersonalities.getRandomPersonality()
        
        return CharacterProfile(
            name: selectedName,
            gender: targetGender,
            voice: randomVoice.voiceName,
            categoryName: categoryName,
            bodyColor: randomBodyColor,
            personality: randomPersonality
        )
    }
    
    // MARK: - User Gender Management (Account-Specific)
    private func getUserGender() -> CharacterGender {
        // Use default male gender for now - in production this would come from UserProfile
        return .male
    }
    
    /// Determine target gender based on category and user gender
    private func determineTargetGender(for categoryName: String, userGender: CharacterGender?) -> CharacterGender {
        let userGenderToUse = userGender ?? .male
        let categoryLower = categoryName.lowercased()
        
        // For love scenarios, use opposite gender
        if categoryLower.contains("love") || categoryLower.contains("romantic") {
            return userGenderToUse == .male ? .female : .male
        }
        
        // For business/professional scenarios, use mixed genders (random)
        return CharacterGender.allCases.randomElement() ?? .female
    }
    
    /// Get character name to inject into system prompt
    public func getCharacterNameForPrompt(_ characterProfile: CharacterProfile) -> String {
        // Extract first name only for natural conversation
        return characterProfile.name.components(separatedBy: " ").first ?? characterProfile.name
    }
    
    /// Get all available voices for a specific gender
    func getAvailableVoices(for gender: CharacterGender) -> [String] {
        return availableVoices.filter { $0.gender == gender }.map { $0.voiceName }
    }
    
    /// Get gender for a specific voice
    func getGender(for voiceName: String) -> CharacterGender? {
        return availableVoices.first { $0.voiceName == voiceName }?.gender
    }
}

// MARK: - User Gender Management
extension SimulationCharacterService {
    
    /// Get stored user gender from UserProfile
    var userGender: String? {
        return "male" // Default fallback - in production this would come from UserProfile
    }
    
    /// Set user gender (would update UserProfile in production)
    func setUserGender(_ gender: String) {
        // In production, this would update UserProfile.shared.gender
        print("✅ User gender set to '\(gender)' (placeholder implementation)")
    }
}
