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
            lastMessage: "",
            timestamp: Date(),
            unreadCount: 0,
            projectId: projectId,
            systemPrompt: systemPrompt,
            messages: []
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
    
    @MainActor
    private func loadState() {
        // Copy main actor references into local variables first
        let localUserDefaults = userDefaults
        let localDecoder = decoder
        
        saveQueue.async {
            // Load from UserDefaults
            let conversationsData = localUserDefaults.data(forKey: "conversations")
            let projectsData = localUserDefaults.data(forKey: "projects")
            
            // Decode on background queue
            var loadedConversations: [Conversation]?
            var loadedProjects: [Project]?
            
            if let data = conversationsData {
                loadedConversations = try? localDecoder.decode([Conversation].self, from: data)
            }
            
            if let data = projectsData {
                loadedProjects = try? localDecoder.decode([Project].self, from: data)
            }
            
            // Update state on main actor
            Task { @MainActor in
                if let conversations = loadedConversations {
                    self.conversations = conversations
                }
                
                if let projects = loadedProjects {
                    self.projects = projects
                }
            }
        }
    }
    
    @MainActor
    private func saveState() {
        // Safely capture main actor properties
        let localConversations = conversations
        let localProjects = projects
        let localSelectedConversationId = selectedConversationId
        let localSelectedProjectId = selectedProjectId
        let localEncoder = encoder
        let localUserDefaults = userDefaults
        
        saveQueue.async {
            // Encode data on background queue
            let conversationsData = try? localEncoder.encode(localConversations)
            let projectsData = try? localEncoder.encode(localProjects)
            
            // Save to UserDefaults
            if let data = conversationsData {
                localUserDefaults.set(data, forKey: "conversations")
            }
            
            if let data = projectsData {
                localUserDefaults.set(data, forKey: "projects")
            }
            
            if let selectedId = localSelectedConversationId {
                localUserDefaults.set(selectedId.uuidString, forKey: "selectedConversationId")
            } else {
                localUserDefaults.removeObject(forKey: "selectedConversationId")
            }
            
            if let selectedId = localSelectedProjectId {
                localUserDefaults.set(selectedId.uuidString, forKey: "selectedProjectId")
            } else {
                localUserDefaults.removeObject(forKey: "selectedProjectId")
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
