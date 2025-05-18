import Foundation

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

struct Chat: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    var isStarred: Bool
    
    init(id: UUID = UUID(), title: String, messages: [Message] = [], isStarred: Bool = false) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isStarred = isStarred
    }
}

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var chats: [Chat]
    let createdAt: Date
    var updatedAt: Date
    var isStarred: Bool
    
    init(id: UUID = UUID(), name: String, description: String = "", chats: [Chat] = [], isStarred: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.chats = chats
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isStarred = isStarred
    }
}