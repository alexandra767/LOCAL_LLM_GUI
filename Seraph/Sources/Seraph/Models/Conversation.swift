import Foundation
import SwiftUI
import Combine

/// Represents a conversation in the app, containing a series of messages between the user and the AI.
/// This class is observable and codable for persistence.
@MainActor
public final class Conversation: ConversationProtocol, Identifiable, ObservableObject, Codable, @unchecked Sendable {
    public typealias MessageType = Message
    
    // MARK: - Properties
    
    public let id: UUID
    public var title: String
    public var lastMessage: String
    public var timestamp: Date
    public var unreadCount: Int
    public var projectId: UUID?
    public var systemPrompt: String
    @Published public var messages: [Message] = []
    
    // MARK: - Private Properties
    
    private enum CodingKeys: String, CodingKey {
        case id, title, lastMessage, timestamp, unreadCount, projectId, systemPrompt, messages
    }
    
    // Required by ObservableObject
    public var objectWillChange: ObservableObjectPublisher {
        return $messages.objectWillChange
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
    }
    
    public convenience init(title: String) {
        self.init(
            id: UUID(),
            title: title,
            lastMessage: "",
            timestamp: Date(),
            unreadCount: 0,
            projectId: nil,
            systemPrompt: "",
            messages: []
        )
    }
    
    // MARK: - Codable
    
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
    
    // MARK: - ConversationProtocol
    
    public func addMessage(_ message: Message) {
        messages.append(message)
        lastMessage = message.content
        timestamp = message.timestamp
        if !message.isFromUser && message.status != .read {
            unreadCount += 1
        }
    }
    
    public func markAsRead() {
        unreadCount = 0
        for i in messages.indices where messages[i].status != .read {
            messages[i].status = .read
        }
    }
    
    public func updateTitle(_ newTitle: String) {
        title = newTitle
    }
    
    public func moveToProject(_ projectId: UUID?) {
        self.projectId = projectId
    }
    @MainActor public var objectWillChange: ObservableObjectPublisher? = nil
    
    private let accessQueue = DispatchQueue(label: "com.seraph.conversation", attributes: .concurrent)
    private var _messages: [Message] = []
    
    public typealias MessageType = Message
    
    // MARK: - Properties
    
    public let id: UUID
    private var _title: String
    private var _lastMessage: String
    private var _timestamp: Date
    private var _unreadCount: Int
    private var _projectId: UUID?
    private var _systemPrompt: String
    
    public var title: String {
        get { accessQueue.sync { _title } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._title = newValue
            DispatchQueue.main.async {
                self?.objectWillChange?.send()
            }
        }}
    }
    
    public var lastMessage: String {
        get { accessQueue.sync { _lastMessage } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._lastMessage = newValue
            DispatchQueue.main.async {
                self?.objectWillChange?.send()
            }
        }}
    }
    
    public var timestamp: Date {
        get { accessQueue.sync { _timestamp } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._timestamp = newValue
            DispatchQueue.main.async {
                self?.objectWillChange?.send()
            }
        }}
    }
    
    public var unreadCount: Int {
        get { accessQueue.sync { _unreadCount } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._unreadCount = newValue
            DispatchQueue.main.async {
                self?.objectWillChange?.send()
            }
        }}
    }
    
    public var projectId: UUID? {
        get { accessQueue.sync { _projectId } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._projectId = newValue
            DispatchQueue.main.async {
                self?.objectWillChange?.send()
            }
        }}
    }
    
    public var systemPrompt: String {
        get { accessQueue.sync { _systemPrompt } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._systemPrompt = newValue
            DispatchQueue.main.async {
                self?.objectWillChange?.send()
            }
        }}
    }
    
    public var messages: [Message] {
        get { accessQueue.sync { _messages } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self._messages = newValue
            
            // Update last message and timestamp when messages change
            if let lastMessage = newValue.last {
                self._lastMessage = lastMessage.content
                self._timestamp = lastMessage.timestamp
                
                // Update unread count if needed
                if !lastMessage.isFromUser && lastMessage.status != .read {
                    self._unreadCount += 1
                }
            }
            
            // Notify observers on the main thread
            DispatchQueue.main.async {
                self.objectWillChange?.send()
            }
        }}
    }
    
    // MARK: - Initialization
    
    /// Creates a new conversation
    /// - Parameters:
    ///   - id: The unique identifier for the conversation
    ///   - title: The title of the conversation
    ///   - messages: Array of messages
    ///   - lastModified: When the conversation was last updated
    ///   - projectId: Optional project ID this conversation belongs to
    ///   - systemPrompt: The system prompt for this conversation
    ///   - unreadCount: Number of unread messages
    public init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        messages: [Message] = [],
        lastModified: Date = Date(),
        projectId: UUID? = nil,
        systemPrompt: String = "You are a helpful AI assistant.",
        unreadCount: Int = 0
    ) {
        self.id = id
        self._title = title
        self._lastMessage = messages.last?.content ?? ""
        self._timestamp = lastModified
        self._unreadCount = unreadCount
        self._projectId = projectId
        self._systemPrompt = systemPrompt
        self._messages = messages
        self.objectWillChange = ObservableObjectPublisher()
        
        // If no title is provided, generate one from the first message
        if title == "New Conversation", let firstMessage = messages.first(where: { !$0.content.isEmpty }) {
            self._title = String(firstMessage.content.prefix(30)) + (firstMessage.content.count > 30 ? "..." : "")
        }
    }
    
    // MARK: - ConversationProtocol Conformance
    
    public func addMessage(_ message: Message) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Update messages on the background queue
            var updatedMessages = self.messages
            updatedMessages.append(message)
            
            // Update properties on the main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.messages = updatedMessages
                self.lastMessage = message.content
                self.timestamp = Date()
                if !message.isFromUser {
                    self.unreadCount += 1
                }
                
                // Explicitly notify observers
                self.objectWillChange?.send()
            }
        }
    }
    
    public func markAsRead() {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self._unreadCount = 0
            
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange?.send()
            }
        }
    }
    
    public func updateTitle(_ newTitle: String) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self._title = newTitle
            
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange?.send()
            }
        }
    }
    
    public func moveToProject(_ projectId: UUID?) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self._projectId = projectId
            
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange?.send()
            }
        }
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, title, lastMessage, timestamp, unreadCount, projectId, systemPrompt, messages
    }
    
    // Non-isolated initializer for Decodable conformance
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required properties
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let lastMessage = try container.decode(String.self, forKey: .lastMessage)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        let projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        let systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        let messages = try container.decode([Message].self, forKey: .messages)
        
        // Initialize properties
        self.id = id
        self._title = title
        self._lastMessage = lastMessage
        self._timestamp = timestamp
        self._unreadCount = unreadCount
        self._projectId = projectId
        self._systemPrompt = systemPrompt
        self._messages = messages
        self.objectWillChange = ObservableObjectPublisher()
        
        // If no title is provided, generate one from the first message
        if title == "New Conversation", let firstMessage = messages.first(where: { !$0.content.isEmpty }) {
            self._title = String(firstMessage.content.prefix(30)) + (firstMessage.content.count > 30 ? "..." : "")
        }
    }
    
    // Helper struct for decoding
    private struct Decoded: Decodable {
        let id: UUID
        let title: String
        let lastMessage: String
        let timestamp: Date
        let unreadCount: Int
        let projectId: UUID?
        let systemPrompt: String
        let messages: [Message]
        
        init(from decoder: Decoder) throws {
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
        
        enum CodingKeys: String, CodingKey {
            case id, title, lastMessage, timestamp, unreadCount, projectId, systemPrompt, messages
        }
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
