import Foundation
import Combine

/// ViewModel responsible for handling chat-related business logic
@MainActor
public final class ChatViewModel: ObservableObject {
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    private let conversation: Conversation
    private let llmService: LLMServiceProtocol
    
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
    var defaultModelId: String = AIModel.llama3.id
    var maxTokens: Int = 2048
    var temperature: Double = 0.7
    var topP: Double = 0.9
    var presencePenalty: Double = 0.0
    var frequencyPenalty: Double = 0.0
    
    var defaultModel: AIModel {
        AIModel.allModels.first(where: { $0.id == defaultModelId }) ?? .llama3
    }
    
    func generateResponse(
        message: String,
        model: AIModel,
        systemPrompt: String,
        history: [Message]
    ) -> AnyPublisher<String, Error> {
        return Just("This is a sample response from the AI.")
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func isModelAvailable(_ model: AIModel) -> Bool {
        return true
    }
    
    func availableModels() -> [AIModel] {
        return AIModel.allCases
    }
    
    func cancelAllRequests() {
        // No-op for preview
    }
    
    func validateAPIKey(_ apiKey: String) -> Bool {
        return !apiKey.isEmpty
    }
    
    func streamMessage(
        _ message: String,
        model: AIModel,
        systemPrompt: String,
        temperature: Double
    ) -> AnyPublisher<String, Error> {
        let responses = [
            "This is a sample streaming response ",
            "from the AI. It's being streamed ",
            "back to you in chunks."
        ]
        
        return Publishers.Sequence(sequence: responses)
            .flatMap { response in
                Just(response)
                    .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
                    .setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    func generateResponse(
        prompt: String,
        model: String,
        conversationHistory: [Message],
        completion: @escaping CompletionHandler
    ) {
        let aiModel = AIModel.allModels.first { $0.id == model } ?? defaultModel
        generateResponse(
            message: prompt,
            model: aiModel,
            systemPrompt: "",
            history: conversationHistory
        )
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
}
#endif
