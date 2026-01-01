//
//  ProfileImageService.swift
//  ConvAI
//
//  Created by GitHub Copilot on 02/08/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage
import Firebase

class ProfileImageService: NSObject, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedAvatarIcon: String?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Predefined avatar icons
    let avatarIcons = [
        "avatar_1", "avatar_2", "avatar_3", "avatar_4",
        "avatar_5", "avatar_6", "avatar_7", "avatar_8",
        "avatar_9", "avatar_10", "avatar_11", "avatar_12"
    ]
    
    private let storage = Storage.storage()
    
    // MARK: - Avatar Icon Selection
    
    func selectAvatarIcon(_ iconName: String) {
        selectedAvatarIcon = iconName
        selectedImage = nil // Clear custom image when avatar is selected
    }
    
    // MARK: - Photo Selection
    
    func selectFromPhotoLibrary() {
        // This will be handled by PhotosPicker in SwiftUI
        // The actual implementation will be in the ProfileSetupView
    }
    
    func takePhotoWithCamera() {
        // This will be handled by ImagePicker in SwiftUI
        // The actual implementation will be in the ProfileSetupView
    }
    
    // Method to handle selected photo from PhotosPicker
    func handleSelectedPhoto(_ photoItem: PhotosPickerItem?) {
        guard let photoItem = photoItem else { return }
        
        isLoading = true
        errorMessage = ""
        
        photoItem.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self.processSelectedImage(image)
                    } else {
                        self.errorMessage = "Failed to load selected image"
                        print("⚠️ ProfileImageService: Failed to create UIImage from data")
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ ProfileImageService: Photo loading error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Image Processing
    
    func processSelectedImage(_ image: UIImage) {
        // Compress and resize image
        let compressedImage = compressImage(image, maxSizeKB: 500)
        selectedImage = compressedImage
        selectedAvatarIcon = nil // Clear avatar selection when custom image is selected
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> UIImage {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Resize if needed
        var resizedImage = image
        if image.size.width > 300 || image.size.height > 300 {
            let targetSize = CGSize(width: 300, height: 300)
            resizedImage = resizeImage(image, targetSize: targetSize)
        }
        
        // Compress until under size limit
        while let data = resizedImage.jpegData(compressionQuality: compression),
              data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
        }
        
        if let finalData = resizedImage.jpegData(compressionQuality: compression),
           let finalImage = UIImage(data: finalData) {
            return finalImage
        }
        
        return resizedImage
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // MARK: - Firebase Storage Upload (Currently Disabled for Development)
    
    /// NOTE: This function is currently disabled to prevent Firebase Storage errors
    /// during development. It should be re-enabled once proper user authentication is implemented.
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Temporarily disabled to prevent profile_images/ errors
        #if DEBUG
        print("⚠️ ProfileImageService: Firebase upload disabled for development")
        completion(.failure(ProfileImageError.uploadDisabled))
        #else
        // Original upload code would go here for production
        performFirebaseUpload(image, completion: completion)
        #endif
    }
    
    private func performFirebaseUpload(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ProfileImageError.imageProcessingFailed))
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Use a temporary user ID or current timestamp for now
        // This should be replaced with actual user ID from authentication
        let userId = UUID().uuidString
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child("profile_images/\(userId)/profile.jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                        }
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url.absoluteString))
                    }
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func clearSelection() {
        selectedImage = nil
        selectedAvatarIcon = nil
        errorMessage = ""
    }
    
    func hasSelection() -> Bool {
        return selectedImage != nil || selectedAvatarIcon != nil
    }
    
    func getDisplayImage() -> UIImage? {
        if let selectedImage = selectedImage {
            return selectedImage
        } else if let avatarIcon = selectedAvatarIcon {
            return UIImage(named: avatarIcon)
        }
        return nil
    }
    
    func getImageIdentifier() -> String? {
        if selectedImage != nil {
            return "custom_image"
        } else if let avatarIcon = selectedAvatarIcon {
            return "avatar:\(avatarIcon)"
        }
        return nil
    }
}

// MARK: - Custom Errors

enum ProfileImageError: LocalizedError {
    case noImageSelected
    case imageProcessingFailed
    case uploadFailed
    case uploadDisabled
    
    var errorDescription: String? {
        switch self {
        case .noImageSelected:
            return "No image selected"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .uploadFailed:
            return "Failed to upload image"
        case .uploadDisabled:
            return "Upload temporarily disabled for development"
        }
    }
}
