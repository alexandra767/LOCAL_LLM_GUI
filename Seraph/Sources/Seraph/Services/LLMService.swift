import Foundation
import Combine

/// Errors that can occur during LLM operations
public enum LLMError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimitExceeded
    case invalidAPIKey
    case requestFailed(Error)
    case decodingError(Error)
    case noDataReceived
    case invalidModel
    case invalidRequest
    case modelNotAvailable
    case contextTooLarge
    case generationFailed
    case unsupportedModel
    case invalidAPIKeyFormat
    case networkUnavailable
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidAPIKey, .invalidAPIKeyFormat:
            return "The provided API key is invalid or missing."
        case .requestFailed(let error):
            return "Request failed with error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noDataReceived:
            return "No data was received from the server."
        case .invalidModel:
            return "The specified model is not available."
        case .invalidRequest:
            return "The request was invalid or malformed."
        case .modelNotAvailable:
            return "The requested model is not available."
        case .contextTooLarge:
            return "The conversation history is too long. Please start a new conversation."
        case .generationFailed:
            return "Failed to generate a response. Please try again."
        case .unsupportedModel:
            return "The selected model is not supported in this version of the app."
        case .networkUnavailable:
            return "Network is unavailable. Please check your connection and try again."
        case .timeout:
            return "The request timed out. Please try again."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .invalidAPIKey, .invalidAPIKeyFormat:
            return "Please check your API key in Settings and try again."
        case .contextTooLarge:
            return "Try starting a new conversation or summarizing the previous context."
        case .rateLimitExceeded:
            return "Please wait a few moments before trying again."
        default:
            return "Please try again later or contact support if the issue persists."
        }
    }
}

/// A type that can be used to handle completion of LLM operations
typealias CompletionHandler = (Result<String, Error>) -> Void

/// Protocol defining the interface for LLM services
public protocol LLMServiceProtocol: AnyObject {
    /// The base URL for the LLM API
    var baseURL: URL? { get set }
    
    /// The API key for the LLM service
    var apiKey: String? { get set }
    
    /// The default model to use
    var defaultModel: AIModel { get set }
    
    /// The maximum number of tokens to generate
    var maxTokens: Int { get set }
    
    /// The temperature for sampling (0.0 to 1.0)
    var temperature: Double { get set }
    
    /// The top-p value for nucleus sampling (0.0 to 1.0)
    var topP: Double { get set }
    
    /// The presence penalty (-2.0 to 2.0)
    var presencePenalty: Double { get set }
    
    /// The frequency penalty (-2.0 to 2.0)
    var frequencyPenalty: Double { get set }
    
    /// Generate a response for the given message
    /// - Parameters:
    ///   - message: The user's message
    ///   - model: The AI model to use
    ///   - systemPrompt: The system prompt to use
    ///   - history: The conversation history
    /// - Returns: A publisher that emits the response or an error
    func generateResponse(
        message: String,
        model: AIModel,
        systemPrompt: String,
        history: [Message]
    ) -> AnyPublisher<String, Error>
    
    /// Check if a model is available
    /// - Parameter model: The model to check
    /// - Returns: A boolean indicating if the model is available
    func isModelAvailable(_ model: AIModel) -> Bool
    
    /// Get the list of available models
    /// - Returns: An array of available models
    func availableModels() -> [AIModel]
    
    /// Cancel any ongoing requests
    func cancelAllRequests()
    
    /// Validate the API key
    /// - Parameter apiKey: The API key to validate
    /// - Returns: A boolean indicating if the API key is valid
    func validateAPIKey(_ apiKey: String) -> Bool
    
    /// Stream a response for a message
    /// - Parameters:
    ///   - message: The message to send to the LLM
    ///   - model: The model to use for the completion
    ///   - systemPrompt: The system prompt to set the behavior of the assistant
    ///   - temperature: Controls randomness (0.0 to 1.0)
    /// - Returns: A publisher that emits response chunks or an error
    func streamMessage(
        _ message: String,
        model: AIModel,
        systemPrompt: String,
        temperature: Double
    ) -> AnyPublisher<String, Error>
    
    /// Generate a response for a conversation (legacy method)
    /// - Parameters:
    ///   - prompt: The user's input prompt
    ///   - model: The model to use for the completion
    ///   - conversationHistory: The history of messages in the conversation
    ///   - completion: Completion handler with the result
    func generateResponse(
        prompt: String,
        model: String,
        conversationHistory: [Message],
        completion: @escaping CompletionHandler
    )
}

/// A service that handles communication with language models
public final class LLMService: LLMServiceProtocol {
    // MARK: - Properties
    
    /// Shared instance of the LLMService
    public static let shared = LLMService()
    
    // MARK: - Properties
    
    /// The base URL for the LLM API
    public var baseURL: URL?
    
    /// The API key for the LLM service
    public var apiKey: String? {
        didSet {
            if let key = apiKey, !key.isEmpty {
                _ = KeychainHelper.shared.saveAPIKey(key)
            } else {
                _ = KeychainHelper.shared.deleteAPIKey()
            }
        }
    }
    
    /// The default model to use
    public var defaultModel: AIModel = .gpt3_5
    
    /// The maximum number of tokens to generate
    public var maxTokens: Int = 2048
    
    /// The temperature for sampling (0.0 to 1.0)
    public var temperature: Double = 0.7
    
    /// The top-p value for nucleus sampling (0.0 to 1.0)
    public var topP: Double = 0.9
    
    /// The presence penalty (-2.0 to 2.0)
    public var presencePenalty: Double = 0.0
    
    /// The frequency penalty (-2.0 to 2.0)
    public var frequencyPenalty: Double = 0.0
    
    /// The URLSession to use for network requests
    private let session: URLSession
    
    /// The JSON encoder to use
    private let encoder = JSONEncoder()
    
    /// The JSON decoder to use
    private let decoder = JSONDecoder()
    
    /// For managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Cancels all ongoing requests
    public func cancelAllRequests() {
        cancellables.removeAll()
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    /// The active tasks
    private var tasks: [URLSessionTask] = []
    
    // MARK: - Initialization
    
    public init(session: URLSession = .shared) {
        self.session = session
        
        // Configure default base URL
        #if DEBUG
        self.baseURL = URL(string: "http://localhost:11434")
        #else
        self.baseURL = URL(string: "https://api.openai.com/v1")
        #endif
        
        // Load saved settings
        if let savedAPIKey = KeychainHelper.shared.retrieveAPIKey() {
            self.apiKey = savedAPIKey
        }
        
        // Load other settings from UserDefaults if needed
        if let savedModel = UserDefaults.standard.string(forKey: "defaultModel"),
           let model = AIModel(rawValue: savedModel) {
            self.defaultModel = model
        }
        
        self.temperature = UserDefaults.standard.double(forKey: "temperature")
        self.maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        self.topP = UserDefaults.standard.double(forKey: "topP")
        self.presencePenalty = UserDefaults.standard.double(forKey: "presencePenalty")
        self.frequencyPenalty = UserDefaults.standard.double(forKey: "frequencyPenalty")
    }
    
    // MARK: - Public Methods
    
    // MARK: - LLMServiceProtocol Conformance
    
    public func generateResponse(
        prompt: String,
        model: String,
        conversationHistory: [Message],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Convert model string to AIModel, defaulting to the service's default model
        let aiModel = AIModel(rawValue: model) ?? defaultModel
        
        if aiModel.requiresAPIKey {
            // For cloud models
            generateRemoteResponse(
                message: prompt,
                model: aiModel,
                systemPrompt: "",
                history: conversationHistory
            )
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                completion(.success(response))
            })
            .store(in: &cancellables)
        } else {
            // For local models
            generateLocalResponse(
                message: prompt,
                model: aiModel,
                systemPrompt: "",
                history: conversationHistory
            )
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                completion(.success(response))
            })
            .store(in: &cancellables)
        }
    }
    
    public func generateResponse(
        message: String,
        model: AIModel,
        systemPrompt: String,
        history: [Message]
    ) -> AnyPublisher<String, Error> {
        if model.requiresAPIKey {
            return generateRemoteResponse(
                message: message,
                model: model,
                systemPrompt: systemPrompt,
                history: history
            )
        } else {
            return generateLocalResponse(
                message: message,
                model: model,
                systemPrompt: systemPrompt,
                history: history
            )
        }
    }
    
    public func streamMessage(
        _ message: String,
        model: AIModel = .gpt3_5,
        systemPrompt: String = "You are a helpful AI assistant.",
        temperature: Double = 0.7
    ) -> AnyPublisher<String, Error> {
        // Implementation for streaming responses
        // This is a simplified implementation - you'll need to adapt it to your specific API
        
        guard let baseURL = baseURL, let apiKey = apiKey, !apiKey.isEmpty else {
            return Fail(error: LLMError.invalidAPIKey).eraseToAnyPublisher()
        }
        
        // Create a URL request
        let endpoint = "/v1/chat/completions"
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create the request body
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": message]
        ]
        
        let parameters: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "stream": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            return Fail(error: LLMError.invalidRequest).eraseToAnyPublisher()
        }
        
        // Create a URLSession data task publisher
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> String in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    if let error = try? JSONDecoder().decode([String: Any].self, from: data) {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: error)
                    } else {
                        throw LLMError.invalidResponse
                    }
                }
                
                // In a real implementation, you would handle the streaming response here
                // This is a simplified version that just returns the full response as a string
                return String(data: data, encoding: .utf8) ?? ""
            }
            .eraseToAnyPublisher()
    }
    
    public func isModelAvailable(_ model: AIModel) -> Bool {
        // For local models, check if they're installed
        if !model.requiresAPIKey {
            // TODO: Implement local model availability check
            return true
        }
        
        // For remote models, just check if we have an API key
        return !(apiKey?.isEmpty ?? true)
    }
    
    public func availableModels() -> [AIModel] {
        return AIModel.allCases
    }
    
    public func cancelAllRequests() {
        // Cancel all Combine subscriptions
        cancellables.removeAll()
        
        // Cancel all active URLSession tasks
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    public func validateAPIKey(_ apiKey: String) -> Bool {
        // Simple validation - in a real app, you might want to make a test API call
        return !apiKey.isEmpty && apiKey.count > 10
    }
    
    // MARK: - Private Methods
    
    private func generateLocalResponse(
        message: String,
        model: AIModel,
        systemPrompt: String,
        history: [Message]
    ) -> AnyPublisher<String, Error> {
        // Implementation for local models (e.g., Ollama, LLaMA.cpp, etc.)
        // This is a simplified implementation - you'll need to adapt it to your specific local model API
        
        guard let baseURL = baseURL else {
            return Fail(error: LLMError.invalidURL).eraseToAnyPublisher()
        }
        
        // Prepare the request body for local models (using Ollama API format)
        var requestBody: [String: Any] = [
            "model": model.rawValue,
            "prompt": message,
            "stream": false
        ]
        
        // Add options if any are set
        var options: [String: Any] = [:]
        if temperature > 0 { options["temperature"] = temperature }
        if maxTokens > 0 { options["max_tokens"] = maxTokens }
        if topP > 0 { options["top_p"] = topP }
        if presencePenalty != 0 { options["presence_penalty"] = presencePenalty }
        if frequencyPenalty != 0 { options["frequency_penalty"] = frequencyPenalty }
        
        if !options.isEmpty {
            requestBody["options"] = options
        }
        
        // Create the request
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            // Make the request
            return session.dataTaskPublisher(for: request)
                .mapError { LLMError.requestFailed($0) }
                .tryMap { data, response -> String in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw LLMError.invalidResponse
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw LLMError.requestFailed(NSError(
                            domain: "",
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        ))
                    }
                    
                    // Parse the response - adjust this based on your local model's response format
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseText = json["response"] as? String {
                        return responseText
                    } else {
                        throw LLMError.invalidResponse
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    private func generateRemoteResponse(
        message: String,
        model: AIModel,
        systemPrompt: String,
        history: [Message]
    ) -> AnyPublisher<String, Error> {
        // Implementation for remote models (e.g., OpenAI, Anthropic, etc.)
        // This is a simplified implementation - you'll need to adapt it to your specific API
        
        guard let baseURL = baseURL, let apiKey = apiKey, !apiKey.isEmpty else {
            return Fail(error: LLMError.invalidAPIKey).eraseToAnyPublisher()
        }
        
        // Prepare the messages array with system prompt and conversation history
        var messages: [[String: Any]] = []
        
        // Add system prompt if provided
        if !systemPrompt.isEmpty {
            messages.append(["role": "system", "content": systemPrompt])
        }
        
        // Add conversation history
        for msg in history {
            messages.append([
                "role": msg.isFromUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        // Add the current message
        messages.append(["role": "user", "content": message])
        
        // Prepare the request body with only non-default values
        var requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": messages,
            "stream": false
        ]
        
        // Add optional parameters if they differ from defaults
        if temperature != 0.7 { requestBody["temperature"] = temperature }
        if maxTokens != 0 { requestBody["max_tokens"] = maxTokens }
        if topP != 1.0 { requestBody["top_p"] = topP }
        if presencePenalty != 0 { requestBody["presence_penalty"] = presencePenalty }
        if frequencyPenalty != 0 { requestBody["frequency_penalty"] = frequencyPenalty }
        
        // Create the request
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            // Make the request
            return session.dataTaskPublisher(for: request)
                .mapError { LLMError.requestFailed($0) }
                .tryMap { data, response -> String in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw LLMError.invalidResponse
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        
                        switch httpResponse.statusCode {
                        case 401:
                            throw LLMError.invalidAPIKey
                        case 429:
                            throw LLMError.rateLimitExceeded
                        case 400...499:
                            throw LLMError.invalidRequest
                        case 500...599:
                            throw LLMError.requestFailed(NSError(domain: "", code: httpResponse.statusCode))
                        default:
                            throw LLMError.requestFailed(NSError(
                                domain: "",
                                code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: errorMessage]
                            ))
                        }
                    }
                    
                    // Parse the response - adjust this based on your API's response format
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        return content
                    } else {
                        throw LLMError.invalidResponse
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Helper Types
    
    private struct OpenAIResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
}
