//
//  ProgressBar.swift
//  HandTalk
//
//  Created by Fachry Anwar on 18/06/25.
//

import SwiftUI

struct ProgressBar: View {
    var currentStep: Int
    var totalSteps: Int = 3

    var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#D38E1E"), lineWidth: 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#D9D9D9"))
                    )
                    .frame(height: 22)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: currentStep < 3 ? "#FFCD7D" : "#77F68C"))
                    .frame(width: geometry.size.width * progress, height: 16)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 10)
        .padding(.bottom)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        if hex.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        } else {
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ProgressBar(currentStep: 2)
}
