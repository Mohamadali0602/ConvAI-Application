//
//  SimulationDetailView.swift
//  ConvAI
//
//  Created by GitHub Copilot on 14/08/2025.
//

import SwiftUI

struct SimulationDetailView: View {
    let scenario: SimulationScenario
    let character: CharacterProfile? // Add this parameter
    let onStart: (SimulationScenario) -> Void
    let onBack: () -> Void
    @StateObject private var characterService = SimulationCharacterService()
    @State private var currentCharacter: CharacterProfile?
    
    // ConvAI Colors - matching other views
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                scenarioHeaderView
                
                // Scenario Description
                scenarioDescriptionView
                
                // Learning Objectives
                learningObjectivesView
                
                // Tips for Success
                tipsForSuccessView
                
                // Start Button
                startButtonView
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .navigationTitle("Scenario Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [darkBackground, secondaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("← Back") {
                    onBack()
                }
                .foregroundColor(.white)
            }
        }
        .onAppear {
            // Use the character passed from SimulateView instead of generating a new one
            currentCharacter = character
            print("🎭 DETAIL VIEW: Using character \(character?.name ?? "NONE") from SimulateView")
        }
    }
    
    private var scenarioHeaderView: some View {
        VStack(spacing: 16) {
            // Icon and category
            HStack {
                Image(systemName: scenario.icon)
                    .font(.largeTitle)
                    .foregroundColor(scenario.category.color)
                    .frame(width: 60, height: 60)
                    .background(scenario.category.color.opacity(0.1))
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let character = currentCharacter {
                        Text("You'll be speaking with \(character.name)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .italic()
                    }
                    
                    Text(scenario.category.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(scenario.category.color)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Difficulty badge inline
                Text(scenario.difficulty.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scenario.difficulty.color)
                    .cornerRadius(8)
            }
            
            // XP and duration info
            HStack(spacing: 20) {
                InfoPill(icon: "star.fill", text: "\(scenario.xpReward) XP", color: .orange)
                InfoPill(icon: "clock.fill", text: "5-10 min", color: .blue)
                InfoPill(icon: "person.2.fill", text: "1-on-1", color: .green)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
    
    private var scenarioDescriptionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenario Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(scenario.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var learningObjectivesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What You'll Practice")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(learningObjectives, id: \.self) { objective in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .offset(y: 2)
                        
                        Text(objective)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var tipsForSuccessView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips for Success")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(successTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .offset(y: 2)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var startButtonView: some View {
        VStack(spacing: 16) {
            Button(action: {
                print("🚀 START BUTTON: Tapped for scenario \(scenario.title)")
                print("🎭 CHARACTER: \(currentCharacter?.name ?? "NO CHARACTER")")
                
                // Direct call since we're no longer using sheets
                onStart(scenario)
                print("✅ START BUTTON: onStart callback executed")
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.headline)
                    
                    Text("Start Simulation")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(scenario.category.color)
                .cornerRadius(12)
            }
            
            Text("Practice makes perfect. The AI will provide realistic responses based on the scenario.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Properties
    
    private var learningObjectives: [String] {
        switch scenario {
        case .coldCall:
            return [
                "Opening conversations with strangers professionally",
                "Handling initial resistance and skepticism",
                "Building rapport quickly and effectively",
                "Presenting value propositions clearly"
            ]
        case .priceObjection:
            return [
                "Reframing price as investment",
                "Demonstrating ROI and value",
                "Handling budget concerns gracefully",
                "Closing techniques after objections"
            ]
        case .jobNegotiation:
            return [
                "Presenting your value confidently",
                "Negotiating compensation packages",
                "Finding win-win solutions",
                "Professional negotiation tactics"
            ]
        case .clientPitch:
            return [
                "Structuring compelling presentations",
                "Handling difficult questions confidently",
                "Reading client needs and concerns",
                "Closing with clear next steps"
            ]
        case .networkingEvent:
            return [
                "Starting conversations with strangers",
                "Making memorable first impressions",
                "Following up professionally",
                "Building mutually beneficial connections"
            ]
        case .investorMeeting:
            return [
                "Presenting business case clearly",
                "Handling skeptical questions",
                "Demonstrating market opportunity",
                "Negotiating terms effectively"
            ]
        case .contractNegotiation:
            return [
                "Understanding all contract terms",
                "Finding win-win solutions",
                "Maintaining professional relationships",
                "Securing favorable agreements"
            ]
        case .businessPartnership:
            return [
                "Evaluating partnership benefits",
                "Discussing shared responsibilities",
                "Aligning on common goals",
                "Establishing trust and commitment"
            ]
        case .firstApproach:
            return [
                "Starting natural conversations",
                "Reading social cues and body language",
                "Building comfort and rapport",
                "Transitioning to deeper connection"
            ]
        case .firstDate:
            return [
                "Keeping conversations flowing smoothly",
                "Showing genuine interest and curiosity",
                "Balancing talking and listening",
                "Creating emotional connection"
            ]
        case .relationshipConflict:
            return [
                "Active listening during disagreements",
                "Expressing needs without attacking",
                "Finding compromise solutions",
                "Strengthening relationships through conflict"
            ]
        case .breakupConversation:
            return [
                "Communicating with compassion and respect",
                "Managing emotional intensity",
                "Providing closure and understanding",
                "Maintaining dignity for both parties"
            ]
        case .meetingParents:
            return [
                "Making positive first impressions",
                "Showing respect and genuine interest",
                "Handling challenging questions gracefully",
                "Building trust and rapport"
            ]
        case .longDistanceRelationship:
            return [
                "Discussing future plans openly",
                "Managing expectations realistically",
                "Maintaining emotional connection",
                "Finding practical solutions together"
            ]
        case .marriageProposal:
            return [
                "Expressing feelings authentically",
                "Choosing the right moment and setting",
                "Handling various possible responses",
                "Creating meaningful romantic moments"
            ]
        case .couples_therapy:
            return [
                "Communicating openly and honestly",
                "Listening without becoming defensive",
                "Working together toward solutions",
                "Building stronger relationship foundations"
            ]
        case .jobInterview:
            return [
                "Answering behavioral questions with STAR method",
                "Demonstrating competence and confidence",
                "Asking thoughtful questions about the role",
                "Making strong final impressions"
            ]
        case .teamLeadership:
            return [
                "Establishing authority while building trust",
                "Addressing team concerns effectively",
                "Facilitating productive discussions",
                "Making decisive leadership choices"
            ]
        case .difficultConversation:
            return [
                "Delivering feedback constructively",
                "Managing emotional responses",
                "Creating safe spaces for dialogue",
                "Focusing on solutions, not blame"
            ]
        case .performanceReview:
            return [
                "Providing specific, actionable feedback",
                "Balancing positive reinforcement with areas for improvement",
                "Setting clear goals and expectations",
                "Motivating continued growth and development"
            ]
        case .conflictResolution:
            return [
                "Remaining neutral and objective",
                "Understanding all perspectives involved",
                "Facilitating productive dialogue",
                "Finding mutually acceptable solutions"
            ]
        case .publicSpeaking:
            return [
                "Structuring engaging presentations",
                "Managing speaking anxiety effectively",
                "Connecting with diverse audiences",
                "Handling questions and interruptions"
            ]
        case .boardPresentation:
            return [
                "Presenting complex data clearly",
                "Anticipating and addressing concerns",
                "Demonstrating strategic thinking",
                "Maintaining composure under pressure"
            ]
        case .mentorshipMeeting:
            return [
                "Providing guidance without micromanaging",
                "Sharing experience and insights effectively",
                "Encouraging independent problem-solving",
                "Building confidence and skills in others"
            ]
        }
    }
    
    private var successTips: [String] {
        switch scenario.category {
        case .money:
            return [
                "Focus on benefits, not features",
                "Ask questions to understand their needs",
                "Use specific examples and case studies",
                "Handle objections with empathy, not pushback"
            ]
        case .love:
            return [
                "Be genuinely curious about them",
                "Share stories, not just facts",
                "Mirror their energy and communication style",
                "Focus on connection, not impression"
            ]
        case .power:
            return [
                "Speak with confidence and clarity",
                "Use specific examples from your experience",
                "Ask strategic questions to show insight",
                "Balance assertiveness with collaboration"
            ]
        default:
            return [
                "Stay calm and composed",
                "Listen more than you speak",
                "Be authentic and genuine",
                "Focus on mutual benefit"
            ]
        }
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
