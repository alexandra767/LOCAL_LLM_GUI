import Foundation

/// Represents an AI model that can be used for generating responses
public enum AIModel: String, CaseIterable, Identifiable, Codable {
    case llama3 = "llama3"
    case mistral = "mistral"
    case gemma = "gemma"
    case gpt4 = "gpt-4"
    case gpt3_5 = "gpt-3.5-turbo"
    case claude = "claude-2"
    
    public var id: String { rawValue }
    
    /// The display name of the model
    public var displayName: String {
        switch self {
        case .llama3: return "Llama 3"
        case .mistral: return "Mistral"
        case .gemma: return "Gemma"
        case .gpt4: return "GPT-4"
        case .gpt3_5: return "GPT-3.5"
        case .claude: return "Claude 2"
        }
    }
    
    /// A description of the model
    public var description: String {
        switch self {
        case .llama3: return "Meta's latest open source model, good balance of speed and quality"
        case .mistral: return "High-quality open source model with strong performance"
        case .gemma: return "Google's lightweight, state-of-the-art open models"
        case .gpt4: return "Most capable model, great for complex tasks (requires API key)"
        case .gpt3_5: return "Fast and capable, good for most use cases (requires API key)"
        case .claude: return "Anthropic's model with strong reasoning (requires API key)"
        }
    }
    
    /// Whether this model requires an API key
    public var requiresAPIKey: Bool {
        switch self {
        case .llama3, .mistral, .gemma:
            return false
        case .gpt4, .gpt3_5, .claude:
            return true
        }
    }
    
    /// The default model to use
    public static var defaultModel: AIModel = .llama3
    
    /// Returns all models that don't require an API key
    public static var localModels: [AIModel] {
        allCases.filter { !$0.requiresAPIKey }
    }
    
    /// Returns all models that require an API key
    public static var cloudModels: [AIModel] {
        allCases.filter { $0.requiresAPIKey }
    }
}

// MARK: - Preview Support

#if DEBUG
extension AIModel {
    static var preview: AIModel = .llama3
}
#endif
