//
//  StoryModel.swift
//  HandTalk
//
//  Created by Francesco on 17/06/25.
//
import Foundation

struct StoryModel: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let storyText: String
    let promptText: String
    let bgImageName: String
    let validationImageName: String
}
