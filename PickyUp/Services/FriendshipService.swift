//
// FriendshipService.swift
//
// Services/FriendshipService.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FriendshipService {
    static let shared = FriendshipService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Send Friend Request
    func sendFriendRequest(from senderId: String, to receiverId: String) async throws -> String {
        // Create sorted user IDs for consistent document lookup
        let sortedIds = [senderId, receiverId].sorted()
        let friendshipId = "\(sortedIds[0])_\(sortedIds[1])"
        
        // Check if friendship already exists
        let existingDoc = try await db.collection("friendships").document(friendshipId).getDocument()
        
        if existingDoc.exists {
            let friendship = try existingDoc.data(as: Friendship.self)
            if friendship.status == .blocked {
                throw NSError(domain: "FriendshipService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot send friend request to blocked user"])
            }
            if friendship.status == .accepted {
                throw NSError(domain: "FriendshipService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Already friends"])
            }
            if friendship.status == .pending {
                throw NSError(domain: "FriendshipService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"])
            }
        }
        
        let friendship = Friendship(
            id: friendshipId,
            userId1: sortedIds[0],
            userId2: sortedIds[1],
            status: .pending,
            requesterId: senderId,
            createdAt: Date(),
            acceptedAt: nil
        )
        
        try db.collection("friendships").document(friendshipId).setData(from: friendship)
        
        try await NotificationService.shared.createNotification(
            userId: receiverId,
            type: NotificationType.friendRequest,
            title: "New Friend Request",
            message: "wants to be your friend!",
            fromUserId: senderId,
            friendshipId: friendshipId
        )
        
        return friendshipId
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(friendshipId: String, userId: String) async throws {
        let docRef = db.collection("friendships").document(friendshipId)
        let document = try await docRef.getDocument()
        
        guard var friendship = try? document.data(as: Friendship.self) else {
            throw NSError(domain: "FriendshipService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
        }
        
        // Verify user is the receiver (not the requester)
        guard friendship.requesterId != userId else {
            throw NSError(domain: "FriendshipService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot accept your own request"])
        }
        
        friendship.status = .accepted
        friendship.acceptedAt = Date()
        
        try docRef.setData(from: friendship)
        
        // Notify requester that their request was accepted
        try await NotificationService.shared.createNotification(
            userId: friendship.requesterId,
            type: NotificationType.friendAccepted,
            title: "Friend Request Accepted",
            message: "accepted your friend request!",
            fromUserId: userId
        )
    }
    
    // MARK: - Reject/Cancel Friend Request
    func rejectFriendRequest(friendshipId: String) async throws {
        try await db.collection("friendships").document(friendshipId).delete()
    }
    
    // MARK: - Remove Friend
    func removeFriend(friendshipId: String) async throws {
        try await db.collection("friendships").document(friendshipId).delete()
    }
    
    // MARK: - Block User
    func blockUser(currentUserId: String, targetUserId: String) async throws {
        let sortedIds = [currentUserId, targetUserId].sorted()
        let friendshipId = "\(sortedIds[0])_\(sortedIds[1])"
        
        let friendship = Friendship(
            id: friendshipId,
            userId1: sortedIds[0],
            userId2: sortedIds[1],
            status: .blocked,
            requesterId: currentUserId,
            createdAt: Date(),
            acceptedAt: nil
        )
        
        try db.collection("friendships").document(friendshipId).setData(from: friendship)
    }
    
    // MARK: - Unblock User
    func unblockUser(friendshipId: String) async throws {
        try await db.collection("friendships").document(friendshipId).delete()
    }
    
    // MARK: - Get Friendship Status
    func getFriendshipStatus(userId1: String, userId2: String) async throws -> Friendship? {
        let sortedIds = [userId1, userId2].sorted()
        let friendshipId = "\(sortedIds[0])_\(sortedIds[1])"
        
        let document = try await db.collection("friendships").document(friendshipId).getDocument()
        
        guard document.exists else { return nil }
        return try document.data(as: Friendship.self)
    }
    
    // MARK: - Get All Friends
    func getFriends(userId: String) async throws -> [Friendship] {
        let query1 = db.collection("friendships")
            .whereField("userId1", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.accepted.rawValue)
        
        let query2 = db.collection("friendships")
            .whereField("userId2", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.accepted.rawValue)
        
        let snapshot1 = try await query1.getDocuments()
        let snapshot2 = try await query2.getDocuments()
        
        var friendships: [Friendship] = []
        
        for document in snapshot1.documents {
            if let friendship = try? document.data(as: Friendship.self) {
                friendships.append(friendship)
            }
        }
        
        for document in snapshot2.documents {
            if let friendship = try? document.data(as: Friendship.self) {
                friendships.append(friendship)
            }
        }
        
        return friendships
    }
    
    // MARK: - Get Pending Friend Requests (received)
    func getPendingRequests(userId: String) async throws -> [Friendship] {
        let query1 = db.collection("friendships")
            .whereField("userId1", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.pending.rawValue)
        
        let query2 = db.collection("friendships")
            .whereField("userId2", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.pending.rawValue)
        
        let snapshot1 = try await query1.getDocuments()
        let snapshot2 = try await query2.getDocuments()
        
        var requests: [Friendship] = []
        
        for document in snapshot1.documents {
            if let friendship = try? document.data(as: Friendship.self),
               friendship.requesterId != userId {  // Only include requests TO this user
                requests.append(friendship)
            }
        }
        
        for document in snapshot2.documents {
            if let friendship = try? document.data(as: Friendship.self),
               friendship.requesterId != userId {
                requests.append(friendship)
            }
        }
        
        return requests
    }
    
    // MARK: - Check if Blocked
    func isBlocked(userId1: String, userId2: String) async throws -> Bool {
        let friendship = try await getFriendshipStatus(userId1: userId1, userId2: userId2)
        return friendship?.status == .blocked
    }
    
    // MARK: - Listen to Friends List
    func listenToFriends(userId: String, completion: @escaping ([Friendship]) -> Void) -> ListenerRegistration {
        let query1 = db.collection("friendships")
            .whereField("userId1", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.accepted.rawValue)
        
        let query2 = db.collection("friendships")
            .whereField("userId2", isEqualTo: userId)
            .whereField("status", isEqualTo: Friendship.FriendshipStatus.accepted.rawValue)
        
        var friendships: [Friendship] = []
        var listener1Results: [Friendship] = []
        var listener2Results: [Friendship] = []
        
        let listener1 = query1.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            listener1Results = documents.compactMap { try? $0.data(as: Friendship.self) }
            completion(listener1Results + listener2Results)
        }
        
        let listener2 = query2.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            listener2Results = documents.compactMap { try? $0.data(as: Friendship.self) }
            completion(listener1Results + listener2Results)
        }
        
        // Return combined listener (will need to manage both)
        return listener1  // Note: This only removes one listener, handle properly in production
    }
}
