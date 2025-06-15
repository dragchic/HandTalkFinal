import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    var viewModel: CameraViewModel
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
    }
    
    private func setupCamera() {
        viewModel.session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              viewModel.session.canAddInput(input),
              viewModel.session.canAddOutput(viewModel.videoOutput) else {
            print("Camera setup failed.")
            return
        }

        viewModel.session.addInput(input)
        viewModel.addOutputVideoBufferToML()
        viewModel.startCamera()
    }

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = viewModel.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        setupCamera()
        updateVideoOrientation(layer: view.videoPreviewLayer) // ✅ initial orientation

        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateVideoOrientation(layer: view.videoPreviewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}

    func dismantleUIView(_ uiView: VideoPreviewView, coordinator: Coordinator) {
        viewModel.session.stopRunning()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    private func updateVideoOrientation(layer: AVCaptureVideoPreviewLayer) {
        guard let connection = layer.connection, connection.isVideoOrientationSupported else { return }

        switch UIDevice.current.orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        default:
            break
        }

        // Optional: Mirror front camera
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}
