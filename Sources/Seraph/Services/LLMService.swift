import Foundation

enum LLMModelError: Error {
    case modelNotFound
    case connectionFailed
    case invalidModelPath
}

protocol LLMService {
    var isConnected: Bool { get }
    var currentModel: String? { get }
    var availableModels: [String] { get }
    
    func connect(model: String) async throws
    func disconnect() async
    func sendMessage(_ message: String) async throws -> String
    func streamMessage(_ message: String) async throws -> AsyncStream<String>
    func getModelList() async throws -> [String]
    func ejectCurrentModel() async throws
}

class LLMServiceImpl: LLMService, ObservableObject {
    @Published var isConnected: Bool = false
    @Published var availableModels: [String] = []
    @Published var currentModel: String? = nil
    
    private var modelPath: String?
    
    init() {
        Task {
            await loadAvailableModels()
        }
    }
    
    private func loadAvailableModels() async {
        do {
            availableModels = try await getModelList()
            if !availableModels.isEmpty {
                currentModel = availableModels.first
            }
        } catch {
            print("Error loading models: \(error)")
        }
    }
    
    func connect(model: String) async throws {
        guard !availableModels.isEmpty else {
            throw LLMModelError.modelNotFound
        }
        
        guard availableModels.contains(model) else {
            throw LLMModelError.invalidModelPath
        }
        
        // Implement connection logic
        currentModel = model
        isConnected = true
    }
    
    func disconnect() async {
        isConnected = false
    }
    
    func ejectCurrentModel() async throws {
        guard isConnected else {
            return
        }
        
        // Implement model ejection logic
        // This would typically involve unloading the model from memory
        
        currentModel = nil
        isConnected = false
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard let model = currentModel else {
            throw LLMModelError.connectionFailed
        }
        
        // Implement message sending
        return "Response from \(model)"
    }
    
    func streamMessage(_ message: String) async throws -> AsyncStream<String> {
        guard let model = currentModel else {
            throw LLMModelError.connectionFailed
        }
        
        return AsyncStream { continuation in
            Task {
                // Simulate streaming
                for i in 0..<5 {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    continuation.yield("Stream part \(i + 1) from \(model)\n")
                }
                continuation.finish()
            }
        }
    }
    
    func getModelList() async throws -> [String] {
        return ["mistral", "deepseek", "llama2"]
    }
}
