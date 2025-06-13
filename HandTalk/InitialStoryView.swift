//
//  InitialStoryView.swift
//  HandTalk
//
//  Created by Grachia Uliari on 12/06/25.
//

import SwiftUI
import AVFoundation

struct InitialStoryView: View {
    @State private var isFirstTypingFinished = false
    @State private var isTextMoved = false
    @State private var showPromptText = false
    @State private var showCamera = false
    
    let storyText = "Seorang anak laki-laki sedang duduk sendirian.\nDia tak mengucapkan sepatah kata pun.\nDia melihatmu, tapi dia tak berpaling."
    let promptText = "Say hello to the boy through the camera"
    
    var body: some View {
        VStack {
            Text("Chapter 1: The Swing")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                VStack {
                    Image("sitting_down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                    
                    if isTextMoved {
                        Text(storyText)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
                
                ZStack {
                    if !isTextMoved {
                        TypewriterText(
                            fullText: storyText,
                            typingSpeed: 0.05,
                            onComplete: {
                                isFirstTypingFinished = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation(.easeInOut(duration: 1.0)) {
                                        isTextMoved = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                        showPromptText = true
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            withAnimation(.easeInOut(duration: 1.0)) {
                                                showCamera = true
                                            }
                                        }
                                    }
                                }
                            }
                        )
                        .transition(.opacity)
                    } else {
                        if showPromptText {
                            VStack {
                                TypewriterText(
                                    fullText: promptText,
                                    typingSpeed: 0.05
                                )
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                                .padding(.bottom, 20)
                                
                                if showCamera {
                                    CameraView()
                                        .frame(width: 500, height: 700)
                                        .cornerRadius(16)
                                        .transition(.opacity)
                                        .shadow(radius: 10)
                                }
                            }
                            .frame(width: 450)
                        }
                    }
                }
                
            }
            .padding(.horizontal, 200)
            
            Spacer()
        }
        .animation(.easeInOut, value: isTextMoved)
        .animation(.easeInOut, value: showPromptText)
        .animation(.easeInOut, value: showCamera)
    }
}



#Preview {
    InitialStoryView()
}
