import Foundation
import Combine
import SwiftUI
import LLMService

// MARK: - App State

/// The main app state that manages the application's data and state.
/// This class is responsible for managing conversations, projects, and their persistence.
@MainActor
public final class AppState: ObservableObject {
    // MARK: - Private Properties
    
    private let saveQueue = DispatchQueue(label: "com.seraph.appstate.save")
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    public var recentChats: [Conversation] {
        conversations.filter { $0.projectId == nil }
    }
    
    public var selectedConversation: Conversation? {
        guard let id = selectedConversationId else { return nil }
        return conversations.first { $0.id == id }
    }
    
    public var selectedProject: Project? {
        guard let id = selectedProjectId else { return nil }
        return projects.first { $0.id == id }
    }
    
    // MARK: - Published Properties
    
    @Published public private(set) var conversations: [Conversation] = []
    @Published public private(set) var projects: [Project] = []
    @Published public private(set) var selectedConversationId: UUID?
    @Published public private(set) var selectedProjectId: UUID?
    @Published public private(set) var currentModel: String = AIModel.defaultModel.rawValue
    @Published public private(set) var llmService: LLMService
    
    // MARK: - Shared Instance
    
    /// The shared instance of AppState for global access
    @MainActor public static let shared = AppState(llmService: LLMService.shared)
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard, llmService: LLMService) {
        self.userDefaults = userDefaults
        self.llmService = llmService
        setupBindings()
        loadState()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new conversation with the given parameters
    public func createNewConversation(
        title: String = "New Conversation",
        systemPrompt: String = "",
        inProject projectId: UUID? = nil
    ) -> Conversation {
        let conversation = Conversation(
            title: title,
            projectId: projectId,
            systemPrompt: systemPrompt
        )
        
        conversations.append(conversation)
        selectedConversationId = conversation.id
        saveState()
        
        return conversation
    }
    
    /// Adds an existing conversation to the app state
    /// - Parameter conversation: The conversation to add
    func addConversation(_ conversation: Conversation) {
        conversations.append(conversation)
        saveState()
    }
    
    /// Deletes a conversation with the given ID
    func deleteConversation(withId id: UUID) {
        conversations.removeAll { $0.id == id }
        
        if selectedConversationId == id {
            selectedConversationId = conversations.first?.id
        }
        
        saveState()
    }
    
    /// Deletes a project and all its associated conversations
    func deleteProject(_ project: Project) {
        deleteProject(withId: project.id)
    }
    
    /// Deletes a project with the given ID and moves its conversations to the recent list
    func deleteProject(withId id: UUID) {
        // Move all conversations to recent chats
        for i in conversations.indices where conversations[i].projectId == id {
            conversations[i].projectId = nil
        }
        
        // Remove the project
        projects.removeAll { $0.id == id }
        
        // Update selection if needed
        if selectedProjectId == id {
            selectedProjectId = projects.first?.id
        }
        
        saveState()
    }
    
    /// Adds a new project to the app state
    /// - Parameter project: The project to add
    func addProject(_ project: Project) {
        projects.append(project)
        saveState()
    }
    
    /// Creates a new project with the given name and description
    /// - Parameters:
    ///   - name: The name of the project
    ///   - description: An optional description of the project
    /// - Returns: The newly created project
    public func createNewProject(name: String, description: String = "") -> Project {
        let project = Project(name: name, description: description)
        
        projects.append(project)
        selectedProjectId = project.id
        saveState()
        
        return project
    }
    
    /// Sets the current model
    /// - Parameter model: The model to set as current
    public func setCurrentModel(_ model: AIModel) {
        currentModel = model.rawValue
        saveState()
    }
    
    /// Sets the selected conversation
    /// - Parameter conversation: The conversation to select
    public func setSelectedConversation(_ conversation: Conversation) {
        selectedConversationId = conversation.id
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
    }
    
    private func loadState() {
        // Load conversations
        if let conversationsData = UserDefaults.standard.data(forKey: "conversations") {
            do {
                let decodedConversations = try decoder.decode([Conversation].self, from: conversationsData)
                DispatchQueue.main.async {
                    self.conversations = decodedConversations
                }
                print("✅ Loaded \(decodedConversations.count) conversations")
            } catch {
                print("❌ Failed to decode conversations: \(error)")
            }
        }
        
        // Load projects
        if let projectsData = UserDefaults.standard.data(forKey: "projects") {
            do {
                let decodedProjects = try decoder.decode([Project].self, from: projectsData)
                DispatchQueue.main.async {
                    self.projects = decodedProjects
                }
                print("✅ Loaded \(decodedProjects.count) projects")
            } catch {
                print("❌ Failed to decode projects: \(error)")
            }
        }
        
        // Load selected conversation ID
        if let selectedIdString = UserDefaults.standard.string(forKey: "selectedConversationId"),
           let selectedId = UUID(uuidString: selectedIdString) {
            DispatchQueue.main.async {
                self.selectedConversationId = selectedId
            }
            print("✅ Loaded selected conversation ID: \(selectedId)")
        }
        
        // Load selected project ID
        if let projectIdString = UserDefaults.standard.string(forKey: "selectedProjectId"),
           let projectId = UUID(uuidString: projectIdString) {
            DispatchQueue.main.async {
                self.selectedProjectId = projectId
            }
            print("✅ Loaded selected project ID: \(projectId)")
        }
    }
    
    /// Saves the current state to UserDefaults
    public func saveState() {
        let conversationsToSave = conversations
        let projectsToSave = projects
        let selectedConversationId = selectedConversationId
        let selectedProjectId = selectedProjectId
        
        // Save to disk on a background queue
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                
                // Encode conversations
                let conversationsData = try encoder.encode(conversationsToSave)
                UserDefaults.standard.set(conversationsData, forKey: "conversations")
                
                // Encode projects
                let projectsData = try encoder.encode(projectsToSave)
                UserDefaults.standard.set(projectsData, forKey: "projects")
                
                // Save selected IDs
                UserDefaults.standard.set(selectedConversationId?.uuidString, forKey: "selectedConversationId")
                UserDefaults.standard.set(selectedProjectId?.uuidString, forKey: "selectedProjectId")
                
                print("✅ App state saved successfully")
            } catch {
                print("❌ Failed to save app state: \(error)")
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
@MainActor
extension AppState {
    static var preview: AppState {
        let state = AppState(llmService: LLMService.shared)
        
        // Add some sample conversations
        let conversation1 = state.createNewConversation(title: "Sample Chat 1")
        let message1 = Message(content: "Hello, how are you?", timestamp: Date().addingTimeInterval(-3600), isFromUser: true)
        let message2 = Message(content: "I'm doing well, thank you! How can I help you today?", timestamp: Date().addingTimeInterval(-3500), isFromUser: false)
        conversation1.addMessage(message1)
        conversation1.addMessage(message2)
        
        let conversation2 = state.createNewConversation(title: "Sample Chat 2")
        let message3 = Message(content: "What's the weather like?", timestamp: Date().addingTimeInterval(-1800), isFromUser: true)
        let message4 = Message(content: "I'm sorry, I don't have access to real-time weather data.", timestamp: Date().addingTimeInterval(-1750), isFromUser: false)
        conversation2.addMessage(message3)
        conversation2.addMessage(message4)
        
        // Add a sample project
        let project = state.createNewProject(name: "Sample Project")
        let projectConversation = state.createNewConversation(title: "Project Chat 1", inProject: project.id)
        let projectMessage = Message(content: "Let's work on the project", timestamp: Date().addingTimeInterval(-900), isFromUser: true)
        projectConversation.addMessage(projectMessage)
        
        state.selectedConversationId = conversation1.id
        
        return state
    }
}
#endif
