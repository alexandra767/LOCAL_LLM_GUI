//
//  OllamaModels.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation

/// Models for interaction with the Ollama API

// MARK: - Request Models

/// Request structure for Ollama chat completions API
struct OllamaRequest: Codable {
    /// The model to use for generation
    let model: String
    
    /// An array of messages to send to the model
    let messages: [OllamaMessage]
    
    /// Generation options
    let options: OllamaOptions?
    
    /// Whether to stream the response
    let stream: Bool
    
    /// System prompt to use
    var system: String?
    
    /// Create a request from our app's model types
    init(model: String, messages: [Message], parameters: ModelParameters, stream: Bool = true) {
        self.model = model
        self.messages = messages.map { OllamaMessage(from: $0) }
        self.options = OllamaOptions(from: parameters)
        self.stream = stream
        
        // Add system prompt if available
        if !parameters.systemPrompt.isEmpty {
            self.system = parameters.systemPrompt
        }
    }
}

/// Message format for Ollama API
struct OllamaMessage: Codable {
    /// The role of the message sender (user or assistant)
    let role: String
    
    /// The content of the message
    let content: String
    
    /// Create an Ollama message from our app's Message type
    init(from message: Message) {
        // Map our role to Ollama's role format
        switch message.role {
        case .user:
            self.role = "user"
        case .assistant:
            self.role = "assistant"
        case .system:
            self.role = "system"
        case .function:
            // Ollama doesn't support function role, use system as fallback
            self.role = "system"
        }
        
        self.content = message.content
    }
}

/// Options for Ollama generation
struct OllamaOptions: Codable {
    /// Sampling temperature between 0 and 1
    let temperature: Double
    
    /// TopP sampling (nucleus sampling) between 0 and 1
    let top_p: Double
    
    /// Create options from our app's ModelParameters
    init(from parameters: ModelParameters) {
        self.temperature = parameters.temperature
        self.top_p = parameters.topP
    }
}

// MARK: - Response Models

/// Response from Ollama chat completions API
struct OllamaResponse: Codable {
    /// The model used for generation
    let model: String
    
    /// Generated response content
    let message: OllamaResponseMessage
    
    /// Whether the response is complete
    let done: Bool
    
    /// Total time taken for generation
    let total_duration: Int?
    
    /// Time taken for prompt evaluation
    let prompt_eval_duration: Int?
    
    /// Time taken for generation
    let eval_duration: Int?
}

/// Message in Ollama response
struct OllamaResponseMessage: Codable {
    /// The role of the message (should be 'assistant')
    let role: String
    
    /// The generated content
    let content: String
}

/// Error response from Ollama API
struct OllamaErrorResponse: Codable, Error {
    /// Error message
    let error: String
}