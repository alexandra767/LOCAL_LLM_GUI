//
//  ContextWindowViewModel.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for visualizing and managing the LLM context window
class ContextWindowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var totalTokens: Int = 0
    @Published var maxTokens: Int = 8192 // Default to a typical context window size
    @Published var showFullContext: Bool = false
    @Published var selectedMessageId: UUID?
    
    // MARK: - Private Properties
    private let tokenCounter = TokenCounter()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(messages: [Message] = []) {
        self.messages = messages
        recalculateTokens()
    }
    
    // MARK: - Public Methods
    
    /// Update the messages in the context window
    func updateMessages(_ newMessages: [Message]) {
        messages = newMessages
        recalculateTokens()
    }
    
    /// Set the maximum token limit based on the model
    func setMaxTokens(for model: LLMModel) {
        switch model {
        case .ollama(let ollamaModel):
            switch ollamaModel {
            case .mistral7b:
                maxTokens = 8192
                
            // Llama models
            case .llama3_8b, .llama3_8b_instruct:
                maxTokens = 8192
            case .llama3_70b, .llama3_70b_instruct:
                maxTokens = 8192
                
            // CodeLlama models
            case .codellama_7b:
                maxTokens = 8192
            case .codellama_13b:
                maxTokens = 8192
            case .codellama_34b:
                maxTokens = 8192
                
            // DeepSeek models
            case .deepseek:
                maxTokens = 4096
            case .deepseek_coder:
                maxTokens = 8192
            case .deepseek_r1_8b_m4:
                maxTokens = 32000
            case .deepseek_r1_14b_m4:
                maxTokens = 32000
                
            // Phi models
            case .phi3_mini:
                maxTokens = 4096
            case .phi3_small:
                maxTokens = 8192
            case .phi3_medium:
                maxTokens = 8192
                
            // Gemma models
            case .gemma_2b:
                maxTokens = 8192
            case .gemma_7b:
                maxTokens = 8192
                
            // Vicuna models
            case .vicuna_7b:
                maxTokens = 4096
            case .vicuna_13b:
                maxTokens = 4096
                
            // Mixtral models
            case .mixtral, .mixtral_8x7b:
                maxTokens = 32000
            }
        }
    }
    
    /// Recalculate token counts for all messages
    private func recalculateTokens() {
        var total = 0
        
        for i in 0..<messages.count {
            let tokenCount = messages[i].tokenCount ?? tokenCounter.countTokens(in: messages[i].content)
            total += tokenCount
            
            // Update the token count if needed
            if messages[i].tokenCount != tokenCount {
                messages[i].tokenCount = tokenCount
            }
        }
        
        totalTokens = total
    }
    
    /// Get token usage as a percentage
    var tokenUsagePercentage: Double {
        Double(totalTokens) / Double(maxTokens)
    }
    
    /// Check if the context window is nearly full
    var isContextNearlyFull: Bool {
        tokenUsagePercentage > 0.9
    }
    
    /// Check if the context window is over capacity
    var isContextOverCapacity: Bool {
        totalTokens > maxTokens
    }
    
    /// Get a color representing the current context usage
    var contextUsageColor: Color {
        if isContextOverCapacity {
            return Color.red
        } else if isContextNearlyFull {
            return Color.orange
        } else if tokenUsagePercentage > 0.7 {
            return Color.yellow
        } else {
            return Color.green
        }
    }
    
    /// Get messages that fit within the context window
    var messagesInContext: [Message] {
        var running = 0
        var result: [Message] = []
        
        // Add messages from newest to oldest until we reach the limit
        for message in messages.reversed() {
            let tokenCount = message.tokenCount ?? tokenCounter.countTokens(in: message.content)
            if running + tokenCount <= maxTokens {
                result.insert(message, at: 0)
                running += tokenCount
            } else {
                break
            }
        }
        
        return result
    }
    
    /// Get messages that would be truncated (outside the context window)
    var truncatedMessages: [Message] {
        let inContext = Set(messagesInContext.map { $0.id })
        return messages.filter { !inContext.contains($0.id) }
    }
    
    /// Toggle visibility of full context or just messages in context
    func toggleContextView() {
        showFullContext.toggle()
    }
    
    /// Get a description of the current token usage
    var tokenUsageDescription: String {
        "\(totalTokens) / \(maxTokens) tokens used"
    }
}

// MARK: - Preview Helper

#if DEBUG
extension ContextWindowViewModel {
    static func preview() -> ContextWindowViewModel {
        let viewModel = ContextWindowViewModel()
        
        // Sample messages
        let messages = [
            Message(content: "Hello, how can I help you today?", role: .assistant),
            Message(content: "I need help with SwiftUI layouts.", role: .user),
            Message(content: "SwiftUI layouts use a declarative syntax where you describe the view hierarchy. What specific aspect are you struggling with?", role: .assistant)
        ]
        
        viewModel.updateMessages(messages)
        return viewModel
    }
}
#endif