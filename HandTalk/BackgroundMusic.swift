//
//  BackgroundMusic.swift
//  HandTalk
//
//  Created by Grachia Uliari on 19/06/25.
//

import AVFoundation

class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()
    private var player: AVAudioPlayer?

    private init() {}

    func play() {
        guard let url = Bundle.main.url(forResource: "bg-music", withExtension: "mp3") else {
            print("bg-music.mp3 not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // loop terus
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
