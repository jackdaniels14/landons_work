import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let senderId: UUID
    let senderName: String
    let receiverId: UUID
    let appointmentId: UUID?
    let content: String
    let timestamp: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        senderId: UUID,
        senderName: String,
        receiverId: UUID,
        appointmentId: UUID? = nil,
        content: String,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.receiverId = receiverId
        self.appointmentId = appointmentId
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}

struct Conversation: Identifiable {
    let id: UUID
    let otherUserId: UUID
    let otherUserName: String
    let appointmentId: UUID?
    var lastMessage: Message?
    var unreadCount: Int

    init(
        id: UUID = UUID(),
        otherUserId: UUID,
        otherUserName: String,
        appointmentId: UUID? = nil,
        lastMessage: Message? = nil,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.appointmentId = appointmentId
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
    }
}
