import SwiftUI
import Combine

import Foundation
import Combine

final class ImageSequenceViewModel: ObservableObject {
    @Published var currentIndex = 0
    
    private var frameCount: Int
    private var timer: AnyCancellable?
    
    init(frameCount: Int) {
        self.frameCount = frameCount
        if frameCount > 1 {
            start()
        }
    }
    
    func start() {
        guard frameCount > 1 else { return }
        
        timer = Timer
            .publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentIndex = (self.currentIndex + 1) % self.frameCount
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
    
    func updateFrameCount(to newCount: Int) {
        stop()
        currentIndex = 0
        frameCount = newCount
        if newCount > 1 {
            start()
        }
    }
}
