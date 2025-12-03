//
//AuthService
//
//Updated 11/13/25
//
//
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
    
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            let newUser = AppUser(
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
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }
    
    func updateEmail(newEmail: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        do {
            try await user.updateEmail(to: newEmail)
            try await db.collection("users").document(user.uid).updateData([
                "email": newEmail
            ])
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }
    
    func updatePassword(newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        do {
            try await user.updatePassword(to: newPassword)
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }
    
    func updateDisplayName(userId: String, newDisplayName: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "displayName": newDisplayName
        ])
    }
    
    func fetchUser(userId: String) async throws -> AppUser {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return AppUser(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            profilePhotoURL: data["profilePhotoURL"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func searchUsers(keyword: String) async throws -> [AppUser] {
        guard !keyword.isEmpty else { return [] }
        
        let lowercaseKeyword = keyword.lowercased()
        
        let snapshot = try await db.collection("users")
            .limit(to: 100)
            .getDocuments()
        
        var allUsers: [AppUser] = []
        
        for document in snapshot.documents {
            if let user = try? document.data(as: AppUser.self) {
                allUsers.append(user)
            }
        }
        
        let filteredUsers = allUsers.filter { user in
            let nameMatches = user.displayName.lowercased().contains(lowercaseKeyword)
            let emailMatches = user.email.lowercased().contains(lowercaseKeyword)
            return nameMatches || emailMatches
        }
        
        print("🔍 Search keyword: '\(keyword)'")
        print("🔍 Total users fetched: \(allUsers.count)")
        print("🔍 Filtered results: \(filteredUsers.count)")
        
        return filteredUsers
    }
    
    // Custom error handling
    enum AuthError: LocalizedError {
        case wrongPassword
        case userNotFound
        case invalidEmail
        case emailAlreadyInUse
        case weakPassword
        case networkError
        case notAuthenticated
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .wrongPassword:
                return "Incorrect password. Please try again."
            case .userNotFound:
                return "No account found with this email."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .emailAlreadyInUse:
                return "An account with this email already exists."
            case .weakPassword:
                return "Password is too weak. Use at least 6 characters."
            case .networkError:
                return "Network error. Please check your connection."
            case .notAuthenticated:
                return "You must be logged in to perform this action."
            case .unknown(let message):
                return message
            }
        }
        
        static func from(_ error: NSError) -> AuthError {
            guard let errorCode = AuthErrorCode(_bridgedNSError: error) else {
                return .unknown(error.localizedDescription)
            }
            
            switch errorCode.code {
            case .wrongPassword:
                return .wrongPassword
            case .userNotFound:
                return .userNotFound
            case .invalidEmail:
                return .invalidEmail
            case .emailAlreadyInUse:
                return .emailAlreadyInUse
            case .weakPassword:
                return .weakPassword
            case .networkError:
                return .networkError
            default:
                return .unknown(error.localizedDescription)
            }
        }
    }
}
