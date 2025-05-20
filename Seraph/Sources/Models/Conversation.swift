import Foundation
import Combine
import SwiftUI
import Seraph

// Typealiases for convenience
typealias Message = Seraph.Message

/// Represents a conversation containing multiple messages
public final class Conversation: Identifiable, ObservableObject, Hashable, Codable, @unchecked Sendable {
    
    // MARK: - Type Aliases
    
    private let queue = DispatchQueue(label: "com.seraph.conversation", attributes: .concurrent)
    private enum CodingKeys: String, CodingKey {
        case id, title, lastMessage, timestamp, messages, unreadCount, systemPrompt
    }
    
    // MARK: - Properties
    
    /// A unique identifier for the conversation
    public let id: UUID
    
    /// The title of the conversation
    @Published public private(set) var title: String
    
    /// The last message in the conversation
    @Published public private(set) var lastMessage: String = ""
    
    /// The timestamp of the last activity in the conversation
    @Published public private(set) var timestamp: Date
    
    /// The list of messages in the conversation
    @Published public private(set) var messages: [Message] = []
    
    /// The number of unread messages in the conversation
    @Published public private(set) var unreadCount: Int = 0
    
    /// The system prompt used for this conversation
    @Published public var systemPrompt: String = "You are a helpful AI assistant."
    
    // MARK: - Initialization
    
    /// Creates a new conversation
    /// - Parameters:
    ///   - id: A unique identifier (defaults to a new UUID)
    ///   - title: The title of the conversation
    ///   - lastMessage: The last message in the conversation (defaults to empty string)
    ///   - timestamp: The timestamp of the last activity (defaults to current date)
    ///   - messages: The initial messages in the conversation (defaults to empty array)
    public init(
        id: UUID = UUID(),
        title: String = "",
        lastMessage: String = "",
        timestamp: Date = Date(),
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.messages = messages
    }
    
    // MARK: - Message Management
    
    /// Adds a new message to the conversation
    /// - Parameter message: The message to add
    @MainActor
    @MainActor
    public func addMessage(_ message: Message) {
        messages.append(message)
        lastMessage = message.content
        timestamp = Date()
        
        if !message.isFromUser {
            unreadCount += 1
        }
    }
    
    /// Updates the last message in the conversation
    /// - Parameter text: The new text for the last message
    @MainActor
    public func updateLastMessage(_ text: String) {
        guard !messages.isEmpty else { return }
        messages[messages.count - 1].content = text
        lastMessage = text
        timestamp = Date()
    }
    
    // MARK: - Codable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode messages as Message type
        messages = try container.decode([Message].self, forKey: .messages)
        
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt) ?? "You are a helpful AI assistant."
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Convert messages to an array of Message before encoding
        let messageArray = messages.compactMap { $0 as? Message }
        try container.encode(messageArray, forKey: .messages)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encode(systemPrompt, forKey: .systemPrompt)
    }
    
    // MARK: - Hashable & Equatable
    
    public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Conversation {
    public static var sample: Conversation {
        let conversation = Conversation(
            title: "Sample Conversation",
            lastMessage: "Hello! How can I help you today?",
            timestamp: Date()
        )
        
        // Create messages and add them to the conversation
        let userMessage = Message(
            content: "Hello!",
            isFromUser: true,
            timestamp: Date().addingTimeInterval(-60)
        )
        
        let assistantMessage = Message(
            content: "Hello! How can I help you today?",
            isFromUser: false,
            timestamp: Date()
        )
        
        conversation.addMessage(userMessage)
        conversation.addMessage(assistantMessage)
        
        return conversation
    }
}
