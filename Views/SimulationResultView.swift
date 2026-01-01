//
//  SimulationResultView.swift
//  ConvAI
//
//  Created by GitHub Copilot on 14/08/2025.
//

import SwiftUI

struct SimulationResultView: View {
    let score: SimulationScore
    let scenario: SimulationScenario
    let onRetry: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Grade display
            VStack(spacing: 16) {
                Text(score.grade.emoji)
                    .font(.system(size: 60))
                
                Text(score.grade.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(score.grade.color)
                
                Text("\(Int(score.overallScore))% Overall Performance")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Detailed metrics
            ScoreBreakdownView(score: score)
            
            // Improvement suggestions
            ImprovementSuggestionsView(score: score, scenario: scenario)
            
            // Action buttons
            HStack(spacing: 16) {
                if score.grade == .retry || score.grade == .needsImprovement {
                    Button("Try Again", action: onRetry)
                        .buttonStyle(SimulationSecondaryButtonStyle())
                }
                
                Button("Continue Learning", action: onContinue)
                    .buttonStyle(SimulationPrimaryButtonStyle())
            }
        }
        .padding(24)
    }
}

struct ScoreBreakdownView: View {
    let score: SimulationScore
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MetricRow(title: "Confidence", value: score.confidence, maxValue: 100)
                MetricRow(title: "Emotional Connection", value: score.emotionalConnection, maxValue: 100)
                MetricRow(title: "Conversation Flow", value: score.conversationFlow, maxValue: 100)
                MetricRow(title: "Technique Usage", value: Double(score.techniqueUsage), maxValue: 5, isCount: true)
                MetricRow(title: "Objection Handling", value: Double(score.objectionHandling), maxValue: 3, isCount: true)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    let title: String
    let value: Double
    let maxValue: Double
    let isCount: Bool
    
    init(title: String, value: Double, maxValue: Double, isCount: Bool = false) {
        self.title = title
        self.value = value
        self.maxValue = maxValue
        self.isCount = isCount
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if isCount {
                Text("\(Int(value))/\(Int(maxValue))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(value >= maxValue * 0.7 ? .green : .orange)
            } else {
                HStack(spacing: 8) {
                    SwiftUI.ProgressView(value: value / maxValue)
                        .progressViewStyle(LinearProgressViewStyle(tint: value >= 70 ? .green : .orange))
                        .frame(width: 100)
                    
                    Text("\(Int(value))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(value >= 70 ? .green : .orange)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
    }
}

struct ImprovementSuggestionsView: View {
    let score: SimulationScore
    let scenario: SimulationScenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ways to Improve")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(improvementSuggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .offset(y: 2)
                        
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var improvementSuggestions: [String] {
        var suggestions: [String] = []
        
        if score.confidence < 70 {
            suggestions.append("Practice assertive body language and speak with more conviction")
        }
        
        if score.emotionalConnection < 70 {
            suggestions.append("Focus on active listening and showing genuine interest in the other person")
        }
        
        if score.conversationFlow < 70 {
            suggestions.append("Ask more open-ended questions to keep the conversation flowing naturally")
        }
        
        if score.techniqueUsage < 3 {
            suggestions.append("Review the techniques taught in lessons and practice applying them")
        }
        
        if score.objectionHandling < 2 {
            suggestions.append("Study common objection handling frameworks and practice responses")
        }
        
        // Scenario-specific suggestions
        switch scenario.category {
        case .money:
            if score.overallScore < 80 {
                suggestions.append("Focus on demonstrating clear value propositions and ROI")
            }
        case .love:
            if score.overallScore < 80 {
                suggestions.append("Practice being more authentic and vulnerable in conversations")
            }
        case .power:
            if score.overallScore < 80 {
                suggestions.append("Work on executive presence and clear communication")
            }
        default:
            break
        }
        
        return suggestions.isEmpty ? ["Great job! Keep practicing to maintain your skills."] : suggestions
    }
}

// MARK: - Button Styles

struct SimulationPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SimulationSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
