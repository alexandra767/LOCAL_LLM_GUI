//
//  SettingsViewModel.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI
import Combine
import CoreData

/// ViewModel for application settings
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User
    @Published var customPrompts: [SystemPrompt] = []
    @Published var availableModels: [LLMModel] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared
    private var userRepository: UserRepository
    private var managedObjectContext: NSManagedObjectContext?
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext? = nil) {
        // Initialize the user repository with the persistence controller
        self.userRepository = UserRepository(persistenceController: PersistenceController.shared)
        self.managedObjectContext = context
        
        // Initialize with default user
        self.user = User(
            name: "Default User",
            preferences: UserPreferences()
        )
        
        loadUser()
        loadSettings()
        loadAvailableModels()
    }
    
    /// Load user from CoreData
    private func loadUser() {
        // Try to load the current user from CoreData
        if let loadedUser = userRepository.getCurrentUser() {
            self.user = loadedUser
        } else {
            // Create a new user if none exists
            let newUser = User(
                name: "Default User",
                preferences: UserPreferences()
            )
            self.user = userRepository.saveUser(newUser)
        }
    }
    
    // MARK: - Public Methods
    
    /// Load user data and preferences
    func loadUserData() {
        loadUser()
        loadSettings()
        loadAvailableModels()
    }
    
    /// Load user settings
    func loadSettings() {
        // In a real implementation, this would load settings from UserDefaults or CoreData
        // For now, we'll create some sample data
        customPrompts = [
            SystemPrompt(
                name: "Default Assistant",
                content: "You are a helpful AI assistant.",
                isDefault: true
            ),
            SystemPrompt(
                name: "Code Assistant",
                content: "You are a helpful programming assistant. Provide code examples and explanations that help developers understand concepts and solve problems."
            ),
            SystemPrompt(
                name: "Creative Writer",
                content: "You are a creative writing assistant skilled in generating stories, narratives, and creative content."
            )
        ]
    }
    
    /// Load available LLM models
    func loadAvailableModels() {
        // Load only Ollama models from the OllamaModel enum since we're focusing on local models
        availableModels = OllamaModel.allCases.map { .ollama($0) }
    }
    
    /// Update user preferences
    func updatePreferences(_ preferences: UserPreferences) {
        user.preferences = preferences
        
        // Update app state
        appState.isDarkMode = preferences.isDarkMode
        appState.accentColor = Color(hex: preferences.accentColor)
        
        // Use LLMModel.fromId extension from AppState
        if let model = LLMModel.fromId(preferences.defaultModel) {
            appState.selectedModel = model
        }
        
        // Save settings
        saveSettings()
    }
    
    /// Save user settings
    func saveSettings() {
        // Save user to CoreData and update local user object with any changes from CoreData
        self.user = userRepository.saveUser(user)
        
        // Update app state
        appState.saveSettings()
    }
    
    /// Update user profile
    func updateUser(_ updatedUser: User) {
        self.user = updatedUser
        saveSettings()
        
        // Notify any subscribers that the user has changed
        objectWillChange.send()
    }
    
    /// Create a new custom system prompt
    func createSystemPrompt(name: String, content: String) -> UUID {
        let newPrompt = SystemPrompt(
            name: name,
            content: content
        )
        
        customPrompts.append(newPrompt)
        return newPrompt.id
    }
    
    /// Update an existing system prompt
    func updateSystemPrompt(_ prompt: SystemPrompt) {
        if let index = customPrompts.firstIndex(where: { $0.id == prompt.id }) {
            customPrompts[index] = prompt
        }
    }
    
    /// Delete a system prompt
    func deleteSystemPrompt(_ promptId: UUID) {
        customPrompts.removeAll { $0.id == promptId && !$0.isDefault }
    }
    
    /// Set a system prompt as default
    func setDefaultSystemPrompt(_ promptId: UUID) {
        for i in 0..<customPrompts.count {
            customPrompts[i].isDefault = (customPrompts[i].id == promptId)
        }
        
        if let defaultPrompt = customPrompts.first(where: { $0.isDefault }) {
            user.preferences.defaultSystemPrompt = defaultPrompt.content
            updatePreferences(user.preferences)
        }
    }
    
    /// Check if a model is available
    func isModelAvailable(_ model: LLMModel) -> Bool {
        // For local models, just check the connection status
        return appState.connectionStatus == .connected
    }
    
    /// Get available model options by category
    func availableModelsByCategory() -> [(String, [LLMModel])] {
        // Group models by category
        let models = OllamaModel.allCases
        
        // DeepSeek models
        let deepseekModels = models.filter { 
            $0 == .deepseek || $0 == .deepseek_coder || 
            $0 == .deepseek_r1_14b_m4 || $0 == .deepseek_r1_8b_m4 
        }.map { LLMModel.ollama($0) }
        
        // Llama models
        let llamaModels = models.filter { 
            $0 == .llama3_8b || $0 == .llama3_70b || 
            $0 == .llama3_8b_instruct || $0 == .llama3_70b_instruct
        }.map { LLMModel.ollama($0) }
        
        // CodeLlama models
        let codeLlamaModels = models.filter { 
            $0 == .codellama_7b || $0 == .codellama_13b || $0 == .codellama_34b
        }.map { LLMModel.ollama($0) }
        
        // Phi models
        let phiModels = models.filter { 
            $0 == .phi3_mini || $0 == .phi3_small || $0 == .phi3_medium
        }.map { LLMModel.ollama($0) }
        
        // Mixtral models
        let mixtralModels = models.filter { 
            $0 == .mixtral || $0 == .mixtral_8x7b
        }.map { LLMModel.ollama($0) }
        
        // Other models
        let otherModels = models.filter { 
            $0 == .mistral7b || $0 == .gemma_2b || $0 == .gemma_7b ||
            $0 == .vicuna_7b || $0 == .vicuna_13b
        }.map { LLMModel.ollama($0) }
        
        return [
            ("DeepSeek", deepseekModels),
            ("Llama", llamaModels),
            ("CodeLlama", codeLlamaModels),
            ("Phi", phiModels),
            ("Mixtral", mixtralModels),
            ("Other", otherModels)
        ]
    }
    
    /// Get the default system prompt
    var defaultSystemPrompt: SystemPrompt? {
        customPrompts.first { $0.isDefault }
    }
}