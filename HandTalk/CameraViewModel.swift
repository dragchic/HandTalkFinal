//
//  CameraViewModel.swift
//  HandTalk
//
//  Created by William on 15/06/25.
//

import Foundation
import AVFoundation
import Vision

final class CameraViewModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    
    var visionHandler : VisionHandler
    
    init(visionHandler: VisionHandler) {
        self.visionHandler = visionHandler
    }
    
    func addOutputVideoBufferToML() {
        session.addOutput(videoOutput)
        videoOutput.setSampleBufferDelegate(visionHandler, queue: DispatchQueue(label: "vision.request.queue"))
    }
    
    func startCamera(){
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

}


import CoreImage

extension CameraViewModel {
    static func cropPixelBuffer(_ pixelBuffer: CVPixelBuffer, cropRect: CGRect) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Flip coordinate system vertically (CIImage is bottom-left origin)
        let imageHeight = ciImage.extent.height
        let adjustedRect = CGRect(
            x: cropRect.origin.x,
            y: imageHeight - cropRect.origin.y - cropRect.size.height,
            width: cropRect.size.width,
            height: cropRect.size.height
        )

        let cropped = ciImage.cropped(to: adjustedRect)

        let context = CIContext()
        var newBuffer: CVPixelBuffer?

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let width = Int(adjustedRect.width)
        let height = Int(adjustedRect.height)

        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         CVPixelBufferGetPixelFormatType(pixelBuffer),
                                         attrs, &newBuffer)

        guard status == kCVReturnSuccess, let outputBuffer = newBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(outputBuffer, [])
        context.render(cropped, to: outputBuffer)
        CVPixelBufferUnlockBaseAddress(outputBuffer, [])

        return outputBuffer
    }
}
