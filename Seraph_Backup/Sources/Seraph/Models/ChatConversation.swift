import Foundation
import SwiftUI

// MARK: - Chat Models

/// Represents a chat conversation with messages and metadata
struct ChatConversation: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var projectId: String?
    var lastMessage: String
    var timestamp: Date
    var isPinned: Bool = false
    var isArchived: Bool = false
    var modelId: String?
    var tags: [String] = []
    
    init(
        id: String = UUID().uuidString,
        title: String,
        projectId: String? = nil,
        lastMessage: String = "",
        timestamp: Date = Date(),
        isPinned: Bool = false,
        isArchived: Bool = false,
        modelId: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.projectId = projectId
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.modelId = modelId
        self.tags = tags
    }
    
    static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents a single message in a chat conversation
struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var isStreaming: Bool = false
    var modelId: String?
    var metadata: [String: String] = [:]
    
    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        modelId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.modelId = modelId
        self.metadata = metadata
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents the role of a message sender
enum MessageRole: String, Codable, Equatable {
    case user
    case assistant
    case system
    case function
}

// MARK: - User Model

/// Represents a user of the application
struct User: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var email: String
    var avatarURL: URL?
    var preferences: UserPreferences
    var subscription: SubscriptionPlan
    var lastActive: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        avatarURL: URL? = nil,
        preferences: UserPreferences = UserPreferences(),
        subscription: SubscriptionPlan = .free,
        lastActive: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.preferences = preferences
        self.subscription = subscription
        self.lastActive = lastActive
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// User preferences for the application
struct UserPreferences: Codable, Equatable {
    var theme: AppTheme = .system
    var fontSize: CGFloat = 14
    var enableAnimations: Bool = true
    var defaultModelId: String?
    var defaultTemperature: Double = 0.7
    var defaultMaxTokens: Int = 2048
    var showTokenCount: Bool = true
    var autoExpandImages: Bool = true
    var markdownRendering: MarkdownRendering = .full
    var codeTheme: CodeTheme = .xcode
    var autoSave: Bool = true
    var autoSaveInterval: TimeInterval = 30 // seconds
}

/// Available application themes
enum AppTheme: String, Codable, CaseIterable {
    case system
    case light
    case dark
}

/// Markdown rendering options
enum MarkdownRendering: String, Codable, CaseIterable {
    case none
    case basic
    case full
}

/// Code theme options
enum CodeTheme: String, Codable, CaseIterable {
    case xcode
    case solarizedLight
    case solarizedDark
    case monokai
    case dracula
}

/// Subscription plan types
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case pro
    case team
    case enterprise
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .team: return "Team"
        case .enterprise: return "Enterprise"
        }
    }
    
    var maxChats: Int? {
        switch self {
        case .free: return 10
        case .pro: return 100
        case .team: return 1000
        case .enterprise: return nil // Unlimited
        }
    }
    
    var maxMessagesPerChat: Int? {
        switch self {
        case .free: return 100
        case .pro: return 1000
        case .team: return 10_000
        case .enterprise: return nil // Unlimited
        }
    }
}
