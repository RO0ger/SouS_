import SwiftUI
import PhotosUI

struct ImageSelectionView: View {
    
    // Use StateObject for the image handling logic within this view instance
    @StateObject private var imagePickerViewModel = ImagePickerViewModel()
    @StateObject private var cameraService = CameraService() // Added CameraService
    
    // Environment object for auth, potentially needed later
    // @EnvironmentObject var authManager: AuthManager 
    
    // State to trigger navigation to RecipeFinderView
    @State private var navigateToFinder = false
    
    // Removed onboardingViewModel property
    // let onboardingViewModel: OnboardingViewModel 
    
    // Use Environment dismiss action to close the modal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if cameraService.isCameraAuthorized {
                    CameraPreview(session: cameraService.session)
                        .ignoresSafeArea()
                        .onAppear {
                            print("ImageSelectionView: CameraPreview .onAppear. Camera authorized. Session running: \\(cameraService.session.isRunning)")
                            // Attempt to setup session only if not already running and authorized
                            // This check prevents re-setup if view reappears (e.g., after gallery)
                            if !cameraService.session.isRunning {
                                do {
                                    try cameraService.setupSession() // Setup inputs/outputs
                                    cameraService.startSession()   // Start the camera feed
                                } catch {
                                    // Handle setup error (e.g., update UI, log)
                                    cameraService.errorMessage = "Failed to setup camera: \(error.localizedDescription)"
                                    cameraService.showError = true
                                    print("Camera setup failed: \(error), Error Localized Description: \(error.localizedDescription)")
                                }
                            }
                        }
                        .onDisappear {
                            print("ImageSelectionView: CameraPreview .onDisappear. Session running: \\(cameraService.session.isRunning)")
                            // Stop session only if it's running.
                            // This prevents trying to stop an already stopped session if navigateToFinder triggers.
                            if cameraService.session.isRunning {
                                cameraService.stopSession()
                            }
                        }
                } else {
                    // Fallback: Black screen with permission message
                    Color.black.ignoresSafeArea()
                        .onAppear {
                            print("ImageSelectionView: Fallback (black screen) .onAppear. Camera authorized: \\(cameraService.isCameraAuthorized), Error message: '\\(cameraService.errorMessage)', Show error: \\(cameraService.showError)")
                        }
                    VStack {
                        Spacer()
                        Text(cameraService.errorMessage.isEmpty ? "Requesting camera permission..." : cameraService.errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        if cameraService.showError && (cameraService.errorMessage.contains("Settings") || cameraService.errorMessage.contains("denied")) {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .padding()
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }

                // --- UI Controls Overlay ---
                VStack {
                    // --- Close Button --- 
                    HStack {
                         Button { dismiss() } label: {
                             Image(systemName: "xmark")
                                 .font(.title2)
                                 .foregroundColor(.white)
                                 .padding()
                                 .background(Color.black.opacity(0.3))
                                 .clipShape(Circle())
                         }
                         .padding(.top)
                         .padding(.leading)
                         Spacer()
                    }
                    
                    Spacer() // Pushes controls to the bottom
                    
                    // Control Buttons Row
                    HStack(alignment: .center, spacing: 60) {
                        // Gallery Button 
                        PhotosPicker(selection: $imagePickerViewModel.selectedPhotoItem,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Image(systemName: "photo.on.rectangle.angled") // ... styling ...
                                .font(.title).foregroundColor(.white).frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.3)).clipShape(Circle()) // Darker background
                        }
                        
                        // Capture Button (Action to be updated in Phase 2)
                        Button { 
                            // TODO: Implement imagePickerViewModel.takePhoto() which calls cameraService.capturePhoto()
                            cameraService.capturePhoto() // Directly call cameraService to capture photo
                        } label: { 
                            ZStack { /* ... styling ... */ 
                                Circle().strokeBorder(Color.white, lineWidth: 4).frame(width: 75, height: 75)
                                Circle().fill(Color.white).frame(width: 65, height: 65)
                            }
                        }
                        
                        Spacer().frame(width: 60) // Balance
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToFinder) {
                if let image = imagePickerViewModel.selectedUIImage {
                    // Pass only the selected image now
                    RecipeFinderView(selectedImage: image)
                } else {
                    // This case should ideally not be hit if navigation is triggered correctly
                    Text("Error: No image selected for navigation.")
                        .onAppear { navigateToFinder = false } 
                }
            }
            // Alert for camera errors (can be refined)
            .alert("Camera Error", isPresented: $cameraService.showError, presenting: cameraService.errorMessage) { message in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
        }
        // Use .task to monitor the image selection from PhotosPicker
        .task(id: imagePickerViewModel.selectedUIImage) { // Re-run task when image changes
            if imagePickerViewModel.selectedUIImage != nil {
                print("ImageSelectionView: .task detected selectedUIImage, navigating to finder.")
                navigateToFinder = true
            }
        }
        // Add .onReceive to observe changes from CameraService.capturedImage
        .onReceive(cameraService.$capturedImage) { newImage in
            if let newImage = newImage {
                print("ImageSelectionView: Received new captured image from CameraService. Updating viewModel.")
                imagePickerViewModel.selectedUIImage = newImage
                // Optional: Clear the capturedImage in CameraService to prevent re-triggering if the view re-appears
                // or if you want to ensure it's a one-time signal per capture.
                // cameraService.capturedImage = nil 
            }
        }
        .onAppear { // Moved initial permission check and session start here
            print("ImageSelectionView: Main .onAppear. Camera authorized: \\(cameraService.isCameraAuthorized)")
            if !cameraService.isCameraAuthorized {
                 cameraService.checkCameraPermissions() // Ensure permissions are checked when view appears
                 print("ImageSelectionView: Called checkCameraPermissions() because camera not authorized.")
            }
            // If already authorized from init or previous check, and view is appearing, try to start.
            // setupSession() and startSession() are now called within the ZStack's .onAppear
            // for the CameraPreview itself, ensuring it only happens when the preview is actually about to be shown.
        }
    }
}

// --- Simple ViewModel for Image Picking Logic ---
// (Can be moved to ViewModels folder later)
@MainActor // Ensure UI updates are on main thread
class ImagePickerViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            if let selectedPhotoItem {
                processPhotoItem(selectedPhotoItem)
            }
        }
    }
    @Published var selectedUIImage: UIImage? = nil

    private func processPhotoItem(_ item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    print("Failed to load image data from gallery.")
                    // Potentially set an error state for the UI
                    return
                }
                guard let image = UIImage(data: data) else {
                    print("Failed to create UIImage from gallery data.")
                    // Potentially set an error state for the UI
                    return
                }
                selectedUIImage = image
                print("Image successfully loaded from gallery and set.")
            } catch {
                print("Error loading image transferable from gallery: \\(error)")
                // Potentially set an error state for the UI
            }
        }
    }
    
    // This function will be modified in Phase 2 to use CameraService
    func takePhoto() {
        // TODO: Call cameraService.capturePhoto() and handle the result
        // This function is no longer directly responsible for initiating the capture.
        // ImageSelectionView now calls cameraService.capturePhoto() directly.
        // This viewModel will receive the image via the .onReceive modifier in ImageSelectionView.
        print("ImagePickerViewModel.takePhoto() called - its role has been shifted. ImageSelectionView handles capture initiation.")
    }

    // Placeholder for camera logic (OLD - openCamera) - to be removed or refactored
    // func openCamera() {
    //     // TODO: Implement camera opening logic using AVFoundation or other libraries
    //     print("Camera functionality not implemented yet.")
    // }
}


#Preview {
    // Remove onboardingViewModel from Preview
    ImageSelectionView()
} 