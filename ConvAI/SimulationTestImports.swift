//
//  SimulationTestImports.swift
//  ConvAI
//
//  Test file to verify imports
//

import SwiftUI
import Foundation

// Test if these are available
struct SimulationTestImports: View {
    var body: some View {
        VStack {
            Text("Testing imports...")
            
            // Test SimulationScenario
            let scenario = SimulationScenario.coldCall
            Text(scenario.title)
            
            // Test PracticeCategory
            let category = PracticeCategory.money
            Text(category.rawValue)
        }
    }
}
