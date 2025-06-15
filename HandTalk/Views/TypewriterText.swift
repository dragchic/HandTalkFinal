//
//  TypewriterText.swift
//  HandTalk
//
//  Created by Grachia Uliari on 13/06/25.
//

import SwiftUI

struct TypewriterText: View {
    let fullText: String
    let typingSpeed: Double  // detik per karakter
    var onComplete: (() -> Void)? = nil
    
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }
    
    func startTyping() {
        displayedText = ""
        currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedText.append(fullText[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                onComplete?()
            }
        }
    }
}
