//
//  FriendshipService.swift
//  PickyUp
//
//  Created by dawid on 11/4/25
//  Updated 11/16/25
//

import Foundation
import FirebaseFirestore

class FriendshipService {
    static let shared = FriendshipService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Send Friend Request
    func sendFriendRequest(from userId: String, to recipientId: String) async throws {
        let friendshipId = Friendship.generateId(userId1: userId, userId2: recipientId)
        
        let friendship = Friendship(
            id: friendshipId,
            userId1: [userId, recipientId].sorted()[0],
            userId2: [userId, recipientId].sorted()[1],
            status: .pending,
            requesterId: userId,
            createdAt: Date(),
            acceptedAt: nil
        )
        
        try db.collection("friendships").document(friendshipId).setData(from: friendship)
        
        // Create notification for recipient
        do {
            let senderUser = try await UserService.shared.getUser(userId: userId)
            try await NotificationService.shared.createNotification(
                userId: recipientId,
                type: .friendRequest,
                title: "Friend Request",
                message: "\(senderUser.displayName) sent you a friend request",
                fromUserId: userId,
                friendshipId: friendshipId
            )
            print("✅ Friend request notification sent to \(recipientId)")
        } catch {
            print("⚠️ Failed to create friend request notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(friendshipId: String, userId: String) async throws {
        // Get the friendship to find the requester
        let friendshipDoc = try await db.collection("friendships").document(friendshipId).getDocument()
        guard let friendship = try? friendshipDoc.data(as: Friendship.self) else {
            throw NSError(domain: "FriendshipService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
        }
        
        // Update friendship status
        try await db.collection("friendships").document(friendshipId)
            .updateData([
                "status": "accepted",
                "acceptedAt": Date()
            ])
        
        // Notify the requester that their request was accepted
        let requesterId = friendship.requesterId
        if requesterId != userId {
            do {
                let accepterUser = try await UserService.shared.getUser(userId: userId)
                try await NotificationService.shared.createNotification(
                    userId: requesterId,
                    type: .friendAccepted,
                    title: "Friend Request Accepted",
                    message: "\(accepterUser.displayName) accepted your friend request",
                    fromUserId: userId,
                    friendshipId: friendshipId
                )
                print("✅ Friend request accepted notification sent to \(requesterId)")
            } catch {
                print("⚠️ Failed to create friend accepted notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Decline Friend Request
    func declineFriendRequest(friendshipId: String) async throws {
        try await db.collection("friendships").document(friendshipId).delete()
    }
    
    // MARK: - Remove Friend
    func removeFriend(friendshipId: String, userId: String) async throws {
        try await db.collection("friendships").document(friendshipId).delete()
    }
    
    // MARK: - Get Friendship Status
    func getFriendshipStatus(userId1: String, userId2: String) async throws -> Friendship? {
        let friendshipId = Friendship.generateId(userId1: userId1, userId2: userId2)
        
        let document = try await db.collection("friendships").document(friendshipId).getDocument()
        
        if document.exists {
            return try document.data(as: Friendship.self)
        }
        
        return nil
    }
    
    // MARK: - Block User
    func blockUser(currentUserId: String, targetUserId: String) async throws {
        let friendshipId = Friendship.generateId(userId1: currentUserId, userId2: targetUserId)
        
        // Check if friendship exists
        let document = try await db.collection("friendships").document(friendshipId).getDocument()
        
        if document.exists {
            // Update existing friendship to blocked
            try await db.collection("friendships").document(friendshipId)
                .updateData([
                    "status": "blocked",
                    "blockerId": currentUserId,
                    "blockedAt": Date()
                ])
        } else {
            // Create new blocked friendship
            let friendship = Friendship(
                id: friendshipId,
                userId1: [currentUserId, targetUserId].sorted()[0],
                userId2: [currentUserId, targetUserId].sorted()[1],
                status: .blocked,
                requesterId: currentUserId,
                createdAt: Date(),
                acceptedAt: nil
            )
            
            try db.collection("friendships").document(friendshipId).setData(from: friendship)
        }
    }
    
    // MARK: - Unblock User
    func unblockUser(friendshipId: String, userId: String) async throws {
        try await db.collection("friendships").document(friendshipId)
            .updateData(["status": "accepted"])
    }
}

// MARK: - Listener Extension
extension FriendshipService {
    
    // Listen to accepted friends for a user
    func listenToFriends(userId: String, completion: @escaping ([Friendship]) -> Void) -> ListenerRegistration {
        let query1 = db.collection("friendships")
            .whereField("status", isEqualTo: "accepted")
            .whereField("userId1", isEqualTo: userId)
        
        let query2 = db.collection("friendships")
            .whereField("status", isEqualTo: "accepted")
            .whereField("userId2", isEqualTo: userId)
        
        let listener = query1.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else { completion([]); return }
            var friends = snapshot.documents.compactMap { try? $0.data(as: Friendship.self) }
            
            query2.getDocuments { snapshot2, error2 in
                if let snapshot2 = snapshot2 {
                    let friends2 = snapshot2.documents.compactMap { try? $0.data(as: Friendship.self) }
                    friends.append(contentsOf: friends2)
                    completion(friends)
                } else {
                    completion(friends)
                }
            }
        }
        
        return listener
    }
    
    // Listen to pending requests where current user is receiver
    func listenToPendingRequests(userId: String, completion: @escaping ([Friendship]) -> Void) -> ListenerRegistration {
        return db.collection("friendships")
            .whereField("status", isEqualTo: "pending")
            .whereField("userId2", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { completion([]); return }
                let pending = snapshot.documents.compactMap { try? $0.data(as: Friendship.self) }
                completion(pending)
            }
    }
}
