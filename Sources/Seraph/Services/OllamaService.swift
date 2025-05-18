import Foundation

enum OllamaError: Error {
    case connectionFailed
    case modelNotFound
    case invalidResponse
    case streamingError
}

class OllamaService: LLMService {
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = "http://localhost:11434") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }
    
    var isConnected: Bool = false
    var currentModel: String?
    var availableModels: [String] = []
    
    func connect(model: String) async throws {
        guard !model.isEmpty else {
            throw OllamaError.modelNotFound
        }
        
        let url = URL(string: "\(baseURL)/api/generate")!
        let request = URLRequest(url: url)
        
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw OllamaError.connectionFailed
            }
            
            isConnected = true
            currentModel = model
        } catch {
            throw OllamaError.connectionFailed
        }
    }
    
    func disconnect() async {
        isConnected = false
        currentModel = nil
    }
    
    func sendMessage(_ message: String) async throws -> String {
        var response = ""
        
        for try await chunk in try await streamMessage(message) {
            response += chunk
        }
        
        return response
    }
    
    func streamMessage(_ message: String) async throws -> AsyncStream<String> {
        guard let model = currentModel else {
            throw OllamaError.modelNotFound
        }
        
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a dictionary for JSON encoding
        let requestDict: [String: Any] = [
            "model": model,
            "prompt": message,
            "stream": true
        ]
        
        // Convert to JSON data
        let requestBody = try JSONSerialization.data(withJSONObject: requestDict)
        
        request.httpBody = requestBody
        
        return AsyncStream<String> { continuation in
            Task {
                do {
                    let (stream, _) = try await session.bytes(for: request)
                    
                    for try await line in stream.lines {
                        if let data = line.data(using: .utf8),
                           let response = try? JSONDecoder().decode(OllamaResponse.self, from: data) {
                            if let text = response.response {
                                continuation.yield(text)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("Streaming error: \(error)")
                    continuation.finish()
                }
            }
        }
    }
    
    func getModelList() async throws -> [String] {
        let url = URL(string: "\(baseURL)/api/tags")!
        let (data, _) = try await session.data(from: url)
        
        let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return response.models
    }
    
    private struct OllamaResponse: Codable {
        let response: String?
    }
    
    private struct OllamaTagsResponse: Codable {
        let models: [String]
    }
    
    func ejectCurrentModel() async throws {
        isConnected = false
        currentModel = nil
    }
}
