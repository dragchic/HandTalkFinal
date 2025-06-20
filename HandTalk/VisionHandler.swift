//
//  VisionHandler.swift
//  HandTalk
//
//  Created by William on 15/06/25.
//

import Foundation
import Vision
import AVFoundation
import UIKit

final class VisionHandler : NSObject, ObservableObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let handPoseRequest = VNDetectHumanHandPoseRequest()
    let faceRectangleRequest = VNDetectFaceRectanglesRequest()
    
    private var handPoseBuffer: [[(Float, Float, Float)]] = []
    
    private let model: HandtalkFinal = {
        do {
            return try HandtalkFinal(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }()
    
    var faceDistance : Double = 0.0
    
    private var lastPredictionTime: TimeInterval = 0
    private let predictionInterval: TimeInterval = 0.2
    
    @Published var cameraFeedbackMassage : String = "Get in the frame"
    @Published var prediction : String?
    @Published var correctCount: Int = 0
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let cropRect = CGRect(x: Int(width/4), y: 0, width: Int(Double(width)/1.5), height: height)
        
        guard let croppedBuffer = CameraViewModel.cropPixelBuffer(buffer, cropRect: cropRect) else { return }
        
        
       handleRequest(for: croppedBuffer)
    }
    
    func handleRequest(for buffer : CVPixelBuffer){
        
        guard let modifiedBuffer = flipPixelBuffer(buffer,horizontally: false, vertically: true) else {return}

        let handler = VNImageRequestHandler(cvPixelBuffer: modifiedBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest, faceRectangleRequest])
            
            let handObservations = handPoseRequest.results ?? []
            let faceRectangleObservations = faceRectangleRequest.results ?? []
            let isAbleToContinue : Bool = handleValidation(hands: handObservations, faces: faceRectangleObservations)
            
            if isAbleToContinue, let observation = handObservations.first {
                changeMassageValue(to: "")
                let keypoints = extractKeypoints(from: observation)
                addToBuffer(keypoints)

                if shouldPredict(), let input = createMLMultiArray() {
                    do {
                        let prediction = try model.prediction(poses: input)
                        handlePrediction(prediction)
                    } catch {
                        print("Prediction failed: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to perform hand pose request: \(error)")
        }
    }
}

extension VisionHandler {
    
    func handlePrediction(_ result : HandtalkFinalOutput) {
        let mostLikelyPrediction = result.label
        let _ : [String : Double] = result.labelProbabilities
        
        //TODO: Handle Prediction nya mau kyk gmn, default nya the most probable
        DispatchQueue.main.async {
            if (self.correctCount < 3) {
                self.prediction = mostLikelyPrediction
            }
        }
    }
    
    func correctGesture() {
        DispatchQueue.main.async {
            self.prediction = nil
            self.correctCount += 1
            SoundManager.SFX.play(withName: "Ding\(self.correctCount)", withExtension: "wav", isLoop: false)
            self.lastPredictionTime = CACurrentMediaTime() + 1.0
        }
    }
        
    func image(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func flipPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        horizontally: Bool = false,
        vertically: Bool = false
    ) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        // Calculate the flip transform
        var transform = CGAffineTransform.identity

        if horizontally {
            transform = transform
                .translatedBy(x: width, y: 0)
                .scaledBy(x: -1, y: 1)
        }

        if vertically {
            transform = transform
                .translatedBy(x: 0, y: height)
                .scaledBy(x: 1, y: -1)
        }

        let flippedImage = ciImage.transformed(by: transform)

        let context = CIContext()

        var outputBuffer: CVPixelBuffer?
        let attrs: CFDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(width),
            Int(height),
            pixelFormat,
            attrs,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let outBuffer = outputBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(outBuffer, [])
        context.render(flippedImage, to: outBuffer)
        CVPixelBufferUnlockBaseAddress(outBuffer, [])

        return outBuffer
    }
    
    func rotatePixelBuffer180(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply 180-degree rotation (π radians)
        let rotatedImage = ciImage.transformed(by: CGAffineTransform(rotationAngle: .pi)
            .translatedBy(x: -ciImage.extent.width, y: -ciImage.extent.height))

        let context = CIContext()
        
        var outputBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attrs,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let outBuffer = outputBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(outBuffer, [])
        context.render(rotatedImage, to: outBuffer)
        CVPixelBufferUnlockBaseAddress(outBuffer, [])

        return outBuffer
    }
    
    func changeMassageValue(to msg : String){
        DispatchQueue.main.async {
            self.cameraFeedbackMassage = msg
        }
    }
    
    func handleValidation(hands handObs : [VNHumanHandPoseObservation], faces faceObs : [VNFaceObservation]) -> Bool {
        // detect face distance first
        faceDistance = calculateFaceDistanceToScreen(faceObs)
//        print("Face distance: \(faceDistance), handCount : \(handObs.count)")
        if faceObs.count == 0 {
            changeMassageValue(to: "The boy can't see you")
            return false
        }
        
        if faceDistance < 1.5 {
            changeMassageValue(to: "You're too close")
            return false
        }
        
        if faceDistance > 7 {
            changeMassageValue(to: "You're too far")
            return false
        }
        
        if handObs.count < 1 {
            changeMassageValue(to: "Make hand gesture")
            return false
        }
       
        return true
    }
    
    private func shouldPredict() -> Bool {
        let now = CACurrentMediaTime()
        if now - lastPredictionTime >= predictionInterval {
            lastPredictionTime = now
            return true
        }
        return false
    }
    
    func calculateFaceDistanceToScreen(_ observations : [VNFaceObservation]) -> Double{
        if let face = observations.first {
            let boundingBox = face.boundingBox
            let faceWidth = boundingBox.width // relative to image size (0.0 - 1.0)
            
            // Empirical estimate: bigger width → closer
            return 1.0 / faceWidth
        }
        return 0
    }
    
    func extractKeypoints(from observation: VNHumanHandPoseObservation) -> [(Float, Float, Float)] {
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
    
    func addToBuffer(_ keypoints: [(Float, Float, Float)]) {
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
                    let index = [NSNumber(value: t), NSNumber(value: c), NSNumber(value: k)]
                    multiArray[index] = NSNumber(value: value)
                }
            }
        }

        return multiArray
    }
}
