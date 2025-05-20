import Foundation
import SwiftUI
import Combine

// MARK: - Public Protocols

/// A type that represents a chat message
public protocol MessageProtocol: Identifiable, Hashable, Codable, Sendable {
    var id: UUID { get }
    var content: String { get }
    var isFromUser: Bool { get }
    var timestamp: Date { get }
}

/// A type that represents a conversation
public protocol ConversationProtocol: ObservableObject, Identifiable, Hashable, Sendable {
    var id: UUID { get }
    var title: String { get }
    var messages: [any MessageProtocol] { get }
    var lastMessage: String { get }
    var timestamp: Date { get }
    var unreadCount: Int { get }
    var systemPrompt: String { get }
    
    func addMessage(_ message: any MessageProtocol)
    func updateLastMessage(_ text: String)
}

/// A type that represents a project
public protocol ProjectProtocol: ObservableObject, Identifiable, Hashable, Sendable {
    var id: UUID { get }
    var name: String { get }
    var description: String { get }
    var lastUpdated: Date { get }
    var isPinned: Bool { get }
}

// MARK: - Concrete Implementations

// Conversation implementation is in Conversation.swift

// MARK: - Type Erasure

/// Type-erased wrapper for MessageProtocol
public struct AnyMessage: MessageProtocol, Codable, Sendable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    
    public init<M: MessageProtocol>(_ message: M) {
        self.id = message.id
        self.content = message.content
        self.isFromUser = message.isFromUser
        self.timestamp = message.timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isFromUser = try container.decode(Bool.self, forKey: .isFromUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isFromUser, forKey: .isFromUser)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, content, isFromUser, timestamp
    }
    
    public static func == (lhs: AnyMessage, rhs: AnyMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
