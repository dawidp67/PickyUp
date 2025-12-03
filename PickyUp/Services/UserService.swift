//
// UserService.swift
//
// Services/UserService.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore
import FirebaseAuth

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Create User
    func createUser(_ user: AppUser) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID is required"])
        }
        
        try db.collection("users").document(userId).setData(from: user)
        
        let searchTokens = generateSearchTokens(from: user.displayName) + generateSearchTokens(from: user.email)
        try await db.collection("users").document(userId).updateData([
            "searchTokens": searchTokens
        ])
        
        let settings = UserSettings.default
        var settingsWithId = settings
        settingsWithId.userId = userId
        try db.collection("userSettings").document(userId).setData(from: settingsWithId)
    }
    
    // MARK: - Migration: Add Search Tokens to Existing Users
    func migrateUsersAddSearchTokens() async throws {
        print("🔄 Starting user search token migration...")
        
        let snapshot = try await db.collection("users").getDocuments()
        
        var updatedCount = 0
        var skippedCount = 0
        
        for document in snapshot.documents {
            let userId = document.documentID
            let data = document.data()
            
            if data["searchTokens"] != nil {
                skippedCount += 1
                continue
            }
            
            guard let displayName = data["displayName"] as? String,
                  let email = data["email"] as? String else {
                print("⚠️ Skipping user \(userId) - missing displayName or email")
                skippedCount += 1
                continue
            }
            
            let searchTokens = generateSearchTokens(from: displayName) + generateSearchTokens(from: email)
            
            try await db.collection("users").document(userId).updateData([
                "searchTokens": searchTokens
            ])
            
            updatedCount += 1
            print("✅ Updated user: \(displayName) (\(userId))")
        }
        
        print("✅ Migration complete! Updated: \(updatedCount), Skipped: \(skippedCount)")
    }
    
    // MARK: - Generate Search Tokens
    private func generateSearchTokens(from text: String) -> [String] {
        let lowercased = text.lowercased()
        var tokens: Set<String> = []
        
        tokens.insert(lowercased)
        
        let words = lowercased.split(separator: " ")
        for word in words {
            tokens.insert(String(word))
            for i in 1...min(word.count, 10) {
                let prefix = String(word.prefix(i))
                tokens.insert(prefix)
            }
        }
        
        return Array(tokens)
    }
    
    // MARK: - Get User
    func getUser(userId: String) async throws -> AppUser {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = try? document.data(as: AppUser.self) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return user
    }
    
    // MARK: - Fetch User (alias for getUser)
    func fetchUser(userId: String) async throws -> AppUser {
        return try await getUser(userId: userId)
    }
    
    // MARK: - Update User
    func updateUser(userId: String, updates: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(updates)
    }
    
    // MARK: - Search Users (Optimized)
    func searchUsers(query: String, currentUserId: String) async throws -> [AppUser] {
        guard query.count >= 2 else { return [] }
        
        let lowercaseQuery = query.lowercased()
        
        let snapshot = try await db.collection("users")
            .whereField("searchTokens", arrayContains: lowercaseQuery)
            .limit(to: 20)
            .getDocuments()
        
        let users = snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
        
        return users.filter { $0.id != currentUserId }
    }
    
    // MARK: - Get Multiple Users
    func getUsers(userIds: [String]) async throws -> [AppUser] {
        guard !userIds.isEmpty else { return [] }
        
        var users: [AppUser] = []
        
        let batches = stride(from: 0, to: userIds.count, by: 10).map {
            Array(userIds[$0..<min($0 + 10, userIds.count)])
        }
        
        for batch in batches {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()
            
            let batchUsers = snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
            users.append(contentsOf: batchUsers)
        }
        
        return users
    }
    
    // MARK: - User Settings
    func getUserSettings(userId: String) async throws -> UserSettings {
        let document = try await db.collection("userSettings").document(userId).getDocument()
        
        if let settings = try? document.data(as: UserSettings.self) {
            return settings
        } else {
            var defaultSettings = UserSettings.default
            defaultSettings.userId = userId
            try db.collection("userSettings").document(userId).setData(from: defaultSettings)
            return defaultSettings
        }
    }
    
    func updateUserSettings(userId: String, updates: [String: Any]) async throws {
        try await db.collection("userSettings").document(userId).updateData(updates)
    }
    
    // MARK: - User Privacy Settings (per-user)
    func getUserPrivacySettings(userId: String, targetUserId: String) async throws -> UserPrivacySettings {
        let settingsId = "\(userId)_\(targetUserId)"
        let document = try await db.collection("userPrivacySettings").document(settingsId).getDocument()
        
        if let settings = try? document.data(as: UserPrivacySettings.self) {
            return settings
        } else {
            return UserPrivacySettings.defaultSettings(userId: userId, targetUserId: targetUserId)
        }
    }
    
    func updateUserPrivacySettings(userId: String, targetUserId: String, updates: [String: Any]) async throws {
        let settingsId = "\(userId)_\(targetUserId)"
        let docRef = db.collection("userPrivacySettings").document(settingsId)
        
        let document = try await docRef.getDocument()
        
        if document.exists {
            try await docRef.updateData(updates)
        } else {
            var settings = UserPrivacySettings.defaultSettings(userId: userId, targetUserId: targetUserId)
            
            if let allowDM = updates["allowDirectMessages"] as? Bool {
                settings.allowDirectMessages = allowDM
            }
            if let allowGroup = updates["allowGroupMessages"] as? Bool {
                settings.allowGroupMessages = allowGroup
            }
            if let showGames = updates["showGames"] as? Bool {
                settings.showGames = showGames
            }
            if let canCollab = updates["canCollaborate"] as? Bool {
                settings.canCollaborate = canCollab
            }
            
            try docRef.setData(from: settings)
        }
    }
    
    // MARK: - Delete User
    func deleteUser(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
        try await db.collection("userSettings").document(userId).delete()
    }
}
