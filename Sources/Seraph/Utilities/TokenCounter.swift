import Foundation

struct TokenCounter {
    static func countTokens(in text: String) -> Int {
        // Simple implementation using whitespace-based tokenization
        // For production, consider using a proper tokenizer for the specific model
        return text.split(whereSeparator: { $0.isWhitespace }).count
    }
    
    static func countTokens(in messages: [Message]) -> Int {
        messages.reduce(0) { count, message in
            count + countTokens(in: message.content)
        }
    }
    
    static func getTokenUsageString(in messages: [Message]) -> String {
        let totalTokens = countTokens(in: messages)
        return "\(totalTokens) tokens"
    }
}
