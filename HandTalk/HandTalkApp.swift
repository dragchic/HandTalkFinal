//
//  HandTalkApp.swift
//  HandTalk
//
//  Created by Grachia Uliari on 12/06/25.
//

import SwiftUI
import AVFoundation

@main
struct HandTalkApp: App {
    
    init(){
        SoundManager.BGMusic.play(withName: "bg-music", withExtension: "mp3", isLoop: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
