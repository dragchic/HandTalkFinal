import SwiftUI

struct InitialStoryView: View {
    @State private var currentStoryIndex = 0
    let stories = [
        StoryModel(
            chapter: 1,
            title: "Chapter 1: “The Swing”",
            imageSequence: ("chapter1_1", 4),
            storyText: "There’s a boy sitting by himself.\nHe doesn’t say a word.\nBut when he sees you… he doesn’t look away.",
            promptText: "Say “hello” to the boy",
            bgImageName: "bg_chapter1",
            validationImageName: "chapter1_val",
            validationMessage: "He blinks, then gives a small smile.\nA beginning.",
            expectedAnswer: "Halo"
        ),
        StoryModel(
            chapter: 2,
            title: "Chapter 2: “Memories”",
            imageSequence: ("chapter2_1",4),
            storyText: "He doesn’t speak. But you see the photo… and the look on his face.",
            promptText: "Let’s show him:\nIt’s okay to be sad",
            bgImageName: "bg_chapter2",
            validationImageName: "chapter2_val",
            validationMessage: "He lowers the photo and meets your eyes.He nods. Just once.\nHe feels understood.",
            expectedAnswer: "Sedih",
            textPosition: .bottom
        ),
        StoryModel(
            chapter: 3,
            title: "Chapter 3: “The Little Bird”",
            imageSequence: ("chapter3_1",1),
            storyText: "He kneels beside the bird. His face is careful. Gentle. You kneel beside him.",
            promptText: "Let’s tell him: I’m your friend.",
            bgImageName: "bg_chapter3",
            validationImageName: "chapter3_val",
            validationMessage: "He looks at you and copies the sign. The bird chirps softly.\nA bond begins to grow.",
            expectedAnswer: "Teman"
        ),
        StoryModel(
            chapter: 4,
            title: "Chapter 4: “Sharing”",
            imageSequence: ("chapter4_1",1),
            storyText: "You sit under a tree and open your lunch.\nYou hand him an apple. He hesitates. Then takes it. You eat together, quietly. No words — just warm company.",
            promptText: "Can you sign Eat with him?",
            bgImageName: "bg_chapter4",
            validationImageName: "chapter4_val",
            validationMessage: "He giggles and signs it back. A moment of normalcy. Of peace.",
            expectedAnswer: "Makan",
            imagePosition: .bottom
        ),
        StoryModel(
            chapter: 5,
            title: "Chapter 5: “Thank You”",
            imageSequence: ("chapter5_1",1),
            storyText: "The boy hands you something — a folded paper bird. On its wing is a small doodle: you and him, sitting under the tree. \nHe gives you a gift. \nSomething small, but full of meaning.",
            promptText: "Let’s tell him: Thank you.",
            bgImageName: "bg_chapter5",
            validationImageName: "chapter5_val",
            validationMessage: "He signs it too, quietly.\nHe holds the paper bird close to his heart.\nHe’s learning. So are you.",
            expectedAnswer: "TerimaKasih",
            imagePosition: .bottom
        ),
        StoryModel(
            chapter: 6,
            title: "Chapter 6: “See you later”",
            imageSequence: ("chapter6_1",1),
            storyText: "A train waits at the platform. The boy stands at the door, holding the scarf and the drawing.",
            promptText: "Let’s say: “See you later”",
            bgImageName: "bg_chapter6",
            validationImageName: "chapter6_val",
            validationMessage: "He doesn’t want to go. You don’t want him to leave.\nBut this isn’t the end.",
            expectedAnswer: "SampaiJumpa"
        )
    ]
    
    var body: some View {
        
        ZStack {
            if currentStoryIndex < stories.count {
                StorySceneView(
                    chapter: stories[currentStoryIndex],
                    onCompleted: {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            currentStoryIndex += 1
                        }
                    }
                )
                .id(currentStoryIndex)
                .transition(.opacity)
            } else {
                ZStack {
                    Image(.end)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack {
                        Text("THE END")
                            .ShantellSans(weight: .bold, size: 40)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        TypewriterText(
                            fullText: "You said hello.\nYou shared silence.\nYou made a history... with your hands...",
                            typingSpeed: 0.05, fontSize: 25, weight: .medium
                        )
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: currentStoryIndex)
    }
}

#Preview {
    InitialStoryView()
}
