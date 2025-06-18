//
//  StorySceneView.swift
//  HandTalk
//
//  Created by Francesco on 17/06/25.
//

import SwiftUI
import AVFoundation

struct StorySceneView: View {
    let chapter: StoryModel
    let onCompleted: () -> Void

    @StateObject private var visionHandler: VisionHandler
    @StateObject private var cameraViewModel: CameraViewModel

    @State private var isFirstTypingFinished = false
    @State private var isTextMoved = false
    @State private var showPromptText = false
    @State private var showCamera = false
    @State private var currentImageName: String
    
    @State private var showStoryText = true

    init(chapter: StoryModel, onCompleted: @escaping () -> Void) {
        let vision = VisionHandler()
        _visionHandler = StateObject(wrappedValue: vision)
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(visionHandler: vision))
        self.chapter = chapter
        self.onCompleted = onCompleted
        _currentImageName = State(initialValue: chapter.imageName)
    }

    var body: some View {
        ZStack {
            Image(chapter.bgImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Text(chapter.title)
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    VStack {
                        Image(currentImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400)

                        if isTextMoved && showStoryText{
                            
                            Text(chapter.storyText)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                    }

                    Spacer()

                    ZStack {
                        if !isTextMoved {
                            
                            TypewriterText(
                                fullText: chapter.storyText,
                                typingSpeed: 0.05,
                                onComplete: handleTypingComplete
                            )
                            .transition(.opacity)
                            
                        } else {
                            
                            if showPromptText {
                                VStack {
                                    TypewriterText(
                                        fullText: chapter.promptText,
                                        typingSpeed: 0.05
                                    )
                                    .multilineTextAlignment(.center)
                                    .transition(.opacity)
                                    .padding(.bottom, 20)

                                    if showCamera {
                                        cameraView
                                            .frame(width: 550, height: 750)
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

                if showCamera {
                    Button(action: {
                        
                
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                showStoryText = false
                                currentImageName = chapter.validationImageName
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                onCompleted()
                                resetState()
                            }
                        }
                    }) {
                        Text("Continue")
                            .padding()
                            .frame(width: 180)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 40)
                    .transition(.opacity)
                }
            }
            .padding()
            .animation(.easeInOut, value: isTextMoved)
            .animation(.easeInOut, value: showPromptText)
            .animation(.easeInOut, value: showCamera)
        }
    }

    private var cameraView: some View {
        ZStack {
            CameraView(viewModel: cameraViewModel)

            VStack {
                Spacer()

                if let text = visionHandler.prediction, !text.isEmpty {
                    Text(text)
                        .font(.title2)
                        .bold()
                        .padding()
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.black)
                                .opacity(0.6)
                        )
                        .padding(.bottom, 10)
                }

                Text(visionHandler.cameraFeedbackMassage)
                    .padding()
                    .foregroundStyle(.black)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white)
                            .opacity(0.7)
                    )
                    .padding(.bottom, 20)
            }
        }
    }

    private func handleTypingComplete() {
        isFirstTypingFinished = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                isTextMoved = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showPromptText = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        showCamera = true
                    }
                }
            }
        }
    }
    private func resetState() {
        isFirstTypingFinished = false
        isTextMoved = false
        showPromptText = false
        showCamera = false
    }

}
