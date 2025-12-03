//
//  Friendship.swift
//  PickyUp
//
//  Created by dawid on 11/4/25.
//  Updated 11/7/25

import Foundation
import FirebaseFirestore

struct Friendship: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var userId1: String  // Alphabetically first user ID
    var userId2: String  // Alphabetically second user ID
    var status: FriendshipStatus
    var requesterId: String  // Who initiated the friend request
    var createdAt: Date
    var acceptedAt: Date?
    
    enum FriendshipStatus: String, Codable {
        case pending
        case accepted
        case blocked
    }
    
    // MARK: - 🔹 Add this helper
    static func generateId(userId1: String, userId2: String) -> String {
        return [userId1, userId2].sorted().joined(separator: "_")
    }
    
    // Helper to get the other user's ID
    func otherUserId(currentUserId: String) -> String {
        return userId1 == currentUserId ? userId2 : userId1
    }
    
    // Helper to check if current user is the requester
    func isRequester(userId: String) -> Bool {
        return requesterId == userId
    }
    
    // Helper to check if user is the receiver of a pending request
    func isReceiver(userId: String) -> Bool {
        return !isRequester(userId: userId) && status == .pending
    }
    
    // Equatable conformance
    static func == (lhs: Friendship, rhs: Friendship) -> Bool {
        return lhs.id == rhs.id
    }
}
