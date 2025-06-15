//
//  VisionHandler.swift
//  HandTalk
//
//  Created by William on 15/06/25.
//

import Foundation
import Vision
import AVFoundation

final class VisionHandler : NSObject, ObservableObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let handPoseRequest = VNDetectHumanHandPoseRequest()
    let faceRectangleRequest = VNDetectFaceRectanglesRequest()
    
    private var handPoseBuffer: [[(Float, Float, Float)]] = []
    
    private let model: HandtalkClassifierNew = {
        do {
            return try HandtalkClassifierNew(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }()
    
    var faceDistance : Double = 0.0
    
    private var lastPredictionTime: TimeInterval = 0
    private let predictionInterval: TimeInterval = 0.2
    
    @Published var limitationMessage : String = ""
    @Published var predictionLabel: String = ""
   
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let cropRect = CGRect(x: Int(width/6), y: 0, width: Int(Double(width)/1.75), height: height)
        
        guard let croppedBuffer = CameraViewModel.cropPixelBuffer(buffer, cropRect: cropRect) else { return }
        
       handleRequest(for: croppedBuffer)
    }
    
    func handleRequest(for buffer : CVPixelBuffer){
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored, options: [:])
        do {
            try handler.perform([handPoseRequest, faceRectangleRequest])
            
            let handObservations = handPoseRequest.results ?? []
            let faceRectangleObservations = faceRectangleRequest.results ?? []
            let isAbleToContinue : Bool = handleValidation(hands: handObservations, faces: faceRectangleObservations)
            
            if isAbleToContinue, let observation = handObservations.first {
                let keypoints = extractKeypoints(from: observation)
                addToBuffer(keypoints)

                if shouldPredict(), let input = createMLMultiArray() {
                    do {
                        let prediction = try model.prediction(poses: input)
                        DispatchQueue.main.async {
                            self.predictionLabel = prediction.label
                            print("Predicted Label: \(prediction.label)")
                        }
                    } catch {
                        print("Prediction failed: \(error)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.predictionLabel = ""
                }
            }
        } catch {
            print("Failed to perform hand pose request: \(error)")
        }
    }
}

private extension VisionHandler {
    
    func changeMassageValue(to msg : String){
        DispatchQueue.main.async {
            self.limitationMessage = msg
        }
    }
    
    func handleValidation(hands handObs : [VNHumanHandPoseObservation], faces faceObs : [VNFaceObservation]) -> Bool {
        // detect face distance first
        faceDistance = calculateFaceDistanceToScreen(faceObs)
        print("Face distance: \(faceDistance), handCount : \(handObs.count)")
        if faceObs.count == 0 {
            changeMassageValue(to: "Get in the frame")
            return false
        }
        
        if faceDistance < 1.5 {
            changeMassageValue(to: "Too Close")
            return false
        }
        
        if faceDistance > 5 {
            changeMassageValue(to: "Too Far")
            return false
        }
        
        let handCount = handObs.count
        if handCount < 1 {
            changeMassageValue(to: "Place hands")
            return false
        }
       
        changeMassageValue(to: ":D")
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
