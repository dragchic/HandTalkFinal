    import UIKit
import AVFoundation
import Vision
import CoreML

class HandActionViewModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    // MARK: - Properties
    @Published var predictionLabel: String = ""
    
    let session = AVCaptureSession()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handPoseBuffer: [[(Float, Float, Float)]] = []
    
    private let model: HandtalkClassifierNew = {
        do {
            return try HandtalkClassifierNew(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }()
    
    override init() {
        super.init()
        setupCamera()
        handPoseRequest.maximumHandCount = 1
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }
        
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    // MARK: - Sample Buffer Delegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            if let observation = handPoseRequest.results?.first {
                let keypoints = extractKeypoints(from: observation)
                addToBuffer(keypoints)
                
                if let input = createMLMultiArray(), let prediction = try? model.prediction(poses: input) {
                    
                    DispatchQueue.main.async {
                        print("Predicted Label: \(prediction.label)")
                        self.predictionLabel = prediction.label
                    }
                }
            }
        } catch {
            print("Vision error: \(error)")
        }
    }
    
    // MARK: - Hand Pose Extraction
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
    
    // MARK: - Buffer Management
    private func addToBuffer(_ keypoints: [(Float, Float, Float)]) {
        handPoseBuffer.append(keypoints)
        if handPoseBuffer.count > 60 {
            handPoseBuffer.removeFirst()
        }
    }
    
    // MARK: - MultiArray Conversion
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
