import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // MARK: - UI State
    @Published var selectedTab: Tab = .chat
    @Published var selectedProject: Project?
    @Published var selectedChatId: String?
    @Published var showSettings = false
    @Published var isSidebarVisible = true
    
    // MARK: - Data
    @Published var projects: [Project] = []
    @Published var recentChats: [ChatConversation] = []
    
    // MARK: - Authentication
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    // MARK: - Enums
    enum Tab: String, CaseIterable {
        case chat = "Chats"
        case files = "Files"
        case settings = "Settings"
    }
    
    // MARK: - Initialization
    init() {
        loadSampleData()
    }
    
    // MARK: - Project Management
    
    /// Creates a new project with the given name
    @discardableResult
    func createProject(name: String = "New Project", description: String? = nil) -> Project {
        let project = Project(
            id: UUID().uuidString, 
            name: name, 
            description: description,
            lastUpdated: Date()
        )
        projects.append(project)
        selectedProject = project
        return project
    }
    
    /// Toggles the pinned state of a project
    func togglePin(project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isPinned.toggle()
            objectWillChange.send()
        }
    }
    
    /// Archives a project
    func archiveProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isArchived = true
            objectWillChange.send()
        }
    }
    
    /// Deletes the specified project
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id {
            selectedProject = nil
        }
    }
    
    // MARK: - Chat Management
    
    /// Creates a new chat conversation
    @discardableResult
    func createNewChat(title: String? = nil, projectId: String? = nil) -> ChatConversation {
        let chatTitle = title ?? "New Chat"
        let chat = ChatConversation(
            id: UUID().uuidString,
            title: chatTitle,
            projectId: projectId,
            lastMessage: "",
            timestamp: Date()
        )
        recentChats.insert(chat, at: 0)
        selectedChatId = chat.id
        return chat
    }
    
    /// Toggles the pinned state of a chat
    func togglePin(chat: ChatConversation) {
        if let index = recentChats.firstIndex(where: { $0.id == chat.id }) {
            recentChats[index].isPinned.toggle()
            objectWillChange.send()
        }
    }
    
    /// Selects a chat by its ID
    func selectChat(_ chatId: String) {
        selectedChatId = chatId
    }
    
    /// Deletes the specified chat
    func deleteChat(_ chat: ChatConversation) {
        recentChats.removeAll { $0.id == chat.id }
        if selectedChatId == chat.id {
            selectedChatId = nil
        }
    }
    
    // MARK: - User Management
    
    /// Signs in a user
    func signIn(user: User) {
        currentUser = user
        isAuthenticated = true
    }
    
    /// Signs out the current user
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Sample Data
    
    /// Loads sample data for preview and testing
    func loadSampleData() {
        // Sample user
        currentUser = User(
            id: "user_123",
            name: "John Doe",
            email: "john@example.com",
            subscription: .pro
        )
        isAuthenticated = true
        
        // Sample projects
        var project1 = createProject(
            name: "Mobile App",
            description: "New mobile application project"
        )
        project1.isPinned = true
        
        let project2 = createProject(
            name: "Website Redesign",
            description: "Redesign of company website"
        )
        
        // Sample chats
        _ = createNewChat(
            title: "Welcome to Seraph",
            projectId: project1.id
        )
        
        _ = createNewChat(
            title: "Project Discussion",
            projectId: project1.id
        )
        
        _ = createNewChat(
            title: "UI/UX Review",
            projectId: project2.id
        )
        
        // Mark the first chat as pinned
        if let firstChat = recentChats.first {
            togglePin(chat: firstChat)
        }
        projects = [
            Project(id: "p1", name: "Mobile App", lastUpdated: Date()),
            Project(id: "p2", name: "Website Redesign", lastUpdated: Date().addingTimeInterval(-86400)),
            Project(id: "p3", name: "API Development", lastUpdated: Date().addingTimeInterval(-172800))
        ]
        
        // Sample chats
        recentChats = [
            ChatConversation(
                id: "c1",
                title: "Welcome to Seraph",
                projectId: "p1",
                lastMessage: "Hello! How can I help you today?",
                timestamp: Date()
            ),
            ChatConversation(
                id: "c2",
                title: "Project Discussion",
                projectId: "p2",
                lastMessage: "Let's discuss the UI design",
                timestamp: Date().addingTimeInterval(-3600)
            )
        ]
        
        // Sample user
        currentUser = User(
            id: "u1",
            name: "John Doe",
            email: "john@example.com",
            avatarURL: nil
        )
        isAuthenticated = true
    }
}
