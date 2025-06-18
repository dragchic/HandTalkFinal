//
//  ImageSequenceView.swift
//  HandTalk
//
//  Created by William on 18/06/25.
//

import SwiftUI

struct ImageSequenceView: View {
    // Array of image names
    let imageNames : String
    let frame : Int
    
    private var currentImgName: String {
        return "\(imageNames)_frame000\(currentIndex)"
    }
    // State to track current frame
    @State private var currentIndex = 0

    // Animation timer
    let timer = Timer.publish(every: 0.65, on: .main, in: .common).autoconnect()

    var body: some View {
        if frame == 1 {
            Image(currentImgName)
                .resizable()
                .scaledToFit()
        }
        else {
            Image(currentImgName)
                .resizable()
                .scaledToFit()
                .onReceive(timer) { _ in
                    // Loop to next frame
                    currentIndex = (currentIndex + 1) % frame
                }
        }
    }
}
