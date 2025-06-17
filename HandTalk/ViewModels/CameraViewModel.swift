//
//  CameraViewModel.swift
//  HandTalk
//
//  Created by William on 15/06/25.
//

import Foundation
import AVFoundation
import Vision
import CoreImage

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

extension CameraViewModel {
    static func cropPixelBuffer(_ pixelBuffer: CVPixelBuffer, cropRect: CGRect) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let imageHeight = ciImage.extent.height
        let adjustedRect = CGRect(
            x: cropRect.origin.x,
            y: imageHeight - cropRect.origin.y - cropRect.size.height,
            width: cropRect.size.width,
            height: cropRect.size.height
        )

        guard adjustedRect.width > 0, adjustedRect.height > 0,
              ciImage.extent.contains(adjustedRect) else {
            print("Invalid crop rect: \(adjustedRect)")
            return nil
        }

        let cropped = ciImage.cropped(to: adjustedRect)

        let context = CIContext()

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let width = Int(adjustedRect.width)
        let height = Int(adjustedRect.height)

        var newBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, // Force supported format
                                         attrs, &newBuffer)

        guard status == kCVReturnSuccess, let outputBuffer = newBuffer else {
            print("Failed to create CVPixelBuffer")
            return nil
        }

        CVPixelBufferLockBaseAddress(outputBuffer, [])
        context.render(cropped, to: outputBuffer)
        CVPixelBufferUnlockBaseAddress(outputBuffer, [])

        return outputBuffer
    }
}
