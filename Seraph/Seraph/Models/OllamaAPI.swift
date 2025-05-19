//
//  OllamaAPI.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation

/// Models for the Ollama API
struct OllamaAPI {
    // MARK: - Request Models
    
    /// Request model for Ollama generate endpoint
    struct GenerateRequest: Codable {
        /// The model name to use
        let model: String
        
        /// The prompt to generate a response for
        let prompt: String
        
        /// Optional system prompt to use for the generation
        let system: String?
        
        /// Optional temperature parameter (0.0 - 1.0)
        let temperature: Double?
        
        /// Optional top_p parameter (0.0 - 1.0)
        let top_p: Double?
        
        /// Format specifying a response format, currently only supports "json"
        let format: String?
        
        /// Whether to use full multi-turn conversation format
        let options: Options?
        
        struct Options: Codable {
            let num_predict: Int?
            let stop: [String]?
        }
        
        init(model: String, prompt: String, system: String? = nil, temperature: Double? = nil, top_p: Double? = nil, format: String? = nil, num_predict: Int? = nil, stop: [String]? = nil) {
            self.model = model
            self.prompt = prompt
            self.system = system
            self.temperature = temperature
            self.top_p = top_p
            self.format = format
            
            // Only create options if needed
            if num_predict != nil || stop != nil {
                self.options = Options(num_predict: num_predict, stop: stop)
            } else {
                self.options = nil
            }
        }
    }
    
    /// Request model for Ollama chat endpoint
    struct ChatRequest: Codable {
        /// The model name to use
        let model: String
        
        /// The messages to use for the chat
        let messages: [ChatMessage]
        
        /// Optional system prompt to use for the chat
        let system: String?
        
        /// Optional temperature parameter (0.0 - 1.0)
        let temperature: Double?
        
        /// Optional top_p parameter (0.0 - 1.0)
        let top_p: Double?
        
        /// Format specifying a response format, currently only supports "json"
        let format: String?
        
        /// Options for the model
        let options: Options?
        
        struct Options: Codable {
            let num_predict: Int?
            let stop: [String]?
        }
        
        init(model: String, messages: [ChatMessage], system: String? = nil, temperature: Double? = nil, top_p: Double? = nil, format: String? = nil, num_predict: Int? = nil, stop: [String]? = nil) {
            self.model = model
            self.messages = messages
            self.system = system
            self.temperature = temperature
            self.top_p = top_p
            self.format = format
            
            // Only create options if needed
            if num_predict != nil || stop != nil {
                self.options = Options(num_predict: num_predict, stop: stop)
            } else {
                self.options = nil
            }
        }
    }
    
    /// Message model for Ollama chat
    struct ChatMessage: Codable {
        /// The role of the message sender (one of "system", "user", "assistant")
        let role: String
        
        /// The content of the message
        let content: String
        
        init(role: String, content: String) {
            self.role = role
            self.content = content
        }
        
        // Helper to convert from our app Message type
        static func from(_ message: Message) -> ChatMessage {
            return ChatMessage(
                role: message.role.rawValue,
                content: message.content
            )
        }
    }
    
    // MARK: - Response Models
    
    /// Response model for Ollama generate/chat endpoints
    struct Response: Codable, Identifiable {
        /// The model name that was used
        let model: String
        
        /// The response from the model
        let response: String
        
        /// Whether the response is complete
        let done: Bool
        
        /// Context information from the model (optional)
        let context: [Int]?
        
        /// The total duration in nanoseconds
        let total_duration: Int64?
        
        /// Load duration in nanoseconds
        let load_duration: Int64?
        
        /// Sample count
        let sample_count: Int?
        
        /// Sample duration in nanoseconds
        let sample_duration: Int64?
        
        /// Prompt evaluation count
        let prompt_eval_count: Int?
        
        /// Prompt evaluation duration in nanoseconds
        let prompt_eval_duration: Int64?
        
        /// Eval count
        let eval_count: Int?
        
        /// Eval duration in nanoseconds
        let eval_duration: Int64?
        
        // Add id for Identifiable conformance
        var id: String {
            UUID().uuidString
        }
    }
    
    /// Model for listing available models
    struct ModelsResponse: Codable {
        let models: [ModelInfo]
        
        struct ModelInfo: Codable, Identifiable {
            let name: String
            let modified_at: String
            let size: Int64
            let digest: String?
            let details: ModelDetails?
            
            var id: String {
                name
            }
            
            struct ModelDetails: Codable {
                let format: String?
                let family: String?
                let families: [String]?
                let parameter_size: String?
                let quantization_level: String?
            }
        }
    }
}