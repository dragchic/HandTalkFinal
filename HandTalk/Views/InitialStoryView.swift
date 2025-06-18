import SwiftUI

struct InitialStoryView: View {
    @State private var currentStoryIndex = 0
    let stories = [
        StoryModel(
            title: "Chapter 1: The Swing",
            imageSequence: ("chapter1_1", 4),
            storyText: "Seorang anak laki-laki sedang duduk sendirian.\nDia tak mengucapkan sepatah kata pun.\nDia melihatmu, tapi dia tak berpaling.",
            promptText: "Say hello to the boy through the camera",
            bgImageName: "bg_chapter1",
            validationImageName: "boy-smile",
            expectedAnswer: "Halo"
        ),
        StoryModel(
            title: "Chapter 2: The Bird",
            imageSequence: ("chapter2_1",1),
            storyText: "He kneels beside the bird. His face is careful. Gentle. You kneel beside him.",
            promptText: "Say “friend” to the boy",
            bgImageName: "bg_chapter2",
            validationImageName: "pg2_validation",
            expectedAnswer: "Teman"
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
                Text("Story complete")
                    .font(.largeTitle)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: currentStoryIndex)
    }
}

#Preview {
    InitialStoryView()
}
