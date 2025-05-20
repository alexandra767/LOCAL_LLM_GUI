import Foundation

/// Represents the status of a message in the conversation.
/// This helps track the delivery and read status of each message.
public enum MessageStatus: String, Codable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

/// Protocol that defines the requirements for a message in the chat
public protocol MessageProtocol: Identifiable, Codable, Sendable {
    var id: UUID { get }
    var content: String { get set }
    var isFromUser: Bool { get set }
    var timestamp: Date { get set }
    var status: MessageStatus { get set }
}

/// Represents a message in a conversation between the user and the AI.
/// This model is thread-safe and can be used across different parts of the application.
public struct Message: MessageProtocol, Equatable, Hashable {
    // MARK: - Properties
    
    /// A unique identifier for the message
    public let id: UUID
    
    /// The content of the message
    public var content: String
    
    /// When the message was created or last modified
    public var timestamp: Date
    
    /// Whether the message is from the user (true) or the AI (false)
    public var isFromUser: Bool
    
    /// The current status of the message
    public var status: MessageStatus
    
    // MARK: - Initialization
    
    /// Creates a new message
    /// - Parameters:
    ///   - id: A unique identifier for the message (auto-generated if not provided)
    ///   - content: The text content of the message
    ///   - timestamp: When the message was created (defaults to current date)
    ///   - isFromUser: Whether the message is from the user (true) or the AI (false)
    ///   - status: The current status of the message (defaults to .sent)
    public init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        isFromUser: Bool,
        status: MessageStatus = .sent
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.status = status
    }
}

// MARK: - CustomStringConvertible

extension Message: CustomStringConvertible {
    public var description: String {
        "\(isFromUser ? "User" : "AI") [\(status.rawValue)]: \(content.prefix(50))"
    }
}

// MARK: - Convenience Methods

public extension Message {
    /// Creates a new message with updated content
    /// - Parameter newContent: The updated content
    /// - Returns: A new message with the updated content
    func updatingContent(_ newContent: String) -> Message {
        var updated = self
        updated.content = newContent
        updated.timestamp = Date()
        return updated
    }
    
    /// Creates a new message with updated status
    /// - Parameter newStatus: The new status
    /// - Returns: A new message with the updated status
    func updatingStatus(_ newStatus: MessageStatus) -> Message {
        var updated = self
        updated.status = newStatus
        if newStatus == .sent || newStatus == .sending {
            updated.timestamp = Date()
        }
        return updated
    }
}

// MARK: - Preview Data

#if DEBUG
extension Message {
    static let sampleUser = Message(
        content: "Hello, how can I help you today?",
        isFromUser: true
    )
    
    static let sampleAI = Message(
        content: "I'm doing well, thank you for asking! How can I assist you today?",
        isFromUser: false
    )
}
#endif
