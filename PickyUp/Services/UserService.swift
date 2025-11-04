//
//  UserService.swift
//  PickyUp
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class UserService: ObservableObject {
    static let shared = UserService()
    private init() {}

    let db = Firestore.firestore()
    @Published var currentUser: User?
    @Published var errorMessage: String?

    // MARK: - Create Account
    func createUser(email: String, password: String, displayName: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            let data: [String: Any] = [
                "email": email,
                "displayName": displayName,
                "createdAt": Timestamp(date: Date())
            ]
            try await db.collection("users").document(uid).setData(data)

            self.currentUser = User(
                id: uid,
                email: email,
                displayName: displayName,
                profilePhotoURL: nil,
                createdAt: Date()
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await loadUser(userId: result.user.uid)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load User
    func loadUser(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "UserService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "User not found"
            ])
        }

        self.currentUser = User(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            profilePhotoURL: data["profilePhotoURL"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    // MARK: - Update Profile
    func updateUserProfile(userId: String, displayName: String? = nil, profilePhotoURL: String? = nil) async {
        var updates: [String: Any] = [:]
        if let displayName = displayName { updates["displayName"] = displayName }
        if let profilePhotoURL = profilePhotoURL { updates["profilePhotoURL"] = profilePhotoURL }
        updates["updatedAt"] = Timestamp(date: Date())

        do {
            try await db.collection("users").document(userId).updateData(updates)
            try await loadUser(userId: userId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Extra Helpers
    func currentUserId() -> String? {
        Auth.auth().currentUser?.uid
    }

    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "UserService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "User not found"
            ])
        }

        return User(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            profilePhotoURL: data["profilePhotoURL"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func updateUserBio(userId: String, bio: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "bio": bio,
            "updatedAt": Timestamp(date: Date())
        ])
    }
}
