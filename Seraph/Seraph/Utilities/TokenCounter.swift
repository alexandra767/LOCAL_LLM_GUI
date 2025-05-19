//
//  TokenCounter.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation

/// A simplified token counter for estimating token counts for different models
class TokenCounter {
    // MARK: - Token Counting Methods
    
    /// Estimate token count for a given text
    /// - Note: This is a simplified estimation. Real implementations would use model-specific tokenizers.
    func countTokens(in text: String) -> Int {
        // A very simple approximation: ~4 characters per token for English text
        // This is not accurate but gives a reasonable estimation for UI purposes
        let characterCount = text.count
        return max(1, characterCount / 4)
    }
    
    /// Count tokens for a message based on its role and content
    func countTokens(in message: Message) -> Int {
        // Role typically adds a few tokens of overhead
        let roleOverhead = 4
        
        // Count tokens in the content
        let contentTokens = countTokens(in: message.content)
        
        // Total tokens for the message
        return roleOverhead + contentTokens
    }
    
    /// Count tokens for multiple messages
    func countTokens(in messages: [Message]) -> Int {
        // Add a small overhead for the message formatting
        let formatOverhead = 3
        
        // Sum up tokens for all messages
        let messagesTokens = messages.reduce(0) { sum, message in
            sum + countTokens(in: message)
        }
        
        return formatOverhead + messagesTokens
    }
    
    /// Check if text fits within token limit
    func fitsWithinTokenLimit(_ text: String, limit: Int) -> Bool {
        return countTokens(in: text) <= limit
    }
    
    /// Truncate text to fit within token limit
    func truncateToTokenLimit(_ text: String, limit: Int) -> String {
        let tokens = countTokens(in: text)
        
        if tokens <= limit {
            return text
        }
        
        // Approximate character count based on token limit
        let approximateCharLimit = limit * 4
        
        // Truncate and add an indicator
        if text.count > approximateCharLimit {
            let index = text.index(text.startIndex, offsetBy: approximateCharLimit)
            return String(text[..<index]) + "... [truncated]"
        }
        
        return text
    }
    
    /// Get a human-readable string representing token usage
    func tokenUsageString(used: Int, total: Int) -> String {
        let formattedUsed = formatTokenCount(used)
        let formattedTotal = formatTokenCount(total)
        return "\(formattedUsed)/\(formattedTotal) tokens"
    }
    
    /// Format token count with k suffix for thousands
    func formatTokenCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    /// Calculate percentage of token limit used
    func percentageUsed(used: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

// MARK: - Preview Helper
#if DEBUG
extension TokenCounter {
    static func previewTokenCounts(for text: String) -> (count: Int, percentage: Double) {
        let counter = TokenCounter()
        let tokens = counter.countTokens(in: text)
        return (tokens, counter.percentageUsed(used: tokens, total: 2048))
    }
}
#endif