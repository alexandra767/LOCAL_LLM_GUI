import Foundation
import Combine

/// Protocol defining the requirements for the app's state management
@MainActor
public protocol AppStateProtocol: ObservableObject {
    associatedtype ConversationType: ConversationProtocol
    
    // MARK: - Published Properties
    
    /// The list of recent conversations
    var recentChats: [ConversationType] { get set }
    
    /// The list of projects
    var projects: [Project] { get set }
    
    /// The currently selected conversation ID
    var selectedConversationId: UUID? { get set }
    
    /// The currently selected project ID
    var selectedProjectId: UUID? { get set }
    
    // MARK: - Conversation Management
    
    /// Creates a new conversation
    /// - Returns: The newly created conversation
    func createNewConversation() -> ConversationType
    
    /// Deletes a conversation
    /// - Parameter id: The ID of the conversation to delete
    func deleteConversation(_ id: UUID)
    
    // MARK: - Project Management
    
    /// Creates a new project
    /// - Returns: The newly created project
    func createNewProject() -> Project
    
    /// Deletes a project
    /// - Parameter id: The ID of the project to delete
    func deleteProject(_ id: UUID)
    
    // MARK: - Data Persistence
    
    /// Saves the current state to persistent storage
    func saveState()
    
    /// Loads the state from persistent storage
    func loadState()
}

// MARK: - Default Implementations

public extension AppStateProtocol {
    /// The currently selected conversation
    var selectedConversation: ConversationType? {
        get {
            guard let id = selectedConversationId else { return nil }
            return recentChats.first { $0.id == id }
        }
        set {
            selectedConversationId = newValue?.id
        }
    }
    
    /// The currently selected project
    var selectedProject: Project? {
        get {
            guard let id = selectedProjectId else { return nil }
            return projects.first { $0.id == id }
        }
        set {
            selectedProjectId = newValue?.id
        }
    }
    
    /// The conversations belonging to the currently selected project
    var currentProjectConversations: [ConversationType] {
        guard let projectId = selectedProjectId else { return [] }
        return recentChats.filter { $0.projectId == projectId }
    }
}
