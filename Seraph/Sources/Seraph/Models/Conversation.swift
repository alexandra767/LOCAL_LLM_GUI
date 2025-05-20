import Foundation
import SwiftUI
import Combine

/// Represents a conversation in the app, containing a series of messages between the user and the AI.
/// This class is observable and codable for persistence.
public final class Conversation: ConversationProtocol, ObservableObject, Identifiable, Sendable, Codable {
    public typealias MessageType = Message
    
    // MARK: - Properties
    
    public let id: UUID
    public var title: String
    public var lastMessage: String
    public var timestamp: Date
    public var unreadCount: Int
    public var projectId: UUID?
    public var systemPrompt: String
    @Published public var messages: [Message] {
        didSet {
            if let lastMessage = messages.last {
                self.lastMessage = lastMessage.content
                self.timestamp = lastMessage.timestamp
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Creates a new conversation
    /// - Parameters:
    ///   - id: The unique identifier for the conversation
    ///   - title: The title of the conversation
    ///   - lastMessage: The last message in the conversation
    ///   - timestamp: When the conversation was last updated
    ///   - unreadCount: Number of unread messages
    ///   - projectId: Optional project ID this conversation belongs to
    ///   - systemPrompt: The system prompt for this conversation
    ///   - messages: Array of messages in the conversation
    public init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        lastMessage: String = "",
        timestamp: Date = Date(),
        unreadCount: Int = 0,
        projectId: UUID? = nil,
        systemPrompt: String = "",
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.unreadCount = unreadCount
        self.projectId = projectId
        self.systemPrompt = systemPrompt
        self.messages = messages
        
        // If no title is provided, generate one from the first message
        if title == "New Conversation", let firstMessage = messages.first(where: { !$0.content.isEmpty }) {
            self.title = String(firstMessage.content.prefix(30)) + (firstMessage.content.count > 30 ? "..." : "")
        }
    }
    
    // MARK: - ConversationProtocol Conformance
    
    public func addMessage(_ message: Message) {
        DispatchQueue.main.async { [weak self] in
            self?.messages.append(message)
            self?.lastMessage = message.content
            self?.timestamp = message.timestamp
            if !message.isFromUser {
                self?.unreadCount += 1
            }
        }
    }
    
    public func markAsRead() {
        DispatchQueue.main.async { [weak self] in
            self?.unreadCount = 0
        }
    }
    
    public func updateTitle(_ newTitle: String) {
        DispatchQueue.main.async { [weak self] in
            self?.title = newTitle
        }
    }
    
    public func moveToProject(_ projectId: UUID?) {
        DispatchQueue.main.async { [weak self] in
            self?.projectId = projectId
        }
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, title, lastMessage, timestamp, unreadCount, projectId, systemPrompt, messages
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        messages = try container.decode([Message].self, forKey: .messages)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(messages, forKey: .messages)
    }
}

// MARK: - Equatable

extension Conversation: Equatable {
    public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Conversation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Data

#if DEBUG
extension Conversation {
    public static let sample = Conversation(
        title: "Sample Conversation",
        lastMessage: "This is a sample message",
        timestamp: Date(),
        unreadCount: 1,
        messages: [
            Message(content: "Hello!", timestamp: Date(), isFromUser: true),
            Message(content: "Hi there! How can I help you today?", timestamp: Date(), isFromUser: false)
        ]
    )
    
    public static func createSampleConversation(title: String, messageCount: Int) -> Conversation {
        let conversation = Conversation(title: title)
        
        for i in 0..<messageCount {
            let isUser = i % 2 == 0
            let message = Message(
                content: "\(isUser ? "User" : "AI") message \(i + 1) in \(title)",
                timestamp: Date(),
                isFromUser: isUser
            )
            conversation.addMessage(message)
        }
        
        return conversation
    }
}
#endif
