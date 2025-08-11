import Foundation
import UIKit
import SwiftUI
import PhotosUI

@MainActor
class ProfileImageManager: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    // MARK: - Image Processing
    
    func compressImage(_ image: UIImage, maxSize: Int = 1024 * 1024) -> Data? {
        var compression: CGFloat = 1.0
        var data = image.jpegData(compressionQuality: compression)
        
        // Reduce quality until we get under maxSize
        while data?.count ?? 0 > maxSize && compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }
        
        return data
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Local Storage
    
    func saveImageLocally(_ image: UIImage, userId: String) -> String? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let profileImagesPath = documentsPath.appendingPathComponent("ProfileImages")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: profileImagesPath, withIntermediateDirectories: true)
        
        let imagePath = profileImagesPath.appendingPathComponent("\(userId)_profile.jpg")
        
        guard let imageData = compressImage(image) else { return nil }
        
        do {
            try imageData.write(to: imagePath)
            return imagePath.path
        } catch {
            return nil
        }
    }
    
    func loadImageLocally(userId: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("ProfileImages/\(userId)_profile.jpg")
        
        guard let imageData = try? Data(contentsOf: imagePath) else { return nil }
        return UIImage(data: imageData)
    }
    
    func deleteLocalImage(userId: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("ProfileImages/\(userId)_profile.jpg")
        
        try? FileManager.default.removeItem(at: imagePath)
    }
    
    // MARK: - Complete Image Update (Local Only for Now)
    
    func updateProfileImage(_ image: UIImage, userId: String) async throws -> String {
        // For now, just save locally and return a placeholder URL
        // Later, you can integrate Firebase Storage here
        
        guard let localPath = saveImageLocally(image, userId: userId) else {
            throw ProfileImageError.localSaveFailed
        }
        
        // Simulate upload progress
        isUploading = true
        uploadProgress = 0.0
        
        // Simulate upload delay
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            uploadProgress = Double(i) / 10.0
        }
        
        isUploading = false
        uploadProgress = 1.0
        
        // Return a placeholder URL for now
        // In a real implementation, you'd upload to Firebase Storage and return the actual URL
        return "local://\(localPath)"
    }
}

// MARK: - Errors

enum ProfileImageError: Error, LocalizedError {
    case compressionFailed
    case localSaveFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .localSaveFailed:
            return "Failed to save image locally"
        case .uploadFailed:
            return "Failed to upload image to cloud"
        }
    }
} 