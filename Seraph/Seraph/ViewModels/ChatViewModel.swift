//
//  ChatViewModel.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import Combine
import SwiftUI

/// Simplified ChatViewModel
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentChat: Chat?
    @Published var allChats: [Chat] = []
    @Published var inputMessage: String = ""
    @Published var isProcessing: Bool = false
    @Published var lastError: String? = nil
    @Published var currentTokenCount: Int = 0
    @Published var currentProcessingTime: TimeInterval = 0
    @Published var currentTokenRate: Double = 0.0
    private var processingStartTime: Date? = nil
    
    // MARK: - Properties
    let llmService: LLMServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(llmService: LLMServiceProtocol = OllamaService.shared) {
        self.llmService = llmService
        
        // Create a simple initial chat
        let newChat = Chat(
            title: "New Chat",
            messages: []
        )
        
        allChats = [newChat]
        currentChat = newChat
    }
    
    // MARK: - Connection Handling
    
    /// Cancel the current generation
    func cancelGeneration() {
        if isProcessing {
            isProcessing = false
            cancellables.forEach { $0.cancel() }
            
            if var chat = currentChat,
               let lastMessage = chat.messages.last,
               lastMessage.role == .assistant {
                // Append cancellation note to the message
                var updatedMessage = lastMessage
                updatedMessage.content += "\n\n[Generation canceled]"
                updatedMessage.isComplete = true
                
                if let lastIndex = chat.messages.lastIndex(where: { $0.id == lastMessage.id }) {
                    chat.messages[lastIndex] = updatedMessage
                    currentChat = chat
                }
            }
        }
    }
    
    /// Check if Ollama is available and update the AppState connection status
    func checkConnection() {
        // Set status to connecting first
        AppState.shared.connectionStatus = .connecting
        
        // Check availability
        if let ollamaService = llmService as? OllamaService {
            ollamaService.checkAvailability()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            print("Connection check failed: \(error.localizedDescription)")
                            AppState.shared.connectionStatus = .disconnected
                            self?.lastError = error.localizedDescription
                        }
                    },
                    receiveValue: { isAvailable in
                        AppState.shared.connectionStatus = isAvailable ? .connected : .disconnected
                    }
                )
                .store(in: &cancellables)
        } else {
            // If not using OllamaService, set to unknown
            AppState.shared.connectionStatus = .unknown
        }
    }
    
    // MARK: - Message Handling
    func sendMessage() {
        guard !inputMessage.isEmpty else { return }
        
        let userMessage = Message(
            content: inputMessage,
            role: .user
        )
        
        if var chat = currentChat {
            chat.messages.append(userMessage)
            currentChat = chat
            
            // Clear input
            inputMessage = ""
            isProcessing = true
            currentTokenCount = 0
            currentTokenRate = 0.0
            currentProcessingTime = 0
            processingStartTime = Date()
            
            // Create a new publisher for streaming
            var responseText = ""
            
            // Start timer for token rate calculation
            let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            let timerCancellable = timer.sink { [weak self] _ in
                guard let self = self, let startTime = self.processingStartTime, self.isProcessing else { return }
                self.currentProcessingTime = Date().timeIntervalSince(startTime)
                
                // Update token rate if we have tokens and processing time
                if self.currentTokenCount > 0 && self.currentProcessingTime > 0 {
                    self.currentTokenRate = Double(self.currentTokenCount) / self.currentProcessingTime
                }
            }
            cancellables.insert(timerCancellable)
            
            // Send to LLM service
            let messageCancellable = llmService.sendMessage(messages: chat.messages, model: AppState.shared.selectedModel)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        // Stop token count timer when complete
                        self?.isProcessing = false
                        
                        if case .failure(let error) = completion {
                            // Handle error
                            self?.lastError = error.localizedDescription
                            
                            if var chat = self?.currentChat {
                                let errorMessage = Message(
                                    content: "Error: \(error.localizedDescription)",
                                    role: .assistant
                                )
                                chat.messages.append(errorMessage)
                                self?.currentChat = chat
                            }
                        } else {
                            // Success - mark the message as complete
                            if var chat = self?.currentChat,
                               let lastIndex = chat.messages.lastIndex(where: { $0.role == .assistant }),
                               chat.messages.indices.contains(lastIndex) {
                                chat.messages[lastIndex].isComplete = true
                                self?.currentChat = chat
                            }
                        }
                    },
                    receiveValue: { [weak self] response in
                        // For streaming, add to current response text
                        responseText += response
                        
                        // Improve token counting with a better estimate
                        // Calculate tokens more accurately based on some heuristics
                        
                        // 1. Count tokens per word: roughly 0.75 tokens per word
                        let wordCount = responseText.components(separatedBy: .whitespacesAndNewlines).count
                        let wordTokenEstimate = Int(Double(wordCount) * 0.75)
                        
                        // 2. Count tokens by character: ~4 chars per token on average 
                        let charTokenEstimate = responseText.count / 4
                        
                        // 3. Use a more conservative estimate that takes both into account
                        // We'll use the higher of the two estimates as a safer approximation
                        let tokenApproximation = max(wordTokenEstimate, charTokenEstimate)
                        
                        // Ensure at least 1 token is shown
                        self?.currentTokenCount = max(1, tokenApproximation)
                        
                        // Use a simpler approach for processing responses to avoid conflicts between messages
                        if var chat = self?.currentChat, let self = self {
                            // Get the basic sanitized text - this is more reliable for all content types
                            let basicSanitized = self.simpleSanitizeText(responseText)
                            
                            // Check if we already have an assistant message
                            if let lastIndex = chat.messages.lastIndex(where: { $0.role == .assistant }),
                                chat.messages.indices.contains(lastIndex) {
                                // Update existing message
                                chat.messages[lastIndex].content = basicSanitized
                                chat.messages[lastIndex].tokenCount = self.currentTokenCount
                                chat.messages[lastIndex].isComplete = false // Mark as still generating
                            } else {
                                // Create new message
                                let aiMessage = Message(
                                    content: basicSanitized,
                                    role: .assistant,
                                    isComplete: false, // Mark as still generating
                                    tokenCount: self.currentTokenCount
                                )
                                chat.messages.append(aiMessage)
                            }
                            self.currentChat = chat
                        }
                    }
                )
            
            cancellables.insert(messageCancellable)
            
            // Set a timeout for response
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                if self?.isProcessing == true {
                    // If still processing after timeout, cancel
                    self?.isProcessing = false
                    self?.cancellables.forEach { $0.cancel() }
                    
                    // Add timeout message if needed
                    if var chat = self?.currentChat, 
                       !chat.messages.contains(where: { $0.role == .assistant }) {
                        let timeoutMessage = Message(
                            content: "The request has timed out. Please try again or check your connection to Ollama.",
                            role: .assistant
                        )
                        chat.messages.append(timeoutMessage)
                        self?.currentChat = chat
                    }
                }
            }
        }
    }
    
    // MARK: - Chat Management
    
    func createNewChat() {
        let newChat = Chat(
            title: "New Chat",
            messages: []
        )
        
        allChats.insert(newChat, at: 0)
        currentChat = newChat
    }
    
    func selectChat(_ chat: Chat) {
        currentChat = chat
    }
    
    func deleteChat(_ chat: Chat) {
        if let index = allChats.firstIndex(where: { $0.id == chat.id }) {
            allChats.remove(at: index)
            
            // If we deleted the current chat, select another one or create new
            if currentChat?.id == chat.id {
                currentChat = allChats.first ?? Chat(title: "New Chat", messages: [])
            }
        }
    }
    
    func updateChatTitle(_ chat: Chat, newTitle: String) {
        if let index = allChats.firstIndex(where: { $0.id == chat.id }) {
            var updatedChat = chat
            updatedChat.title = newTitle
            allChats[index] = updatedChat
            
            if currentChat?.id == chat.id {
                currentChat = updatedChat
            }
        }
    }
    
    // MARK: - Message Sanitization
    
    /// A simple, highly reliable text sanitizer that won't cause issues
    private func simpleSanitizeText(_ text: String) -> String {
        // Skip sanitization for empty text
        if text.isEmpty {
            return text
        }
        
        var cleaned = text
        
        // Stage 1: Handle code blocks with a more robust approach
        // We need to extract and protect code blocks from further processing
        
        // First identify all tripple backtick pairs
        var codeBlockRanges: [(start: String.Index, end: String.Index, language: String)] = []
        var searchRange = cleaned.startIndex..<cleaned.endIndex
        
        while let startRange = cleaned.range(of: "```", options: [], range: searchRange) {
            // Find language identifier on same line
            let lineEnd = cleaned[startRange.upperBound...].firstIndex(of: "\n") ?? cleaned.endIndex
            let languageLine = String(cleaned[startRange.upperBound..<lineEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for the closing backticks
            let searchStart = lineEnd != cleaned.endIndex ? cleaned.index(after: lineEnd) : cleaned.endIndex
            if searchStart < cleaned.endIndex,
               let endRange = cleaned[searchStart...].range(of: "```") {
                // Found a complete code block
                codeBlockRanges.append((startRange.lowerBound, endRange.upperBound, languageLine))
                searchRange = endRange.upperBound..<cleaned.endIndex
            } else {
                // No closing backticks found, move past this opening set
                searchRange = startRange.upperBound..<cleaned.endIndex
            }
        }
        
        // Create a dictionary of placeholders and replace code blocks
        var codeBlockPlaceholders: [String: (content: String, language: String)] = [:]
        
        // Process in reverse to maintain indices
        for (index, blockRange) in codeBlockRanges.enumerated().reversed() {
            if blockRange.start < blockRange.end {
                let language = blockRange.language
                
                // Content is everything between the opening line and closing backticks
                let startLineEnd = cleaned[blockRange.start...].firstIndex(of: "\n") ?? cleaned.endIndex
                
                if startLineEnd < blockRange.end, 
                   let endBlockStart = cleaned[..<blockRange.end].lastIndex(of: "`") {
                    let contentStart = cleaned.index(after: startLineEnd)
                    let contentEnd = cleaned.index(endBlockStart, offsetBy: -2)
                    if contentStart <= contentEnd {
                        let content = String(cleaned[contentStart..<contentEnd])
                        
                        // Create unique placeholder
                        let placeholder = "__CODE_BLOCK_PLACEHOLDER_\(index)__"
                        codeBlockPlaceholders[placeholder] = (content, language)
                        
                        // Replace the block with the placeholder
                        cleaned.replaceSubrange(blockRange.start..<blockRange.end, with: placeholder)
                    }
                }
            }
        }
        
        // Stage 2: Basic XML tag handling while preserving specific tags
        
        // Remove standalone tags but preserve our special tags
        if let regex = try? NSRegularExpression(pattern: "<(?!think|function_calls|/think|/function_calls)[^>]+>", options: []) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        // Convert thinking and function call tags to readable format
        cleaned = cleaned.replacingOccurrences(of: "<think>", with: "\n\n💭 THINKING: \n")
        cleaned = cleaned.replacingOccurrences(of: "</think>", with: "\n\n")
        cleaned = cleaned.replacingOccurrences(of: "<function_calls>", with: "\n\n💭 FUNCTION CALL: \n")
        cleaned = cleaned.replacingOccurrences(of: "</function_calls>", with: "\n\n")
        
        // Stage 3: Normalize whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple consecutive newlines with just two
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // Stage 4: Restore code blocks
        for (placeholder, blockInfo) in codeBlockPlaceholders {
            let language = blockInfo.language.isEmpty ? "" : blockInfo.language
            let content = blockInfo.content
            
            // Restore with proper formatting
            let formattedBlock = "```\(language)\n\(content)\n```"
            cleaned = cleaned.replacingOccurrences(of: placeholder, with: formattedBlock)
        }
        
        return cleaned
    }
    
    /// Processes response text to preserve thinking process but clean other markup
    private func sanitizeResponseText(_ text: String) -> String {
        // Skip sanitization for empty or short text
        if text.count < 10 {
            return text
        }
        
        // Use a more resilient approach to prevent crashes
        var cleaned = text
        
        // PRESERVE the thinking process but format it nicely
        // Replace <think>...</think> with a formatted version
        if let regex = try? NSRegularExpression(pattern: "<think>(.*?)</think>", options: [.dotMatchesLineSeparators]) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            let matches = regex.matches(in: cleaned, options: [], range: range)
            
            // Process matches in reverse order to not affect string indices
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let thinkingRange = match.range(at: 1)
                    if let range = Range(match.range, in: cleaned),
                       let thinkingTextRange = Range(thinkingRange, in: cleaned) {
                        let thinkingText = String(cleaned[thinkingTextRange])
                        let formattedThinking = "\n\n💭 THINKING: \n\(thinkingText)\n\n"
                        cleaned.replaceSubrange(range, with: formattedThinking)
                    }
                }
            }
        }
        
        // Special handling for <function_calls> tags - preserve them with formatting
        if let regex = try? NSRegularExpression(pattern: "<function_calls>(.*?)</function_calls>", options: [.dotMatchesLineSeparators]) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            let matches = regex.matches(in: cleaned, options: [], range: range)
            
            // Process matches in reverse order to not affect string indices
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let functionRange = match.range(at: 1)
                    if let range = Range(match.range, in: cleaned),
                       let functionTextRange = Range(functionRange, in: cleaned) {
                        let functionText = String(cleaned[functionTextRange])
                        let formattedFunction = "\n\n💭 FUNCTION CALL: \n\(functionText)\n\n"
                        cleaned.replaceSubrange(range, with: formattedFunction)
                    }
                }
            }
        }
        
        // Process code blocks carefully to preserve them
        var processedText = ""
        var insideCodeBlock = false
        
        // Split by lines but ensure we handle very large texts properly
        let lines = cleaned.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        
        for line in lines {
            if line.hasPrefix("```") {
                // Start or end of code block
                if insideCodeBlock {
                    // End of code block - add the closing marker
                    processedText += "```\n"
                    insideCodeBlock = false
                } else {
                    // Start of code block
                    insideCodeBlock = true
                    
                    // Check for language identifier
                    let _ = line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Add the opening marker with language
                    processedText += line + "\n"
                }
            } else if insideCodeBlock {
                // Inside code block - preserve as is
                processedText += line + "\n"
            } else {
                // Outside code block - process XML tags
                let pattern = "<(?!think|function_calls)[^>]+>"
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let nsLine = line as NSString
                    let range = NSRange(location: 0, length: nsLine.length)
                    let processedLine = regex.stringByReplacingMatches(in: line, options: [], range: range, withTemplate: "")
                    processedText += processedLine + "\n"
                } else {
                    // If regex fails, just add the line as is
                    processedText += line + "\n"
                }
            }
        }
        
        // Clean up whitespace but ensure we don't have excessive newlines
        var finalText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace any instances of 3+ consecutive newlines with just 2
        while finalText.contains("\n\n\n") {
            finalText = finalText.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return finalText
    }
    
    /// Extract code blocks from text in a safe way
    private func extractCodeBlocks(from text: String) -> [TextComponent] {
        var components: [TextComponent] = []
        var currentText = ""
        var insideCodeBlock = false
        var currentLanguage = ""
        
        // Use a safer approach
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("```") {
                if insideCodeBlock {
                    // End of code block
                    components.append(TextComponent(text: currentText, isCodeBlock: true, language: currentLanguage))
                    currentText = ""
                    currentLanguage = ""
                    insideCodeBlock = false
                } else {
                    // Start of code block
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, isCodeBlock: false))
                        currentText = ""
                    }
                    insideCodeBlock = true
                    
                    // Extract language if specified
                    let languageSpecifier = line.dropFirst(3)
                    if !languageSpecifier.isEmpty {
                        currentLanguage = String(languageSpecifier).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } else {
                currentText += line + "\n"
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            components.append(TextComponent(text: currentText, isCodeBlock: insideCodeBlock, language: currentLanguage))
        }
        
        return components
    }
    
    /// Extract language from a code block
    private func extractLanguageFromCodeBlock(_ block: String) -> String? {
        // This is a very simple implementation - in a real app, you'd want something more robust
        let firstLine = block.components(separatedBy: "\n").first ?? ""
        if firstLine.hasPrefix("```") && firstLine.count > 3 {
            return firstLine.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    /// Text component structure for code blocks
    struct TextComponent {
        let text: String
        let isCodeBlock: Bool
        let language: String?
        
        init(text: String, isCodeBlock: Bool, language: String? = nil) {
            self.text = text
            self.isCodeBlock = isCodeBlock
            self.language = language
        }
    }
}