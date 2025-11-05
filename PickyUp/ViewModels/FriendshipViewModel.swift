//
// FriendshipViewModel.swift
//
// ViewModels/FriendshipViewModel.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

@MainActor
class FriendshipViewModel: ObservableObject {
    @Published var friends: [Friendship] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var friendUsers: [String: User] = [:]  // userId: User
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let friendshipService = FriendshipService.shared
    private let userService = UserService.shared
    private var friendsListener: ListenerRegistration?
    
    deinit {
        friendsListener?.remove()
    }
    
    // MARK: - Setup Listener
    func setupFriendsListener(userId: String) {
        friendsListener = friendshipService.listenToFriends(userId: userId) { [weak self] friendships in
            Task { @MainActor in
                self?.friends = friendships
                await self?.fetchFriendUsers(friendships: friendships, currentUserId: userId)
            }
        }
    }
    
    // MARK: - Fetch Friend Users
    private func fetchFriendUsers(friendships: [Friendship], currentUserId: String) async {
        let userIds = friendships.map { $0.otherUserId(currentUserId: currentUserId) }
        
        do {
            let users = try await userService.getUsers(userIds: userIds)
            var userDict: [String: User] = [:]
            for user in users {
                if let userId = user.id {
                    userDict[userId] = user
                }
            }
            friendUsers = userDict
        } catch {
            print("Error fetching friend users: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to userId: String, from currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            _ = try await friendshipService.sendFriendRequest(from: currentUserId, to: userId)
            successMessage = "Friend request sent!"
        } catch {
            if error.localizedDescription.contains("Already friends") {
                errorMessage = "You're already friends!"
            } else if error.localizedDescription.contains("already sent") {
                errorMessage = "Friend request already sent!"
            } else if error.localizedDescription.contains("blocked") {
                errorMessage = "Cannot send friend request"
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(friendship: Friendship, currentUserId: String) async {
        guard let friendshipId = friendship.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendshipService.acceptFriendRequest(friendshipId: friendshipId, userId: currentUserId)
            
            // Remove from pending requests
            pendingRequests.removeAll { $0.id == friendshipId }
            
            // Get other user's name for success message
            let otherUserId = friendship.otherUserId(currentUserId: currentUserId)
            if let userName = friendUsers[otherUserId]?.displayName {
                successMessage = "Added \(userName) as a friend!"
            } else {
                successMessage = "Friend request accepted!"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }
    
    // MARK: - Reject Friend Request
    func rejectFriendRequest(friendship: Friendship) async {
        guard let friendshipId = friendship.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendshipService.rejectFriendRequest(friendshipId: friendshipId)
            
            // Remove from pending requests
            pendingRequests.removeAll { $0.id == friendshipId }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Remove Friend
    func removeFriend(friendship: Friendship, currentUserId: String) async {
        guard let friendshipId = friendship.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendshipService.removeFriend(friendshipId: friendshipId)
            
            // Remove from friends list
            friends.removeAll { $0.id == friendshipId }
            
            // Get other user's name for success message
            let otherUserId = friendship.otherUserId(currentUserId: currentUserId)
            if let userName = friendUsers[otherUserId]?.displayName {
                successMessage = "Removed \(userName) from friends"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }
    
    // MARK: - Block User
    func blockUser(userId: String, currentUserId: String, userName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendshipService.blockUser(currentUserId: currentUserId, targetUserId: userId)
            successMessage = "\(userName) blocked!"
            
            // Remove from friends if they were friends
            friends.removeAll { friendship in
                friendship.userId1 == userId || friendship.userId2 == userId
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        
        // Clear success message after 3 seconds
        if successMessage != nil {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }
    
    // MARK: - Unblock User
    func unblockUser(userId: String, currentUserId: String) async {
        let sortedIds = [currentUserId, userId].sorted()
        let friendshipId = "\(sortedIds[0])_\(sortedIds[1])"
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendshipService.unblockUser(friendshipId: friendshipId)
            successMessage = "User unblocked"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Get Friendship Status
    func getFriendshipStatus(userId1: String, userId2: String) async -> Friendship? {
        do {
            return try await friendshipService.getFriendshipStatus(userId1: userId1, userId2: userId2)
        } catch {
            return nil
        }
    }
    
    // MARK: - Fetch Pending Requests
    func fetchPendingRequests(userId: String) async {
        do {
            let requests = try await friendshipService.getPendingRequests(userId: userId)
            pendingRequests = requests
            
            // Fetch users for pending requests
            let userIds = requests.map { $0.requesterId }
            let users = try await userService.getUsers(userIds: userIds)
            
            var userDict: [String: User] = [:]
            for user in users {
                if let userId = user.id {
                    userDict[userId] = user
                }
            }
            
            // Merge with existing friend users
            friendUsers.merge(userDict) { _, new in new }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Check if Friends
    func areFriends(userId1: String, userId2: String) -> Bool {
        return friends.contains { friendship in
            (friendship.userId1 == userId1 && friendship.userId2 == userId2) ||
            (friendship.userId1 == userId2 && friendship.userId2 == userId1)
        }
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
