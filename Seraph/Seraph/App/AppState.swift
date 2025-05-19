//
//  AppState.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

// Simplified AppState
class AppState: ObservableObject {
    // MARK: - Shared Instance
    static let shared = AppState()
    
    // MARK: - UI State
    @Published var isDarkMode: Bool = true
    @Published var accentColor: Color = .blue
    
    // MARK: - Connection Status
    @Published var connectionStatus: ConnectionStatus = .connecting
    
    // MARK: - Processing Status
    @Published var isProcessingMessage: Bool = false
    
    // MARK: - Selected Model
    @Published var selectedModel: LLMModel = .ollama(.mistral7b)
    
    // Simple model parameters
    @Published var modelParameters = ModelParameters()
    
    // MARK: - Tab Selection
    @Published var selectedTab: Tab = .chat
    
    // MARK: - User
    @Published var userPreferences = UserPreferences()
    
    // MARK: - Advanced Configuration Options
    
    /// Flag to always use the generate endpoint instead of chat endpoint
    /// This avoids JSON parsing issues with models like DeepSeek
    @Published var alwaysUseGenerateEndpoint: Bool = true
    
    /// Flag to enable aggressive token counting by character estimate
    @Published var useAggressiveTokenCounting: Bool = true
    
    /// Flag to enable specialized creative content handling for DeepSeek models
    /// This helps with story generation and other creative tasks
    @Published var enableCreativeContentMode: Bool = true
    
    /// Conservative parameters for creative content to prevent JSON issues
    @Published var useConservativeParamsForCreative: Bool = true
    
    /// Debug mode to show raw model responses
    @Published var debugMode: Bool = false
    
    private init() {
        // Empty initialization
    }
    
    // Used by AppTheme to safely access the instance
    func accessInstance() -> AppState? {
        return AppState.shared
    }
    
    func saveSettings() {
        // Simplified placeholder for saving settings
        // In a real implementation, this would save to UserDefaults, Keychain, etc.
        print("AppState: Settings saved")
    }
}

// Minimal required enums and structs

// A global error handler to ensure processing state is reset
class GlobalErrorHandler {
    static func resetProcessingState() {
        DispatchQueue.main.async {
            if AppState.shared.isProcessingMessage {
                print("GlobalErrorHandler: Forcing reset of processing state")
                AppState.shared.isProcessingMessage = false
            }
        }
    }
    
    static func startProcessingTimeout() {
        // Set a fail-safe timeout that will reset processing state after 2 minutes
        // This ensures the app can't get permanently stuck
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            if AppState.shared.isProcessingMessage {
                print("GlobalErrorHandler: Processing timeout triggered - forcing reset")
                AppState.shared.isProcessingMessage = false
            }
        }
    }
}

enum Tab: String {
    case chat = "Chat"
    case projects = "Projects" 
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .chat: return "bubble.left"
        case .projects: return "folder"
        case .settings: return "gear"
        }
    }
}

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case unknown
    
    var icon: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .connecting: return "arrow.clockwise"
        case .disconnected: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        case .unknown: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnected: return "Disconnected"
        case .unknown: return "Unknown"
        }
    }
}

enum LLMProvider: String, CaseIterable {
    case ollama = "Ollama"
}

enum LLMModel: Hashable {
    case ollama(OllamaModel)
    
    var id: String {
        switch self {
        case .ollama(let model):
            return "ollama-\(model.rawValue)"
        }
    }
    
    var displayName: String {
        switch self {
        case .ollama(let model):
            return model.rawValue
        }
    }
    
    var provider: LLMProvider {
        switch self {
        case .ollama: return .ollama
        }
    }
    
    static func fromId(_ id: String) -> LLMModel? {
        if id.starts(with: "ollama-") {
            let modelName = id.replacingOccurrences(of: "ollama-", with: "")
            if let model = OllamaModel.allCases.first(where: { $0.rawValue == modelName }) {
                return .ollama(model)
            }
        }
        return .ollama(.mistral7b) // Default fallback
    }
}

enum OllamaModel: String, CaseIterable {
    // Mistral models
    case mistral7b = "Mistral 7B"
    
    // Llama models
    case llama3_8b = "Llama 3 8B"
    case llama3_70b = "Llama 3 70B"
    case llama3_8b_instruct = "Llama 3 8B Instruct"
    case llama3_70b_instruct = "Llama 3 70B Instruct"
    
    // CodeLlama models
    case codellama_7b = "CodeLlama 7B"
    case codellama_13b = "CodeLlama 13B"
    case codellama_34b = "CodeLlama 34B"
    
    // Phi models
    case phi3_mini = "Phi-3 Mini"
    case phi3_small = "Phi-3 Small"
    case phi3_medium = "Phi-3 Medium"
    
    // Gemma models
    case gemma_2b = "Gemma 2B"
    case gemma_7b = "Gemma 7B"
    
    // Vicuna models
    case vicuna_7b = "Vicuna 7B"
    case vicuna_13b = "Vicuna 13B"
    
    // DeepSeek models
    case deepseek_coder = "DeepSeek Coder"
    case deepseek = "DeepSeek"
    case deepseek_r1_14b_m4 = "DeepSeek-R1:14B-M4"
    case deepseek_r1_8b_m4 = "DeepSeek-R1:8B-M4"
    
    // Mixtral models
    case mixtral = "Mixtral"
    case mixtral_8x7b = "Mixtral 8x7B"
}

struct ModelParameters {
    var temperature: Double = 0.7
    var topP: Double = 0.95
    var maxTokens: Int = 2048
    var systemPrompt: String = "You are a helpful AI assistant."
}