import Foundation

// Simple OllamaService for testing LLM connection
class OllamaService {
    private let baseURL: String
    private let session: URLSession
    private var currentModel: String?
    
    init(baseURL: String = "http://localhost:11434", model: String = "mistral") {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.currentModel = model
        print("Initialized OllamaService with model: \(model)")
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard let model = currentModel else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No model selected"])
        }
        
        print("Sending message to model \(model): \"\(message)\"")
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a dictionary for JSON encoding
        let requestDict: [String: Any] = [
            "model": model,
            "prompt": message,
            "stream": false
        ]
        
        // Convert to JSON data
        let requestBody = try JSONSerialization.data(withJSONObject: requestDict)
        request.httpBody = requestBody
        
        print("Sending request to \(url)...")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("Received response with status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("Error response: \(errorText)")
            }
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
        }
        
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = responseDict["response"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return responseText
    }
    
    func getModelList() async throws -> [String] {
        let url = URL(string: "\(baseURL)/api/tags")!
        
        print("Fetching available models from \(url)...")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get model list"])
        }
        
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = responseDict["models"] as? [String] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid model list format"])
        }
        
        return models
    }
}

print("Starting Ollama connection test...")

// Run the test
@main struct TestApp {
    static func main() async throws {
        print("Initializing test connection...")
        let ollama = OllamaService()
        
        // Test 1: Get available models
        print("\n--- Test 1: Fetching available models ---")
        let models = try await ollama.getModelList()
        print("Available models: \(models.joined(separator: ", "))")
        
        // Test 2: Send a message
        print("\n--- Test 2: Sending a test message ---")
        let response = try await ollama.sendMessage("What is the capital of France?")
        print("\nResponse from model:")
        print("-------------------")
        print(response)
        print("-------------------")
        print("\nConnection test completed successfully!")
    }
}