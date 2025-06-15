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
    
    var faceDistance : Double = 0.0
    
    @Published var limitationMessage : String = ""
   
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
            
            if isAbleToContinue {
                // TODO: Lanjutin inference model di sini
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
    
    func calculateFaceDistanceToScreen(_ observations : [VNFaceObservation]) -> Double{
        if let face = observations.first {
            let boundingBox = face.boundingBox
            let faceWidth = boundingBox.width // relative to image size (0.0 - 1.0)
            
            // Empirical estimate: bigger width → closer
            return 1.0 / faceWidth
        }
        return 0
    }
}
