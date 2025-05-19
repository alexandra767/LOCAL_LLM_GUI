import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // UI State
    @Published var selectedTab: Tab = .chat
    @Published var selectedProject: Project?
    @Published var showSettings = false
    @Published var isSidebarVisible = true
    
    // Data
    @Published var projects: [Project] = []
    @Published var recentChats: [ChatConversation] = []
    
    // Authentication
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    enum Tab {
        case chat, files, settings
    }
    
    init() {
        loadSampleData()
    }
    
    // MARK: - Data Management
    
    func createNewProject() {
        let project = Project(name: "New Project")
        projects.append(project)
        selectedProject = project
        selectedTab = .chat
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id {
            selectedProject = nil
        }
    }
    
    @discardableResult
    func createNewChat() -> ChatConversation {
        let chat = ChatConversation(title: "New Chat", messages: [])
        recentChats.insert(chat, at: 0)
        selectedTab = .chat
        return chat
    }
    
    // MARK: - Sample Data
    
    func loadSampleData() {
        projects = [
            Project(name: "Project 1", isPinned: true),
            Project(name: "Project 2"),
            Project(name: "Project 3", isPinned: true)
        ]
        
        recentChats = [
            ChatConversation(title: "Welcome to Seraph", messages: [])
        ]
    }
}
