//
//  PronunciationHistoryView.swift
//  ConvAI
//
//  Created by Copilot on 15/08/2025.
//

import SwiftUI
import Charts

struct PronunciationHistoryView: View {
    let history: [PronunciationResult]
    @Environment(\.dismiss) private var dismiss
    
    // ConvAI Colors
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    private let secondaryColor = Color(red: 0.97, green: 0.70, blue: 0.35)
    private let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    private let secondaryDark = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showDetailedView = false
    @State private var selectedResult: PronunciationResult?
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    var filteredHistory: [PronunciationResult] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            return history.filter { calendar.dateInterval(of: .weekOfYear, for: now)?.contains($0.timestamp) == true }
        case .month:
            return history.filter { calendar.dateInterval(of: .month, for: now)?.contains($0.timestamp) == true }
        case .all:
            return history
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [darkBackground, secondaryDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Stats
                        headerStatsSection
                        
                        // Time Period Selector
                        timePeriodSelector
                        
                        // Progress Chart
                        if !filteredHistory.isEmpty {
                            progressChartSection
                        }
                        
                        // Practice Sessions List
                        practiceSessionsList
                    }
                    .padding()
                }
            }
            .navigationTitle("Practice History")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
        }
        .sheet(item: $selectedResult) { result in
            PronunciationDetailView(result: result)
        }
    }
    
    // MARK: - Header Stats Section
    private var headerStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                PronunciationStatCard(
                    title: "Total Sessions",
                    value: "\(filteredHistory.count)",
                    icon: "waveform.circle.fill",
                    color: primaryColor
                )
                
                PronunciationStatCard(
                    title: "Average Score",
                    value: averageScore,
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: secondaryColor
                )
                
                PronunciationStatCard(
                    title: "Improvement",
                    value: improvementTrend,
                    icon: trendIcon,
                    color: trendColor
                )
            }
        }
    }
    
    // MARK: - Time Period Selector
    private var timePeriodSelector: some View {
        HStack {
            Text("Period:")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Picker("Time Period", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorMultiply(primaryColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Progress Chart Section
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            if #available(iOS 16.0, *) {
                Chart(filteredHistory.enumerated().map { (index, result) in
                    ChartDataPoint(session: index + 1, score: result.overallScore * 100, date: result.timestamp)
                }, id: \.session) { dataPoint in
                    LineMark(
                        x: .value("Session", dataPoint.session),
                        y: .value("Score", dataPoint.score)
                    )
                    .foregroundStyle(primaryColor)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Session", dataPoint.session),
                        y: .value("Score", dataPoint.score)
                    )
                    .foregroundStyle(primaryColor)
                    .symbolSize(80)
                }
                .frame(height: 200)
                .chartXScale(domain: 1...max(1, filteredHistory.count))
                .chartYScale(domain: 0...100)
                .chartXAxisLabel("Sessions")
                .chartYAxisLabel("Score (%)")
                .chartPlotStyle { plotArea in
                    plotArea.background(Color.white.opacity(0.05))
                }
            } else {
                // Fallback for iOS 15 and below
                SimplLineChart(data: filteredHistory.map { $0.overallScore * 100 })
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Practice Sessions List
    private var practiceSessionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundColor(.white)
            
            if filteredHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No practice sessions yet")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Start practicing to see your progress here!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredHistory.sorted { $0.timestamp > $1.timestamp }.prefix(10), id: \.timestamp) { result in
                        PracticeSessionRow(result: result) {
                            selectedResult = result
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var averageScore: String {
        guard !filteredHistory.isEmpty else { return "0%" }
        let average = filteredHistory.reduce(0) { $0 + $1.overallScore } / Double(filteredHistory.count)
        return "\(Int(average * 100))%"
    }
    
    private var improvementTrend: String {
        guard filteredHistory.count >= 2 else { return "0%" }
        let sorted = filteredHistory.sorted { $0.timestamp < $1.timestamp }
        let first = sorted.first!.overallScore
        let last = sorted.last!.overallScore
        let improvement = (last - first) * 100
        return improvement >= 0 ? "+\(Int(improvement))%" : "\(Int(improvement))%"
    }
    
    private var trendIcon: String {
        guard filteredHistory.count >= 2 else { return "minus.circle.fill" }
        let sorted = filteredHistory.sorted { $0.timestamp < $1.timestamp }
        let first = sorted.first!.overallScore
        let last = sorted.last!.overallScore
        return last > first ? "arrow.up.circle.fill" : 
               last < first ? "arrow.down.circle.fill" : "minus.circle.fill"
    }
    
    private var trendColor: Color {
        guard filteredHistory.count >= 2 else { return .gray }
        let sorted = filteredHistory.sorted { $0.timestamp < $1.timestamp }
        let first = sorted.first!.overallScore
        let last = sorted.last!.overallScore
        return last > first ? .green : 
               last < first ? .red : .gray
    }
}

// MARK: - Supporting Views

struct PronunciationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct PracticeSessionRow: View {
    let result: PronunciationResult
    let action: () -> Void
    
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: result.overallScore)
                        .stroke(scoreColor, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(result.overallScore * 100))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Session Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.targetText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(result.recognizedText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Text(formatDate(result.timestamp))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var scoreColor: Color {
        switch result.overallScore {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return Color(red: 0.97, green: 0.70, blue: 0.35)
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Fallback chart for iOS 15
struct SimplLineChart: View {
    let data: [Double]
    private let primaryColor = Color(red: 0.78, green: 0.36, blue: 0.17)
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 100
            let minValue = data.min() ?? 0
            let range = maxValue - minValue
            
            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * (geometry.size.width / CGFloat(data.count - 1))
                    let y = geometry.size.height - CGFloat((value - minValue) / range) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(primaryColor, lineWidth: 3)
            
            // Data points
            ForEach(data.indices, id: \.self) { index in
                let x = CGFloat(index) * (geometry.size.width / CGFloat(data.count - 1))
                let y = geometry.size.height - CGFloat((data[index] - minValue) / range) * geometry.size.height
                
                Circle()
                    .fill(primaryColor)
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// Chart data point for iOS 16+
struct ChartDataPoint {
    let session: Int
    let score: Double
    let date: Date
}

// MARK: - Preview
struct PronunciationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PronunciationHistoryView(history: [
            // Sample data for preview
            PronunciationResult(
                targetText: "Hello",
                recognizedText: "Hello",
                overallScore: 0.95,
                wordScores: [],
                feedback: PronunciationFeedback(
                    overallMessage: "Excellent!",
                    strengths: [],
                    improvements: [],
                    specificTips: [],
                    practiceWords: []
                ),
                timestamp: Date()
            )
        ])
    }
}
