import Foundation
import UniformTypeIdentifiers

/// Represents an AI model that can be used for generating responses
public enum AIModel: Identifiable, Hashable, Codable, CaseIterable {
    case builtIn(String, displayName: String, description: String, requiresAPIKey: Bool)
    case localModel(name: String, path: String, displayName: String, description: String)
    public var id: String {
        switch self {
        case .builtIn(let id, _, _, _):
            return "builtin_\(id)"
        case .localModel(let name, let path, _, _):
            return "local_\(name)_\(path.hashValue)"
        }
    }
    
    public var rawValue: String {
        switch self {
        case .builtIn(let id, _, _, _):
            return id
        case .localModel(let name, let path, _, _):
            return "local:\(name):\(path)"
        }
    }
    
    /// The display name of the model
    public var displayName: String {
        switch self {
        case .builtIn(_, let displayName, _, _):
            return displayName
        case .localModel(_, _, let displayName, _):
            return "\(displayName) (Local)"
        }
    }
    
    /// All available models
    public static var allCases: [AIModel] {
        [
            .llama3,
            .mistral,
            .gemma,
            .gpt4,
            .gpt3_5,
            .claude3
        ]
    }
    
    // MARK: - Built-in Models
    
    public static let llama3 = AIModel.builtIn(
        "llama3",
        displayName: "Llama 3",
        description: "Meta's latest open source model, good balance of speed and quality",
        requiresAPIKey: false
    )
    
    public static let mistral = AIModel.builtIn(
        "mistral",
        displayName: "Mistral",
        description: "High-quality open source model with strong performance",
        requiresAPIKey: false
    )
    
    public static let gemma = AIModel.builtIn(
        "gemma",
        displayName: "Gemma",
        description: "Google's lightweight, state-of-the-art open models",
        requiresAPIKey: false
    )
    
    public static let gpt4 = AIModel.builtIn(
        "gpt-4",
        displayName: "GPT-4",
        description: "Most capable model, great for complex tasks (requires API key)",
        requiresAPIKey: true
    )
    
    public static let gpt3_5 = AIModel.builtIn(
        "gpt-3.5-turbo",
        displayName: "GPT-3.5",
        description: "Fast and capable, good for most use cases (requires API key)",
        requiresAPIKey: true
    )
    
    public static let claude3 = AIModel.builtIn(
        "claude-3",
        displayName: "Claude 3",
        description: "Anthropic's most capable model (requires API key)",
        requiresAPIKey: true
    )
    
    /// A description of the model
    public var description: String {
        switch self {
        case .builtIn(_, _, let description, _):
            return description
        case .localModel(_, _, _, let description):
            return description
        }
    }
    
    /// Whether this model requires an API key
    public var requiresAPIKey: Bool {
        switch self {
        case .builtIn(_, _, _, let requiresAPIKey):
            return requiresAPIKey
        case .localModel:
            return false
        }
    }
    
    /// The model file path if this is a local model
    public var modelPath: String? {
        if case .localModel(_, let path, _, _) = self {
            return path
        }
        return nil
    }
    

    
    /// The default model to use
    public static var defaultModel: AIModel = llama3
    
    /// Returns all built-in models that don't require an API key
    public static var localBuiltInModels: [AIModel] {
        return [llama3, mistral, gemma]
    }
    
    /// Returns all available models including built-in, API, and custom local models
    public static var allModels: [AIModel] {
        var models = [AIModel]()
        
        // Add built-in local models
        models.append(contentsOf: localBuiltInModels)
        
        // Add API models
        models.append(contentsOf: apiModels)
        
        // Load custom local models from UserDefaults
        if let savedModels = UserDefaults.standard.array(forKey: "customLocalModels") as? [[String: String]] {
            for modelData in savedModels {
                if let name = modelData["name"],
                   let path = modelData["path"],
                   let displayName = modelData["displayName"],
                   let description = modelData["description"] {
                    let model = AIModel.localModel(
                        name: name,
                        path: path,
                        displayName: displayName,
                        description: description
                    )
                    models.append(model)
                }
            }
        }
        
        return models
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case type, id, name, path, displayName, description, requiresAPIKey
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "builtIn":
            let id = try container.decode(String.self, forKey: .id)
            let displayName = try container.decode(String.self, forKey: .displayName)
            let description = try container.decode(String.self, forKey: .description)
            let requiresAPIKey = try container.decode(Bool.self, forKey: .requiresAPIKey)
            self = .builtIn(id, displayName: displayName, description: description, requiresAPIKey: requiresAPIKey)
            
        case "localModel":
            let name = try container.decode(String.self, forKey: .name)
            let path = try container.decode(String.self, forKey: .path)
            let displayName = try container.decode(String.self, forKey: .displayName)
            let description = try container.decode(String.self, forKey: .description)
            self = .localModel(name: name, path: path, displayName: displayName, description: description)
            
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid model type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .builtIn(let id, let displayName, let description, let requiresAPIKey):
            try container.encode("builtIn", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(displayName, forKey: .displayName)
            try container.encode(description, forKey: .description)
            try container.encode(requiresAPIKey, forKey: .requiresAPIKey)
            
        case .localModel(let name, let path, let displayName, let description):
            try container.encode("localModel", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(path, forKey: .path)
            try container.encode(displayName, forKey: .displayName)
            try container.encode(description, forKey: .description)
        }
    }
    
    /// Returns all local models (both built-in and custom) that don't require an API key
    public static var localModels: [AIModel] {
        return allModels.filter { model in
            switch model {
            case .builtIn(_, _, _, false):
                return true  // Built-in local models
            case .localModel:
                return true  // Custom local models
            default:
                return false
            }
        }
    }
    
    /// Add a new local model
    public static func addLocalModel(name: String, path: String, displayName: String, description: String) {
        var savedModels = UserDefaults.standard.array(forKey: "customLocalModels") as? [[String: String]] ?? []
        
        // Check if model with same path already exists
        if !savedModels.contains(where: { $0["path"] == path }) {
            let modelData: [String: String] = [
                "name": name,
                "path": path,
                "displayName": displayName,
                "description": description
            ]
            savedModels.append(modelData)
            UserDefaults.standard.set(savedModels, forKey: "customLocalModels")
        }
    }
    
    /// Remove a local model
    public static func removeLocalModel(at index: Int) {
        var savedModels = UserDefaults.standard.array(forKey: "customLocalModels") as? [[String: String]] ?? []
        guard index >= 0, index < savedModels.count else { return }
        savedModels.remove(at: index)
        UserDefaults.standard.set(savedModels, forKey: "customLocalModels")
    }
    
    /// Returns all models that require an API key
    public static var apiModels: [AIModel] {
        return allModels.filter { model in
            if case .builtIn(_, _, _, true) = model {
                return true
            }
            return false
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension AIModel {
    static var preview: AIModel = .llama3
}
#endif
