//
//  OllamaService.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import Combine

/// Service for Ollama models (open source local models)
class OllamaService: LLMServiceProtocol {
    // MARK: - Shared Instance
    static let shared = OllamaService()
    
    // MARK: - Private Properties
    private let baseUrl = "http://localhost:11434/api"
    private let urlSession: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - LLMServiceProtocol Implementation
    
    func sendMessage(messages: [Message], model: LLMModel) -> AnyPublisher<String, Error> {
        return sendMessage(messages: messages, model: model, parameters: AppState.shared.modelParameters)
    }
    
    func sendMessage(messages: [Message], model: LLMModel, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // Validate model
        guard case .ollama(let ollamaModel) = model else {
            return Fail(error: LLMServiceError.modelNotAvailable).eraseToAnyPublisher()
        }
        
        // Return offline message if not connected
        if AppState.shared.connectionStatus != .connected {
            let message = """
            I'm currently running in offline mode. The connection to Ollama appears to be unavailable.

            To use Ollama with this app:
            1. Make sure Ollama is installed (https://ollama.com)
            2. Open Terminal and run: ollama serve
            3. Ensure the Ollama server is running on http://localhost:11434
            4. Restart this app after Ollama is running

            Some models may need to be pulled first with:
            ollama pull \(ollamaModel.rawValue.replacingOccurrences(of: " ", with: "-").lowercased())
            """
            
            return Just(message)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        // ------- REAL IMPLEMENTATION (ENABLED) -------
        
        // Convert model name to Ollama format (lowercase with hyphens)
        let ollamaModelName = ollamaModel.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        
        // For non-chat models, use the generate endpoint with the last message only
        if messages.count == 1 {
            return sendGenerateRequest(
                prompt: messages[0].content,
                model: ollamaModelName,
                systemPrompt: parameters.systemPrompt,
                parameters: parameters
            )
        }
        
        // For chat, use the chat endpoint
        return sendChatRequest(
            messages: messages,
            model: ollamaModelName,
            systemPrompt: parameters.systemPrompt,
            parameters: parameters
        )
    }
    
    // Send a request to the generate endpoint (simpler, for single messages)
    private func sendGenerateRequest(prompt: String, model: String, systemPrompt: String, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // Create the generate request
        let generateRequest = OllamaAPI.GenerateRequest(
            model: model,
            prompt: prompt,
            system: systemPrompt.isEmpty ? nil : systemPrompt,
            temperature: parameters.temperature,
            top_p: parameters.topP,
            format: nil,
            num_predict: parameters.maxTokens
        )
        
        // Convert to JSON data
        guard let jsonData = try? JSONEncoder().encode(generateRequest) else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        // Create URL request
        guard let url = URL(string: "\(baseUrl)/generate") else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For debugging
        print("Generate Request URL: \(url.absoluteString)")
        print("Generate Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
        
        return simpleRequest(request: request)
    }
    
    // Send a request to the chat endpoint (for multiple messages)
    private func sendChatRequest(messages: [Message], model: String, systemPrompt: String, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // Convert app messages to Ollama chat messages
        let chatMessages = messages.map { OllamaAPI.ChatMessage.from($0) }
        
        // Create the chat request
        let chatRequest = OllamaAPI.ChatRequest(
            model: model,
            messages: chatMessages,
            system: systemPrompt.isEmpty ? nil : systemPrompt,
            temperature: parameters.temperature,
            top_p: parameters.topP,
            format: nil,
            num_predict: parameters.maxTokens
        )
        
        // Convert to JSON data
        guard let jsonData = try? JSONEncoder().encode(chatRequest) else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        // Create URL request
        guard let url = URL(string: "\(baseUrl)/chat") else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For debugging
        print("Chat Request URL: \(url.absoluteString)")
        print("Chat Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
        
        // Use streaming request handler for real-time updates
        return streamingRequest(request: request)
    }
    
    // Stream data from the API with line-by-line JSON parsing
    private func streamingRequest(request: URLRequest) -> AnyPublisher<String, Error> {
        let subject = PassthroughSubject<String, Error>()
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(LLMServiceError.networkError("Invalid response")))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error response
                if let data = data, 
                   let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = errorJson["error"] as? String {
                    subject.send(completion: .failure(LLMServiceError.serverError(errorMessage)))
                } else {
                    subject.send(completion: .failure(LLMServiceError.serverError("HTTP error \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                subject.send(completion: .failure(LLMServiceError.unknownError("No data received")))
                return
            }
            
            // Process the data line by line (as JSON objects)
            let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            for line in lines {
                if let lineData = line.data(using: .utf8),
                   let response = try? JSONDecoder().decode(OllamaAPI.Response.self, from: lineData) {
                    subject.send(response.response)
                }
            }
            
            subject.send(completion: .finished)
        }
        
        // Start the task
        task.resume()
        
        // Store the task in a cancellable that will cancel the task when cancelled
        let cancellable = AnyCancellable {
            task.cancel()
        }
        
        cancellables.insert(cancellable)
        
        return subject.eraseToAnyPublisher()
    }
    
    // A simplified non-streaming request to get the full response at once
    private func simpleRequest(request: URLRequest) -> AnyPublisher<String, Error> {
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMServiceError.networkError("Invalid response")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to parse error response
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = errorJson["error"] as? String {
                        throw LLMServiceError.serverError(errorMessage)
                    } else {
                        throw LLMServiceError.serverError("HTTP error \(httpResponse.statusCode)")
                    }
                }
                
                // For debugging
                print("Response Data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF8")")
                
                return data
            }
            .flatMap { data -> AnyPublisher<String, Error> in
                // Try to decode as a single response
                if let json = try? JSONDecoder().decode(OllamaAPI.Response.self, from: data) {
                    return Just(json.response)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                // If not a single response, try to parse as a newline-delimited JSON stream
                if let text = String(data: data, encoding: .utf8) {
                    let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                    var fullResponse = ""
                    
                    for line in lines {
                        if let lineData = line.data(using: .utf8),
                           let json = try? JSONDecoder().decode(OllamaAPI.Response.self, from: lineData) {
                            fullResponse += json.response
                        }
                    }
                    
                    if !fullResponse.isEmpty {
                        return Just(fullResponse)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                }
                
                // If all else fails, just return the plain text response
                if let text = String(data: data, encoding: .utf8) {
                    return Just(text)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                return Fail(error: LLMServiceError.unknownError("Failed to parse response"))
                    .eraseToAnyPublisher()
            }
            .catch { error -> AnyPublisher<String, Error> in
                print("Request error: \(error.localizedDescription)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func checkAvailability() -> AnyPublisher<Bool, Error> {
        // For debugging: print endpoint URL
        let urlString = "\(baseUrl)/tags"
        print("Checking Ollama availability at: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3 // Even shorter timeout for availability check
        
        // Start a timer to force-fail if request is taking too long
        let timerPublisher = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .first()
            .map { _ -> Bool in
                print("Timeout check failed: Force failing after 5 seconds")
                return false
            }
            .setFailureType(to: Error.self)
        
        let requestPublisher = urlSession.dataTaskPublisher(for: request)
            .timeout(.seconds(3), scheduler: RunLoop.main) // Add a timeout constraint
            .tryMap { data, response -> Bool in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Not an HTTP response")
                    throw LLMServiceError.networkError("Invalid response")
                }
                
                let statusCode = httpResponse.statusCode
                print("Status code: \(statusCode)")
                
                if !(200...299).contains(statusCode) {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response text: \(responseString)")
                    }
                    throw LLMServiceError.serverError("HTTP error \(statusCode)")
                }
                
                return true
            }
            .retry(1) // One retry attempt
            .catch { error -> AnyPublisher<Bool, Error> in
                print("Ollama availability check failed: \(error.localizedDescription)")
                return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Return the first publisher that completes
        return Publishers.Merge(requestPublisher, timerPublisher)
            .first() // Only take the first result
            .eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    /// Send a chat request directly with messages
    func sendChatRequest(messages: [Message]) -> AnyPublisher<String, Error> {
        return sendMessage(messages: messages, model: AppState.shared.selectedModel)
    }
    
    // MARK: - Helper Methods
    
    /// Get a list of available models from Ollama
    func fetchAvailableModels() -> AnyPublisher<[OllamaAPI.ModelsResponse.ModelInfo], Error> {
        guard let url = URL(string: "\(baseUrl)/tags") else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMServiceError.networkError("Invalid response")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw LLMServiceError.serverError("HTTP error \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: OllamaAPI.ModelsResponse.self, decoder: JSONDecoder())
            .map { $0.models }
            .catch { error -> AnyPublisher<[OllamaAPI.ModelsResponse.ModelInfo], Error> in
                print("Failed to fetch Ollama models: \(error.localizedDescription)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Simple helper to create a model name that Ollama expects
    func ollamaModelName(from model: OllamaModel) -> String {
        return model.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
    }
    
    // Cancel any current request
    func cancelRequest() {
        cancellables.forEach { $0.cancel() }
    }
}