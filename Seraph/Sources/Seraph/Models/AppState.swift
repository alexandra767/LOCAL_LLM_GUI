import Foundation
import Combine
import SwiftUI

// Import AIModel for default model value

// MARK: - App State

/// The main app state that manages the application's data and state.
/// This class is responsible for managing conversations, projects, and their persistence.

/// The main app state that manages the application's data and state.
/// This class is responsible for managing conversations, projects, and their persistence.
@MainActor
public final class AppState: ObservableObject {
    // MARK: - Published Properties
    
    /// All conversations in the app, both with and without projects
    @Published public private(set) var conversations: [Conversation] = []
    
    /// All projects in the app
    @Published public private(set) var projects: [Project] = []
    
    /// The currently selected conversation ID
    @Published public var selectedConversationId: UUID?
    
    /// The currently selected project ID
    @Published public var selectedProjectId: UUID?
    
    /// The currently selected AI model
    @Published public var currentModel: String = AIModel.defaultModel.rawValue
    
    // MARK: - Computed Properties
    
    /// Recent chats (conversations not in a project)
    public var recentChats: [Conversation] {
        conversations.filter { $0.projectId == nil }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let saveQueue = DispatchQueue(label: "com.seraph.appstate.save")
    
    // MARK: - Initialization
    
    /// Shared instance of AppState for app-wide state management
    public static let shared = AppState()
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        setupBindings()
        loadState()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new conversation and adds it to the recent chats
    /// - Parameters:
    ///   - title: The title of the new conversation (default: "New Conversation")
    ///   - systemPrompt: The system prompt for the conversation (default: empty string)
    ///   - projectId: The ID of the project this conversation belongs to (default: nil)
    /// - Returns: The newly created conversation
    public func createNewConversation(
        title: String = "New Conversation",
        systemPrompt: String = "",
        inProject projectId: UUID? = nil
    ) -> Conversation {
        let conversation = Conversation(
            id: UUID(),
            title: title,
            messages: [],
            lastMessage: "",
            timestamp: Date(),
            unreadCount: 0,
            projectId: projectId,
            systemPrompt: systemPrompt
        )
        
        conversations.append(conversation)
        selectedConversationId = conversation.id
        selectedProjectId = projectId
        
        saveState()
        return conversation
    }
    
    /// Deletes a conversation from the app state.
    /// - Parameter conversation: The conversation to delete.
    public func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        
        // Update selected conversation if needed
        if selectedConversationId == conversation.id {
            selectedConversationId = nil
        }
        
        saveState()
    }
    
    /// Deletes a conversation
    /// - Parameter id: The ID of the conversation to delete
    public func deleteConversation(withId id: UUID) {
        conversations.removeAll { $0.id == id }
        if selectedConversationId == id {
            selectedConversationId = nil
        }
        saveState()
    }
    
    /// Creates a new project
    /// - Parameter title: The title of the new project
    /// - Returns: The newly created project
    public func createProject(title: String) -> Project {
        let project = Project(
            id: UUID(),
            name: title,
            description: "",
            lastUpdated: Date(),
            createdAt: Date()
        )
        projects.append(project)
        selectedProjectId = project.id
        saveState()
        return project
    }
    
    /// Deletes a project and all its associated conversations.
    /// - Parameter project: The project to delete.
    public func deleteProject(_ project: Project) {
        // Remove the project
        projects.removeAll { $0.id == project.id }
        
        // Remove all conversations associated with this project
        conversations.removeAll { $0.projectId == project.id }
        
        // Update selected conversation/project if needed
        if selectedProjectId == project.id {
            selectedProjectId = nil
        }
        
        saveState()
    }
    
    /// Deletes a project and all its conversations
    /// - Parameter id: The ID of the project to delete
    public func deleteProject(withId id: UUID) {
        // Move all conversations to recent chats
        for i in conversations.indices where conversations[i].projectId == id {
            conversations[i].projectId = nil
        }
        
        projects.removeAll { $0.id == id }
        if selectedProjectId == id {
            selectedProjectId = nil
        }
        saveState()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Save state when any published property changes
        $conversations
            .dropFirst()
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)
            
        $projects
            .dropFirst()
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)
            
        // Load saved state on init
        loadState()
    }
    
    private func loadState() {
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = self.userDefaults.data(forKey: "conversations"),
               let conversations = try? self.decoder.decode([Conversation].self, from: data) {
                DispatchQueue.main.async {
                    self.conversations = conversations
                }
            }
            
            if let data = self.userDefaults.data(forKey: "projects"),
               let projects = try? self.decoder.decode([Project].self, from: data) {
                DispatchQueue.main.async {
                    self.projects = projects
                }
            }
        }
    }
    
    private func saveState() {
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = try? self.encoder.encode(self.conversations) {
                self.userDefaults.set(data, forKey: "conversations")
            }
            
            if let data = try? self.encoder.encode(self.projects) {
                self.userDefaults.set(data, forKey: "projects")
            }
            
            if let selectedId = self.selectedConversationId {
                self.userDefaults.set(selectedId.uuidString, forKey: "selectedConversationId")
            } else {
                self.userDefaults.removeObject(forKey: "selectedConversationId")
            }
            
            if let selectedProjectId = self.selectedProjectId {
                self.userDefaults.set(selectedProjectId.uuidString, forKey: "selectedProjectId")
            } else {
                self.userDefaults.removeObject(forKey: "selectedProjectId")
            }
        }
    }
}
// MARK: - Preview Support

#if DEBUG
extension AppState {
    static var preview: AppState {
        let state = AppState()
        
        // Add sample projects
        let project1 = state.createProject(title: "Project 1")
        _ = state.createProject(title: "Project 2")
        
        // Add sample conversations
        _ = state.createNewConversation(title: "Welcome to Seraph")
        _ = state.createNewConversation(
            title: "Project Discussion",
            inProject: project1.id
        )
        
        return state
    }
}
#endif
