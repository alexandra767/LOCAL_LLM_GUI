import Foundation
import SwiftUI

class ChatConversation: Identifiable, ObservableObject, Codable, Equatable {
    static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.messages == rhs.messages &&
        lhs.lastModified == rhs.lastModified
    }
    @Published var id: UUID
    @Published var title: String
    @Published var messages: [ChatMessage]
    @Published var lastModified: Date
    
    init(id: UUID = UUID(), title: String, messages: [ChatMessage] = [], lastModified: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.lastModified = lastModified
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, messages, lastModified
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encode(lastModified, forKey: .lastModified)
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp
    }
    var id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp
    }
}

struct User: Identifiable, Codable {
    var id: UUID
    var name: String
    var email: String
    var plan: String
    
    init(id: UUID = UUID(), name: String, email: String, plan: String = "Free") {
        self.id = id
        self.name = name
        self.email = email
        self.plan = plan
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, email, plan
    }
}
