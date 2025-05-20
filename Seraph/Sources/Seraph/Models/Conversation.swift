import Foundation
import SwiftUI
import Combine

/// Represents a conversation in the app, containing a series of messages between the user and the AI.
/// This class is observable and codable for persistence.
public final class Conversation: ConversationProtocol, Identifiable, ObservableObject, Codable, @unchecked Sendable {
    // MARK: - Type Aliases
    public typealias MessageType = Message
    
    // MARK: - Published Properties
    public nonisolated let objectWillChange = ObservableObjectPublisher()
    
    // MARK: - Private Properties
    private let accessQueue = DispatchQueue(label: "com.seraph.conversation", attributes: .concurrent)
    private var _title: String
    private var _lastMessage: String
    private var _timestamp: Date
    private var _unreadCount: Int
    private var _projectId: UUID?
    private var _systemPrompt: String
    private var _messages: [Message]
    private var _isPinned: Bool
    
    // MARK: - Public Properties
    public let id: UUID
    public let createdAt: Date
    public var updatedAt: Date
    
    public var title: String {
        get { accessQueue.sync { _title } }
        set { updateProperty("title", newValue: newValue) }
    }
    
    public var lastMessage: String {
        get { accessQueue.sync { _lastMessage } }
        set { updateProperty("lastMessage", newValue: newValue) }
    }
    
    public var timestamp: Date {
        get { accessQueue.sync { _timestamp } }
        set { updateProperty("timestamp", newValue: newValue) }
    }
    
    public var unreadCount: Int {
        get { accessQueue.sync { _unreadCount } }
        set { updateProperty("unreadCount", newValue: newValue) }
    }
    
    public var projectId: UUID? {
        get { accessQueue.sync { _projectId } }
        set { updateProperty("projectId", newValue: newValue) }
    }
    
    public var systemPrompt: String {
        get { accessQueue.sync { _systemPrompt } }
        set { updateProperty("systemPrompt", newValue: newValue) }
    }
    
    public var messages: [Message] {
        get { accessQueue.sync { _messages } }
        set { updateProperty("messages", newValue: newValue) }
    }
    
    public var isPinned: Bool {
        get { accessQueue.sync { _isPinned } }
        set { updateProperty("isPinned", newValue: newValue) }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        lastMessage: String = "",
        timestamp: Date = Date(),
        unreadCount: Int = 0,
        projectId: UUID? = nil,
        systemPrompt: String = "",
        messages: [Message] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self._title = title
        self._lastMessage = messages.last?.content ?? lastMessage
        self._timestamp = timestamp
        self._unreadCount = unreadCount
        self._projectId = projectId
        self._systemPrompt = systemPrompt
        self._messages = messages
        self._isPinned = isPinned
        self.createdAt = timestamp
        self.updatedAt = timestamp
        
        // If no title is provided, generate one from the first message
        if title == "New Conversation", let firstMessage = messages.first(where: { !$0.content.isEmpty }) {
            self._title = String(firstMessage.content.prefix(30)) + (firstMessage.content.count > 30 ? "..." : "")
        }
    }
    
    // MARK: - Thread-Safe Property Updates
    
    private func updateProperty<T>(_ property: String, newValue: T) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Use direct property access
            switch property {
            case "title":
                self._title = newValue as! String
            case "lastMessage":
                self._lastMessage = newValue as! String
            case "timestamp":
                self._timestamp = newValue as! Date
            case "unreadCount":
                self._unreadCount = newValue as! Int
            case "projectId":
                self._projectId = newValue as? UUID
            case "systemPrompt":
                self._systemPrompt = newValue as! String
            case "messages":
                self._messages = newValue as! [Message]
            case "isPinned":
                self._isPinned = newValue as! Bool
            default:
                break
            }
            
            // Update the timestamp
            if property != "timestamp" {
                self.updatedAt = Date()
            }
            
            // Notify observers on the main thread
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Message Management
    
    public func addMessage(_ message: Message) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Update messages on the background queue
            self._messages.append(message)
            self._lastMessage = message.content
            self._timestamp = message.timestamp
            self.updatedAt = Date()
            
            // Update unread count if needed
            if !message.isFromUser && message.status != .read {
                self._unreadCount += 1
            }
            
            // Notify observers on the main thread
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, title, lastMessage, timestamp, unreadCount, projectId, systemPrompt, messages, isPinned, createdAt, updatedAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties using the same key names as the stored properties
        id = try container.decode(UUID.self, forKey: .id)
        _title = try container.decode(String.self, forKey: .title)
        _lastMessage = try container.decode(String.self, forKey: .lastMessage)
        _timestamp = try container.decode(Date.self, forKey: .timestamp)
        _unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        _projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        _systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        _messages = try container.decode([Message].self, forKey: .messages)
        _isPinned = try container.decode(Bool.self, forKey: .isPinned)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(_title, forKey: .title)
        try container.encode(_lastMessage, forKey: .lastMessage)
        try container.encode(_timestamp, forKey: .timestamp)
        try container.encode(_unreadCount, forKey: .unreadCount)
        try container.encodeIfPresent(_projectId, forKey: .projectId)
        try container.encode(_systemPrompt, forKey: .systemPrompt)
        try container.encode(_messages, forKey: .messages)
        try container.encode(_isPinned, forKey: .isPinned)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - ConversationProtocol
    
    public func markAsRead() {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self._unreadCount = 0
            for i in self._messages.indices where self._messages[i].status != .read {
                self._messages[i].status = .read
            }
            
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    public func updateTitle(_ newTitle: String) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self._title = newTitle
            self.updatedAt = Date()
            
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    public func moveToProject(_ projectId: UUID?) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self._projectId = projectId
            self.updatedAt = Date()
            
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    public func updateMessage(_ id: UUID, content: String, status: MessageStatus) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if let index = self._messages.firstIndex(where: { $0.id == id }) {
                self._messages[index].content = content
                self._messages[index].status = status
                
                // Update conversation metadata
                self._lastMessage = content
                self._timestamp = Date()
                self.updatedAt = Date()
                
                Task { @MainActor in
                    self.objectWillChange.send()
                }
            }
        }
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
