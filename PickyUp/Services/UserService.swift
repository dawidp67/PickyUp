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
    func createUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID is required"])
        }
        
        try db.collection("users").document(userId).setData(from: user)
        
        // Add search tokens for better search performance
        let searchTokens = generateSearchTokens(from: user.displayName) + generateSearchTokens(from: user.email)
        try await db.collection("users").document(userId).updateData([
            "searchTokens": searchTokens
        ])
        
        // Create default settings
        let settings = UserSettings.default
        var settingsWithId = settings
        settingsWithId.userId = userId
        try db.collection("userSettings").document(userId).setData(from: settingsWithId)
    }
    
    // MARK: - Generate Search Tokens
    private func generateSearchTokens(from text: String) -> [String] {
        let lowercased = text.lowercased()
        var tokens: Set<String> = []
        
        // Add full text
        tokens.insert(lowercased)
        
        // Add words
        let words = lowercased.split(separator: " ")
        for word in words {
            tokens.insert(String(word))
            
            // Add prefixes (for autocomplete)
            for i in 1...min(word.count, 10) {
                let prefix = String(word.prefix(i))
                tokens.insert(prefix)
            }
        }
        
        return Array(tokens)
    }
    
    // MARK: - Get User
    func getUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = try? document.data(as: User.self) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return user
    }
    
    // MARK: - Fetch User (alias for getUser)
    func fetchUser(userId: String) async throws -> User {
        return try await getUser(userId: userId)
    }
    
    // MARK: - Update User
    func updateUser(userId: String, updates: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(updates)
    }
    
    // MARK: - Search Users (Optimized)
    func searchUsers(query: String, currentUserId: String) async throws -> [User] {
        guard query.count >= 2 else { return [] }  // Require at least 2 characters
        
        let lowercaseQuery = query.lowercased()
        
        // Use array-contains to search tokens
        let snapshot = try await db.collection("users")
            .whereField("searchTokens", arrayContains: lowercaseQuery)
            .limit(to: 20)
            .getDocuments()
        
        let users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        
        // Filter out current user
        return users.filter { $0.id != currentUserId }
    }
    
    // MARK: - Get Multiple Users
    func getUsers(userIds: [String]) async throws -> [User] {
        guard !userIds.isEmpty else { return [] }
        
        var users: [User] = []
        
        // Firestore has a limit of 10 items per 'in' query
        let batches = stride(from: 0, to: userIds.count, by: 10).map {
            Array(userIds[$0..<min($0 + 10, userIds.count)])
        }
        
        for batch in batches {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()
            
            let batchUsers = snapshot.documents.compactMap { try? $0.data(as: User.self) }
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
            // Create default settings if they don't exist
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
            // Return defaults if not set
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
            // Create new settings
            var settings = UserPrivacySettings.defaultSettings(userId: userId, targetUserId: targetUserId)
            
            // Apply updates
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
        // Delete user document
        try await db.collection("users").document(userId).delete()
        
        // Delete user settings
        try await db.collection("userSettings").document(userId).delete()
        
        // Note: In production, should also clean up:
        // - All friendships
        // - All messages
        // - All notifications
        // - Auth account
    }
}
