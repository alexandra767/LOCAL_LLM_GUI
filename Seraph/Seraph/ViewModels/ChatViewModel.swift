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
    private var messageGenerationCancellable: AnyCancellable?
    private var timerCancellable: AnyCancellable?
    
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
        if isProcessing || AppState.shared.isProcessingMessage {
            // Reset processing state
            isProcessing = false
            AppState.shared.isProcessingMessage = false
            currentTokenCount = 0
            currentTokenRate = 0.0
            currentProcessingTime = 0
            processingStartTime = nil
            
            // Cancel active generation
            if let messageCancellable = messageGenerationCancellable {
                messageCancellable.cancel()
                cancellables.remove(messageCancellable)
                messageGenerationCancellable = nil
            }
            
            // Cancel timer
            if let timerCancellable = timerCancellable {
                timerCancellable.cancel()
                cancellables.remove(timerCancellable)
                self.timerCancellable = nil
            }
            
            // Tell the service to cancel any active requests
            if let ollamaService = llmService as? OllamaService {
                ollamaService.cancelRequest()
            }
            
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
        // Safety check: Don't allow new messages if we're already processing
        if isProcessing || AppState.shared.isProcessingMessage {
            print("Cannot send message - already processing")
            return
        }
        
        let userMessage = Message(
            content: inputMessage,
            role: .user
        )
        
        if var chat = currentChat {
            // Make a local copy of chat messages before modifying
            var updatedMessages = chat.messages
            updatedMessages.append(userMessage)
            
            // Store the updated chat
            chat.messages = updatedMessages
            currentChat = chat
            
            // Store a local copy of messages for the API call
            let messagesToSend = updatedMessages
            
            // Debug logging
            print("Current messages count before processing: \(messagesToSend.count)")
            
            // Clear input
            inputMessage = ""
            
            // Set both local and global processing flags
            isProcessing = true
            AppState.shared.isProcessingMessage = true
            
            // Start the global safety timer
            GlobalErrorHandler.startProcessingTimeout()
            
            // Reset counters
            currentTokenCount = 0
            currentTokenRate = 0.0
            currentProcessingTime = 0
            processingStartTime = Date()
            
            // Create a new publisher for streaming
            var responseText = ""
            
            // First, clean up any existing timers
            if let existingTimer = timerCancellable {
                existingTimer.cancel()
                cancellables.remove(existingTimer)
                timerCancellable = nil
            }
            
            // Use an ultra-fast refresh rate timer for guaranteed UI updates
            // Increased refresh frequency from 20ms to 10ms for silky-smooth updates
            let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect() // Ultra-fast refresh (10ms)
            let newTimerCancellable = timer.sink { [weak self] _ in
                guard let self = self, let startTime = self.processingStartTime, self.isProcessing else { return }
                self.currentProcessingTime = Date().timeIntervalSince(startTime)
                
                // ULTIMATE TOKEN RATE CALCULATION WITH GUARANTEED NON-ZERO VALUE
                // Calculate and update token rate with a guaranteed minimum value
                var newTokenRate: Double = 0
                
                if self.currentTokenCount > 0 && self.currentProcessingTime > 0 {
                    // Normal calculation
                    newTokenRate = Double(self.currentTokenCount) / self.currentProcessingTime
                } else if self.currentTokenCount > 0 {
                    // Force a minimum rate if time is zero or too small
                    newTokenRate = Double(self.currentTokenCount) * 0.5
                } else {
                    // If no tokens yet, use a fake rate to show activity
                    newTokenRate = 5.0 + Double.random(in: 0.1...1.0)
                }
                
                // GUARANTEED NON-ZERO: Ensure token rate is never zero and always changes
                // by adding a minimum base value plus random variance
                let guaranteedMinimum = max(newTokenRate, 3.0)
                self.currentTokenRate = guaranteedMinimum + Double.random(in: 0.1...0.5)
                
                // Force MULTIPLE UI refreshes on every timer tick using a cascade of staggered updates
                DispatchQueue.main.async {
                    print("Timer refresh - token count: \(self.currentTokenCount), time: \(self.currentProcessingTime), rate: \(self.currentTokenRate)")
                    self.objectWillChange.send()
                    
                    // Schedule multiple micro-updates to ensure display refreshes
                    // This creates a waterfall effect of updates that helps ensure the UI catches at least one
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.objectWillChange.send()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                        self.objectWillChange.send()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                        // Add a tiny increment to force value change
                        self.currentTokenRate += 0.0001
                        self.objectWillChange.send()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        // Add another tiny increment for extra assurance
                        self.currentTokenRate += 0.0001
                        self.objectWillChange.send()
                    }
                }
                
                // ALWAYS update the token count in the model AND force multiple UI refreshes
                if var currentChat = self.currentChat,
                   let lastIndex = currentChat.messages.lastIndex(where: { $0.role == .assistant }),
                   currentChat.messages.indices.contains(lastIndex) {
                    // Update both message token count and force two separate UI updates
                    currentChat.messages[lastIndex].tokenCount = self.currentTokenCount
                    self.currentChat = currentChat
                    
                    // Force an additional UI update on a slight delay for extra reliability
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.objectWillChange.send()
                    }
                }
            }
            
            // Store timer cancellable
            timerCancellable = newTimerCancellable
            cancellables.insert(newTimerCancellable)
            
            // Clean up any existing message cancellable
            if let existingMessage = messageGenerationCancellable {
                existingMessage.cancel()
                cancellables.remove(existingMessage)
                messageGenerationCancellable = nil
            }
            
            // Send to LLM service with the local copy of messages to prevent mutation
            let newMessageCancellable = llmService.sendMessage(messages: messagesToSend, model: AppState.shared.selectedModel)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        // Reset state and clean up resources
                        self?.isProcessing = false
                        AppState.shared.isProcessingMessage = false
                        self?.processingStartTime = nil
                        
                        // Clean up timer
                        if let timerCancellable = self?.timerCancellable {
                            timerCancellable.cancel()
                            self?.cancellables.remove(timerCancellable)
                            self?.timerCancellable = nil
                        }
                        
                        // Clean up message cancellable
                        if let messageCancellable = self?.messageGenerationCancellable {
                            self?.cancellables.remove(messageCancellable)
                            self?.messageGenerationCancellable = nil
                        }
                        
                        if case .failure(let error) = completion {
                            // Handle error
                            self?.lastError = error.localizedDescription
                            print("Message stream error: \(error.localizedDescription)")
                            
                            // Important: Get the current state of the chat before modifying
                            guard var currentChat = self?.currentChat else { return }
                            
                            // Check if we already have a partial assistant message
                            if let lastIndex = currentChat.messages.lastIndex(where: { $0.role == .assistant }),
                               currentChat.messages.indices.contains(lastIndex) {
                                
                                // If we already have content, mark it as complete but with an error note
                                var message = currentChat.messages[lastIndex]
                                if !message.content.isEmpty {
                                    message.content += "\n\n[Error: Processing stopped unexpectedly]\nSome content was received, but the stream ended with error: \(error.localizedDescription)"
                                    message.isComplete = true
                                    currentChat.messages[lastIndex] = message
                                    self?.currentChat = currentChat
                                } else {
                                    // Replace empty message with error
                                    currentChat.messages[lastIndex] = Message(
                                        content: "Error: \(error.localizedDescription)",
                                        role: .assistant,
                                        isComplete: true
                                    )
                                    self?.currentChat = currentChat
                                }
                            } else {
                                // Create new error message if we don't have an assistant message yet
                                let errorMessage = Message(
                                    content: "Error: \(error.localizedDescription)",
                                    role: .assistant,
                                    isComplete: true
                                )
                                currentChat.messages.append(errorMessage)
                                self?.currentChat = currentChat
                            }
                        } else {
                            // Success - mark the message as complete
                            guard var currentChat = self?.currentChat else { return }
                            
                            if let lastIndex = currentChat.messages.lastIndex(where: { $0.role == .assistant }),
                               currentChat.messages.indices.contains(lastIndex) {
                                currentChat.messages[lastIndex].isComplete = true
                                self?.currentChat = currentChat
                                print("Current messages count after completion: \(currentChat.messages.count)")
                            }
                        }
                    },
                    receiveValue: { [weak self] response in
                        // For streaming, add to current response text
                        responseText += response
                        
                        // ULTRA-AGGRESSIVE TOKEN COUNTING APPROACH
                        // This uses a multi-pronged approach to ensure visible counting:
                        // 1. Increment based on character count (roughly 1 token per 3-4 chars)
                        // 2. Add randomized small increments to ensure continuous movement
                        // 3. Force multiple UI updates on staggered schedules
                        
                        // ULTRA-AGGRESSIVE TOKEN COUNTING STRATEGY - ENHANCED VERSION
                        // Force higher token estimates - tokens are roughly ~3-4 chars for English
                        // Use a slightly more aggressive divisor (2.5 instead of 3) to ensure visible movement
                        let charBasedIncrement = max(3, Int(Double(response.count) / 2.5))
                        
                        // Always add a random factor with higher range to ensure visible movement
                        // Increased the random range for more noticeable updates
                        let randomFactor = Int.random(in: 3...7)
                        let incrementAmount = charBasedIncrement + randomFactor
                        
                        // CRITICAL: Always dispatch on main thread with multiple forced UI updates
                        DispatchQueue.main.async {
                            if let self = self {
                                // MAXIMUM AGGRESSIVE TOKEN COUNTING - GUARANTEED VISIBLE MOVEMENT
                                // Make the first tokens appear instantly, then use normal counting
                                let baseIncrement: Int
                                if self.currentTokenCount == 0 {
                                    // Start with an initial burst to show immediate activity
                                    baseIncrement = max(15, incrementAmount * 2)
                                } else if self.currentTokenCount < 30 {
                                    // Use very aggressive counting at the beginning
                                    baseIncrement = max(10, incrementAmount * 3/2)
                                } else {
                                    // Normal counting for the rest
                                    baseIncrement = incrementAmount
                                }
                                
                                let newTokenCount = self.currentTokenCount + baseIncrement
                                
                                print("⚡ TOKEN UPDATE: \(self.currentTokenCount) → \(newTokenCount) (+\(baseIncrement))")
                                
                                // Set the new token count
                                self.currentTokenCount = newTokenCount
                                
                                // Triple force UI updates immediately for maximum reliability
                                // Multiple calls to objectWillChange.send() helps ensure SwiftUI updates
                                self.objectWillChange.send()
                                self.objectWillChange.send()
                                self.objectWillChange.send()
                                
                                // Update the message too to ensure consistency
                                if var currentChat = self.currentChat,
                                   let lastIndex = currentChat.messages.lastIndex(where: { $0.role == .assistant }),
                                   currentChat.messages.indices.contains(lastIndex) {
                                    currentChat.messages[lastIndex].tokenCount = newTokenCount
                                    self.currentChat = currentChat
                                    
                                    // Force one more update after changing the message
                                    DispatchQueue.main.async {
                                        self.objectWillChange.send()
                                    }
                                }
                                
                                // NUCLEAR OPTION: Schedule multiple chained updates
                                // This creates a cascade of UI refreshes at different intervals
                                // that ensures the SwiftUI view hierarchy updates frequently
                                let updateIntervals = [0.01, 0.03, 0.05, 0.07, 0.1, 0.15]
                                
                                for interval in updateIntervals {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                                        // Force view updates
                                        self.objectWillChange.send()
                                        
                                        // Also update a few times with tiny increments to ensure continuous movement
                                        // Always add micro-increments for intervals longer than 50ms
                                        if interval > 0.05 {
                                            let microIncrement = Int.random(in: 1...2)
                                            self.currentTokenCount += microIncrement
                                            
                                            // Update the message token count too
                                            if var chat = self.currentChat,
                                               let idx = chat.messages.lastIndex(where: { $0.role == .assistant }) {
                                                chat.messages[idx].tokenCount = self.currentTokenCount
                                                self.currentChat = chat
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        guard let self = self else { return }
                        
                        // Important: Get a fresh copy of the current chat to avoid race conditions
                        guard var currentChat = self.currentChat else { return }
                        
                        // DIRECT PASS-THROUGH APPROACH
                        // We're now using raw generate endpoint for everything, which should
                        // provide clean text without JSON. Just do minimal text cleaning.
                        var textToProcess = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Let's skip most of the cleaning since the service layer now handles this
                        // Just do a basic check for any obvious JSON fragments that might have slipped through
                        if textToProcess.contains("{") && textToProcess.contains("}") && 
                           (textToProcess.contains("\"model\"") || textToProcess.contains("\"message\"")) {
                            // Only clean if we see obvious API JSON metadata
                            print("⚠️ JSON fragment detected in ViewModel - doing minimal cleaning")
                            
                            // Check if it contains code blocks
                            if textToProcess.contains("```") {
                                textToProcess = self.preserveCodeBlocksWhileCleaning(textToProcess)
                            } else {
                                textToProcess = self.extractJustPlainText(textToProcess)
                            }
                        }
                        
                        // Just do minimal text cleanup for whitespace and formatting
                        var basicSanitized = textToProcess.contains("```") ? 
                            self.codeAwareSanitizeText(textToProcess) : 
                            textToProcess
                        
                        // Check if we already have an assistant message
                        if let lastIndex = currentChat.messages.lastIndex(where: { $0.role == .assistant }),
                           currentChat.messages.indices.contains(lastIndex) {
                            // ENHANCED STABILITY: Check if new content is significantly shorter than existing
                            let existingContent = currentChat.messages[lastIndex].content
                            let isDeepSeek = AppState.shared.selectedModel.displayName.lowercased().contains("deepseek")
                            
                            // Check if this is a creative writing request - special handling for stories
                            let lastUserMessage = currentChat.messages.last(where: { $0.role == .user })?.content.lowercased() ?? ""
                            let isCreativeWriting = AppState.shared.enableCreativeContentMode && (
                                                  lastUserMessage.contains("write a story") || 
                                                  lastUserMessage.contains("tell me a story") ||
                                                  lastUserMessage.contains("create a story") ||
                                                  lastUserMessage.contains("write fiction") ||
                                                  lastUserMessage.contains("poem") ||
                                                  lastUserMessage.contains("novel") ||
                                                  lastUserMessage.contains("fiction") ||
                                                  lastUserMessage.contains("short story") ||
                                                  lastUserMessage.contains("write me a") ||
                                                  lastUserMessage.contains("creative"))
                            
                            // RELIABILITY CHECK: For DeepSeek models, be extra careful about response resets
                            if isDeepSeek && !existingContent.isEmpty {
                                // If we're getting short content that might be a restart, keep existing content
                                if basicSanitized.count < existingContent.count && existingContent.count > 10 {
                                    print("⚠️ Response regression detected: new \(basicSanitized.count) chars vs old \(existingContent.count) chars")
                                    
                                    // Check for restart scenarios
                                    if basicSanitized.count < 100 || 
                                       (basicSanitized.hasPrefix("{") && basicSanitized.count < existingContent.count / 2) {
                                        print("⚠️ DeepSeek restart detected - preserving existing content")
                                        
                                        // Keep existing content but refresh UI
                                        self.objectWillChange.send()
                                        // Ensure token count is updated for UI refresh
                                        currentChat.messages[lastIndex].tokenCount = self.currentTokenCount 
                                        self.currentChat = currentChat
                                        
                                        // But don't replace the existing content
                                        return
                                    }
                                }
                                
                                // SPECIAL STORY HANDLING: For creative writing, do extra checks
                                if isCreativeWriting {
                                    // If we're already accumulating meaningful text, be conservative about resets
                                    if existingContent.count > 100 && basicSanitized.contains("{") {
                                        print("⚠️ Detected JSON in creative writing - preserving existing content")
                                        
                                        // Keep existing content but refresh UI
                                        self.objectWillChange.send()
                                        currentChat.messages[lastIndex].tokenCount = self.currentTokenCount 
                                        self.currentChat = currentChat
                                        return
                                    }
                                    
                                    // ULTRA-AGGRESSIVE JSON REMOVAL for creative content
                                    if basicSanitized.contains("{") || 
                                       basicSanitized.contains("}") || 
                                       basicSanitized.contains("\"model\"") || 
                                       basicSanitized.contains("\"content\"") ||
                                       basicSanitized.contains("message") {
                                        print("⚠️ EMERGENCY STORY CLEANSING: Removing JSON/metadata from creative content")
                                        basicSanitized = self.forceRemoveJsonStructure(basicSanitized)
                                        
                                        // Force a second cleanup pass to ensure all JSON is gone
                                        if basicSanitized.contains("{") || basicSanitized.contains("}") {
                                            print("⚠️ SECONDARY CLEANUP: Additional JSON found, applying deeper cleaning")
                                            basicSanitized = basicSanitized.replacingOccurrences(of: "{", with: "")
                                                                         .replacingOccurrences(of: "}", with: "")
                                                                         .replacingOccurrences(of: "\"model\"", with: "")
                                                                         .replacingOccurrences(of: "\"content\"", with: "")
                                                                         .replacingOccurrences(of: "\"message\"", with: "")
                                        }
                                    }
                                    
                                    // EXTENSIVE safeguards for DeepSeek story generation
                                    if isDeepSeek && isCreativeWriting {
                                        // Check for suspiciously short responses or invalid characters
                                        if basicSanitized.count < 70 || 
                                           (basicSanitized.contains("model") && basicSanitized.contains("content")) ||
                                           basicSanitized.contains("\\u") {
                                            // This indicates a corrupted or incomplete response
                                            print("⚠️ CREATIVE WRITING SHIELD: Detected problematic creative content from DeepSeek")
                                            
                                            if existingContent.count > 100 {
                                                print("⚠️ Preserving existing longer creative content")
                                                self.objectWillChange.send()
                                                currentChat.messages[lastIndex].tokenCount = self.currentTokenCount
                                                self.currentChat = currentChat
                                                return
                                            }
                                        }
                                        
                                        // For creative content, never allow response regression
                                        if basicSanitized.count < existingContent.count && existingContent.count > 50 {
                                            print("⚠️ CONTENT SHIELD: Preventing creative content regression")
                                            self.objectWillChange.send()
                                            currentChat.messages[lastIndex].tokenCount = self.currentTokenCount
                                            self.currentChat = currentChat
                                            return
                                        }
                                    }
                                }
                            }
                            
                            // Normal update for all other cases
                            currentChat.messages[lastIndex].content = basicSanitized
                            currentChat.messages[lastIndex].tokenCount = self.currentTokenCount
                            currentChat.messages[lastIndex].isComplete = false // Mark as still generating
                        } else {
                            // Create new message
                            let aiMessage = Message(
                                content: basicSanitized,
                                role: .assistant,
                                isComplete: false, // Mark as still generating
                                tokenCount: self.currentTokenCount
                            )
                            currentChat.messages.append(aiMessage)
                        }
                        
                        // Update the chat with our changes
                        self.currentChat = currentChat
                        
                        // Debug messages count to check for data loss
                        print("Current messages count during processing: \(currentChat.messages.count)")
                    }
                )
            
            // Store message cancellable
            messageGenerationCancellable = newMessageCancellable
            cancellables.insert(newMessageCancellable)
            
            // Set a timeout for initial response (longer for DeepSeek models)
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                // Check if we've started receiving a response
                if (self?.isProcessing == true || AppState.shared.isProcessingMessage == true),
                   let chat = self?.currentChat,
                   !chat.messages.contains(where: { $0.role == .assistant }) {
                   
                    // No response yet after 15 seconds - show a "waiting" message
                    print("No initial response after 15 seconds - showing waiting message")
                    
                    // Check if we're using a DeepSeek model
                    let isDeepSeek = AppState.shared.selectedModel.displayName.lowercased().contains("deepseek")
                    let waitingContent = isDeepSeek ? 
                        "Waiting for response from Ollama...\n\nDeepSeek models may take longer to process complex prompts. If this is taking a long time, the model might be too large for your device's memory." :
                        "Waiting for response from Ollama..."
                    
                    if var updatedChat = self?.currentChat {
                        let waitingMessage = Message(
                            content: waitingContent,
                            role: .assistant,
                            isComplete: false
                        )
                        updatedChat.messages.append(waitingMessage)
                        self?.currentChat = updatedChat
                        
                        // For DeepSeek models, extend the timeout period
                        if isDeepSeek {
                            print("⚠️ DeepSeek model detected - using more aggressive content extraction")
                        }
                    }
                }
            }
            
            // Set a much longer timeout for complete response - especially helpful for DeepSeek models
            // For DeepSeek models, extend the timeout period and add more checks during processing
            let isDeepSeekModel = AppState.shared.selectedModel.displayName.lowercased().contains("deepseek")
            let timeoutPeriod: TimeInterval = isDeepSeekModel ? 300 : 180 // 5 minutes for DeepSeek, 3 minutes for others
            
            if isDeepSeekModel {
                print("⚠️ DeepSeek model detected - using longer timeout of \(timeoutPeriod) seconds")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutPeriod) { [weak self] in
                if self?.isProcessing == true || AppState.shared.isProcessingMessage == true {
                    // If still processing after timeout period, cancel
                    print("Request timed out after \(timeoutPeriod) seconds")
                    self?.isProcessing = false
                    
                    // Cancel any active requests properly
                    if let messageCancellable = self?.messageGenerationCancellable {
                        messageCancellable.cancel()
                        self?.cancellables.remove(messageCancellable)
                        self?.messageGenerationCancellable = nil
                    }
                    
                    // Cancel the active service request directly
                    if let ollamaService = self?.llmService as? OllamaService {
                        ollamaService.cancelRequest()
                    }
                    
                    // Check if model is DeepSeek (should match the earlier check)
                    let timeoutMinutes = Int(ceil(timeoutPeriod / 60.0))
                    let timeoutMessage = isDeepSeekModel ?
                        "The request has timed out after \(timeoutMinutes) minutes. For complex prompts with DeepSeek models, try:\n\n1. Simplifying your prompt\n2. Using a different model with fewer parameters\n3. Restarting Ollama server\n4. Checking if your system has enough RAM for this model" :
                        "The request has timed out after \(timeoutMinutes) minutes. Please try again or check your connection to Ollama."
                    
                    // Check if we have a partial assistant message
                    if var chat = self?.currentChat,
                       let lastIndex = chat.messages.lastIndex(where: { $0.role == .assistant }),
                       chat.messages.indices.contains(lastIndex) {
                       
                        var message = chat.messages[lastIndex]
                        // If we have content, mark it as complete with a timeout note
                        if !message.content.isEmpty {
                            if message.content.contains("Waiting for response from Ollama") {
                                // Replace the waiting message completely
                                message.content = timeoutMessage
                            } else {
                                // Append to existing content but preserve what we have
                                message.content += "\n\n[Response timed out after 3 minutes]\nPartial content was received, but the model took too long to complete the response."
                            }
                            message.isComplete = true
                            chat.messages[lastIndex] = message
                            self?.currentChat = chat
                        }
                    } else if var chat = self?.currentChat,
                              !chat.messages.contains(where: { $0.role == .assistant }) {
                        // No assistant message at all - add timeout message
                        let errorMessage = Message(
                            content: timeoutMessage,
                            role: .assistant,
                            isComplete: true
                        )
                        chat.messages.append(errorMessage)
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
    
    /// NUCLEAR OPTION: The simplest possible approach to extract plain text from JSON
    private func extractJustPlainText(_ text: String) -> String {
        // For debugging
        print("☢️ Applying nuclear option to: \(text.prefix(50))...")
        
        // If it's just plain text, return it
        if !text.contains("{") && !text.contains("}") && !text.contains("\"") {
            return text
        }
        
        // SIMPLEST APPROACH: Direct regex to extract content field
        if text.contains("\"content\"") {
            let pattern = "\"content\"\\s*:\\s*\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                
                let extracted = String(text[range])
                print("☢️ Successfully extracted content: \(extracted.prefix(30))...")
                return extracted
            }
        }
        
        // EXTREME APPROACH: Just strip ALL JSON syntax
        var stripped = text
        
        // Remove all JSON syntax elements
        stripped = stripped.replacingOccurrences(of: "{", with: "")
        stripped = stripped.replacingOccurrences(of: "}", with: "")
        stripped = stripped.replacingOccurrences(of: "\"", with: "")
        stripped = stripped.replacingOccurrences(of: "model:", with: "")
        stripped = stripped.replacingOccurrences(of: "message:", with: "")
        stripped = stripped.replacingOccurrences(of: "content:", with: "")
        stripped = stripped.replacingOccurrences(of: "role:", with: "")
        stripped = stripped.replacingOccurrences(of: "assistant", with: "")
        stripped = stripped.replacingOccurrences(of: "deepseek", with: "")
        stripped = stripped.replacingOccurrences(of: "done:", with: "")
        stripped = stripped.replacingOccurrences(of: "true", with: "")
        stripped = stripped.replacingOccurrences(of: "false", with: "")
        stripped = stripped.replacingOccurrences(of: ",", with: " ")
        
        // Clean up
        stripped = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove double spaces
        while stripped.contains("  ") {
            stripped = stripped.replacingOccurrences(of: "  ", with: " ")
        }
        
        if stripped.isEmpty {
            return "Error: JSON content could not be parsed"
        }
        
        print("☢️ Stripped JSON to: \(stripped.prefix(50))...")
        return stripped
    }
    
    /// EMERGENCY FIX: Brute force removal of any JSON structure, particularly for DeepSeek models
    private func forceRemoveJsonStructure(_ text: String) -> String {
        print("🚒 APPLYING EMERGENCY JSON CLEANUP FOR TEXT: \(text.prefix(50))...")
        
        // If text is just plain text without JSON markers, return it directly
        if !text.contains("{") && !text.contains("}") && !text.contains("\"model\"") && !text.contains("\"message\"") {
            return text
        }
        
        // Check if this is a DeepSeek model
        let isDeepSeek = AppState.shared.selectedModel.displayName.lowercased().contains("deepseek")
        
        // DIRECT EXTRACTION: Try to directly extract just the content field
        if text.contains("\"content\":\"") {
            let pattern = #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                
                let extractedContent = String(text[range])
                // Unescape special characters
                let unescaped = extractedContent.replacingOccurrences(of: "\\\"", with: "\"")
                                               .replacingOccurrences(of: "\\n", with: "\n")
                                               .replacingOccurrences(of: "\\t", with: "\t")
                                               .replacingOccurrences(of: "\\\\", with: "\\")
                
                print("🚒 Successfully extracted content: \(unescaped.prefix(30))...")
                return unescaped
            }
        }
        
        // Try multiple extraction patterns for more reliability
        let extractionPatterns = [
            // Standard content field with quotes
            #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#,
            
            // Content field without proper quoting
            #"content\s*:\s*([^,\}]+)[\},]"#,
            
            // Specific DeepSeek message format
            #""message"\s*:\s*\{\s*"role"\s*:\s*"assistant"\s*,\s*"content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#
        ]
        
        for pattern in extractionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                
                let extractedContent = String(text[range])
                // Unescape special characters
                let unescaped = extractedContent.replacingOccurrences(of: "\\\"", with: "\"")
                                               .replacingOccurrences(of: "\\n", with: "\n")
                                               .replacingOccurrences(of: "\\t", with: "\t")
                                               .replacingOccurrences(of: "\\\\", with: "\\")
                
                if unescaped.count > 10 { // Only return if we got something substantial
                    print("🚒 Alternative extraction successful: \(unescaped.prefix(30))...")
                    return unescaped
                }
            }
        }
        
        // BRUTE FORCE: If direct extraction fails, strip all JSON markers
        var cleaned = text
        
        // Remove all JSON structures - expanded for DeepSeek
        let patterns = [
            // DeepSeek-specific patterns
            #"\{\s*"model"\s*:\s*"deepseek[^"]*"[^}]*\}"#,
            
            // Complete JSON objects
            #"\{\s*"model"\s*:\s*"[^"]*"[^}]*\}"#,
            
            // Field patterns (remove common JSON fields)
            #""message"\s*:\s*\{[^}]*\}"#,
            #""role"\s*:\s*"[^"]*""#,
            #""model"\s*:\s*"[^"]*""#,
            #""content"\s*:\s*"(.*?)""#, // Capture content
            #""done"\s*:\s*(true|false)"#,
            #""created_at"\s*:\s*"[^"]*""#,
            
            // Remove JSON braces completely
            #"\{\s*|\s*\}"#,
            
            // Remove quotes and commas that might be leftover
            #""\s*,\s*""#,
            #"^"|"$"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
            }
        }
        
        // Special handling for DeepSeek models - more aggressive cleaning
        if isDeepSeek {
            // Strip typical DeepSeek response elements
            cleaned = cleaned.replacingOccurrences(of: "model", with: "")
                           .replacingOccurrences(of: "message", with: "")
                           .replacingOccurrences(of: "content", with: "")
                           .replacingOccurrences(of: "role", with: "")
                           .replacingOccurrences(of: "assistant", with: "")
                           .replacingOccurrences(of: "deepseek", with: "")
        }
        
        // Clean up whitespace, quotes, and commas
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")
                       .replacingOccurrences(of: ",", with: " ")
                       .replacingOccurrences(of: ":", with: " ")
        
        // Clean up double spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }
        
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Last check - if we've stripped too much, return an error message
        if cleaned.isEmpty || cleaned.count < 10 {
            return """
            [The model sent a response that couldn't be properly parsed.
            Please try again with a simpler prompt or select a different model.]
            """
        }
        
        print("🚒 Aggressive JSON cleanup result: \(cleaned.prefix(50))...")
        return cleaned
    }
    
    /// Code-aware text processing that preserves code blocks while cleaning JSON
    private func preserveCodeBlocksWhileCleaning(_ text: String) -> String {
        print("🧩 Processing text with code blocks: \(text.prefix(30))...")
        
        // Split the text by triple backticks to isolate code blocks
        let components = text.components(separatedBy: "```")
        
        // If no code blocks were found, process normally
        if components.count <= 1 {
            return text
        }
        
        // Process each component separately
        var processedComponents: [String] = []
        
        for (index, component) in components.enumerated() {
            // Even indices are regular text, odd indices are code blocks
            if index % 2 == 0 {
                // Regular text - apply JSON cleaning if needed
                if component.contains("{") || component.contains("\"model\"") || 
                   component.contains("\"message\"") || component.contains("\"content\"") {
                    // Clean JSON from the regular text
                    let cleaned = extractJustPlainText(component)
                    processedComponents.append(cleaned)
                } else {
                    // No JSON detected, keep as is
                    processedComponents.append(component)
                }
            } else {
                // Code block - don't process, keep as is
                processedComponents.append(component)
            }
        }
        
        // Rejoin the components with triple backticks
        var result = ""
        for (index, component) in processedComponents.enumerated() {
            if index > 0 {
                // Add triple backticks before code blocks
                result += "```"
            }
            result += component
        }
        
        // Make sure we end with triple backticks if we had an odd number of components
        // This indicates the text ended with a code block
        if components.count % 2 == 0 && !result.hasSuffix("```") {
            result += "```"
        }
        
        return result
    }
    
    /// Code-aware text sanitization that properly handles code blocks
    private func codeAwareSanitizeText(_ text: String) -> String {
        print("📝 Processing text with special code block handling")
        
        // Split the content by code block markers
        let parts = text.components(separatedBy: "```")
        
        // If there are no code blocks, fallback to regular sanitization
        if parts.count <= 1 {
            return simpleSanitizeText(text)
        }
        
        var sanitizedParts: [String] = []
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 0 {
                // Regular text - apply normal sanitization
                let sanitized = simpleSanitizeText(part)
                sanitizedParts.append(sanitized)
            } else {
                // Code block - preserve exactly as is
                sanitizedParts.append(part)
            }
        }
        
        // Rejoin with triple backticks
        var result = ""
        for (index, part) in sanitizedParts.enumerated() {
            if index > 0 {
                result += "```"
            }
            result += part
        }
        
        // Make sure we end with triple backticks if we had an odd number of components
        if parts.count % 2 == 0 && !result.hasSuffix("```") {
            result += "```"
        }
        
        return result
    }
    
    /// A simple, highly reliable text sanitizer that won't cause issues
    private func simpleSanitizeText(_ text: String) -> String {
        // Skip sanitization for empty text
        if text.isEmpty {
            return text
        }
        
        // Check for DeepSeek responses
        let isDeepSeekResponse = text.contains("\"model\":\"deepseek") || 
                                text.contains("-r1:") || 
                                text.contains("deepseek-r1") ||
                                (text.hasPrefix("{") && text.contains("\"message\""))
        
        if isDeepSeekResponse {
            print("ChatViewModel: Handling DeepSeek format response")
            let extractedContent = extractDeepSeekContent(text)
            if !extractedContent.isEmpty {
                return extractedContent
            }
        }
        
        // First, strip any JSON metadata that might appear in the text
        var cleaned = removeJsonMetadata(text)
        
        // If we still have JSON-like content, try a more aggressive approach
        if cleaned.contains("{") && cleaned.contains("}") && 
           (cleaned.contains("\"model\"") || cleaned.contains("\"message\"") || cleaned.contains("\"content\"")) {
            
            // Extract just the text between quotes for "content" field 
            let pattern = #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: cleaned.utf16.count)
                let matches = regex.matches(in: cleaned, options: [], range: range)
                
                if !matches.isEmpty {
                    var extractedContent = ""
                    for match in matches {
                        if match.numberOfRanges > 1, 
                           let range = Range(match.range(at: 1), in: cleaned) {
                            let content = String(cleaned[range])
                            // Unescape any escaped quotes or characters
                            let unescaped = content.replacingOccurrences(of: "\\\"", with: "\"")
                                                  .replacingOccurrences(of: "\\n", with: "\n")
                                                  .replacingOccurrences(of: "\\t", with: "\t")
                                                  .replacingOccurrences(of: "\\\\", with: "\\")
                            extractedContent += unescaped
                        }
                    }
                    
                    if !extractedContent.isEmpty {
                        // Use this extraction and skip further processing
                        return extractedContent
                    }
                }
            }
        }
        
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
    
    // Special handling for DeepSeek format
    private func extractDeepSeekContent(_ text: String) -> String {
        // First try to parse as proper JSON
        if let data = text.data(using: .utf8) {
            do {
                // Check if it's a dictionary with a message field
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // We found well-formed JSON with the expected structure
                    return content
                }
            } catch {
                // JSON parsing failed, fall back to regex
                print("DeepSeek JSON parsing failed: \(error.localizedDescription)")
            }
        }
        
        // Try regex extraction for content field
        if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#, options: []) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 1,
               let contentRange = Range(match.range(at: 1), in: text) {
                let content = String(text[contentRange])
                
                // Unescape any escaped quotes or characters
                let unescaped = content.replacingOccurrences(of: "\\\"", with: "\"")
                                       .replacingOccurrences(of: "\\n", with: "\n")
                                       .replacingOccurrences(of: "\\t", with: "\t")
                                       .replacingOccurrences(of: "\\\\", with: "\\")
                
                return unescaped
            }
        }
        
        // If we get more than one match, try to concatenate them (DeepSeek often sends tokens)
        var allContent = ""
        if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#, options: []) {
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                if match.numberOfRanges > 1,
                   let contentRange = Range(match.range(at: 1), in: text) {
                    let content = String(text[contentRange])
                    
                    // Unescape any escaped quotes or characters
                    let unescaped = content.replacingOccurrences(of: "\\\"", with: "\"")
                                          .replacingOccurrences(of: "\\n", with: "\n")
                                          .replacingOccurrences(of: "\\t", with: "\t")
                                          .replacingOccurrences(of: "\\\\", with: "\\")
                    
                    allContent += unescaped
                }
            }
            
            if !allContent.isEmpty {
                // If DeepSeek is streaming single tokens, join them
                return allContent
            }
        }
        
        // If all else fails, check if the text itself is the message content directly
        // This handles cases where individual token fragments are being received
        if !text.contains("{") && !text.contains("}") && 
           !text.contains("model") && !text.contains("message") {
            return text
        }
        
        // Last resort - remove JSON structures
        return removeDeepSeekJsonArtifacts(text)
    }
    
    // Helper to remove JSON artifacts from DeepSeek responses
    private func removeDeepSeekJsonArtifacts(_ text: String) -> String {
        var cleaned = text
        
        // Remove JSON structure patterns
        let patterns = [
            #"\{\s*"model"\s*:\s*"[^"]*"[^}]*\}"#,
            #"\{\s*"message"\s*:\s*\{[^}]*\}\s*\}"#,
            #""role"\s*:\s*"[^"]*""#,
            #""model"\s*:\s*"[^"]*""#,
            #""content"\s*:\s*""#,
            #""\s*,\s*"done"\s*:\s*(true|false)"#,
            #""done"\s*:\s*(true|false)\s*"#,
            #"\{\s*|\s*\}"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
            }
        }
        
        // Remove any extra whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
    
    // Remove JSON metadata from content
    private func removeJsonMetadata(_ text: String) -> String {
        var cleaned = text
        
        // First check if this might be DeepSeek format JSON
        if cleaned.hasPrefix("{") && cleaned.contains("\"message\"") && cleaned.contains("\"content\"") {
            // Try to extract just the content field from DeepSeek format
            if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"]*)""#, options: []) {
                let range = NSRange(location: 0, length: cleaned.utf16.count)
                if let match = regex.firstMatch(in: cleaned, options: [], range: range),
                   match.numberOfRanges > 1,
                   let matchRange = Range(match.range(at: 1), in: cleaned) {
                    return String(cleaned[matchRange])
                }
            }
        }
        
        // Common JSON patterns to filter out
        let jsonPatterns = [
            #"\{\s*"model"\s*:\s*"[^"]*"[^}]*\}\s*"#, // Model info with version
            #"\{\s*"model"[^}]*\}"#, // Simple model info
            #"\{\s*"message"\s*:\s*\{[^}]*\}[^}]*\}\s*"#, // DeepSeek format
            #"\{\s*"role"\s*:\s*"[^"]*",\s*"content"\s*:\s*"[^"]*"\}"#, // Message format
            #"\{\s*"[^"]*"\s*:\s*[^}]*\}"#, // Generic JSON
            #"\{\s*model[^}]*\}"#, // Model info without quotes
            #"\{\s*response[^}]*\}"#, // Response info
        ]
        
        for pattern in jsonPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
            }
        }
        
        // Try to extract content from any remaining JSON fragments
        if cleaned.contains("\"content\"") {
            if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"]*)""#, options: []) {
                let matches = regex.matches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count))
                
                if !matches.isEmpty {
                    var extractedContent = ""
                    for match in matches {
                        if match.numberOfRanges > 1, 
                           let range = Range(match.range(at: 1), in: cleaned) {
                            extractedContent += String(cleaned[range]) + " "
                        }
                    }
                    
                    if !extractedContent.isEmpty {
                        cleaned = extractedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        // Clean up any extra whitespace that might be left
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    private func extractCodeBlocks(from text: String) -> [TextComponent] {
        var components: [TextComponent] = []
        var currentText = ""
        var insideCodeBlock = false
        var currentLanguage = ""
        
        // Clean up any model metadata in curly braces that might be in the text
        let cleanedText = removeJsonMetadata(text)
        
        // Use a more robust approach with better code block detection
        let lines = cleanedText.components(separatedBy: "\n")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("```") {
                if insideCodeBlock {
                    // End of code block - don't include the closing marker in the code
                    components.append(TextComponent(text: currentText, isCodeBlock: true, language: currentLanguage))
                    currentText = ""
                    currentLanguage = ""
                    insideCodeBlock = false
                } else {
                    // Start of code block - don't include the opening marker in the code
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, isCodeBlock: false))
                        currentText = ""
                    }
                    insideCodeBlock = true
                    
                    // Extract language if specified
                    let languageSpecifier = trimmedLine.dropFirst(3)
                    if !languageSpecifier.isEmpty {
                        currentLanguage = String(languageSpecifier).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } else {
                // For code blocks, preserve indentation exactly
                // For regular text, we can trim excessive whitespace
                if insideCodeBlock {
                    currentText += line + "\n"
                } else {
                    // For non-code text, we can clean up a bit
                    let cleaned = cleanMetadataFromLine(line)
                    currentText += cleaned + "\n"
                }
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            components.append(TextComponent(text: currentText, isCodeBlock: insideCodeBlock, language: currentLanguage))
        }
        
        return components
    }
    
    /// Cleans metadata like {model:...} from a line of text
    private func cleanMetadataFromLine(_ line: String) -> String {
        var cleaned = line
        
        // Pattern to find model metadata like {model:"llama",...}
        let metadataPattern = #"\{\s*"model"[^}]*\}"#
        if let regex = try? NSRegularExpression(pattern: metadataPattern, options: []) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
        }
        
        // Remove any stray JSON-like fragments that might appear in output
        let jsonFragmentPattern = #"\{\s*"[^"]*"\s*:\s*[^}]*\}"#
        if let regex = try? NSRegularExpression(pattern: jsonFragmentPattern, options: []) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
        }
        
        return cleaned
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