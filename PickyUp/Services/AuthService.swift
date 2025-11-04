import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    var currentUserId: String? {
        return auth.currentUser?.uid
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        let newUser = User(
            id: result.user.uid,
            email: email,
            displayName: displayName,
            profilePhotoURL: nil,
            createdAt: Date()
        )
        
        try await db.collection("users").document(result.user.uid).setData([
            "email": email,
            "displayName": displayName,
            "createdAt": Timestamp(date: Date())
        ])
        
        return newUser
    }
    
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return User(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            profilePhotoURL: data["profilePhotoURL"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func updateUserProfile(userId: String, displayName: String?, profilePhotoURL: String?) async throws {
        var updateData: [String: Any] = [:]
        
        if let displayName = displayName {
            updateData["displayName"] = displayName
        }
        
        if let profilePhotoURL = profilePhotoURL {
            updateData["profilePhotoURL"] = profilePhotoURL
        }
        
        if !updateData.isEmpty {
            try await db.collection("users").document(userId).updateData(updateData)
        }
    }
}
