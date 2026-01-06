import Foundation
import FirebaseFirestore

@MainActor
class MessageService: ObservableObject {
    private let db = Firestore.firestore()
    private let collection = "conversations"

    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false

    private var messagesListener: ListenerRegistration?

    // MARK: - Fetch Conversations
    func fetchConversations(for userId: UUID) async throws {
        isLoading = true

        let snapshot = try await db.collection(collection)
            .whereField("participantIds", arrayContains: userId.uuidString)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments()

        var fetchedConversations: [Conversation] = []

        for doc in snapshot.documents {
            let data = doc.data()
            let participantIds = data["participantIds"] as? [String] ?? []
            let participantNames = data["participantNames"] as? [String: String] ?? [:]

            // Find the other user
            let otherUserId = participantIds.first { $0 != userId.uuidString }
            guard let otherIdString = otherUserId, let otherUUID = UUID(uuidString: otherIdString) else { continue }

            let otherUserName = participantNames[otherIdString] ?? "Unknown"
            let appointmentIdString = data["appointmentId"] as? String
            let appointmentId = appointmentIdString.flatMap { UUID(uuidString: $0) }
            let unreadCount = data["unreadCount_\(userId.uuidString)"] as? Int ?? 0

            let conversation = Conversation(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                otherUserId: otherUUID,
                otherUserName: otherUserName,
                appointmentId: appointmentId,
                lastMessage: nil,
                unreadCount: unreadCount
            )

            fetchedConversations.append(conversation)
        }

        conversations = fetchedConversations
        isLoading = false
    }

    // MARK: - Listen to Messages
    func listenToMessages(conversationId: UUID) {
        messagesListener?.remove()

        messagesListener = db.collection(collection)
            .document(conversationId.uuidString)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                let fetchedMessages = documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }

                Task { @MainActor in
                    self?.messages = fetchedMessages
                }
            }
    }

    func stopListening() {
        messagesListener?.remove()
        messagesListener = nil
    }

    // MARK: - Send Message
    func sendMessage(
        conversationId: UUID,
        senderId: UUID,
        senderName: String,
        receiverId: UUID,
        content: String,
        appointmentId: UUID? = nil
    ) async throws {
        let message = Message(
            senderId: senderId,
            senderName: senderName,
            receiverId: receiverId,
            appointmentId: appointmentId,
            content: content
        )

        let data = try Firestore.Encoder().encode(message)

        // Add message to subcollection
        try await db.collection(collection)
            .document(conversationId.uuidString)
            .collection("messages")
            .document(message.id.uuidString)
            .setData(data)

        // Update conversation metadata
        try await db.collection(collection).document(conversationId.uuidString).updateData([
            "lastMessage": content,
            "lastMessageTimestamp": Date(),
            "unreadCount_\(receiverId.uuidString)": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Create or Get Conversation
    func getOrCreateConversation(
        currentUserId: UUID,
        currentUserName: String,
        otherUserId: UUID,
        otherUserName: String,
        appointmentId: UUID? = nil
    ) async throws -> UUID {
        // Check if conversation exists
        let snapshot = try await db.collection(collection)
            .whereField("participantIds", arrayContains: currentUserId.uuidString)
            .getDocuments()

        for doc in snapshot.documents {
            let participantIds = doc.data()["participantIds"] as? [String] ?? []
            if participantIds.contains(otherUserId.uuidString) {
                return UUID(uuidString: doc.documentID) ?? UUID()
            }
        }

        // Create new conversation
        let conversationId = UUID()

        var data: [String: Any] = [
            "participantIds": [currentUserId.uuidString, otherUserId.uuidString],
            "participantNames": [
                currentUserId.uuidString: currentUserName,
                otherUserId.uuidString: otherUserName
            ],
            "createdAt": Date(),
            "lastMessageTimestamp": Date(),
            "unreadCount_\(currentUserId.uuidString)": 0,
            "unreadCount_\(otherUserId.uuidString)": 0
        ]

        if let appointmentId = appointmentId {
            data["appointmentId"] = appointmentId.uuidString
        }

        try await db.collection(collection).document(conversationId.uuidString).setData(data)

        return conversationId
    }

    // MARK: - Mark as Read
    func markConversationAsRead(conversationId: UUID, userId: UUID) async throws {
        try await db.collection(collection).document(conversationId.uuidString).updateData([
            "unreadCount_\(userId.uuidString)": 0
        ])

        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].unreadCount = 0
        }
    }
}
