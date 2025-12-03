//
//  AppDelegate.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//
import UIKit
import Firebase
import Cloudinary

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// MARK: - Cloudinary Manager (Unsigned upload, no forbidden params)
class CloudinaryManager {
    static let shared = CloudinaryManager()
    let cloudinary: CLDCloudinary
    private let uploadPreset: String // Your unsigned upload preset ID
    
    private init() {
        let config = CLDConfiguration(
            cloudName: "dzgxc4ri3"
        )
        self.cloudinary = CLDCloudinary(configuration: config)
        self.uploadPreset = "iOS_uploads" // must be an UNSIGNED preset in your Cloudinary console
    }
    
    // Upload raw Data to Cloudinary, returns secure URL
    // For unsigned uploads: do not set publicId/overwrite/invalidate (usually rejected for unsigned presets)
    func upload(data: Data, folder: String? = "profile_photos") async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let params = CLDUploadRequestParams()
                .setUploadPreset(uploadPreset)
                .setUniqueFilename(true) // ensure Cloudinary generates a unique public_id
            
            if let folder {
                _ = params.setFolder(folder)
            }
            
            let request = cloudinary.createUploader()
                .upload(data: data,
                        uploadPreset: uploadPreset,
                        params: params,
                        progress: nil) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let result = result,
                          let secure = result.secureUrl,
                          let url = URL(string: secure) else {
                        let customError = NSError(
                            domain: "CloudinaryManager",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Upload succeeded, but no secure URL was returned."]
                        )
                        continuation.resume(throwing: customError)
                        return
                    }
                    continuation.resume(returning: url)
                }
            _ = request
        }
    }
}
