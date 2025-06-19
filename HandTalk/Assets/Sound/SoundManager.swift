//
//  BackgroundMusic.swift
//  HandTalk
//
//  Created by Grachia Uliari on 19/06/25.
//

import AVFoundation

class SoundManager {
    static let BGMusic = SoundManager()
    static let SFX = SoundManager()
    
    private var player: AVAudioPlayer?

    private init() {}

    func play(withName musicName : String, withExtension fileExtension : String, isLoop : Bool) {
        guard let url = Bundle.main.url(forResource: musicName, withExtension: fileExtension) else {
            print("\(musicName)\(fileExtension) not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = isLoop ? -1 : 0 // loop terus
            player?.volume = 0.3
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Error playing music: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
    }
}
