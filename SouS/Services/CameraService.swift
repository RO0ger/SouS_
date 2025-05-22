import AVFoundation
import Combine
import UIKit // For UIImage, if we process it here later

enum CameraError: Error, LocalizedError {
    case cameraUnavailable
    case permissionDenied
    case inputDeviceUnavailable
    case outputUnavailable
    case sessionSetupFailed(Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return NSLocalizedString("The camera is unavailable on this device. This might be a simulator issue or a device without a suitable camera.", comment: "CameraError: Camera Unavailable")
        case .permissionDenied:
            return NSLocalizedString("Camera permission was denied. Please enable it in Settings to use the camera.", comment: "CameraError: Permission Denied")
        case .inputDeviceUnavailable:
            return NSLocalizedString("Could not find a suitable camera input device (e.g., the back camera might be missing or inaccessible).", comment: "CameraError: Input Device Unavailable")
        case .outputUnavailable:
            return NSLocalizedString("Failed to set up the photo output for the camera session.", comment: "CameraError: Output Unavailable")
        case .sessionSetupFailed(let underlyingError):
            return NSLocalizedString("Camera session setup failed. Underlying error: \(underlyingError.localizedDescription)", comment: "CameraError: Session Setup Failed")
        case .unknown:
            return NSLocalizedString("An unknown camera error occurred. Please try again.", comment: "CameraError: Unknown")
        }
    }
}

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isCameraAuthorized: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var capturedImage: UIImage? = nil // For Phase 2

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput() // For Phase 2
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override init() {
        print("CameraService: init called.")
        super.init()
        checkCameraPermissions()
    }

    func checkCameraPermissions() {
        print("CameraService: checkCameraPermissions called. Current status: \(AVCaptureDevice.authorizationStatus(for: .video))")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("CameraService: Status is .authorized")
            isCameraAuthorized = true
        case .notDetermined:
            print("CameraService: Status is .notDetermined, requesting permission.")
            requestCameraPermission()
        case .denied, .restricted:
            print("CameraService: Status is .denied or .restricted.")
            isCameraAuthorized = false
            errorMessage = "Camera access is denied or restricted. Please enable it in Settings."
            showError = true // This can be observed by the View
        @unknown default:
            print("CameraService: Status is @unknown.")
            isCameraAuthorized = false
            errorMessage = "Unknown camera authorization status."
            showError = true
        }
    }

    private func requestCameraPermission() {
        print("CameraService: requestCameraPermission called.")
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                print("CameraService: Permission request returned. Granted: \(granted)")
                self?.isCameraAuthorized = granted
                if !granted {
                    self?.errorMessage = "Camera access was not granted. Please enable it in Settings."
                    self?.showError = true
                    print("CameraService: Permission not granted. Error message set.")
                } else {
                    print("CameraService: Permission granted.")
                    // If permission is granted here, we might need to explicitly tell the view
                    // or trigger session setup if it hasn't happened.
                    // For now, relying on the view's .onAppear logic after isCameraAuthorized changes.
                }
            }
        }
    }

    func setupSession() throws {
        guard isCameraAuthorized else {
            print("CameraService: Camera permission not granted. Cannot setup session.")
            // It's good practice to set the showError and errorMessage here too for consistency
            self.errorMessage = CameraError.permissionDenied.localizedDescription
            self.showError = true
            throw CameraError.permissionDenied
        }

        session.beginConfiguration()
        // Use defer to ensure commitConfiguration is always called, even if an error is thrown.
        defer { session.commitConfiguration() }

        // Remove existing inputs before trying to add new ones
        session.inputs.forEach { input in
            print("CameraService: Removing existing input: \\(input)")
            session.removeInput(input)
        }

        // Remove existing outputs before trying to add new ones
        // (Especially important if photoOutput could be added multiple times)
        session.outputs.forEach { output in
            print("CameraService: Removing existing output: \\(output)")
            session.removeOutput(output)
        }

        session.sessionPreset = .photo // Or another preset if needed

        // Input Device (Back Camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("CameraService: Failed to get back camera.")
            self.errorMessage = CameraError.inputDeviceUnavailable.localizedDescription
            self.showError = true
            throw CameraError.inputDeviceUnavailable
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                print("CameraService: Successfully added video device input.")
            } else {
                print("CameraService: Could not add video device input to the session (canAddInput was false).")
                self.errorMessage = "Failed to add camera input to session." // More specific than generic inputDeviceUnavailable
                self.showError = true
                throw CameraError.inputDeviceUnavailable // Or a new, more specific error case
            }
        } catch {
            print("CameraService: Error creating or adding video device input: \\(error.localizedDescription)")
            // If the error is already one of our CameraErrors, use its localizedDescription.
            // Otherwise, wrap it.
            let cameraError = error as? CameraError ?? CameraError.sessionSetupFailed(error)
            self.errorMessage = cameraError.localizedDescription
            self.showError = true
            throw cameraError
        }
        
        // Photo Output (for Phase 2)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            print("CameraService: Successfully added photo output.")
        } else {
            print("CameraService: Could not add photo output to the session.")
            // Not throwing here as preview might still work, but capture won't
            // Consider if this should set an error state if capture is critical.
            // self.errorMessage = CameraError.outputUnavailable.localizedDescription
            // self.showError = true
            // throw CameraError.outputUnavailable // Example if it were critical
        }
        print("CameraService: AVCaptureSession setup complete.")
    }

    func startSession() {
        if isCameraAuthorized && !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                print("AVCaptureSession started.")
            }
        } else if !isCameraAuthorized {
            print("Cannot start session: Camera not authorized.")
            checkCameraPermissions() // Re-check and potentially show error message via @Published vars
        }
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
            print("AVCaptureSession stopped.")
        }
    }
    
    // Placeholder for Phase 2
    func capturePhoto() {
        // Implementation for capturing photo will go here in Phase 2
        let settings = AVCapturePhotoSettings()
        // Configure settings as needed, e.g., settings.flashMode = .auto
        // For basic capture, default settings are often fine.
        // You can specify pixel format, HEVC, etc.
        // settings.previewPhotoFormat = settings.availablePreviewPhotoPixelFormatTypes.first // Example

        print("CameraService: Attempting to capture photo.")
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("CameraService: photoOutput didFinishProcessingPhoto called.")
        if let error = error {
            print("CameraService: Error capturing photo: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error capturing photo: \(error.localizedDescription)"
                self.showError = true
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            print("CameraService: Could not get image data.")
            DispatchQueue.main.async {
                self.errorMessage = "Could not process captured image."
                self.showError = true
            }
            return
        }

        print("CameraService: Photo data received, creating UIImage.")
        if let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.capturedImage = image
                print("CameraService: capturedImage updated.")
            }
        } else {
            print("CameraService: Could not create UIImage from data.")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to convert photo data to image."
                self.showError = true
            }
        }
    }
} 