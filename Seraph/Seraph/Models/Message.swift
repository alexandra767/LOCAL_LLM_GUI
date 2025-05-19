//
//  Message.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import CoreData

// MARK: - Message Model

/// A message within a chat conversation
struct Message: Identifiable, Codable, Equatable {
    /// Unique identifier for the message
    var id: UUID = UUID()
    
    /// The content of the message
    var content: String
    
    /// The role of the message sender
    var role: MessageRole
    
    /// Timestamp when the message was created
    var timestamp: Date = Date()
    
    /// Flag indicating if the message generation is complete
    var isComplete: Bool = true
    
    /// Attachments to the message
    var attachments: [DocumentAttachment] = []
    
    /// Token count for context window management
    var tokenCount: Int?
    
    /// Initialize a new message
    init(id: UUID = UUID(), content: String, role: MessageRole, timestamp: Date = Date(), isComplete: Bool = true, attachments: [DocumentAttachment] = [], tokenCount: Int? = nil) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.isComplete = isComplete
        self.attachments = attachments
        self.tokenCount = tokenCount
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.content == rhs.content &&
               lhs.role == rhs.role &&
               lhs.timestamp == rhs.timestamp &&
               lhs.isComplete == rhs.isComplete &&
               lhs.attachments == rhs.attachments &&
               lhs.tokenCount == rhs.tokenCount
    }
}

/// Role of a message sender
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
    case function
}

// MARK: - Chat Model

/// A chat conversation containing multiple messages
struct Chat: Identifiable, Codable {
    /// Unique identifier for the chat
    var id: UUID = UUID()
    
    /// Title of the chat
    var title: String
    
    /// Messages in the chat
    var messages: [Message]
    
    /// Associated project ID (if any)
    var projectId: UUID?
    
    /// Creation timestamp
    var createdAt: Date = Date()
    
    /// Last update timestamp
    var updatedAt: Date = Date()
    
    /// Model used for this chat
    var model: String = "ollama-Mistral 7B"
    
    /// Custom system prompt
    var systemPrompt: String = ""
    
    /// Is this chat pinned
    var isPinned: Bool = false
    
    /// Total token count for context window management
    var totalTokenCount: Int {
        messages.reduce(0) { count, message in
            count + (message.tokenCount ?? 0)
        }
    }
}