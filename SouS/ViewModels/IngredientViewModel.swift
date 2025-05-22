import SwiftUI
import PhotosUI // Import for PhotosPickerItem
import CoreTransferable // Import for Transferable

@MainActor // Ensure UI updates run on the main thread
class IngredientViewModel: ObservableObject {
    
    // MARK: - Image Selection Properties
    @Published var selectedImage: Image? = nil // SwiftUI Image for display
    @Published var selectedUIImage: UIImage? = nil // UIImage for processing/API
    
    // Property to hold the item selected by PhotosPicker
    @Published var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet {
            // When the item changes, try to load the image
            if let selectedPhotoItem {
                loadImage(from: selectedPhotoItem)
            }
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            // Request the data representation of the image
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                print("Failed to load image data from PhotosPickerItem")
                // TODO: Handle error (e.g., show an alert to the user)
                selectedImage = nil
                selectedUIImage = nil
                return
            }
            
            // Create UIImage from data
            guard let uiImage = UIImage(data: data) else {
                print("Failed to create UIImage from data")
                // TODO: Handle error
                 selectedImage = nil
                 selectedUIImage = nil
                return
            }
            
            // Update published properties
            selectedUIImage = uiImage
            selectedImage = Image(uiImage: uiImage)
            print("Successfully loaded image")
        }
    }
    
    // MARK: - Future Actions (Placeholder)
    
    func clearSelection() {
        selectedImage = nil
        selectedUIImage = nil
        selectedPhotoItem = nil
    }
    
    func proceedWithDetection() {
        guard selectedUIImage != nil else {
            print("No image selected to proceed with.")
            // TODO: Show alert to user
            return
        }
        print("Proceeding with ingredient detection...")
        // TODO: Trigger navigation to the results view, passing the selectedUIImage
        // This might involve calling a completion handler passed to the View, 
        // or updating a shared state variable.
    }
    
    func openCamera() {
        print("Camera button tapped - requires UIKit integration")
        // TODO: Implement camera access using UIImagePickerController
    }
} 