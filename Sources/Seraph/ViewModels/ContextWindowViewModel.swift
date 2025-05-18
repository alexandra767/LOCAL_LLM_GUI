import Foundation
import SwiftUI

@MainActor
class ContextWindowViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var tokenCount: Int = 0
    @Published var maxTokens: Int = 4096
    @Published var userTokenCount: Int = 0
    @Published var assistantTokenCount: Int = 0
    @Published var systemTokenCount: Int = 0
    @Published var showTokenDetails: Bool = false
    @Published var currentModel: String?
    
    private let tokenCounter = TokenCounter()
    
    func updateContext(from chatViewModel: ChatViewModel) {
        messages = chatViewModel.messages
        calculateTokenCounts()
        currentModel = chatViewModel.llmService.currentModel
    }
    
    private func calculateTokenCounts() {
        tokenCount = TokenCounter.countTokens(in: messages)
        userTokenCount = messages.filter { $0.role == .user }
            .reduce(0) { count, message in
                count + TokenCounter.countTokens(in: message.content)
            }
        assistantTokenCount = messages.filter { $0.role == .assistant }
            .reduce(0) { count, message in
                count + TokenCounter.countTokens(in: message.content)
            }
        systemTokenCount = messages.filter { $0.role == .system }
            .reduce(0) { count, message in
                count + TokenCounter.countTokens(in: message.content)
            }
    }
    
    var isTokenLimitExceeded: Bool {
        tokenCount > maxTokens
    }
    
    func clearContext() {
        messages.removeAll()
        tokenCount = 0
        userTokenCount = 0
        assistantTokenCount = 0
        systemTokenCount = 0
    }
    
    func truncateContext() {
        guard !messages.isEmpty else { return }
        
        var currentCount = tokenCount
        var truncatedMessages = messages
        
        while currentCount > maxTokens && !truncatedMessages.isEmpty {
            if let firstMessage = truncatedMessages.first {
                truncatedMessages.removeFirst()
                currentCount -= TokenCounter.countTokens(in: firstMessage.content)
            }
        }
        
        messages = truncatedMessages
        calculateTokenCounts()
    }
}
