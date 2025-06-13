import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    
    class Coordinator: NSObject {
        var session: AVCaptureSession?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        context.coordinator.session = session
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            return view
        }
        session.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
        
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
            previewLayer.connection?.videoRotationAngle = 0 //buat jadi landscape right
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                context.coordinator.session?.startRunning()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
        coordinator.session = nil
    }
}

//private func applyOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
//        guard let connection = previewLayer.connection else { return }
//        if connection.isVideoRotationAngleSupported(90) {
//            connection.videoRotationAngle = 90  // ⬅ Landscape Right
//        }
//    }
