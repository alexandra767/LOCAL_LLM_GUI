import Foundation
import Combine

/// Protocol defining the requirements for a conversation in the app
public protocol ConversationProtocol: Identifiable, ObservableObject, Sendable {
    associatedtype MessageType: MessageProtocol where MessageType: Identifiable, MessageType: Sendable
    
    /// A unique identifier for the conversation
    var id: UUID { get }
    
    /// The title of the conversation
    var title: String { get set }
    
    /// The content of the last message in the conversation
    var lastMessage: String { get set }
    
    /// When the conversation was last updated
    var timestamp: Date { get set }
    
    /// Number of unread messages in the conversation
    var unreadCount: Int { get set }
    
    /// The ID of the project this conversation belongs to, if any
    var projectId: UUID? { get set }
    
    /// The messages in the conversation
    var messages: [MessageType] { get set }
    
    /// The system prompt to use for this conversation
    var systemPrompt: String { get set }
    
    /// Adds a new message to the conversation
    /// - Parameter message: The message to add
    func addMessage(_ message: MessageType)
    
    /// Marks the conversation as read
    func markAsRead()
    
    /// Updates the conversation title
    /// - Parameter newTitle: The new title for the conversation
    func updateTitle(_ newTitle: String)
    
    /// Moves the conversation to a different project
    /// - Parameter projectId: The ID of the project to move to, or nil for no project
    func moveToProject(_ projectId: UUID?)
}

// MARK: - Default Implementations

public extension ConversationProtocol where MessageType: MessageProtocol {
    /// The preview text to show in the conversation list
    var previewText: String {
        if let lastMessage = messages.last?.content {
            return lastMessage
        }
        return lastMessage
    }
    
    /// Whether the conversation is unread
    var isUnread: Bool {
        unreadCount > 0
    }
    
    /// The formatted timestamp string
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
