import Foundation

class AppState: ObservableObject {
    @Published var selectedProject: Project?
    @Published var selectedChat: Chat?
    @Published var isSidebarCollapsed: Bool = false
    
    // Chat and Message Data
    @Published var chats: [Chat] = []
    @Published var chatHistory: [Message] = []
    
    // LLM Service
    let llmService: LLMService
    
    // Connection State
    var isConnected: Bool {
        return llmService.isConnected
    }
    
    var currentModel: String? {
        return llmService.currentModel
    }
    
    // Model State
    @Published var availableModels: [String] = []
    @Published var selectedModel: String? {
        didSet {
            Task {
                do {
                    try await llmService.connect(model: selectedModel ?? "")
                } catch {
                    print("Error connecting to model: \(error)")
                }
            }
        }
    }
    
    // UI State
    @Published var showSettings: Bool = false
    @Published var showNewChat: Bool = false
    @Published var showProfileEditor: Bool = false
    @Published var showFilePicker: Bool = false
    @Published var showProjectsView: Bool = false
    
    init() {
        self.llmService = LLMServiceImpl()
        
        // Load available models
        Task {
            do {
                availableModels = try await llmService.getModelList()
                if !availableModels.isEmpty {
                    selectedModel = availableModels.first
                }
            } catch {
                print("Error loading models: \(error)")
            }
        }
    }
}
