import Foundation
import Combine
import SwiftUI

// Import the necessary protocols
@_exported import protocol SeraphModels.ConversationProtocol
@_exported import protocol SeraphModels.ProjectProtocol
@_exported import protocol SeraphModels.MessageProtocol

// Import the necessary types
@_exported import struct SeraphModels.NavigationDestination
@_exported import struct SeraphModels.AIModel
@_exported import struct SeraphModels.Theme

// MARK: - AppState

/// The main application state manager that handles all the app's data and state
@MainActor
public final class AppState: ObservableObject, @unchecked Sendable {
    // MARK: - Singleton
    
    public static let shared = AppState()
    
    // MARK: - Published Properties
    
    /// The list of recent conversations
    @Published public private(set) var recentChats: [any ConversationProtocol] = []
    
    /// The list of projects.
    @Published public private(set) var projects: [any ProjectProtocol] = []
    
    /// The currently selected navigation destination
    @Published public var selectedNavigation: NavigationDestination = .chats
    
    /// The currently selected AI model.
    @Published public var selectedModel: AIModel = .defaultModel {
        didSet {
            saveState()
        }
    }
    
    /// The current app theme.
    @Published public var selectedTheme: Theme = .system {
        didSet {
            saveState()
        }
    }
    
    /// The list of available AI models
    @Published public private(set) var availableModels: [AIModel] = AIModel.availableModels
    
    /// The currently selected model ID
    @Published public var currentModel: String = "llama3"
    
    /// The ID of the currently selected conversation
    @Published public var selectedConversationId: UUID?
    
    /// The ID of the currently selected project
    @Published public var selectedProjectId: UUID?
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Creates a new instance of the app state.
    /// - Parameter userDefaults: The UserDefaults instance to use for persistence.
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        setupBindings()
        loadState()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new conversation and adds it to the recent chats.
    @discardableResult
    public func createNewConversation() async -> any ConversationProtocol {
        let conversation = Conversation()
        recentChats.insert(conversation, at: 0)
        saveState()
        return conversation
    }
    
    /// Deletes a conversation with the specified ID.
    /// - Parameter id: The ID of the conversation to delete.
    public func deleteConversation(_ id: UUID) {
        recentChats.removeAll { $0.id == id }
        saveState()
    }
    
    /// Finds a conversation by its ID.
    /// - Parameter id: The ID of the conversation to find.
    /// - Returns: The conversation if found, otherwise nil.
    public func conversation(with id: UUID) -> (any ConversationProtocol)? {
        recentChats.first { $0.id == id }
    }
    
    /// Finds a project by its ID.
    /// - Parameter id: The ID of the project to find.
    /// - Returns: The project if found, otherwise nil.
    public func project(with id: UUID) -> (any ProjectProtocol)? {
        projects.first { $0.id == id }
    }
    
    public func loadSampleData() {
        // Only load sample data if we don't have any chats
        guard recentChats.isEmpty else { return }
        
        let welcomeConversation = Conversation(
            title: "Welcome to Seraph",
            lastMessage: "Hello! How can I help you today?",
            timestamp: Date(),
            messages: [
                Message(content: "Hello!", isFromUser: true, timestamp: Date().addingTimeInterval(-60)),
                Message(content: "Hello! How can I help you today?", isFromUser: false, timestamp: Date())
            ]
        )
        
        let projectIdeas = Conversation(
            title: "Project Ideas",
            lastMessage: "Here are some ideas...",
            timestamp: Date().addingTimeInterval(-3600),
            messages: [
                Message(content: "I need some project ideas", isFromUser: true, timestamp: Date().addingTimeInterval(-3660)),
                Message(content: "Here are some ideas...", isFromUser: false, timestamp: Date().addingTimeInterval(-3600))
            ]
        )
        
        recentChats = [welcomeConversation, projectIdeas]
        
        // Create a sample project if none exists
        if projects.isEmpty {
            let sampleProject = Project(name: "Sample Project", description: "A sample project to get you started")
            projects = [sampleProject]
        }
    }
    
    public func createNewProject(name: String) -> Project {
        let project = Project(name: name, description: "")
        projects.append(project)
        selectedProjectId = project.id
        selectedConversationId = nil
        return project
    }
    
    public func createNewConversation() -> Conversation {
        let conversation = Conversation(
            title: "New Chat",
            lastMessage: "",
            timestamp: Date(),
            messages: []
        )
        recentChats.insert(conversation, at: 0)
        selectedConversationId = conversation.id
        selectedProjectId = nil
        return conversation
    }
    
    public func deleteConversation(_ id: UUID) {
        recentChats.removeAll { $0.id == id }
        if selectedConversationId == id {
            selectedConversationId = nil
        }
    }
    
    public func deleteProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        if selectedProjectId == id {
            selectedProjectId = nil
        }
    }
    
    // MARK: - State Management
    
    private func setupBindings() {
        // Setup state observation and auto-save
        $recentChats
            .dropFirst()
            .debounce(for: .init(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)
        
        $projects
            .dropFirst()
            .debounce(for: .init(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)
        
        $currentModel
            .dropFirst()
            .debounce(for: .init(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)
    }
    
    private func saveState() {
        let recentChats = self.recentChats
        let projects = self.projects
        let currentModel = self.currentModel
        
        stateSaveQueue.async {
            do {
                let encoder = JSONEncoder()
                let recentChatsData = try encoder.encode(recentChats)
                let projectsData = try encoder.encode(projects)
                let modelData = try encoder.encode(currentModel)
                
                UserDefaults.standard.set(recentChatsData, forKey: "recentChats")
                UserDefaults.standard.set(projectsData, forKey: "projects")
                UserDefaults.standard.set(modelData, forKey: "currentModel")
            } catch {
                print("Failed to save state: \(error)")
            }
        }
    }
    
    private func loadState() {
        stateSaveQueue.async {
            let decoder = JSONDecoder()
            
            // Load recent chats
            if let chatsData = UserDefaults.standard.data(forKey: "recentChats") {
                do {
                    let loadedChats = try decoder.decode([Conversation].self, from: chatsData)
                    Task { @MainActor in
                        self.recentChats = loadedChats
                    }
                } catch {
                    print("Failed to decode recent chats: \(error)")
                }
            }
            
            // Load projects
            if let projectsData = UserDefaults.standard.data(forKey: "projects") {
                do {
                    let loadedProjects = try decoder.decode([Project].self, from: projectsData)
                    Task { @MainActor in
                        self.projects = loadedProjects
                    }
                } catch {
                    print("Failed to decode projects: \(error)")
                }
            }
            
            // Load current model
            if let modelData = UserDefaults.standard.data(forKey: "currentModel") {
                do {
                    let model = try decoder.decode(String.self, from: modelData)
                    Task { @MainActor in
                        self.currentModel = model
                    }
                } catch {
                    print("Failed to decode current model: \(error)")
                }
            }
            
            // Load sample data if no data was found
            Task { @MainActor in
                if self.recentChats.isEmpty {
                    self.loadSampleData()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Finds a conversation by its ID
    public func conversation(withId id: UUID) -> Conversation? {
        recentChats.first { $0.id == id }
    }
    
    /// Finds a project by its ID
    public func project(withId id: UUID) -> Project? {
        projects.first { $0.id == id }
    }
    
    /// Updates the last message and timestamp of a conversation
    public func updateConversationLastMessage(_ conversationId: UUID, lastMessage: String) {
        if let index = recentChats.firstIndex(where: { $0.id == conversationId }) {
            recentChats[index].lastMessage = lastMessage
            recentChats[index].timestamp = Date()
        }
    }
}

// MARK: - Previews

extension AppState {
    /// A preview instance of AppState with sample data
    public static var preview: AppState {
        let state = AppState()
        
        // Add some sample conversations
        let conversation1 = Conversation()
        conversation1.title = "Sample Chat 1"
        conversation1.lastMessage = "Hello, how can I help you today?"
        
        let conversation2 = Conversation()
        conversation2.title = "Sample Chat 2"
        conversation2.lastMessage = "I need help with my project"
        
        state.recentChats = [conversation1, conversation2]
        
        // Add some sample projects
        let project1 = Project()
        project1.name = "Project A"
        project1.description = "A sample project"
        
        let project2 = Project()
        project2.name = "Project B"
        project2.description = "Another sample project"
        
        state.projects = [project1, project2]
        
        return state
    }
}
