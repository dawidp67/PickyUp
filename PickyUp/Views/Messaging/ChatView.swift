//
// ChatView.swift
//
// Views/Messaging/ChatView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    
    let conversationId: String
    
    @State private var messageText = ""
    @State private var conversation: Conversation?
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messagingViewModel.currentMessages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == authViewModel.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messagingViewModel.currentMessages.count) { _, _ in
                    if let lastMessage = messagingViewModel.currentMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(getConversationTitle())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            messagingViewModel.setupMessagesListener(conversationId: conversationId)
            loadConversation()
        }
        .onDisappear {
            messagingViewModel.clearSelection()
        }
    }
    
    private func loadConversation() {
        conversation = messagingViewModel.conversations.first { $0.id == conversationId }
    }
    
    private func getConversationTitle() -> String {
        guard let conv = conversation else { return "Chat" }
        
        switch conv.type {
        case .directMessage:
            return conv.otherUserName(currentUserId: authViewModel.currentUser?.id ?? "") ?? "Chat"
        case .groupChat:
            return conv.groupName ?? "Group Chat"
        case .gameAnnouncement:
            return conv.groupName ?? "Game Chat"
        }
    }
    
    private func sendMessage() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let textToSend = messageText
        messageText = ""
        
        Task {
            await messagingViewModel.sendMessage(
                text: textToSend,
                conversationId: conversationId,
                senderId: userId,
                senderName: userName
            )
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
