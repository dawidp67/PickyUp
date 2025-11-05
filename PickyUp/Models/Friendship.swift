//
//  Friendship.swift
//  PickyUp
//
//  Created by dawid on 11/4/25.
//


import Foundation
import FirebaseFirestore

struct Friendship: Codable, Identifiable {
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
    
    // Helper to get the other user's ID
    func otherUserId(currentUserId: String) -> String {
        return userId1 == currentUserId ? userId2 : userId1
    }
    
    // Helper to check if current user is the requester
    func isRequester(userId: String) -> Bool {
        return requesterId == userId
    }
}
