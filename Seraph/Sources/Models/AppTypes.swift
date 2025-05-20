import Foundation
import SwiftUI

// MARK: - Navigation

/// Represents the different navigation destinations in the app
public enum NavigationDestination: Hashable, Codable, Sendable {
    case chats
    case chat(UUID)
    case project(UUID)
    case settings
    
    public var id: String {
        switch self {
        case .chats: return "chats"
        case .chat(let id): return "chat_\(id.uuidString)"
        case .project(let id): return "project_\(id.uuidString)"
        case .settings: return "settings"
        }
    }
    
    public static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - AI Models

/// Represents an AI model that can be used for generating responses
public struct AIModel: Identifiable, Hashable, Codable, Sendable {
    /// A unique identifier for the model
    public let id: String
    
    /// The display name of the model
    public let name: String
    
    /// The maximum number of tokens the model can handle
    public let maxTokens: Int
    
    /// Whether this is the default model
    public let isDefault: Bool
    
    public init(id: String, name: String, maxTokens: Int, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.maxTokens = maxTokens
        self.isDefault = isDefault
    }
    
    // MARK: - Default Models
    
    /// The default model to use when none is specified
    public static let defaultModel = AIModel(
        id: "llama3",
        name: "Llama 3",
        maxTokens: 4096,
        isDefault: true
    )
    
    /// A list of all available models
    public static let availableModels: [AIModel] = [
        defaultModel,
        AIModel(id: "gpt-4", name: "GPT-4", maxTokens: 8192),
        AIModel(id: "claude-2", name: "Claude 2", maxTokens: 100000),
        AIModel(id: "llama2", name: "Llama 2", maxTokens: 4096)
    ]
}

// MARK: - App Theme

/// Represents the app's visual theme
public enum Theme: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case light
    case dark
    
    public var id: String { rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
