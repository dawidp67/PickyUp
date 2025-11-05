//
// ConversationView.swift
//
// Views/Messaging/ConversationView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct ConversationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    
    let conversation: Conversation
    @State private var messageText = ""
    @State private var showingParticipants = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messagingViewModel.currentMessages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isFromCurrentUser: message.senderId == authViewModel.currentUser?.id
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
                
                Divider()
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle(getConversationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if conversation.type != .directMessage {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingParticipants = true
                        } label: {
                            Image(systemName: "person.2")
                        }
                    }
                }
            }
            .onAppear {
                if let conversationId = conversation.id {
                    messagingViewModel.setupMessagesListener(conversationId: conversationId)
                }
            }
            .onDisappear {
                messagingViewModel.clearSelection()
            }
            .sheet(isPresented: $showingParticipants) {
                ParticipantsView(conversation: conversation)
                    .environmentObject(messagingViewModel)
            }
        }
    }
    
    private func getConversationTitle() -> String {
        guard let currentUserId = authViewModel.currentUser?.id else { return "Chat" }
        
        switch conversation.type {
        case .directMessage:
            return conversation.otherUserName(currentUserId: currentUserId) ?? "Chat"
        case .groupChat, .gameAnnouncement:
            return conversation.groupName ?? "Group Chat"
        }
    }
    
    private func sendMessage() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName,
              let conversationId = conversation.id else { return }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await messagingViewModel.sendMessage(
                text: text,
                conversationId: conversationId,
                senderId: userId,
                senderName: userName
            )
        }
    }
}

// MARK: - Message Bubble
struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(message.text)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Participants View
struct ParticipantsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    
    let conversation: Conversation
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(conversation.participantNames.keys), id: \.self) { userId in
                    if let userName = conversation.participantNames[userId] {
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text(getInitials(userName))
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            
                            Text(userName)
                                .font(.headline)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}
