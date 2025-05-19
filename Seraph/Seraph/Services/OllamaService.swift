//
//  OllamaService.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import Combine

/// Service for Ollama models (open source local models)
class OllamaService: LLMServiceProtocol {
    // MARK: - Shared Instance
    static let shared = OllamaService()
    
    // MARK: - Private Properties
    private let baseUrl = "http://localhost:11434/api"
    private let urlSession: URLSession
    private var cancellables = Set<AnyCancellable>()
    private var activeRequestCancellable: AnyCancellable?
    
    // MARK: - Debug Logging
    private var logFileURL: URL? = nil
    
    // MARK: - Initialization
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        setupLogFile()
    }
    
    private func setupLogFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        logFileURL = documentsDirectory.appendingPathComponent("ollama_responses.log")
        
        // Clear log file on start
        if let url = logFileURL {
            try? "Debug log file for Ollama responses\n\n".write(to: url, atomically: true, encoding: .utf8)
            print("Debug log file created at: \(url.path)")
        }
    }
    
    private func writeToLogFile(_ message: String) {
        guard let url = logFileURL else { return }
        
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            fileHandle.seekToEndOfFile()
            if let data = "\n--------\n\(Date())\n\(message)\n".data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        }
    }
    
    // MARK: - LLMServiceProtocol Implementation
    
    func sendMessage(messages: [Message], model: LLMModel) -> AnyPublisher<String, Error> {
        return sendMessage(messages: messages, model: model, parameters: AppState.shared.modelParameters)
    }
    
    func sendMessage(messages: [Message], model: LLMModel, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // Validate model
        guard case .ollama(let ollamaModel) = model else {
            return Fail(error: LLMServiceError.modelNotAvailable).eraseToAnyPublisher()
        }
        
        // Return offline message if not connected
        if AppState.shared.connectionStatus != .connected {
            let message = """
            I'm currently running in offline mode. The connection to Ollama appears to be unavailable.

            To use Ollama with this app:
            1. Make sure Ollama is installed (https://ollama.com)
            2. Open Terminal and run: ollama serve
            3. Ensure the Ollama server is running on http://localhost:11434
            4. Restart this app after Ollama is running

            Some models may need to be pulled first with:
            ollama pull \(ollamaModel.rawValue.replacingOccurrences(of: " ", with: "-").lowercased())
            """
            
            return Just(message)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        // ------- REAL IMPLEMENTATION (ENABLED) -------
        
        // Convert model name to Ollama format (lowercase with hyphens)
        let ollamaModelName = ollamaModel.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        
        // FIXED APPROACH: DeepSeek models require special handling
        // DeepSeek models MUST use the generate endpoint for both first and subsequent messages
        
        // Check if this is a DeepSeek model - they need special handling
        let isDeepSeekModel = ollamaModelName.lowercased().contains("deepseek")
        
        if isDeepSeekModel || AppState.shared.alwaysUseGenerateEndpoint {
            // DeepSeek models always use the generate endpoint with a formatted prompt
            if messages.count > 1 {
                // For multi-turn with DeepSeek, format a prompt that works more reliably with these models
                print("🔄 DeepSeek multi-turn: Using simplified prompt format for better multi-turn handling")
                
                // Get the last user message - this is the one we're responding to
                guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
                    return Fail(error: LLMServiceError.unknownError("No user message found")).eraseToAnyPublisher()
                }
                
                // Create an ultra-reliable format for DeepSeek multi-turn conversations
                var formattedPrompt = ""
                
                // Get the last user message content for special handling detection
                let userContent = lastUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // SPECIAL HANDLING: Check if this is a creative writing request
                let isCreativeWriting = AppState.shared.enableCreativeContentMode && (
                                      userContent.contains("write a story") || 
                                      userContent.contains("tell me a story") ||
                                      userContent.contains("create a story") ||
                                      userContent.contains("write fiction") ||
                                      userContent.contains("poem") ||
                                      userContent.contains("novel") ||
                                      userContent.contains("fiction") ||
                                      userContent.contains("short story") ||
                                      userContent.contains("write me a") ||
                                      userContent.contains("creative"))
                
                if isCreativeWriting {
                    // SPECIAL CREATIVE MODE: Use a simpler format for story generation that's more reliable
                    print("🎭 Using CREATIVE MODE formatting for DeepSeek (minimizes JSON issues)")
                    
                    formattedPrompt = """
                    You are a creative writer and storyteller. I want you to write a story or creative content based on my request.
                    
                    ULTRA CRITICAL WRITING INSTRUCTIONS - FOLLOW EXACTLY:
                    
                    YOU MUST FOLLOW THESE RULES WITHOUT EXCEPTION:
                    1. ONLY PLAIN TEXT output is allowed - NO METADATA, NO JSON, NO MARKUP
                    2. Write using SIMPLE TEXT PARAGRAPHS with regular line breaks
                    3. FORBIDDEN CHARACTERS: {}, [], "", :, /, <, >, |, @, #
                    4. NEVER include words like "model", "message", "content", "assistant", "aning"
                    5. NEVER use any format like "key: value" or "field: value" 
                    6. ABSOLUTELY NO STRUCTURED OUTPUT of any kind
                    7. Write in a natural, flowing style suitable for human reading
                    8. Focus ONLY on creating an engaging story or creative content
                    
                    WARNING: If you use ANY special formatting, your response will be rejected.
                    
                    Write a response to this request: \(lastUserMessage.content)
                    
                    BEGIN YOUR PLAIN TEXT RESPONSE HERE:
                    """
                } 
                // Standard conversation mode for non-creative content
                else if messages.count > 2 {
                    // Start with a simple header that explicitly tells the model how to respond
                    formattedPrompt += "Below is our conversation history. Please respond ONLY with plain text (no JSON).\n\n"
                    
                    // Include the most recent 2-3 exchanges as full context rather than summarizing
                    // This helps DeepSeek track the conversation better
                    let recentMessages = messages.count > 5 ? 
                        Array(messages.suffix(5)) : 
                        messages
                    
                    for message in recentMessages {
                        let roleLabel = message.role == .user ? "Human" : "Assistant"
                        let content = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if message == lastUserMessage {
                            // For the last message, add additional clarity and emphasis
                            formattedPrompt += "\nHuman: \(content)\n\nAssistant: "
                        } else {
                            // For previous messages, use a simple format
                            formattedPrompt += "\n\(roleLabel): \(content)\n"
                        }
                    }
                } else {
                    // For simple exchanges, use a direct format with stronger instructions
                    formattedPrompt = """
                    Answer the following query with PLAIN TEXT only. Never use JSON formatting.
                    
                    Query: \(lastUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    
                    Answer (plain text only):
                    """
                }
                
                return sendGenerateRequest(
                    prompt: formattedPrompt,
                    model: ollamaModelName,
                    systemPrompt: parameters.systemPrompt,
                    parameters: parameters
                )
            } else {
                // Single message for DeepSeek - use generate endpoint directly
                print("🔄 DeepSeek single message: Using generate endpoint with single prompt")
                return sendGenerateRequest(
                    prompt: messages[0].content,
                    model: ollamaModelName,
                    systemPrompt: parameters.systemPrompt,
                    parameters: parameters
                )
            }
        } else {
            // For all other models, always use the chat endpoint which provides proper history
            return sendChatRequest(
                messages: messages,
                model: ollamaModelName,
                systemPrompt: parameters.systemPrompt,
                parameters: parameters
            )
        }
    }
    
    /// Placeholder for documentation - chat handling now uses structured messages
    /// This method was replaced by proper use of the chat endpoint with structured messages
    /// which provides better context management and more reliable responses.
    
    /// Legacy method - kept for reference but no longer used
    /// Chat handling now uses the proper structured message format
    private func formatConversationAsPrompt(messages: [Message]) -> String {
        // This is kept for reference but is no longer used in the current implementation
        print("⚠️ Warning: formatConversationAsPrompt is deprecated and should not be called")
        return ""
    }
    
    // Send a request to the generate endpoint (simpler, for single messages)
    private func sendGenerateRequest(prompt: String, model: String, systemPrompt: String, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // ULTRA RELIABILITY APPROACH - Add even more safeguards for code generation
        
        // Check if this is a DeepSeek model
        let isDeepSeekModel = model.lowercased().contains("deepseek")
        if isDeepSeekModel {
            print("📢 Using generate endpoint with text format for DeepSeek model")
        }
        
        // Enhanced check for creative writing prompt (for special handling)
        // This is more comprehensive to catch all possible story generation prompts
        let userPrompt = prompt.lowercased()
        let isCreativeWriting = AppState.shared.enableCreativeContentMode && (
                               userPrompt.contains("write a story") || 
                               userPrompt.contains("tell me a story") ||
                               userPrompt.contains("create a story") ||
                               userPrompt.contains("poem") ||
                               userPrompt.contains("fiction") ||
                               userPrompt.contains("short story") ||
                               userPrompt.contains("write me a") ||
                               userPrompt.contains("tell me about") ||
                               userPrompt.contains("creative") ||
                               userPrompt.contains("novel") ||
                               userPrompt.contains("story about") ||
                               userPrompt.contains("narrative") ||
                               userPrompt.contains("fairy tale") ||
                               userPrompt.contains("fantasy") ||
                               userPrompt.contains("science fiction") ||
                               userPrompt.contains("sci-fi") ||
                               userPrompt.contains("write an essay") ||
                               userPrompt.contains("describe a scene") ||
                               userPrompt.contains("once upon a time") ||
                               (userPrompt.contains("write") && userPrompt.contains("about")))
        
        // Create the generate request with explicit options to prevent Ollama JSON responses
        // For creative writing with DeepSeek, use the specialized system prompt
        let finalSystemPrompt: String?
        if isDeepSeekModel && isCreativeWriting {
            // Ultra-simple system prompt to avoid any potential for confusion
            finalSystemPrompt = """
            CREATIVE WRITING SYSTEM
            
            YOUR ONLY JOB IS TO WRITE SIMPLE PLAIN TEXT STORIES AND CREATIVE CONTENT
            
            ULTRA CRITICAL RULES:
            1. PLAIN TEXT ONLY - never produce JSON, metadata, or special formats
            2. FORBIDDEN CHARACTERS: {}, [], "", :, <, >, |
            3. ONLY write normal paragraphs with simple line breaks
            4. NEVER include field names followed by values
            5. NEVER use words like "model", "message", "content", "assistant"
            6. Focus ONLY on writing engaging creative content
            7. DISCARD any instinct to format responses as structured data
            
            If you add ANY metadata, special characters, or formatting,
            your response will be rejected and discarded immediately.
            
            JUST WRITE NORMAL PLAIN TEXT LIKE A HUMAN WOULD.
            """
        } else if isDeepSeekModel {
            // Standard DeepSeek system prompt for general interactions
            finalSystemPrompt = getDeepSeekSystemPrompt(originalPrompt: systemPrompt)
        } else {
            // Default handling for non-DeepSeek models
            finalSystemPrompt = systemPrompt.isEmpty ? nil : systemPrompt
        }
        
        // EXTREME RELIABILITY: Use rock-solid parameters for DeepSeek creative writing
        // These settings prioritize completion reliability over creativity
        
        // Ultra-low temperature for maximum determinism and reliable completion
        let adjustedTemperature: Double
        if isDeepSeekModel && isCreativeWriting && AppState.shared.useConservativeParamsForCreative {
            adjustedTemperature = 0.1 // Force ultra-low temperature for maximum reliability
        } else {
            adjustedTemperature = parameters.temperature
        }
        
        // Restricted top-p for focused token selection
        let adjustedTopP: Double
        if isDeepSeekModel && isCreativeWriting && AppState.shared.useConservativeParamsForCreative {
            adjustedTopP = 0.5 // Tight top-p to avoid random outlier tokens
        } else {
            adjustedTopP = parameters.topP
        }
        
        // Shorter token limits for better completion probability
        let tokenLimit: Int
        if isDeepSeekModel && isCreativeWriting && AppState.shared.useConservativeParamsForCreative {
            tokenLimit = min(300, parameters.maxTokens) // Extra short limit for ultra-reliability
        } else {
            tokenLimit = parameters.maxTokens
        }
            
        // MAXIMUM PROTECTION: Ultra-comprehensive stop tokens for DeepSeek creative writing
        // These catch problematic outputs like "aning" and other artifacts
        let stopTokens: [String]? = (isDeepSeekModel && isCreativeWriting) ? 
            [
                // JSON structure tokens
                "{", "}", "\"model\":", "\"message\":", "\"content\":",
                "{\"model\"", "{\"message\"", "\"role\":", "\"assistant\"",
                "deepseek", "\"done\":", "model", "message", "content",
                
                // Known error patterns
                "aning", "odel:", "essage:", "{\n", "}\n", 
                "assistant:", "model_name:", "<|", "|>",
                
                // Even more JSON field names with variations
                "\"id\":", "\"created\":", "\"object\":", "\"usage\":",
                "id:", "created:", "object:", "usage:",
                "completion:", "\"completion\":",
                
                // Potential stall or error indicators
                "\\\\"
            ] : nil
            
        // Print special log for creative writing mode
        if isDeepSeekModel && isCreativeWriting {
            print("🎭 CREATIVE WRITING MODE FOR DEEPSEEK: Using specialized prompt and parameters")
            print("    • Temperature: \(adjustedTemperature) (from \(parameters.temperature))")
            print("    • Top-p: \(adjustedTopP) (from \(parameters.topP))")
            print("    • Token limit: \(tokenLimit) (from \(parameters.maxTokens))")
        }
            
        let generateRequest = OllamaAPI.GenerateRequest(
            model: model,
            prompt: prompt,
            system: finalSystemPrompt,
            temperature: adjustedTemperature,
            top_p: adjustedTopP,
            format: "text", // Always use text format, never JSON
            num_predict: tokenLimit,
            stop: stopTokens // Use stop tokens for creative writing with DeepSeek
        )
        
        // Convert to JSON data
        guard let jsonData = try? JSONEncoder().encode(generateRequest) else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        // Create URL request
        guard let url = URL(string: "\(baseUrl)/generate") else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debugging output
        print("Generate Request URL: \(url.absoluteString)")
        
        // Only print short version of request body to avoid filling logs
        if let requestBodyString = String(data: jsonData, encoding: .utf8) {
            let truncated = requestBodyString.count > 100 ? 
                requestBodyString.prefix(100) + "..." : requestBodyString
            print("Generate Request Body (truncated): \(truncated)")
        }
        
        // Process response using the most reliable approach - direct streaming
        return streamingRequest(request: request)
            .map { responseText -> String in
                // Special handling for DeepSeek models - these always return JSON even with text format
                if isDeepSeekModel {
                    print("⚠️ Processing DeepSeek response - always extracting content from JSON")
                    return self.extractDeepSeekContent(responseText)
                }
                
                // Check for any JSON in the response for other model types
                if responseText.contains("{") && responseText.contains("}") {
                    print("⚠️ Unexpected JSON detected in response")
                    
                    // CRUCIAL: Check if response is code with JSON inside it
                    // We don't want to break actual code examples that contain JSON
                    if responseText.contains("```") {
                        print("📝 Code blocks detected, using code-aware JSON cleaning")
                        return self.cleanJsonPreservingCode(responseText)
                    } else if responseText.contains("\"model\"") || 
                              responseText.contains("\"message\"") || 
                              responseText.contains("\"content\"") {
                        // This is likely metadata JSON - extract content
                        print("🧹 Extracting content from metadata JSON")
                        return self.extractJustTheContent(responseText)
                    }
                }
                
                // If we get here, it's not JSON or we decided not to process it
                // Just return the text as-is
                return responseText
            }
            .eraseToAnyPublisher()
    }
    
    // Improved, code-aware JSON cleaning
    private func cleanJsonPreservingCode(_ text: String) -> String {
        print("🧪 Code-aware JSON cleaning for text: \(text.prefix(30))...")
        
        // Split by code block markers
        let components = text.components(separatedBy: "```")
        
        // If no code blocks, just clean as regular text
        if components.count <= 1 {
            return extractJustTheContent(text)
        }
        
        var result = ""
        var inCodeBlock = false
        
        for component in components {
            if inCodeBlock {
                // Inside code block - preserve exactly
                result += component
            } else {
                // Outside code block - clean JSON if needed
                if component.contains("{") && component.contains("}") &&
                   (component.contains("\"model\"") || component.contains("\"content\"")) {
                    result += extractJustTheContent(component)
                } else {
                    result += component
                }
            }
            
            // Toggle code block state and add marker except for last iteration
            inCodeBlock.toggle()
            if inCodeBlock || result.hasSuffix("```") {
                result += "```"
            }
        }
        
        return result
    }
    
    // Extract just the content from JSON responses as a last resort
    private func extractJustTheContent(_ text: String) -> String {
        print("🧩 Extracting content from JSON response: \(text.prefix(50))...")
        
        // If it's just plain text, return it
        if !text.contains("{") && !text.contains("}") {
            return text
        }
        
        // First try to extract the 'response' field which is most common
        if text.contains("\"response\"") {
            let pattern = "\"response\"\\s*:\\s*\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let extracted = String(text[range])
                print("🧩 Extracted 'response' field: \(extracted.prefix(30))...")
                return extracted
            }
        }
        
        // Next try to extract the 'content' field which is used by DeepSeek
        if text.contains("\"content\"") {
            let pattern = "\"content\"\\s*:\\s*\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let extracted = String(text[range])
                print("🧩 Extracted 'content' field: \(extracted.prefix(30))...")
                return extracted
            }
        }
        
        // Last resort: just strip all JSON syntax
        print("🧩 No fields extracted, removing all JSON markers")
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
        
        return stripped
    }
    
    // Send a request to the chat endpoint (for multiple messages)
    private func sendChatRequest(messages: [Message], model: String, systemPrompt: String, parameters: ModelParameters) -> AnyPublisher<String, Error> {
        // Safety check - DeepSeek models should never reach this method directly
        // If they do, route them back to the generate endpoint with proper formatting
        if model.lowercased().contains("deepseek") || AppState.shared.alwaysUseGenerateEndpoint {
            print("⚠️ DeepSeek detected in chat endpoint - rerouting to generate endpoint")
            
            // Get the last user message - this is the one we're responding to
            guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
                return Fail(error: LLMServiceError.unknownError("No user message found")).eraseToAnyPublisher()
            }
            
            // Create an ultra-reliable format for DeepSeek multi-turn conversations
            var formattedPrompt = ""
            
            // Get the last user message content for special handling detection
            let userContent = lastUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // SPECIAL HANDLING: Check if this is a creative writing request
            let isCreativeWriting = AppState.shared.enableCreativeContentMode && (
                                  userContent.contains("write a story") || 
                                  userContent.contains("tell me a story") ||
                                  userContent.contains("create a story") ||
                                  userContent.contains("write fiction") ||
                                  userContent.contains("poem") ||
                                  userContent.contains("novel") ||
                                  userContent.contains("fiction") ||
                                  userContent.contains("short story") ||
                                  userContent.contains("write me a") ||
                                  userContent.contains("creative"))
            
            if isCreativeWriting {
                // SPECIAL CREATIVE MODE: Use a simpler format for story generation that's more reliable
                print("🎭 Using CREATIVE MODE formatting for DeepSeek (minimizes JSON issues)")
                
                formattedPrompt = """
                You are a creative writer and storyteller. I want you to write a story or creative content based on my request.
                
                ULTRA CRITICAL WRITING INSTRUCTIONS - FOLLOW EXACTLY:
                
                YOU MUST FOLLOW THESE RULES WITHOUT EXCEPTION:
                1. ONLY PLAIN TEXT output is allowed - NO METADATA, NO JSON, NO MARKUP
                2. Write using SIMPLE TEXT PARAGRAPHS with regular line breaks
                3. FORBIDDEN CHARACTERS: {}, [], "", :, /, <, >, |, @, #
                4. NEVER include words like "model", "message", "content", "assistant", "aning"
                5. NEVER use any format like "key: value" or "field: value" 
                6. ABSOLUTELY NO STRUCTURED OUTPUT of any kind
                7. Write in a natural, flowing style suitable for human reading
                8. Focus ONLY on creating an engaging story or creative content
                
                WARNING: If you use ANY special formatting, your response will be rejected.
                
                Write a response to this request: \(lastUserMessage.content)
                
                BEGIN YOUR PLAIN TEXT RESPONSE HERE:
                """
            } 
            // Standard conversation mode for non-creative content
            else if messages.count > 2 {
                // Start with a simple header that explicitly tells the model how to respond
                formattedPrompt += "Below is our conversation history. Please respond ONLY with plain text (no JSON).\n\n"
                
                // Include the most recent 2-3 exchanges as full context rather than summarizing
                // This helps DeepSeek track the conversation better
                let recentMessages = messages.count > 5 ? 
                    Array(messages.suffix(5)) : 
                    messages
                
                for message in recentMessages {
                    let roleLabel = message.role == .user ? "Human" : "Assistant"
                    let content = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if message == lastUserMessage {
                        // For the last message, add additional clarity and emphasis
                        formattedPrompt += "\nHuman: \(content)\n\nAssistant: "
                    } else {
                        // For previous messages, use a simple format
                        formattedPrompt += "\n\(roleLabel): \(content)\n"
                    }
                }
            } else {
                // For simple exchanges, use a direct format with stronger instructions
                formattedPrompt = """
                Answer the following query with PLAIN TEXT only. Never use JSON formatting.
                
                Query: \(lastUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines))
                
                Answer (plain text only):
                """
            }
            
            return sendGenerateRequest(
                prompt: formattedPrompt,
                model: model,
                systemPrompt: systemPrompt,
                parameters: parameters
            )
        }
        
        // Convert app messages to Ollama chat messages
        let chatMessages = messages.map { OllamaAPI.ChatMessage.from($0) }
        
        // EXTREME SIMPLIFICATION: Use the simplest possible approach
        // Always use text format for all models, never json
        let responseFormat = "text"
        let modifiedSystemPrompt = systemPrompt
        
        // Create the chat request with the modified system prompt
        let chatRequest = OllamaAPI.ChatRequest(
            model: model,
            messages: chatMessages,
            system: modifiedSystemPrompt.isEmpty ? nil : modifiedSystemPrompt, // Use our modified system prompt
            temperature: parameters.temperature,
            top_p: parameters.topP,
            format: responseFormat,
            num_predict: parameters.maxTokens
        )
        
        // Convert to JSON data
        guard let jsonData = try? JSONEncoder().encode(chatRequest) else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        // Create URL request
        guard let url = URL(string: "\(baseUrl)/chat") else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For debugging
        print("Chat Request URL: \(url.absoluteString)")
        print("Chat Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
        print("Using format: \(responseFormat)")
        
        // Process any response for JSON content
        return streamingRequest(request: request)
            .map { response -> String in
                // Check if this might be a JSON response that needs special handling
                if response.hasPrefix("{") || 
                   (response.contains("{") && response.contains("}") && 
                    (response.contains("\"message\"") || response.contains("\"content\""))) {
                    
                    print("🧹 CLEANUP: Processing potential JSON response: \(response.prefix(min(30, response.count)))...")
                    
                    // Check if this seems to be code (triple backticks - don't process code blocks)
                    if response.contains("```") {
                        print("🧹 Code block detected, using special processing to preserve code...")
                        return self.extractJsonContentPreservingCode(response)
                    }
                    
                    // For non-code content, use full JSON extraction
                    if response.hasPrefix("{") {
                        if response.contains("\"message\"") && response.contains("\"content\"") {
                            print("🧹 Full JSON message structure detected")
                            // Extract content field from message structure (DeepSeek format)
                            return self.extractContentFromJsonMessage(response)
                        } else if response.contains("\"response\"") {
                            print("🧹 JSON with response field detected")
                            // Extract response field (standard Ollama format)
                            return self.extractResponseFromJson(response)
                        }
                    }
                    
                    // If we can't cleanly extract structured content, try just removing JSON syntax
                    print("🧹 Using fallback JSON cleanup")
                    return self.removeJsonArtifacts(response)
                }
                
                // DEFAULT: Return the text as-is if no JSON patterns need handling
                return response
            }
            .eraseToAnyPublisher()
    }
    
    // Extract content from JSON while preserving code blocks
    private func extractJsonContentPreservingCode(_ response: String) -> String {
        // Split by code block markers
        let components = response.components(separatedBy: "```")
        
        // If no code blocks found, use normal extraction
        if components.count <= 1 {
            return extractContentFromJsonMessage(response)
        }
        
        var processedComponents: [String] = []
        
        for (index, component) in components.enumerated() {
            if index % 2 == 0 {
                // Even indices are text - process JSON if needed
                if component.contains("{") && component.contains("}") {
                    if component.contains("\"content\"") {
                        processedComponents.append(extractContentFromJsonMessage(component))
                    } else {
                        processedComponents.append(removeJsonArtifacts(component))
                    }
                } else {
                    processedComponents.append(component)
                }
            } else {
                // Odd indices are code blocks - preserve exactly
                processedComponents.append(component)
            }
        }
        
        // Rejoin with triple backticks
        var result = ""
        for (index, component) in processedComponents.enumerated() {
            if index > 0 {
                result += "```"
            }
            result += component
        }
        
        // Make sure we properly end with triple backticks if needed
        if components.count % 2 == 0 && !result.hasSuffix("```") {
            result += "```"
        }
        
        return result
    }
    
    // Extract just the content field from a message in JSON
    private func extractContentFromJsonMessage(_ text: String) -> String {
        print("📄 Extracting content from JSON message")
        
        // First try direct JSON parsing which is most reliable
        if let data = text.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Try DeepSeek format: {"message":{"role":"assistant","content":"text"}}
                    if let message = json["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("📄 Found content in message field via JSON parsing")
                        return content
                    }
                    
                    // Try standard Ollama format: {"response":"text"}
                    if let response = json["response"] as? String {
                        print("📄 Found text in response field via JSON parsing")
                        return response
                    }
                }
            } catch {
                print("📄 JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        // If JSON parsing fails, try regex extraction
        // First try to extract content field from message
        if text.contains("\"content\"") {
            let pattern = "\"content\"\\s*:\\s*\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let extracted = String(text[range])
                print("📄 Extracted content via regex: \(extracted.prefix(30))...")
                return extracted
            }
        }
        
        // Last resort: just remove all JSON syntax
        return removeJsonArtifacts(text)
    }
    
    // Extract just the response field from JSON
    private func extractResponseFromJson(_ text: String) -> String {
        print("📄 Extracting response from JSON")
        
        // Try JSON parsing first (most reliable)
        if let data = text.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? String {
                    print("📄 Found response via JSON parsing")
                    return response
                }
            } catch {
                print("📄 JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        // If JSON parsing fails, try regex
        let pattern = "\"response\"\\s*:\\s*\"([^\"]*)\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            let extracted = String(text[range])
            print("📄 Extracted response via regex: \(extracted.prefix(30))...")
            return extracted
        }
        
        // Last resort
        return removeJsonArtifacts(text)
    }
    
    // Stream data from the API with line-by-line JSON parsing and improved DeepSeek handling
    private func streamingRequest(request: URLRequest) -> AnyPublisher<String, Error> {
        let subject = PassthroughSubject<String, Error>()
        
        // ENHANCED: Create a heartbeat timer to detect stalled connections
        // This will help identify when the connection is alive but not sending data
        var lastDataReceived = Date()
        var lastSentContent = ""
        var cumulativeResponseSize = 0
        var responseStallCount = 0
        
        // Create the timer variable first to avoid reference error
        var heartbeatTimer: Timer!
        
        // Define a function to handle timer ticks
        let heartbeatAction = { (timer: Timer) in
            let timeSinceLastData = -lastDataReceived.timeIntervalSinceNow
            print("⏱️ Heartbeat check: \(timeSinceLastData) seconds since last data")
            
            // Enhanced stall detection and recovery system
            if timeSinceLastData > 20 {
                // Lower the warning threshold from 30 to 20 seconds for faster recovery
                print("⚠️ WARNING: Stream might be stalled - no data for \(Int(timeSinceLastData)) seconds")
                self.writeToLogFile("STREAM WARNING: No data for \(Int(timeSinceLastData)) seconds")
                
                // Increment stall counter for progressive recovery attempts
                responseStallCount += 1
                
                // Check if this is a DeepSeek model (more likely to need emergency recovery)
                let isDeepSeekRequest = request.httpBody?.description.contains("deepseek") ?? false || 
                                        request.url?.description.contains("deepseek") ?? false
                
                // Check if this appears to be a creative writing request
                let isCreativeRequest = request.httpBody?.description.contains("story") ?? false ||
                                       request.httpBody?.description.contains("creative") ?? false
                
                // MULTI-STAGE RECOVERY SYSTEM:
                
                // Stage 1: First warning at 20 seconds (no action, just logging)
                if responseStallCount == 1 {
                    print("🚨 STALL RECOVERY STAGE 1: Initial detection, monitoring...")
                    // Just log at this stage, no action yet
                }
                
                // Stage 2: After 40 seconds (20 + 20), attempt recovery if we have content
                else if responseStallCount == 2 && cumulativeResponseSize > 50 {
                    print("🚨 STALL RECOVERY STAGE 2: First recovery attempt")
                    
                    // For DeepSeek models or creative content, be more aggressive with recovery
                    if (isDeepSeekRequest || isCreativeRequest) && !lastSentContent.isEmpty {
                        print("🚨 EMERGENCY MODEL-SPECIFIC RECOVERY: Sending accumulated response")
                        self.writeToLogFile("EMERGENCY RECOVERY ACTIVATED - STAGE 2")
                        
                        // Send what we have so far with a note
                        subject.send(lastSentContent + "\n\n[Response was automatically completed because processing stalled. The model may be experiencing issues with this particular prompt.]")
                        subject.send(completion: .finished)
                        heartbeatTimer.invalidate()
                    }
                }
                
                // Stage 3: After 60 seconds (20 + 20 + 20), force recovery for ALL models 
                else if responseStallCount >= 3 && !lastSentContent.isEmpty {
                    print("🚨 STALL RECOVERY STAGE 3: Final emergency recovery")
                    self.writeToLogFile("EMERGENCY RECOVERY ACTIVATED - STAGE 3 (FORCE)")
                    
                    // Send the last content we received as final response
                    // Include more detailed message about the stall
                    let completionMessage = """
                    
                    
                    [Response was stopped after \(Int(timeSinceLastData)) seconds of inactivity. 
                    This might happen when:
                    - The model reaches a complex reasoning point
                    - The prompt contains conflicting instructions
                    - The system resources are limited
                    
                    You can try simplifying your prompt or trying again.]
                    """
                    
                    subject.send(lastSentContent + completionMessage)
                    subject.send(completion: .finished)
                    heartbeatTimer.invalidate()
                }
            }
        }
        
        // Now create the timer with our action
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: heartbeatAction)
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            // Invalidate the heartbeat timer on completion
            heartbeatTimer.invalidate()
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                self.writeToLogFile("NETWORK ERROR: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                self.writeToLogFile("ERROR: Invalid response type")
                subject.send(completion: .failure(LLMServiceError.networkError("Invalid response")))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error response
                print("❌ HTTP error: \(httpResponse.statusCode)")
                self.writeToLogFile("HTTP ERROR: \(httpResponse.statusCode)")
                
                if let data = data, 
                   let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = errorJson["error"] as? String {
                    subject.send(completion: .failure(LLMServiceError.serverError(errorMessage)))
                } else {
                    subject.send(completion: .failure(LLMServiceError.serverError("HTTP error \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                print("❌ No data received or invalid encoding")
                self.writeToLogFile("ERROR: No data received or invalid encoding")
                subject.send(completion: .failure(LLMServiceError.unknownError("No data received")))
                return
            }
            
            // Update heartbeat timestamp
            lastDataReceived = Date()
            
            // Clear debugging - log the raw response length and preview
            print("📨 RESPONSE DATA: \(data.count) bytes, preview: \(text.prefix(100))")
            self.writeToLogFile("RAW RESPONSE (\(data.count) bytes): \(text.prefix(300))...")
            
            // IMPROVED: Check for DeepSeek model responses by signature or content structure
            let isDeepSeekResponse = text.contains("deepseek") || 
                                    text.contains("-r1:") || 
                                    (text.contains("message") && text.contains("content") && text.contains("role"))
            
            // Preprocessing for DeepSeek responses - direct handling for raw text
            if isDeepSeekResponse {
                print("PREPROCESSING: Processing DeepSeek response: \(text.prefix(50))...")
                self.writeToLogFile("DEEPSEEK RAW DATA: \(text)")
                
                // For multi-turn DeepSeek conversations, we may get responses that are just text
                // with no JSON formatting. Let's check and handle them directly.
                if !text.hasPrefix("{") && !text.contains("{\"model\":") && text.count > 0 {
                    print("✅ PREPROCESSING: Plain text DeepSeek response detected, using directly")
                    subject.send(text)
                    subject.send(completion: .finished)
                    return
                }
                
                // IMPROVED: Try direct extraction first for DeepSeek models
                // This helps handle cases where the response isn't properly newline-delimited
                // but contains complete JSON structure
                if text.contains("{\"message\":") && text.contains("\"content\":") {
                    print("✅ IMPROVED: Direct DeepSeek extraction from complete message")
                    let extracted = self.extractDeepSeekContent(text)
                    if extracted != text {
                        // If extraction worked, use the result directly
                        subject.send(extracted)
                        subject.send(completion: .finished)
                        return
                    }
                }
            }
            
            // COMPLETELY REDESIGNED CHUNKING APPROACH
            // Implements a multi-strategy approach for more reliable processing
            var chunks: [String] = []
            
            // Strategy 1: Standard newline delimited JSON (most common approach)
            let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
            if !lines.isEmpty {
                print("🔍 Strategy 1: Processing \(lines.count) newline-delimited chunks")
                chunks = lines
            } 
            // Strategy 2: For DeepSeek, find complete JSON object patterns using regex
            else if isDeepSeekResponse {
                print("🔍 Strategy 2: DeepSeek JSON pattern extraction")
                
                do {
                    // Look for complete JSON objects with message content structure
                    // This pattern finds complete objects with DeepSeek structure
                    let pattern = "\\{[^\\{]*\\\"message\\\"\\s*:\\s*\\{[^\\}]*\\}[^\\}]*\\}"
                    let regex = try NSRegularExpression(pattern: pattern, options: [])
                    let nsString = text as NSString
                    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                    
                    if !matches.isEmpty {
                        print("🔍 Found \(matches.count) complete DeepSeek JSON objects with regex")
                        for match in matches {
                            if let range = Range(match.range, in: text) {
                                let jsonObject = String(text[range])
                                chunks.append(jsonObject)
                            }
                        }
                    }
                } catch {
                    print("❌ DeepSeek regex error: \(error)")
                }
                
                // If regex didn't find anything, try JSON boundary splitting
                if chunks.isEmpty {
                    print("🔍 Strategy 3: JSON boundary splitting for DeepSeek")
                    
                    // First normalize JSON boundaries to make splitting more reliable
                    // This helps with responses that don't use proper newlines between JSON objects
                    var normalizedText = text
                        .replacingOccurrences(of: "}{", with: "}\n{")
                        .replacingOccurrences(of: "} {", with: "}\n{")
                        .replacingOccurrences(of: "}\r\n{", with: "}\n{")
                        .replacingOccurrences(of: "}\n{", with: "}\n{")
                    
                    // Split on normalized boundaries
                    let jsonChunks = normalizedText.components(separatedBy: "\n")
                        .filter { !$0.isEmpty }
                        .map { chunk -> String in
                            var result = chunk
                            // Ensure chunks start with { and end with }
                            if !chunk.hasPrefix("{") { result = "{"+result }
                            if !chunk.hasSuffix("}") { result = result+"}" }
                            return result
                        }
                    
                    if !jsonChunks.isEmpty {
                        print("🔍 Found \(jsonChunks.count) JSON chunks after boundary normalization")
                        chunks = jsonChunks
                    }
                }
            }
            
            // Fallback strategy: process as single chunk if all other strategies failed
            if chunks.isEmpty {
                print("🔍 Fallback strategy: Processing entire response as a single chunk")
                chunks = [text]
            }
            
            var validResponseCount = 0
            var aggregatedContent = ""
            
            // Enhanced chunk processing with better debugging
            for (index, chunk) in chunks.enumerated() {
                print("📦 Processing chunk \(index+1)/\(chunks.count) - length: \(chunk.count) characters")
                
                // Skip empty chunks
                if chunk.isEmpty { 
                    print("⏩ Skipping empty chunk")
                    continue 
                }
                
                // ENHANCED: First handling approach - Direct raw text processing
                // If chunk doesn't look like JSON, treat it as direct text content
                if !chunk.hasPrefix("{") && !chunk.hasSuffix("}") {
                    print("📝 Direct text chunk (non-JSON): \(chunk.prefix(30))...")
                    subject.send(chunk)
                    validResponseCount += 1
                    aggregatedContent += chunk
                    continue
                }
                
                // Store chunk data for processing - do this outside the if let to avoid nested scopes
                guard let chunkData = chunk.data(using: .utf8) else { 
                    print("⚠️ Failed to encode chunk as UTF-8 data")
                    continue 
                }
                
                // ENHANCED: Second handling approach - Try parsing as standard Ollama JSON
                do {
                    print("🧩 Attempting to parse as standard Ollama JSON response")
                    let response = try JSONDecoder().decode(OllamaAPI.Response.self, from: chunkData)
                    
                    // Successfully parsed as standard Ollama response
                    print("✅ Successfully parsed standard Ollama JSON format")
                    print("📄 Response content: \(response.response.prefix(30))...")
                    self.writeToLogFile("STANDARD OLLAMA FORMAT: \(response.response)")
                    
                    // Extract the actual content from the response
                    let cleanedResponse = self.extractContentFromResponse(response.response)
                    subject.send(cleanedResponse)
                    validResponseCount += 1
                    aggregatedContent += cleanedResponse
                    
                    // Track cumulative response size for stall detection
                    cumulativeResponseSize += cleanedResponse.count
                    lastSentContent = aggregatedContent
                    
                    // Check if this is the final response
                    if response.done {
                        print("🏁 Stream completed normally with done=true")
                    }
                    continue // Successfully handled this chunk, move to the next
                } catch {
                    print("⚠️ Not a standard Ollama JSON format: \(error.localizedDescription)")
                }
                
                // ENHANCED: Third handling approach - DeepSeek specialized extraction
                if isDeepSeekResponse || chunk.contains("message") || chunk.contains("content") {
                    print("🧩 Attempting DeepSeek-specific JSON extraction")
                    
                    // First try parsing with JSONSerialization for maximum flexibility
                    do {
                        if let json = try JSONSerialization.jsonObject(with: chunkData, options: []) as? [String: Any] {
                            print("✅ Successfully parsed as generic JSON")
                            
                            // DeepSeek format has message.content structure
                            if let message = json["message"] as? [String: Any],
                               let content = message["content"] as? String {
                                print("📄 Extracted DeepSeek message content: \(content.prefix(30))...")
                                self.writeToLogFile("DEEPSEEK JSON CONTENT: \(content)")
                                subject.send(content)
                                validResponseCount += 1
                                aggregatedContent += content
                                
                                // Track cumulative response size for stall detection
                                cumulativeResponseSize += content.count 
                                lastSentContent = aggregatedContent
                                continue // Successfully handled, move to next chunk
                            }
                            
                            // Standard Ollama format has response field
                            else if let responseText = json["response"] as? String {
                                print("📄 Extracted standard response field: \(responseText.prefix(30))...")
                                self.writeToLogFile("RESPONSE FIELD: \(responseText)")
                                let cleanedResponse = self.extractContentFromResponse(responseText)
                                subject.send(cleanedResponse)
                                validResponseCount += 1
                                aggregatedContent += cleanedResponse
                                continue // Successfully handled, move to next chunk
                            }
                        }
                    } catch {
                        print("⚠️ JSON parsing failed: \(error.localizedDescription)")
                    }
                    
                    // Specialized DeepSeek content extraction as last approach for this chunk
                    print("🧩 Trying specialized DeepSeek content extraction")
                    let extractedDeepSeek = self.extractDeepSeekContent(chunk)
                    if extractedDeepSeek != chunk && !extractedDeepSeek.isEmpty {
                        print("✅ DeepSeek extraction successful: \(extractedDeepSeek.prefix(30))...")
                        self.writeToLogFile("DEEPSEEK EXTRACTED: \(extractedDeepSeek)")
                        subject.send(extractedDeepSeek)
                        validResponseCount += 1
                        aggregatedContent += extractedDeepSeek
                        continue // Successfully handled, move to next chunk
                    }
                }
                
                // ENHANCED: Fourth handling approach - Last resort regex extraction
                print("🧩 Attempting last-resort regex extraction")
                
                // Try content field extraction
                if chunk.contains("content") {
                    if let regex = try? NSRegularExpression(pattern: #"\"content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#, options: []) {
                        let range = NSRange(location: 0, length: chunk.utf16.count)
                        if let match = regex.firstMatch(in: chunk, options: [], range: range),
                           match.numberOfRanges > 1,
                           let contentRange = Range(match.range(at: 1), in: chunk) {
                            
                            let extracted = String(chunk[contentRange])
                                .replacingOccurrences(of: "\\\"", with: "\"")
                                .replacingOccurrences(of: "\\n", with: "\n")
                            
                            print("✅ Regex extraction succeeded: \(extracted.prefix(30))...")
                            self.writeToLogFile("REGEX EXTRACTED: \(extracted)")
                            subject.send(extracted)
                            validResponseCount += 1
                            aggregatedContent += extracted
                            continue // Successfully handled, move to next chunk
                        }
                    }
                }
                
                // Try response field extraction
                if chunk.contains("response") {
                    if let regex = try? NSRegularExpression(pattern: #"\"response"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#, options: []) {
                        let range = NSRange(location: 0, length: chunk.utf16.count)
                        if let match = regex.firstMatch(in: chunk, options: [], range: range),
                           match.numberOfRanges > 1,
                           let responseRange = Range(match.range(at: 1), in: chunk) {
                            
                            let extracted = String(chunk[responseRange])
                                .replacingOccurrences(of: "\\\"", with: "\"")
                                .replacingOccurrences(of: "\\n", with: "\n")
                            
                            print("✅ Regex response extraction succeeded: \(extracted.prefix(30))...")
                            self.writeToLogFile("RESPONSE REGEX EXTRACTED: \(extracted)")
                            subject.send(extracted)
                            validResponseCount += 1
                            aggregatedContent += extracted
                            continue // Successfully handled, move to next chunk
                        }
                    }
                }
                
                // ENHANCED: Super last resort - Brutal JSON cleaning
                print("🧯 Final attempt: Using brute force JSON artifact removal")
                let cleanedChunk = self.removeJsonArtifacts(chunk)
                if cleanedChunk.count > 10 && cleanedChunk != chunk {
                    print("✅ Brute force extraction yielded: \(cleanedChunk.prefix(30))...")
                    self.writeToLogFile("BRUTE FORCED: \(cleanedChunk)")
                    subject.send(cleanedChunk)
                    validResponseCount += 1
                    aggregatedContent += cleanedChunk
                    continue
                }
                
                // If we got here, we failed to extract anything useful from this chunk
                print("❌ Failed to extract any useful content from chunk")
            }
            
            // ENHANCED: Better completion handling with more detailed fallbacks
            if validResponseCount > 0 {
                // Normal completion - we processed at least one valid response
                print("🏁 Stream processing completed successfully with \(validResponseCount) valid responses")
                subject.send(completion: .finished)
            } else if isDeepSeekResponse {
                // SUBSTANTIALLY IMPROVED: DeepSeek recovery mechanism
                print("🚨 DeepSeek RECOVERY: No processed responses, using whole-text extraction")
                self.writeToLogFile("DEEPSEEK RECOVERY ATTEMPT")
                
                // Try all available extraction methods in sequence
                
                // 1. First attempt - Try extractDeeSeekContent method which combines multiple strategies
                let extractedContent = self.extractDeepSeekContent(text)
                if extractedContent != text && !extractedContent.isEmpty {
                    print("✅ Primary DeepSeek extraction succeeded: \(extractedContent.prefix(50))...")
                    self.writeToLogFile("DEEPSEEK RECOVERY SUCCESS: \(extractedContent)")
                    subject.send(extractedContent)
                    
                    // Track this content in case we need emergency recovery later
                    cumulativeResponseSize += extractedContent.count
                    lastSentContent = extractedContent
                    
                    subject.send(completion: .finished)
                    return
                }
                
                // 2. Second attempt - Check if the response has a JSON-like structure but is malformed
                if text.contains("\"content\":\"") {
                    print("🔍 Searching for content field in malformed JSON")
                    // Extract content between content:" and the next quote
                    if let startRange = text.range(of: "\"content\":\"") {
                        let contentStart = startRange.upperBound
                        let remainingText = text[contentStart...]
                        
                        // Find the end of the content - look for next quote that's not escaped
                        var contentEndIdx = contentStart
                        var insideEscape = false
                        var foundEnd = false
                        
                        for (idx, char) in remainingText.enumerated() {
                            let currentIdx = text.index(contentStart, offsetBy: idx)
                            
                            if char == "\\", !insideEscape {
                                insideEscape = true
                            } else if char == "\"" {
                                if !insideEscape {
                                    // Found unescaped quote - this is the end
                                    contentEndIdx = currentIdx
                                    foundEnd = true
                                    break
                                }
                                insideEscape = false
                            } else {
                                insideEscape = false
                            }
                        }
                        
                        if foundEnd {
                            let extractedContent = String(text[contentStart..<contentEndIdx])
                                .replacingOccurrences(of: "\\\"", with: "\"")
                                .replacingOccurrences(of: "\\n", with: "\n")
                            
                            if !extractedContent.isEmpty {
                                print("✅ Manual content extraction succeeded: \(extractedContent.prefix(50))...")
                                self.writeToLogFile("MANUAL CONTENT EXTRACTION: \(extractedContent)")
                                subject.send(extractedContent)
                                subject.send(completion: .finished)
                                return
                            }
                        }
                    }
                }
                
                // 3. Ultra-aggressive pattern matching for DeepSeek format
                print("🧯 Ultra-aggressive DeepSeek pattern matching")
                if let pattern = try? NSRegularExpression(pattern: #"content"?\s*:?\s*"?([^}\\"]{10,})"?"#, options: []) {
                    let range = NSRange(location: 0, length: text.utf16.count)
                    if let match = pattern.firstMatch(in: text, options: [], range: range),
                       match.numberOfRanges > 1,
                       let contentRange = Range(match.range(at: 1), in: text) {
                        
                        let extracted = String(text[contentRange])
                            .replacingOccurrences(of: "\\n", with: "\n")
                            .replacingOccurrences(of: "\\\"", with: "\"")
                        
                        if !extracted.isEmpty && extracted.count > 10 {
                            print("✅ Ultra-pattern matching succeeded: \(extracted.prefix(50))...")
                            self.writeToLogFile("ULTRA PATTERN MATCH: \(extracted)")
                            subject.send(extracted)
                            subject.send(completion: .finished)
                            return
                        }
                    }
                }
                
                // 4. Last resort - direct artifact removal
                print("☢️ Last resort: Direct JSON artifact removal")
                let cleanedText = self.removeJsonArtifacts(text)
                if cleanedText.count > 20 && !cleanedText.contains("error") {
                    print("✅ Direct artifact removal yielded: \(cleanedText.prefix(50))...")
                    self.writeToLogFile("DIRECT ARTIFACT REMOVAL: \(cleanedText)")
                    subject.send(cleanedText)
                    subject.send(completion: .finished)
                    return
                }
                
                // 5. Complete failure - nothing worked
                print("❌ All DeepSeek recovery methods failed")
                self.writeToLogFile("ALL RECOVERY METHODS FAILED")
                subject.send(completion: .failure(LLMServiceError.unknownError("Could not parse DeepSeek response")))
            } else if text.contains("error") {
                // There's an error message somewhere in the response
                // Try to extract a meaningful error message
                let errorMessage = "Server error: " + (text.components(separatedBy: "error").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error")
                print("❌ Extracted error message: \(errorMessage)")
                self.writeToLogFile("ERROR MESSAGE: \(errorMessage)")
                subject.send(completion: .failure(LLMServiceError.serverError(errorMessage)))
            } else {
                // No valid responses were found, and it's not a DeepSeek model
                // This is unexpected - let's send a meaningful error
                print("❌ No valid JSON responses found in data")
                self.writeToLogFile("ERROR: No valid responses found")
                subject.send(completion: .failure(LLMServiceError.unknownError("Invalid response format")))
            }
        }
        
        // Start the task
        task.resume()
        
        // Store the task in a cancellable that will cancel the task when cancelled
        let cancellable = AnyCancellable {
            task.cancel()
        }
        
        // Store as the active request and in the set
        activeRequestCancellable = cancellable
        cancellables.insert(cancellable)
        
        // Create a publisher that will automatically remove the cancellable when completed
        return subject
            .handleEvents(receiveCompletion: { [weak self] _ in
                // Clean up the cancellable when the publisher completes
                if let activeCancellable = self?.activeRequestCancellable {
                    self?.cancellables.remove(activeCancellable)
                    self?.activeRequestCancellable = nil
                }
            })
            .eraseToAnyPublisher()
    }
    
    // A simplified non-streaming request to get the full response at once
    private func simpleRequest(request: URLRequest) -> AnyPublisher<String, Error> {
        let subject = PassthroughSubject<String, Error>()
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(LLMServiceError.networkError("Invalid response")))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error response
                if let data = data, 
                   let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = errorJson["error"] as? String {
                    subject.send(completion: .failure(LLMServiceError.serverError(errorMessage)))
                } else {
                    subject.send(completion: .failure(LLMServiceError.serverError("HTTP error \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                subject.send(completion: .failure(LLMServiceError.unknownError("No data received")))
                return
            }
            
            // For debugging
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF8")")
            
            // Try to decode as a single response first
            if let json = try? JSONDecoder().decode(OllamaAPI.Response.self, from: data) {
                let cleanedResponse = self.extractContentFromResponse(json.response)
                subject.send(cleanedResponse)
                subject.send(completion: .finished)
                return
            }
            
            // Try to decode as DeepSeek format
            if let text = String(data: data, encoding: .utf8),
               text.contains("\"message\"") && text.contains("\"content\"") {
                // Try to extract content from DeepSeek format
                let cleanedContent = self.extractContentFromResponse(text)
                if cleanedContent != text {
                    subject.send(cleanedContent)
                    subject.send(completion: .finished)
                    return
                }
            }
            
            // If not a single response, try to parse as a newline-delimited JSON stream
            if let text = String(data: data, encoding: .utf8) {
                let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                var fullResponse = ""
                var foundValidJson = false
                
                for line in lines {
                    if let lineData = line.data(using: .utf8) {
                        if let json = try? JSONDecoder().decode(OllamaAPI.Response.self, from: lineData) {
                            // Clean the response text
                            let cleanedResponse = self.extractContentFromResponse(json.response)
                            fullResponse += cleanedResponse
                            foundValidJson = true
                        } else if let dict = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                                  let message = dict["message"] as? [String: Any],
                                  let content = message["content"] as? String {
                            // Handle DeepSeek format
                            fullResponse += content
                            foundValidJson = true
                        }
                    }
                }
                
                if foundValidJson {
                    subject.send(fullResponse)
                    subject.send(completion: .finished)
                    return
                }
            }
            
            // If all else fails, just return the plain text response
            if let text = String(data: data, encoding: .utf8) {
                subject.send(text)
                subject.send(completion: .finished)
                return
            }
            
            subject.send(completion: .failure(LLMServiceError.unknownError("Failed to parse response")))
        }
        
        // Start the task
        task.resume()
        
        // Store the task in a cancellable that will cancel the task when cancelled
        let cancellable = AnyCancellable {
            task.cancel()
        }
        
        // Store as the active request
        activeRequestCancellable = cancellable
        cancellables.insert(cancellable)
        
        return subject
            .handleEvents(receiveCompletion: { [weak self] _ in
                // Clean up the cancellable when the publisher completes
                if let activeCancellable = self?.activeRequestCancellable {
                    self?.cancellables.remove(activeCancellable)
                    self?.activeRequestCancellable = nil
                }
            })
            .eraseToAnyPublisher()
    }
    
    func checkAvailability() -> AnyPublisher<Bool, Error> {
        // For debugging: print endpoint URL
        let urlString = "\(baseUrl)/tags"
        print("Checking Ollama availability at: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3 // Even shorter timeout for availability check
        
        // Start a timer to force-fail if request is taking too long
        let timerPublisher = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .first()
            .map { _ -> Bool in
                print("Timeout check failed: Force failing after 5 seconds")
                return false
            }
            .setFailureType(to: Error.self)
        
        let requestPublisher = urlSession.dataTaskPublisher(for: request)
            .timeout(.seconds(3), scheduler: RunLoop.main) // Add a timeout constraint
            .tryMap { data, response -> Bool in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Not an HTTP response")
                    throw LLMServiceError.networkError("Invalid response")
                }
                
                let statusCode = httpResponse.statusCode
                print("Status code: \(statusCode)")
                
                if !(200...299).contains(statusCode) {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response text: \(responseString)")
                    }
                    throw LLMServiceError.serverError("HTTP error \(statusCode)")
                }
                
                return true
            }
            .retry(1) // One retry attempt
            .catch { error -> AnyPublisher<Bool, Error> in
                print("Ollama availability check failed: \(error.localizedDescription)")
                return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Return the first publisher that completes
        return Publishers.Merge(requestPublisher, timerPublisher)
            .first() // Only take the first result
            .eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    /// Send a chat request directly with messages
    func sendChatRequest(messages: [Message]) -> AnyPublisher<String, Error> {
        return sendMessage(messages: messages, model: AppState.shared.selectedModel)
    }
    
    // MARK: - Helper Methods
    
    /// Get a list of available models from Ollama
    func fetchAvailableModels() -> AnyPublisher<[OllamaAPI.ModelsResponse.ModelInfo], Error> {
        guard let url = URL(string: "\(baseUrl)/tags") else {
            return Fail(error: LLMServiceError.invalidConfiguration).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMServiceError.networkError("Invalid response")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw LLMServiceError.serverError("HTTP error \(httpResponse.statusCode)")
                }
                
                return data
            }
            .decode(type: OllamaAPI.ModelsResponse.self, decoder: JSONDecoder())
            .map { $0.models }
            .catch { error -> AnyPublisher<[OllamaAPI.ModelsResponse.ModelInfo], Error> in
                print("Failed to fetch Ollama models: \(error.localizedDescription)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Simple helper to create a model name that Ollama expects
    func ollamaModelName(from model: OllamaModel) -> String {
        return model.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
    }
    
    /// Get a custom system prompt optimized for DeepSeek models
    private func getDeepSeekSystemPrompt(originalPrompt: String) -> String {
        // If original prompt is not empty, use it as a base
        let basePrompt = originalPrompt.isEmpty ? 
            "You are a helpful AI assistant." : 
            originalPrompt
        
        // Add special instructions for DeepSeek models to improve output quality and reliability
        let deepSeekPrompt = """
        \(basePrompt)
        
        IMPORTANT INSTRUCTIONS:
        1. NEVER use JSON formatting in your responses - ALWAYS respond with plain text only
        2. Your responses should be clear, helpful and direct
        3. NEVER use curly braces ({}) in your responses unless writing code examples
        4. For code, always wrap code blocks with triple backticks (```)
        5. For stories and creative content, use plain text paragraphs with regular line breaks
        6. Always complete your responses fully - never stop mid-sentence or mid-paragraph
        7. When responding to complex topics, break information into clear sections
        8. Use complete sentences with proper grammar and punctuation
        
        CRITICAL: Complete all responses properly, providing a coherent and finished answer.
        """
        
        print("🔄 Using optimized system prompt for DeepSeek model")
        return deepSeekPrompt
    }
    
    // Removed cleanResponseText method to simplify debugging
    // All responses will be returned unmodified so we can see raw content
    
    // Extract response text from JSON using regex as a last resort
    private func extractResponseFromJSON(_ jsonString: String) -> String {
        // Look for "response":"text" pattern
        let pattern = #""response"\s*:\s*"([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return ""
        }
        
        let range = NSRange(location: 0, length: jsonString.utf16.count)
        guard let match = regex.firstMatch(in: jsonString, options: [], range: range),
              match.numberOfRanges > 1 else {
            return ""
        }
        
        let matchRange = match.range(at: 1)
        guard let stringRange = Range(matchRange, in: jsonString) else {
            return ""
        }
        
        return String(jsonString[stringRange])
    }
    
    // Process response content to extract actual text from potential JSON
    private func extractContentFromResponse(_ responseText: String) -> String {
        // Check if we're dealing with a DeepSeek model response
        let isDeepSeekResponse = responseText.contains("\"model\":\"deepseek") || 
                                responseText.contains("-r1:") ||
                                (responseText.hasPrefix("{") && responseText.contains("\"message\""))
        
        if isDeepSeekResponse {
            print("Handling DeepSeek format response")
            // Special handling for DeepSeek format
            return extractDeepSeekContent(responseText)
        }
        
        // First check if the response contains a proper JSON structure
        if responseText.hasPrefix("{") && responseText.hasSuffix("}") {
            // Try to extract just the message.content from DeepSeek JSON format
            // Check for DeepSeek format: {"model":"...", "message":{"role":"...", "content":"..."}, "done":...}
            if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"]*)""#, options: []) {
                let range = NSRange(location: 0, length: responseText.utf16.count)
                if let match = regex.firstMatch(in: responseText, options: [], range: range),
                   match.numberOfRanges > 1,
                   let contentRange = Range(match.range(at: 1), in: responseText) {
                    return String(responseText[contentRange])
                }
            }
            
            // Try extracting the 'response' field directly
            if let regex = try? NSRegularExpression(pattern: #""response"\s*:\s*"([^"]*)""#, options: []) {
                let range = NSRange(location: 0, length: responseText.utf16.count)
                if let match = regex.firstMatch(in: responseText, options: [], range: range),
                   match.numberOfRanges > 1,
                   let contentRange = Range(match.range(at: 1), in: responseText) {
                    return String(responseText[contentRange])
                }
            }
        }
        
        // If no JSON pattern matched, return the text as-is
        return responseText
    }
    
    // COMPLETELY REWRITTEN: Enhanced extraction for DeepSeek model responses
    private func extractDeepSeekContent(_ responseText: String) -> String {
        // Enhanced debug logging to track response processing
        let timestamp = Date().timeIntervalSince1970
        print("📝 DEBUG [\(timestamp)]: Processing DeepSeek response (\(responseText.count) chars): \(responseText.prefix(50))...")
        self.writeToLogFile("===== DEEPSEEK RESPONSE PROCESSING =====")
        self.writeToLogFile("TIMESTAMP: \(timestamp)")
        self.writeToLogFile("RESPONSE SIZE: \(responseText.count) bytes")
        self.writeToLogFile("CONTAINS JSON MARKERS: \(responseText.contains("{") && responseText.contains("}") ? "YES" : "NO")")
        self.writeToLogFile("FULL DEEPSEEK RESPONSE: \(responseText)")
        
        // STAGE 1: Direct plain text check - simplest and most reliable case
        if !responseText.hasPrefix("{") && !responseText.contains("{\"model\":") && 
           !responseText.contains("\"message\":") && !responseText.contains("\"role\":") {
            print("✅ DeepSeek response is plain text, using directly")
            self.writeToLogFile("EXTRACTION SUCCESS: Plain text detected, no processing needed")
            self.writeToLogFile("TEXT SIZE: \(responseText.count) bytes")
            self.writeToLogFile("===== END DEEPSEEK PROCESSING (SUCCESS: PLAIN TEXT) =====")
            return responseText
        }
        
        // STAGE 2: Robust JSON parsing for well-formed responses
        if responseText.contains("\"message\":") && responseText.contains("\"content\":") {
            print("🔍 Attempting direct JSON parsing for DeepSeek response")
            if let data = responseText.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("✅ Successfully extracted via standard JSON parsing")
                        let unescaped = content.replacingOccurrences(of: "\\\"", with: "\"")
                                         .replacingOccurrences(of: "\\n", with: "\n")
                                         .replacingOccurrences(of: "\\t", with: "\t")
                        self.writeToLogFile("EXTRACTION SUCCESS: Standard JSON parsing succeeded")
                        self.writeToLogFile("EXTRACTED CONTENT SIZE: \(unescaped.count) bytes")
                        self.writeToLogFile("EXTRACTION METHOD: JSON parser")
                        self.writeToLogFile("===== END DEEPSEEK PROCESSING (SUCCESS: JSON PARSING) =====")
                        return unescaped
                    }
                } catch {
                    print("📝 Standard JSON parsing failed: \(error.localizedDescription)")
                }
            }
        }
        
        // STAGE 3: Multi-pattern regex extraction - try several patterns in order of specificity
        print("🔍 Attempting regex-based extraction")
        let patterns = [
            // Pattern 1: Standard DeepSeek message content format
            #""message"\s*:\s*\{[^{]*?"content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#,
            
            // Pattern 2: Direct content field
            #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#,
            
            // Pattern 3: Simplified content field (more permissive)
            #"content\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#,
            
            // Pattern 4: Ultra permissive pattern for badly formatted responses
            #"content"?\s*:?\s*"?([^}\\"]{10,})"?"#
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("🔍 Trying regex pattern #\(index+1)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: responseText.utf16.count)
                let matches = regex.matches(in: responseText, options: [], range: range)
                
                if !matches.isEmpty {
                    print("✅ Found \(matches.count) matches with pattern #\(index+1)")
                    
                    // If multiple matches, concatenate them all
                    var extractedContent = ""
                    for match in matches {
                        if match.numberOfRanges > 1,
                           let contentRange = Range(match.range(at: 1), in: responseText) {
                            let content = String(responseText[contentRange])
                            let unescaped = content.replacingOccurrences(of: "\\\"", with: "\"")
                                                 .replacingOccurrences(of: "\\n", with: "\n")
                                                 .replacingOccurrences(of: "\\t", with: "\t")
                                                 .replacingOccurrences(of: "\\\\", with: "\\")
                            extractedContent += unescaped
                        }
                    }
                    
                    if !extractedContent.isEmpty {
                        return extractedContent
                    }
                }
            }
        }
        
        // STAGE 4: Chunk-based processing for multi-part responses
        print("🔍 Attempting chunk-based processing")
        
        // First normalize JSON boundaries to make chunking more reliable
        var normalizedText = responseText
            .replacingOccurrences(of: "}{", with: "}\n{")
            .replacingOccurrences(of: "} {", with: "}\n{")
            .replacingOccurrences(of: "}\r\n{", with: "}\n{")
        
        // Try multiple chunking strategies
        var chunks: [String] = []
        
        // Strategy 1: Newline chunking
        chunks = normalizedText.components(separatedBy: "\n").filter { !$0.isEmpty }
        if chunks.count > 1 {
            print("🔍 Found \(chunks.count) newline-delimited chunks")
        } else {
            // Strategy 2: Try to find JSON object patterns
            do {
                let pattern = "\\{[^\\{]*\\\"message\\\"\\s*:\\s*\\{[^\\}]*\\}[^\\}]*\\}"
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let matches = regex.matches(in: responseText, options: [], range: NSRange(location: 0, length: responseText.utf16.count))
                
                if !matches.isEmpty {
                    print("🔍 Found \(matches.count) distinct JSON objects with regex")
                    chunks = matches.compactMap { match -> String? in
                        if let range = Range(match.range, in: responseText) {
                            return String(responseText[range])
                        }
                        return nil
                    }
                }
            } catch {
                print("❌ JSON object regex failed: \(error)")
            }
        }
        
        // Process each chunk and concatenate results
        if !chunks.isEmpty {
            var extractedContent = ""
            for (index, chunk) in chunks.enumerated() {
                print("🔍 Processing chunk \(index+1)/\(chunks.count) (\(chunk.count) chars)")
                
                // Skip empty chunks
                if chunk.isEmpty { continue }
                
                // If chunk is plain text, use directly
                if !chunk.hasPrefix("{") && !chunk.contains("\"model\":") {
                    extractedContent += chunk + (chunk.hasSuffix("\n") ? "" : "\n")
                    continue
                }
                
                // Try parseDeepSeekChunk (a more focused version of extractSingleDeepSeekResponse)
                let parsed = self.parseDeepSeekChunk(chunk)
                if !parsed.isEmpty {
                    extractedContent += parsed + (parsed.hasSuffix("\n") ? "" : "\n")
                }
            }
            
            if !extractedContent.isEmpty {
                print("✅ Successfully extracted content from \(chunks.count) chunks")
                return extractedContent.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // STAGE 5: Incomplete JSON handling - for interrupted streams
        if responseText.contains("\"content\":\"") {
            print("🔍 Attempting to extract from incomplete JSON")
            let contentMarker = "\"content\":\""
            if let startRange = responseText.range(of: contentMarker)?.upperBound {
                // Find the position of the next unescaped quote
                var endPos = startRange
                var escaped = false
                var found = false
                
                for index in responseText[startRange...].indices {
                    let char = responseText[index]
                    
                    if char == "\\" && !escaped {
                        escaped = true
                    } else if char == "\"" && !escaped {
                        // Found an unescaped quote - this is the end
                        endPos = index
                        found = true
                        break
                    } else {
                        escaped = false
                    }
                }
                
                let contentRange = found ? startRange..<endPos : startRange..<responseText.endIndex
                let content = String(responseText[contentRange])
                
                // Unescape any characters
                let unescaped = content.replacingOccurrences(of: "\\\"", with: "\"")
                                      .replacingOccurrences(of: "\\n", with: "\n")
                                      .replacingOccurrences(of: "\\t", with: "\t")
                                      .replacingOccurrences(of: "\\\\", with: "\\")
                
                if !unescaped.isEmpty {
                    print("✅ Successfully extracted from incomplete JSON")
                    return unescaped
                }
            }
        }
                
        // STAGE 6: Last resort - brute force cleanup
        print("🧯 Using brute force JSON artifact removal")
        let cleanedOutput = self.removeJsonArtifacts(responseText)
        
        if cleanedOutput.count > 20 {
            print("✅ Brute force cleanup yielded a result")
            return cleanedOutput
        }
        
        // STAGE 7: Complete failure - return error message
        print("❌ All extraction methods failed")
        self.writeToLogFile("EXTRACTION FAILURE: All methods failed")
        self.writeToLogFile("===== END DEEPSEEK PROCESSING (FAILURE) =====")
        return "[Error: The model sent a response in an unexpected format that couldn't be processed. Please try again with a simpler prompt.]"
    }
    
    // New helper function for efficient chunk processing
    private func parseDeepSeekChunk(_ chunk: String) -> String {
        // Fast path for direct text
        if !chunk.contains("{") && !chunk.contains("}") {
            return chunk
        }
        
        // Try JSON parsing first (most efficient)
        if let data = chunk.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check for message.content structure
                    if let message = json["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        return content
                    }
                    
                    // Check for direct content field
                    if let content = json["content"] as? String {
                        return content
                    }
                    
                    // Check for response field
                    if let response = json["response"] as? String {
                        return response
                    }
                }
            } catch {}
        }
        
        // Try regex extraction if JSON parsing fails
        if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#, options: []) {
            let range = NSRange(location: 0, length: chunk.utf16.count)
            if let match = regex.firstMatch(in: chunk, options: [], range: range),
               match.numberOfRanges > 1,
               let contentRange = Range(match.range(at: 1), in: chunk) {
                let content = String(chunk[contentRange])
                return content.replacingOccurrences(of: "\\\"", with: "\"")
                              .replacingOccurrences(of: "\\n", with: "\n")
            }
        }
        
        // Basic check for incomplete content field
        if chunk.contains("\"content\":\"") && !chunk.hasSuffix("}") {
            let contentPrefix = "\"content\":\""
            if let contentStart = chunk.range(of: contentPrefix)?.upperBound {
                return String(chunk[contentStart...])
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\n", with: "\n")
            }
        }
        
        // Ultra fallback for chunks with recognizable parts but not valid JSON
        if chunk.contains("content") || chunk.contains("message") {
            return self.removeJsonArtifacts(chunk)
        }
        
        return ""
    }
    
    // Helper to remove JSON artifacts from text
    private func removeJsonArtifacts(_ text: String) -> String {
        // Debug output
        print("🧹 Cleaning JSON artifacts from text (\(text.count) chars)")
        
        // Skip processing for plain text
        if !text.contains("{") && !text.contains("}") {
            return text
        }
        
        var cleaned = text
        
        // APPROACH 1: First try to extract content with precise patterns
        let precisePatterns = [
            // DeepSeek message.content pattern with balanced braces
            #"\{\s*"model"\s*:\s*"[^"]*"\s*,\s*"message"\s*:\s*\{\s*"role"\s*:\s*"[^"]*"\s*,\s*"content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*\}[^}]*\}"#,
            
            // Simpler content pattern for nested objects
            #""\s*content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*}"#,
            
            // Direct content field extraction
            #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#
        ]
        
        for pattern in precisePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
               match.numberOfRanges > 1,
               let contentRange = Range(match.range(at: 1), in: cleaned) {
                
                // Found a direct content match
                let extractedContent = String(cleaned[contentRange])
                
                // Unescape special characters
                let unescaped = extractedContent.replacingOccurrences(of: "\\\"", with: "\"")
                                               .replacingOccurrences(of: "\\n", with: "\n")
                                               .replacingOccurrences(of: "\\t", with: "\t")
                                               .replacingOccurrences(of: "\\\\", with: "\\")
                
                print("✅ Precise pattern extraction successful")
                return unescaped
            }
        }
        
        // APPROACH 2: Try multiple extraction passes to handle complex JSON
        print("🧪 Using multi-pass JSON cleaning approach")
        
        // First pass: Remove the most common JSON structural elements
        let structuralPatterns = [
            // Complex object patterns
            #"\{\s*"model"\s*:\s*"[^"]*"[^{]*\{[^}]*\}[^}]*\}"#,
            #"\{\s*"message"\s*:\s*\{[^}]*\}[^}]*\}"#,
            
            // Wrapper patterns
            #"\{\s*"message"\s*:"#,
            #""role"\s*:\s*"assistant""#,
            #""model"\s*:\s*"[^"]*""#,
            #""done"\s*:\s*(true|false)"#,
            
            // Remove all JSON brackets
            #"\{|\}"#
        ]
        
        for pattern in structuralPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: " ")
            }
        }
        
        // Second pass: Extract content after removing structure
        if cleaned.contains("content") {
            if let regex = try? NSRegularExpression(pattern: #""content"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"#, options: []),
               let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
               match.numberOfRanges > 1,
               let contentRange = Range(match.range(at: 1), in: cleaned) {
                
                let extractedContent = String(cleaned[contentRange])
                
                // Unescape special characters
                let unescaped = extractedContent.replacingOccurrences(of: "\\\"", with: "\"")
                                               .replacingOccurrences(of: "\\n", with: "\n")
                                               .replacingOccurrences(of: "\\t", with: "\t")
                                               .replacingOccurrences(of: "\\\\", with: "\\")
                
                print("✅ Second-pass extraction successful")
                return unescaped
            }
        }
        
        // Third pass: Ultra aggressive cleaning - remove all JSON syntax
        print("🧰 Using aggressive JSON syntax removal")
        
        // Remove quotes, field names, and other JSON syntax elements
        cleaned = cleaned.replacingOccurrences(of: "\"content\":\"", with: "")
                        .replacingOccurrences(of: "\"role\":\"", with: "")
                        .replacingOccurrences(of: "\"model\":\"", with: "")
                        .replacingOccurrences(of: "\"done\":", with: "")
                        .replacingOccurrences(of: "\"message\":", with: "")
                        .replacingOccurrences(of: "assistant", with: "")
                        .replacingOccurrences(of: "deepseek", with: "")
                        .replacingOccurrences(of: "true", with: "")
                        .replacingOccurrences(of: "false", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                        .replacingOccurrences(of: ",", with: " ")
        
        // Clean up spacing and trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }
        
        // Only return if we have substantial content
        if cleaned.count > 15 {
            print("✅ Aggressive cleaning yielded: \(cleaned.prefix(30))...")
            return cleaned
        }
        
        print("❌ All cleaning approaches failed")
        return "[Error: Response contained only JSON structure that couldn't be parsed]"
    }
    
    // Cancel any current request
    func cancelRequest() {
        // Only cancel the active request, not all cancellables
        if let activeCancellable = activeRequestCancellable {
            activeCancellable.cancel()
            cancellables.remove(activeCancellable)
            activeRequestCancellable = nil
        }
    }
}
