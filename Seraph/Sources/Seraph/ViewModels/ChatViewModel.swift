import Foundation
import Combine

/// ViewModel responsible for handling chat-related business logic
@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Properties
    
    private let conversation: Conversation
    private let llmService: LLMServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(conversation: Conversation, llmService: LLMServiceProtocol = LLMService.shared) {
        self.conversation = conversation
        self.llmService = llmService
    }
    
    // MARK: - Public Methods
    
    /// Generates an AI response for the given message
    /// - Parameters:
    ///   - message: The user's message
    ///   - model: The AI model to use for the response
    ///   - systemPrompt: The system prompt to use for the AI
    ///   - completion: Completion handler with the result of the operation
    func generateResponse(
        for message: String,
        model: AIModel,
        systemPrompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Create a conversation history for context
        let history = conversation.messages
            .suffix(10) // Limit context window
            .map { message in
                Message(
                    id: message.id,
                    content: message.content,
                    timestamp: message.timestamp,
                    isFromUser: message.isFromUser,
                    status: message.status
                )
            }
        
        // Generate the response
        llmService.generateResponse(
            message: message,
            model: model,
            systemPrompt: systemPrompt,
            history: history
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            },
            receiveValue: { response in
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Regenerates the last AI response
    /// - Parameters:
    ///   - model: The AI model to use
    ///   - systemPrompt: The system prompt to use
    ///   - completion: Completion handler with the result of the operation
    func regenerateLastResponse(
        model: AIModel,
        systemPrompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let lastUserMessage = conversation.messages
            .last(where: { $0.isFromUser }) else {
            completion(.failure(ChatError.noUserMessages))
            return
        }
        
        // Remove all messages after the last user message
        let lastUserMessageIndex = conversation.messages.firstIndex { $0.id == lastUserMessage.id } ?? 0
        let messagesToKeep = Array(conversation.messages.prefix(through: lastUserMessageIndex))
        
        // Update conversation messages
        conversation.messages = messagesToKeep
        
        // Generate new response
        generateResponse(
            for: lastUserMessage.content,
            model: model,
            systemPrompt: systemPrompt,
            completion: completion
        )
    }
}

// MARK: - Error Types

extension ChatViewModel {
    enum ChatError: LocalizedError {
        case noUserMessages
        
        var errorDescription: String? {
            switch self {
            case .noUserMessages:
                return "No user messages found in the conversation"
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension ChatViewModel {
    static var preview: ChatViewModel {
        let message = Message(
            id: UUID(),
            content: "Hello, how can I help you today?",
            timestamp: Date(),
            isFromUser: false,
            status: .delivered
        )
        
        let conversation = Conversation(
            id: UUID(),
            title: "Preview Chat",
            lastMessage: message.content,
            timestamp: Date(),
            unreadCount: 0,
            projectId: nil,
            systemPrompt: "You are a helpful AI assistant.",
            messages: [message]
        )
        
        return ChatViewModel(conversation: conversation, llmService: PreviewLLMService())
    }
}

// Dummy LLMService for previews
private class PreviewLLMService: LLMServiceProtocol {
    var baseURL: URL?
    var apiKey: String?
    var defaultModel: AIModel = .llama3
    var maxTokens: Int = 2048
    var temperature: Double = 0.7
    var topP: Double = 0.9
    var presencePenalty: Double = 0.0
    var frequencyPenalty: Double = 0.0
    
    func generateResponse(
        message: String,
        model: AIModel,
        systemPrompt: String,
        history: [Message]
    ) -> AnyPublisher<String, Error> {
        return Just("This is a sample response from the AI.")
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func isModelAvailable(_ model: AIModel) -> Bool { true }
    
    func availableModels() -> [AIModel] { AIModel.allCases }
    
    func cancelAllRequests() {}
    
    func validateAPIKey(_ apiKey: String) -> Bool { true }
    
    func streamMessage(_ message: String, model: String, systemPrompt: String, temperature: Double) -> AnyPublisher<String, Error> {
        Just("Streaming response for: \(message)")
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func generateResponse(
        prompt: String,
        model: String,
        conversationHistory: [Message],
        completion: @escaping CompletionHandler
    ) {
        completion(.success("Response to: \(prompt)"))
    }
}
#endif
