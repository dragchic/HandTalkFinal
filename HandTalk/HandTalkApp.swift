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
        BackgroundMusicPlayer.shared.play()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
