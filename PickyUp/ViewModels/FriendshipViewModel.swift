//
//  FriendshipViewModel.swift
//  PickyUp
//
//  Created by dawid on 11/4/25
//  Updated 11/11/25
//

import SwiftUI
import FirebaseFirestore

@MainActor
class FriendshipViewModel: ObservableObject {
    @Published var friends: [Friendship] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var friendsListener: ListenerRegistration?
    private var pendingListener: ListenerRegistration?
    
    init() {}
    
    func blockUser(currentUserId: String, targetUserId: String) async {
        do {
            try await FriendshipService.shared.blockUser(currentUserId: currentUserId, targetUserId: targetUserId)
            successMessage = "User blocked."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    // MARK: - Listeners
    func startListening(userId: String) {
        removeListeners()
        
        friendsListener = FriendshipService.shared.listenToFriends(userId: userId) { [weak self] friends in
            self?.friends = friends
        }
        
        pendingListener = FriendshipService.shared.listenToPendingRequests(userId: userId) { [weak self] pending in
            self?.pendingRequests = pending
        }
    }
    
    func removeListeners() {
        friendsListener?.remove()
        pendingListener?.remove()
        friendsListener = nil
        pendingListener = nil
    }
    
    // MARK: - Friend Requests
    func sendFriendRequest(to recipientId: String, from userId: String) async {
        do {
            try await FriendshipService.shared.sendFriendRequest(from: userId, to: recipientId)
            successMessage = "Friend request sent!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func acceptFriendRequest(friendshipId: String, userId: String) async {
        do {
            try await FriendshipService.shared.acceptFriendRequest(friendshipId: friendshipId, userId: userId)
            successMessage = "Friend request accepted!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func declineFriendRequest(friendshipId: String) async {
        do {
            try await FriendshipService.shared.declineFriendRequest(friendshipId: friendshipId)
            successMessage = "Friend request declined."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeFriend(friendshipId: String, userId: String) async {
        do {
            try await FriendshipService.shared.removeFriend(friendshipId: friendshipId, userId: userId)
            successMessage = "Friend removed."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func unblockUser(friendshipId: String, userId: String) async {
        do {
            try await FriendshipService.shared.unblockUser(friendshipId: friendshipId, userId: userId)
            successMessage = "User unblocked."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helpers
    func otherUserId(for friendship: Friendship, currentUserId: String) -> String {
        return friendship.otherUserId(currentUserId: currentUserId)
    }
    
    func isRequester(_ friendship: Friendship, userId: String) -> Bool {
        return friendship.isRequester(userId: userId)
    }
    
    func isReceiver(_ friendship: Friendship, userId: String) -> Bool {
        return friendship.isReceiver(userId: userId)
    }
}
