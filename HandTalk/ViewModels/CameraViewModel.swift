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
    
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handPoseBuffer: [[(Float, Float, Float)]] = []
    
    private let model: HandtalkClassifierNew = {
        do {
            return try HandtalkClassifierNew(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }()
    
    @Published var predictionLabel: String = ""
    
    var visionHandler : VisionHandler
    
    init(visionHandler: VisionHandler) {
        self.visionHandler = visionHandler
    }
    
    func addOutputVideoBufferToML() {
        session.addOutput(videoOutput)
//        videoOutput.setSampleBufferDelegate(visionHandler, queue: DispatchQueue(label: "vision.request.queue"))
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "vision.request.queue"))
    }
    
    func startCamera(){
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func processWithVisionHandler(sampleBuffer: CMSampleBuffer) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let cropRect = CGRect(x: Int(width / 6), y: 0, width: Int(Double(width) / 1.75), height: height)

        guard let cropped = CameraViewModel.cropPixelBuffer(buffer, cropRect: cropRect) else { return }

        visionHandler.handleRequest(for: cropped)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processWithVisionHandler(sampleBuffer: sampleBuffer)

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            if let observation = handPoseRequest.results?.first {
                let keypoints = extractKeypoints(from: observation)
                addToBuffer(keypoints)
                
                if let input = createMLMultiArray(),
                   let prediction = try? model.prediction(poses: input) {
                    DispatchQueue.main.async {
                        print(prediction.label)
                        self.predictionLabel = prediction.label
                    }
                }
            }
        } catch {
            print("Vision error: \(error)")
        }
    }
    
    private func extractKeypoints(from observation: VNHumanHandPoseObservation) -> [(Float, Float, Float)] {
        guard let allPoints = try? observation.recognizedPoints(.all) else { return [] }

        let keypointsOrder: [VNHumanHandPoseObservation.JointName] = [
            .wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]

        return keypointsOrder.map { joint in
            if let point = allPoints[joint], point.confidence > 0 {
                return (Float(point.location.x), Float(point.location.y), Float(point.confidence))
            } else {
                return (0.0, 0.0, 0.0)
            }
        }
    }
    
    private func addToBuffer(_ keypoints: [(Float, Float, Float)]) {
        handPoseBuffer.append(keypoints)
        if handPoseBuffer.count > 60 {
            handPoseBuffer.removeFirst()
        }
    }
    
    private func createMLMultiArray() -> MLMultiArray? {
        guard handPoseBuffer.count == 60 else { return nil }

        let shape: [NSNumber] = [60, 3, 21]
        guard let multiArray = try? MLMultiArray(shape: shape, dataType: .float32) else { return nil }

        for t in 0..<60 {
            for c in 0..<3 {
                for k in 0..<21 {
                    let value: Float
                    switch c {
                    case 0: value = handPoseBuffer[t][k].0
                    case 1: value = handPoseBuffer[t][k].1
                    case 2: value = handPoseBuffer[t][k].2
                    default: value = 0
                    }
                    multiArray[[NSNumber(value: t), NSNumber(value: c), NSNumber(value: k)]] = NSNumber(value: value)
                }
            }
        }

        return multiArray
    }
}

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
