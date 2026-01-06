import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var messageService = MessageService()
    @State private var searchText = ""

    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return messageService.conversations
        }
        return messageService.conversations.filter {
            $0.otherUserName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if messageService.isLoading {
                    ProgressView()
                } else if messageService.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No messages yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Messages with customers and employees will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredConversations) { conversation in
                            NavigationLink {
                                ConversationView(conversation: conversation)
                            } label: {
                                ConversationRow(conversation: conversation)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .searchable(text: $searchText, prompt: "Search conversations")
            .task {
                if let userId = authManager.currentUser?.id {
                    try? await messageService.fetchConversations(for: userId)
                }
            }
            .refreshable {
                if let userId = authManager.currentUser?.id {
                    try? await messageService.fetchConversations(for: userId)
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.headline)

                    Spacer()

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.formattedTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConversationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var messageService = MessageService()

    let conversation: Conversation
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messageService.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authManager.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messageService.messages.count) { _, _ in
                    if let lastMessage = messageService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(messageText.isEmpty ? Color.gray : Color.green)
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            messageService.listenToMessages(conversationId: conversation.id)
            markAsRead()
        }
        .onDisappear {
            messageService.stopListening()
        }
    }

    func sendMessage() {
        guard let currentUser = authManager.currentUser else { return }

        Task {
            try? await messageService.sendMessage(
                conversationId: conversation.id,
                senderId: currentUser.id,
                senderName: currentUser.name,
                receiverId: conversation.otherUserId,
                content: messageText,
                appointmentId: conversation.appointmentId
            )
            messageText = ""
        }
    }

    func markAsRead() {
        guard let userId = authManager.currentUser?.id else { return }

        Task {
            try? await messageService.markConversationAsRead(
                conversationId: conversation.id,
                userId: userId
            )
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromCurrentUser ? Color.green : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isFromCurrentUser { Spacer() }
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(AuthenticationManager())
}
