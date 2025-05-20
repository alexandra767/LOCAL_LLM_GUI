import Foundation

/// Represents an AI model that can be used for generating responses
public struct AIModel: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for the model
    public let id: String
    
    /// Display name of the model
    public let name: String
    
    /// Description of the model's capabilities
    public let description: String
    
    /// The provider of the model (e.g., "Ollama", "OpenAI")
    public let provider: String
    
    /// Whether the model is running locally
    public let isLocal: Bool
    
    /// Maximum number of tokens the model can handle in a single request
    public let maxTokens: Int
    
    /// All available AI models
    public static let availableModels: [AIModel] = [
        // Local models (Ollama)
        AIModel(
            id: "llama3",
            name: "Llama 3",
            description: "Meta's latest open model, good balance of speed and quality",
            provider: "Ollama",
            isLocal: true,
            maxTokens: 8192
        ),
        AIModel(
            id: "mistral",
            name: "Mistral",
            description: "High quality open model, good for coding",
            provider: "Ollama",
            isLocal: true,
            maxTokens: 4096
        ),
        
        // Cloud models (example placeholders)
        AIModel(
            id: "gpt-4",
            name: "GPT-4",
            description: "Most capable model, great for complex tasks",
            provider: "OpenAI",
            isLocal: false,
            maxTokens: 8192
        ),
        AIModel(
            id: "claude-3-opus",
            name: "Claude 3 Opus",
            description: "Most capable Claude model, excelling at highly complex tasks",
            provider: "Anthropic",
            isLocal: false,
            maxTokens: 200000
        )
    ]
    
    /// Get a model by its ID
    /// - Parameter id: The ID of the model to retrieve
    /// - Returns: The model with the specified ID, or nil if not found
    public static func getModel(byId id: String) -> AIModel? {
        return availableModels.first { $0.id == id }
    }
    
    static var defaultModel: AIModel {
        return availableModels.first { $0.id == "llama3" } ?? availableModels[0]
    }
}
