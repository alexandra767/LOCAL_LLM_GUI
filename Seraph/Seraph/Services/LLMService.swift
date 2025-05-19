//
//  LLMService.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import Combine

/// Simple protocol for LLM services
protocol LLMServiceProtocol {
    /// Send messages and get a response
    func sendMessage(messages: [Message], model: LLMModel) -> AnyPublisher<String, Error>
    
    /// Send messages with parameters
    func sendMessage(messages: [Message], model: LLMModel, parameters: ModelParameters) -> AnyPublisher<String, Error>
    
    /// Check if service is available
    func checkAvailability() -> AnyPublisher<Bool, Error>
}

/// Error types for LLM services
enum LLMServiceError: Error, LocalizedError {
    case invalidConfiguration
    case networkError(String)
    case authenticationError
    case modelNotAvailable
    case rateLimitExceeded
    case serverError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid service configuration"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationError:
            return "Authentication failed"
        case .modelNotAvailable:
            return "The requested model is not available"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

/// Main service facade
class LLMService: LLMServiceProtocol {
    func sendMessage(messages: [Message], model: LLMModel) -> AnyPublisher<String, Error> {
        return sendMessage(messages: messages, model: model, parameters: ModelParameters())
    }
    
    func sendMessage(messages: [Message], model: LLMModel, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // Simple implementation that just returns a fixed response
        let response = "This is a response from the LLM service."
        return Just(response)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func checkAvailability() -> AnyPublisher<Bool, Error> {
        // Always return true
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}