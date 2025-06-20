//
//  ImageSequenceView.swift
//  HandTalk
//
//  Created by William on 18/06/25.
//

import SwiftUI

struct ImageSequenceView: View {
    let imagePrefix: String
    let frameCount: Int
    @ObservedObject var viewModel: ImageSequenceViewModel
    
    private var currentImgName: String {
        return String(format: "\(imagePrefix)_frame%04d", viewModel.currentIndex)
    }
    
    var body: some View {
        if frameCount == 1 {
            Image(currentImgName)
                .resizable()
                .scaledToFit()
        } else {
            Image(currentImgName)
                .resizable()
                .scaledToFit()
                .transition(.opacity)
                .id(currentImgName)
                .animation(.easeInOut(duration: 0.5), value: currentImgName)
        }
    }
}
