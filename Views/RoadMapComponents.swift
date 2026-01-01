//
//  RoadMapComponents.swift
//  ConvAI
//
//  Created by Mohamad Ali on 29/07/2025.
//

import SwiftUI

// MARK: - Road Map Models
struct RoadNode: Identifiable {
    let id = UUID()
    let type: NodeType
    let position: CGPoint
    let levelId: Int
    let partId: Int?
    let lessonId: Int?
    let isCompleted: Bool
    let isUnlocked: Bool
    let title: String
    let subtitle: String?
    
    enum NodeType {
        case lesson      // Regular station
        case checkpoint  // Part boundary (border toll)
        case levelStart  // Level entrance
    }
}

// MARK: - Level Road Section
struct LevelRoadSection: View {
    let level: ConversationLevel
    let userXP: Int
    let screenWidth: CGFloat
    let onNodeTap: (RoadNode) -> Void
    
    private var isLevelUnlocked: Bool {
        userXP >= level.requiredXP
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Level entrance marker
            LevelEntranceView(level: level, isUnlocked: isLevelUnlocked)
                .onTapGesture {
                    let node = RoadNode(
                        type: .levelStart,
                        position: CGPoint(x: screenWidth/2, y: 0),
                        levelId: level.id,
                        partId: nil,
                        lessonId: nil,
                        isCompleted: false,
                        isUnlocked: isLevelUnlocked,
                        title: level.title,
                        subtitle: level.description
                    )
                    onNodeTap(node)
                }
            
            // Road path through parts and lessons
            ForEach(Array(level.parts.enumerated()), id: \.offset) { partIndex, part in
                PartRoadSection(
                    part: part,
                    partIndex: partIndex,
                    levelId: level.id,
                    screenWidth: screenWidth,
                    isUnlocked: isLevelUnlocked,
                    onNodeTap: onNodeTap
                )
            }
        }
        .opacity(isLevelUnlocked ? 1.0 : 0.4)
    }
}

// MARK: - Part Road Section
struct PartRoadSection: View {
    let part: LevelPart
    let partIndex: Int
    let levelId: Int
    let screenWidth: CGFloat
    let isUnlocked: Bool
    let onNodeTap: (RoadNode) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Checkpoint (Border Toll) at start of each part
            CheckpointView(
                part: part,
                partIndex: partIndex,
                levelId: levelId,
                isUnlocked: isUnlocked
            )
            .onTapGesture {
                let node = RoadNode(
                    type: .checkpoint,
                    position: CGPoint(x: screenWidth/2, y: 0),
                    levelId: levelId,
                    partId: partIndex,
                    lessonId: nil,
                    isCompleted: false,
                    isUnlocked: isUnlocked,
                    title: "Part \(partIndex + 1): \(part.title)",
                    subtitle: part.description
                )
                onNodeTap(node)
            }
            
            // Winding road with lesson stations
            LessonsRoadPath(
                lessons: part.lessons,
                partIndex: partIndex,
                levelId: levelId,
                screenWidth: screenWidth,
                isUnlocked: isUnlocked,
                onNodeTap: onNodeTap
            )
        }
    }
}

// MARK: - Level Entrance View
struct LevelEntranceView: View {
    let level: ConversationLevel
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Level number badge
            ZStack {
                Circle()
                    .fill(level.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(level.color, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Text("\(level.id)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(level.color)
            }
            
            VStack(spacing: 4) {
                Text(level.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Level \(level.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                    Text("\(level.requiredXP) XP needed")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Checkpoint View (Border Toll)
struct CheckpointView: View {
    let part: LevelPart
    let partIndex: Int
    let levelId: Int
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Checkpoint building
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.78, green: 0.36, blue: 0.17))
                    .frame(width: 120, height: 60)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 120, height: 60)
                
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                    
                    Text("PART \(partIndex + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            Text(part.title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 140)
        }
        .padding(.vertical, 10)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

// MARK: - Lessons Road Path
struct LessonsRoadPath: View {
    let lessons: [ConversationLesson]
    let partIndex: Int
    let levelId: Int
    let screenWidth: CGFloat
    let isUnlocked: Bool
    let onNodeTap: (RoadNode) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(Array(lessons.enumerated()), id: \.offset) { lessonIndex, lesson in
                lessonStationWithConnector(lessonIndex: lessonIndex, lesson: lesson)
            }
        }
    }
    
    // Helper function to break down complex expression
    @ViewBuilder
    private func lessonStationWithConnector(lessonIndex: Int, lesson: ConversationLesson) -> some View {
        LessonStationView(
            lesson: lesson,
            lessonIndex: lessonIndex,
            partIndex: partIndex,
            levelId: levelId,
            isUnlocked: isUnlocked,
            alignment: lessonIndex % 2 == 0 ? .leading : .trailing
        )
        .onTapGesture {
            let node = RoadNode(
                type: .lesson,
                position: CGPoint(x: screenWidth/2, y: 0),
                levelId: levelId,
                partId: partIndex,
                lessonId: lessonIndex,
                isCompleted: false,
                isUnlocked: isUnlocked,
                title: lesson.title,
                subtitle: lesson.description
            )
            onNodeTap(node)
        }
        
        // Road connector (except for last lesson)
        if lessonIndex < lessons.count - 1 {
            RoadConnector(isActive: isUnlocked)
        }
    }
}

// MARK: - Lesson Station View
struct LessonStationView: View {
    let lesson: ConversationLesson
    let lessonIndex: Int
    let partIndex: Int
    let levelId: Int
    let isUnlocked: Bool
    let alignment: HorizontalAlignment
    
    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Station circle
                ZStack {
                    Circle()
                        .fill(Color(red: 0.97, green: 0.70, blue: 0.35))
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .stroke(Color(red: 0.78, green: 0.36, blue: 0.17), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    if isUnlocked {
                        Image(systemName: "play.fill")
                            .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.17))
                            .font(.title3)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(lesson.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 100)
                    
                    Text("Lesson \(lessonIndex + 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if alignment == .leading {
                Spacer()
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Road Connector
struct RoadConnector: View {
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(isActive ? Color(red: 0.78, green: 0.36, blue: 0.17) : Color.gray)
            .frame(width: 4, height: 30)
            .cornerRadius(2)
    }
}

// MARK: - Node Detail View
struct NodeDetailView: View {
    let node: RoadNode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Node type icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.97, green: 0.70, blue: 0.35).opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: iconForNodeType(node.type))
                        .font(.largeTitle)
                        .foregroundColor(Color(red: 0.78, green: 0.36, blue: 0.17))
                }
                
                VStack(spacing: 8) {
                    Text(node.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = node.subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if node.isUnlocked {
                    Button("Start Learning") {
                        // TODO: Navigate to lesson/part content
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.78, green: 0.36, blue: 0.17))
                } else {
                    Text("Complete previous levels to unlock")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Learning Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        // Sheet will dismiss automatically
                    }
                }
            }
        }
    }
    
    private func iconForNodeType(_ type: RoadNode.NodeType) -> String {
        switch type {
        case .lesson:
            return "book.fill"
        case .checkpoint:
            return "checkmark.shield.fill"
        case .levelStart:
            return "flag.fill"
        }
    }
}
