//
//  SimulationCard.swift
//  ConvAI
//
//  Created by Mohamad Ali on 09/08/2025.
//

import SwiftUI
import Foundation

struct SimulationCard: View {
    let scenario: SimulationScenario
    let userLevel: Int
    let onTap: () -> Void
    
    private var isUnlocked: Bool {
        userLevel >= scenario.difficulty.requiredLevel
    }
    
    private var cardBackgroundColor: Color {
        if scenario.isCompleted {
            return scenario.category.color.opacity(0.3)
        } else if isUnlocked {
            return scenario.category.color.opacity(0.15)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                onTap()
            }
        }) {
            VStack(spacing: 12) {
                // Icon and difficulty badge
                HStack {
                    // Scenario icon
                    ZStack {
                        Circle()
                            .fill(isUnlocked ? scenario.category.color.opacity(0.2) : Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: scenario.icon)
                            .font(.title3)
                            .foregroundColor(isUnlocked ? scenario.category.color : .gray)
                    }
                    
                    Spacer()
                    
                    // Difficulty badge
                    Text(scenario.difficulty.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(scenario.difficulty.color.opacity(0.2))
                        .foregroundColor(scenario.difficulty.color)
                        .cornerRadius(8)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 6) {
                    Text(scenario.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(scenario.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Footer with unlock status or completion status
                cardFooterView
            }
            .padding(16)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isUnlocked ? scenario.category.color.opacity(0.3) : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isUnlocked)
    }
    
    private var cardFooterView: some View {
        HStack {
            // XP Reward
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Text("\(scenario.xpReward) XP")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            // Lock/Unlock/Complete status
            if scenario.isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Completed")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(scenario.category.color)
                    
                    Text("Start")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(scenario.category.color)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("Level \(scenario.difficulty.requiredLevel)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
