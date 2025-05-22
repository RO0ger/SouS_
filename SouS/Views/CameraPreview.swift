import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    // The AVCaptureSession is passed from the CameraService
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear // Ensure background doesn't obscure layer
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // previewLayer.frame = view.bounds // Set frame after adding to layer hierarchy or in layoutSubviews
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        // It's often better to set the layer's frame in layoutSubviews of the UIView subclass or ensure it's updated in updateUIView.
        // For simplicity here, we will rely on updateUIView and an initial set after adding.
        previewLayer.frame = view.bounds // Set initial frame
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // This is where you would update the view if the session or other properties change.
        // For example, if the device orientation changes, update the previewLayer's orientation.
        // We might need to handle orientation changes later.
        DispatchQueue.main.async { // Ensure UI updates are on the main thread
            if let previewLayer = context.coordinator.previewLayer {
                previewLayer.frame = uiView.bounds
                // Update orientation if necessary, e.g., based on device orientation
                // if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
                //     connection.videoOrientation = currentVideoOrientation() // You'd need to implement currentVideoOrientation
                // }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: CameraPreview
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(_ parent: CameraPreview) {
            self.parent = parent
        }
    }
    
    // Helper to determine video orientation (can be expanded later)
    // private func currentVideoOrientation() -> AVCaptureVideoOrientation {
    //     // TODO: Implement proper orientation detection if needed
    //     return .portrait
    // }
} 