//
// MessagingViewModel.swift
//
// ViewModels/MessagingViewModel.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

@MainActor
class MessagingViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentMessages: [Message] = []
    @Published var selectedConversation: Conversation?
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let messagingService = MessagingService.shared
    private let userService = UserService.shared
    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    
    deinit {
        conversationsListener?.remove()
        messagesListener?.remove()
    }
    
    // MARK: - Setup Conversations Listener
    func setupConversationsListener(userId: String) {
        conversationsListener = messagingService.listenToConversations(userId: userId) { [weak self] conversations in
            Task { @MainActor in
                self?.conversations = conversations
            }
        }
    }
    
    // MARK: - Setup Messages Listener
    func setupMessagesListener(conversationId: String) {
        messagesListener?.remove()
        
        messagesListener = messagingService.listenToMessages(conversationId: conversationId) { [weak self] messages in
            Task { @MainActor in
                self?.currentMessages = messages
            }
        }
    }
    
    // MARK: - Search Users
    func searchUsers(query: String, currentUserId: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let users = try await userService.searchUsers(query: query, currentUserId: currentUserId)
            searchResults = users
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
        
        isLoading = false
    }
    
    // MARK: - Start DM Conversation
    func startDMConversation(
        withUser user: User,
        currentUserId: String,
        currentUserName: String
    ) async -> Conversation? {
        guard let otherUserId = user.id else { return nil }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let conversation = try await messagingService.getOrCreateDMConversation(
                userId1: currentUserId,
                userId2: otherUserId,
                userName1: currentUserName,
                userName2: user.displayName
            )
            
            selectedConversation = conversation
            setupMessagesListener(conversationId: conversation.id!)
            
            isLoading = false
            return conversation
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Create Group Chat
    func createGroupChat(
        name: String,
        participants: [User],
        currentUserId: String,
        currentUserName: String
    ) async {
        isLoading = true
        errorMessage = nil
        
        var participantIds = participants.compactMap { $0.id }
        participantIds.append(currentUserId)
        
        var participantNames: [String: String] = [:]
        for user in participants {
            if let userId = user.id {
                participantNames[userId] = user.displayName
            }
        }
        participantNames[currentUserId] = currentUserName
        
        do {
            let conversationId = try await messagingService.createGroupChat(
                name: name,
                participantIds: participantIds,
                participantNames: participantNames,
                creatorId: currentUserId
            )
            
            successMessage = "Group chat created!"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Send Message
    func sendMessage(
        text: String,
        conversationId: String,
        senderId: String,
        senderName: String
    ) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            _ = try await messagingService.sendMessage(
                conversationId: conversationId,
                senderId: senderId,
                senderName: senderName,
                text: text
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Mark Message as Read
    func markMessageAsRead(messageId: String, conversationId: String, userId: String) async {
        do {
            try await messagingService.markMessageAsRead(
                conversationId: conversationId,
                messageId: messageId,
                userId: userId
            )
        } catch {
            print("Error marking message as read: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Conversation
    func deleteConversation(conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await messagingService.deleteConversation(conversationId: conversationId)
            conversations.removeAll { $0.id == conversationId }
            
            if selectedConversation?.id == conversationId {
                selectedConversation = nil
                messagesListener?.remove()
                currentMessages = []
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Add Participant to Group
    func addParticipantToGroup(conversationId: String, user: User) async {
        guard let userId = user.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await messagingService.addParticipant(
                conversationId: conversationId,
                userId: userId,
                userName: user.displayName
            )
            
            successMessage = "\(user.displayName) added to group"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Remove Participant from Group
    func removeParticipantFromGroup(conversationId: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await messagingService.removeParticipant(
                conversationId: conversationId,
                userId: userId
            )
            
            successMessage = "Participant removed from group"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Get Unread Message Count
    func getUnreadCount(for conversation: Conversation, currentUserId: String) -> Int {
        // This would need to be implemented with a query
        // For now, return 0
        return 0
    }
    
    // MARK: - Select Conversation
    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
        if let conversationId = conversation.id {
            setupMessagesListener(conversationId: conversationId)
        }
    }
    
    // MARK: - Clear Selection
    func clearSelection() {
        selectedConversation = nil
        messagesListener?.remove()
        currentMessages = []
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
