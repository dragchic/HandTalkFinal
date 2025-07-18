import SwiftUI
import AVFoundation

struct StorySceneView: View {
    let chapter: StoryModel
    let onCompleted: () -> Void
    
    @StateObject private var visionHandler: VisionHandler
    @StateObject private var cameraViewModel: CameraViewModel
    @StateObject private var imageSequenceViewModel: ImageSequenceViewModel
    
    @State private var isFirstTypingFinished = false
    @State private var isTextMoved = false
    @State private var showPromptText = false
    @State private var showCamera = false
    @State private var imageSequence: (String,Int)
    @State private var isComplete = false
    @State private var showGhostHand = false
    
    @State private var showStoryText = true
    
    init(chapter: StoryModel, onCompleted: @escaping () -> Void) {
        let vision = VisionHandler()
        _visionHandler = StateObject(wrappedValue: vision)
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(visionHandler: vision))
        _imageSequenceViewModel = StateObject(wrappedValue: ImageSequenceViewModel(frameCount: chapter.imageSequence.1))
        
        self.chapter = chapter
        self.onCompleted = onCompleted
        _imageSequence = State(initialValue: (chapter.imageSequence.0,chapter.imageSequence.1))
    }
    
    var body: some View {
        ZStack {
            Image(chapter.chapter == 6 && isComplete ? "bg_chapter6_2" : chapter.bgImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            if [1,2,3,5].contains(chapter.chapter) {
                AnimatedGIFView(gifName: "Leaves")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            HStack {
                VStack(alignment : .center) {
                    
                    if (isComplete || chapter.imagePosition == .bottom) {
                        Spacer()
                    }
                    
                    ImageSequenceView(
                        imagePrefix: imageSequence.0,
                        frameCount: imageSequence.1,
                        viewModel: imageSequenceViewModel
                    )
                    
                    if !isComplete && isTextMoved && showStoryText && chapter.textPosition == .bottom {
                        Text(chapter.storyText)
                            .ShantellSans(weight: .regular, size: 25)
                            .transition(.opacity)
                            .padding()
                            .background(.white.opacity(0.4))
                            .cornerRadius(10)
                            .padding(.horizontal, 28)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, (isComplete || chapter.imagePosition == .bottom) ? 0 : 28)
                
                VStack {
                }
                .frame(maxWidth: .infinity)
            }
            
            if (isComplete || chapter.textPosition != .bottom) {
                HStack {
                    VStack() {
                        Spacer()
                        if !isComplete && isTextMoved && showStoryText {
                            Text(chapter.storyText)
                                .ShantellSans(weight: .regular, size: 25)
                                .transition(.opacity)
                                .padding()
                                .background(.white.opacity(0.5))
                                .cornerRadius(10)
                                .padding(.horizontal, 28)
                        } else if (isComplete) {
                            TypewriterText(
                                fullText: chapter.validationMessage,
                                typingSpeed: 0.05, fontSize: 25, weight: .regular,
                                onComplete: handleCompleteValidation
                            )
                            .padding()
                            .background(.white.opacity(0.4))
                            .cornerRadius(10)
                            .padding(.horizontal, 28)
                        }
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, isComplete ? 0 : 28)
                    
                    VStack {
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            HStack {
                
            }
            
            VStack {
                Text(chapter.title)
                    .ShantellSans(weight: .bold, size: 40)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    VStack(alignment : .center){
                        
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        if !isTextMoved {
                            TypewriterText(
                                fullText: chapter.storyText,
                                typingSpeed: 0.05, fontSize: 25, weight: .regular,
                                onComplete: handleTypingComplete
                            )
                            .transition(.opacity)
                            
                        } else {
                            if showPromptText {
                                VStack {
                                    TypewriterText(
                                        fullText: chapter.promptText,
                                        typingSpeed: 0.05, fontSize: 25, weight: .bold
                                    )
                                    .multilineTextAlignment(.center)
                                    .transition(.opacity)
                                    .padding(.bottom, 8)
                                    
                                    if showCamera {
                                        ProgressBar(currentStep: visionHandler.correctCount)
                                            .frame(width: 540)
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
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            .animation(.easeInOut, value: isTextMoved)
            .animation(.easeInOut, value: showPromptText)
            .animation(.easeInOut, value: showCamera)
            .onChange(of: visionHandler.prediction) {
                if let prediction = visionHandler.prediction {
                    if prediction == chapter.expectedAnswer {
                        visionHandler.correctGesture()
                    }
                }
            }
            .onChange(of: visionHandler.correctCount) {
                if visionHandler.correctCount >= 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showGhostHand = false
                            showStoryText = false
                            isComplete = true
                            imageSequence = (chapter.validationImageName, chapter.chapter == 1 ? 2 : 1)
                            imageSequenceViewModel.updateFrameCount(to: 1)
                        }
                    }
                }
            }
        }
    }
    
    private var cameraView: some View {
        ZStack {
            CameraView(viewModel: cameraViewModel)
            
            VStack {
                
                if !visionHandler.cameraFeedbackMassage.isEmpty && showGhostHand {
                    Text(visionHandler.cameraFeedbackMassage)
                        .ShantellSans(weight: .regular, size: 20)
                        .padding()
                        .foregroundStyle(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .opacity(0.7)
                        )
                        .padding(.top, 20)
                }
               
                Spacer()
                
                HStack {
                    Spacer()
                    if showGhostHand {
                        AnimatedGIFView(gifName: chapter.expectedAnswer)
                            .frame(width: 225, height: 225)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
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
                        showGhostHand = true
                    }
                }
            }
        }
    }
    
    private func handleCompleteValidation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onCompleted()
            resetState()
        }
    }
    
    private func resetState() {
        isFirstTypingFinished = false
        isTextMoved = false
        showPromptText = false
        showCamera = false
        visionHandler.correctCount = 0
    }
    
}
