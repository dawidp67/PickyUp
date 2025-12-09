//
//  AppDelegate.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//
import UIKit
import Firebase
import Cloudinary

extension Notification.Name {
    static let didReceivePasswordResetLink = Notification.Name("didReceivePasswordResetLink")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }

    // Universal Links (recommended path with Associated Domains)
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        // Broadcast to SwiftUI
        NotificationCenter.default.post(name: .didReceivePasswordResetLink, object: url)
        return true
    }

    // Fallback: custom URL schemes if you later add one
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        NotificationCenter.default.post(name: .didReceivePasswordResetLink, object: url)
        return true
    }
}

// MARK: - Cloudinary Manager (Unsigned upload for development)
class CloudinaryManager {
    static let shared = CloudinaryManager()
    
    private let cloudName = "dzgxc4ri3"
    private let uploadPreset = "iOS_uploads" // Your unsigned upload preset
    
    private init() {}
    
    // Upload with unsigned preset (no signature needed)
    // Note: publicId parameter is ignored for unsigned uploads, but accepted for compatibility
    func upload(data: Data, publicId: String? = nil) async throws -> URL {
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add upload preset (required for unsigned uploads)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // Add folder parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("profile_photos\r\n".data(using: .utf8)!)
        
        // Add the file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "com.cloudinary.error", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            // Parse error message from response
            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("Cloudinary error: \(message)")
                throw NSError(domain: "com.cloudinary.error", code: httpResponse.statusCode,
                             userInfo: ["statusCode": httpResponse.statusCode, "message": message])
            }
            throw NSError(domain: "com.cloudinary.error", code: httpResponse.statusCode,
                         userInfo: ["statusCode": httpResponse.statusCode, "message": "Upload failed"])
        }
        
        // Parse the response to get the secure URL
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let secureUrl = json["secure_url"] as? String,
              let url = URL(string: secureUrl) else {
            throw NSError(domain: "com.cloudinary.error", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to parse URL from response"])
        }
        
        return url
    }
}
