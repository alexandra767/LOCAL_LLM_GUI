import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var attachments: [DocumentAttachment] = []
    @Published var isProcessingAttachment: Bool = false
    @Published var currentChat: Chat?
    
    let llmService: LLMService
    private let documentProcessor: DocumentProcessor
    private var currentStream: AsyncStream<String>?
    
    init(llmService: LLMService = LLMServiceImpl()) {
        self.llmService = llmService
        self.documentProcessor = DocumentProcessor()
        loadChats()
    }
    
    private func loadChats() {
        // Load from database eventually
        // For now, using sample data
        chats = [
            Chat(
                title: "Understanding LLMs",
                messages: [
                    Message(role: .user, content: "What are LLMs?"),
                    Message(role: .assistant, content: "Large Language Models (LLMs) are a type of artificial intelligence model designed to understand and generate human-like text.")
                ]
            ),
            Chat(
                title: "Coding Project",
                messages: [
                    Message(role: .user, content: "Help me with a Swift project")
                ],
                isStarred: true
            ),
            Chat(
                title: "Data Analysis",
                messages: [
                    Message(role: .user, content: "How do I analyze this dataset?")
                ]
            )
        ]
    }
    
    func createNewChat() {
        let newChat = Chat(
            title: "New Chat \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
            messages: []
        )
        chats.insert(newChat, at: 0)
        currentChat = newChat
        saveChats()
    }
    
    func deleteChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats.remove(at: index)
            saveChats()
            
            // If current chat was deleted, select none
            if currentChat?.id == chat.id {
                currentChat = nil
            }
        }
    }
    
    func toggleStarChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            var updatedChat = chat
            updatedChat.isStarred.toggle()
            chats[index] = updatedChat
            
            // Update current chat if needed
            if currentChat?.id == chat.id {
                currentChat = updatedChat
            }
            
            saveChats()
        }
    }
    
    func updateChat(_ chat: Chat, title: String) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            var updatedChat = chat
            updatedChat.title = title
            chats[index] = updatedChat
            
            // Update current chat if needed
            if currentChat?.id == chat.id {
                currentChat = updatedChat
            }
            
            saveChats()
        }
    }
    
    func selectChat(_ chat: Chat) {
        currentChat = chat
        messages = chat.messages
    }
    
    func sendMessage() async {
        guard !inputText.isEmpty else { return }
        
        // Add user message
        let userMessage = Message(role: .user, content: inputText)
        messages.append(userMessage)
        
        // Update current chat
        if let currentChat = currentChat {
            if let index = chats.firstIndex(where: { $0.id == currentChat.id }) {
                var updatedChat = currentChat
                updatedChat.messages.append(userMessage)
                chats[index] = updatedChat
                self.currentChat = updatedChat
            }
        } else {
            // Create a new chat if none is selected
            let newChat = Chat(
                title: inputText.prefix(20) + "...",
                messages: [userMessage]
            )
            chats.insert(newChat, at: 0)
            currentChat = newChat
        }
        
        inputText = ""
        
        // Include attachments in the message
        let attachmentContent = attachments.map { "\n\n--- Attachment: \($0.name) ---\n\n\($0.content)" }.joined()
        let fullMessage = "\(userMessage.content)\(attachmentContent)"
        
        do {
            // Get response stream
            currentStream = try await llmService.streamMessage(fullMessage)
            
            // Create assistant message
            let assistantMessage = Message(
                id: UUID(),
                role: .assistant,
                content: "",
                timestamp: Date(),
                isStreaming: true
            )
            messages.append(assistantMessage)
            
            // Update current chat with initial empty assistant message
            if let currentChat = currentChat, let index = chats.firstIndex(where: { $0.id == currentChat.id }) {
                var updatedChat = currentChat
                updatedChat.messages.append(assistantMessage)
                chats[index] = updatedChat
                self.currentChat = updatedChat
            }

            for try await chunk in currentStream! {
                // Update local messages array
                if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                    messages[index].content += chunk
                }
                
                // Update chat in the chats array
                if let currentChat = currentChat, let chatIndex = chats.firstIndex(where: { $0.id == currentChat.id }) {
                    if let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                        var updatedChat = chats[chatIndex]
                        updatedChat.messages[messageIndex].content += chunk
                        chats[chatIndex] = updatedChat
                        self.currentChat = updatedChat
                    }
                }
            }
            
            // Update streaming state
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages[index].isStreaming = false
            }
            
            // Update chat in the chats array
            if let currentChat = currentChat, let chatIndex = chats.firstIndex(where: { $0.id == currentChat.id }) {
                if let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                    var updatedChat = chats[chatIndex]
                    updatedChat.messages[messageIndex].isStreaming = false
                    chats[chatIndex] = updatedChat
                    self.currentChat = updatedChat
                }
            }
            
            saveChats()
            
        } catch {
            print("Error streaming message: \(error)")
            
            // Create error message if one doesn't exist
            let errorMessage = Message(
                id: UUID(),
                role: .assistant,
                content: "Error: \(error.localizedDescription)",
                timestamp: Date(),
                isStreaming: false
            )
            
            messages.append(errorMessage)
            
            // Update chat in the chats array
            if let currentChat = currentChat, let chatIndex = chats.firstIndex(where: { $0.id == currentChat.id }) {
                var updatedChat = chats[chatIndex]
                updatedChat.messages.append(errorMessage)
                chats[chatIndex] = updatedChat
                self.currentChat = updatedChat
            }
            
            saveChats()
        }
    }
    
    func addAttachment(from url: URL) async {
        isProcessingAttachment = true
        
        do {
            let attachment = try await documentProcessor.processFile(at: url)
            attachments.append(attachment)
        } catch {
            print("Error processing attachment: \(error)")
        }
        
        isProcessingAttachment = false
    }
    
    func removeAttachment(_ attachment: DocumentAttachment) {
        if let index = attachments.firstIndex(where: { $0.id == attachment.id }) {
            attachments.remove(at: index)
        }
    }
    
    func clearChat() {
        messages.removeAll()
        attachments.removeAll()
        
        // Create a new empty chat
        if let currentChat = currentChat, let index = chats.firstIndex(where: { $0.id == currentChat.id }) {
            var updatedChat = currentChat
            updatedChat.messages.removeAll()
            chats[index] = updatedChat
            self.currentChat = updatedChat
            
            saveChats()
        }
    }
    
    private func saveChats() {
        // TODO: Save to database
    }
}