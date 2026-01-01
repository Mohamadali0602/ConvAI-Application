//
//  ConvAITextFieldStyle.swift
//  ConvAI
//
//  Created by Mohamad Ali on 01/08/2025.
//

import SwiftUI

struct ConvAITextFieldStyle: TextFieldStyle {
    var isError: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isError ? Color.red : Color.white.opacity(0.3),
                                lineWidth: isError ? 2 : 1
                            )
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
    }
}

// Extension for easy use
extension View {
    func convAITextFieldStyle(isError: Bool = false) -> some View {
        self.textFieldStyle(ConvAITextFieldStyle(isError: isError))
    }
}
