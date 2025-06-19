//
//  StoryModel.swift
//  HandTalk
//
//  Created by Francesco on 17/06/25.
//
import Foundation

enum Position: String {
    case `default`
    case bottom
}

struct StoryModel: Identifiable {
    let id = UUID()
    let title: String
    let imageSequence: (String, Int)
    let storyText: String
    let promptText: String
    let bgImageName: String
    let validationImageName: String
    let validationMessage: String
    let expectedAnswer: String
    let imagePosition: Position
    let textPosition: Position
    
    init(
        title: String,
        imageSequence: (String, Int),
        storyText: String,
        promptText: String,
        bgImageName: String,
        validationImageName: String,
        validationMessage: String,
        expectedAnswer: String,
        imagePosition: Position = .default,
        textPosition: Position = .default
    ) {
        self.title = title
        self.imageSequence = imageSequence
        self.storyText = storyText
        self.promptText = promptText
        self.bgImageName = bgImageName
        self.validationImageName = validationImageName
        self.validationMessage = validationMessage
        self.expectedAnswer = expectedAnswer
        self.imagePosition = imagePosition
        self.textPosition = textPosition
    }
}
