import SwiftUI
import Combine
import Foundation
import AppKit

// Import Seraph models and protocols
@_exported import struct Seraph.Message
@_exported import class Seraph.Conversation
@_exported import class Seraph.AppState
@_exported import class Seraph.LLMService
@_exported import struct Seraph.AIModel
@_exported import protocol Seraph.LLMServiceProtocol
@_exported import protocol Seraph.ConversationProtocol

// MARK: - Type Aliases

/// Alias for Message from the Seraph module
typealias Message = Seraph.Message

/// Alias for Conversation from the Seraph module
typealias Conversation = Seraph.Conversation

/// Alias for AppState from the Seraph module
typealias AppState = Seraph.AppState

/// Alias for LLMService from the Seraph module
typealias LLMService = Seraph.LLMService

/// Alias for AIModel from the Seraph module
typealias AIModel = Seraph.AIModel

// MARK: - Message Status

public extension Message {
    enum Status: String, Codable {
        case sending
        case sent
        case delivered
        case read
        case failed
    }
}

// MARK: - Message View

struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                HStack(alignment: .top) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.gray)
                    Text(message.content)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .opacity(message.status == .sending ? 0.5 : 1.0)
                    if message.status == .sending {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    var body: some View {
        HStack {
            Text("AI is typing...")
                .foregroundColor(.secondary)
                .font(.caption)
            ProgressView()
                .scaleEffect(0.5)
        }
        .padding()
    }
}

// MARK: - Color Extensions

extension Color {
    static let textBackgroundColor = Color(NSColor.textBackgroundColor)
    static let windowBackgroundColor = Color(NSColor.windowBackgroundColor)
}

// MARK: - Chat View

/// A view that displays and manages a chat conversation
public struct ChatView: View {
    // MARK: - Environment
    
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Properties
    
    @ObservedObject var conversation: Conversation
    @State private var messageText: String = ""
    @State private var selectedModelId: String = ""
    @State private var availableModels: [AIModel] = []
    @State private var systemPrompt: String = "You are a helpful AI assistant."
    @State private var isProcessing: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    private let llmService: LLMServiceProtocol
    
    // MARK: - Initialization
    
    /// Initialize a new ChatView
    /// - Parameters:
    ///   - conversation: The conversation to display and manage
    ///   - llmService: The LLM service to use for generating responses
    public init(conversation: Conversation, llmService: LLMServiceProtocol = LLMService.shared) {
        self.conversation = conversation
        self.llmService = llmService
        
        // Initialize selected model if available
        if let firstModel = AIModel.availableModels.first {
            _selectedModelId = State(initialValue: firstModel.id)
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Model selector
            modelSelector
            
            // Messages list
            messagesView
            
            // Input area
            bottomBar
        }
        .navigationTitle(conversation.title)
        .onAppear(perform: setupView)
    }
    
    // MARK: - View Components
    
    private var modelSelector: some View {
        Picker("Model", selection: $selectedModelId) {
            ForEach(availableModels) { model in
                Text(model.name).tag(model.id)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(conversation.messages) { message in
                    MessageView(message: message)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .id(message.id)
                }
                
                if isProcessing {
                    TypingIndicatorView()
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
            .onChange(of: conversation.messages) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private var bottomBar: some View {
        HStack {
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .background(Color.textBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onSubmit(sendMessage)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
        .padding()
        .background(Color.windowBackgroundColor)
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        // Initialize available models
        availableModels = AIModel.availableModels
        
        // Select first model by default if none selected
        if selectedModelId.isEmpty && !availableModels.isEmpty {
            selectedModelId = availableModels[0].id
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = conversation.messages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let selectedModel = availableModels.first(where: { $0.id == selectedModelId }) else {
            return
        }
        
        let userMessage = Message(
            id: UUID(),
            content: messageText,
            isFromUser: true,
            timestamp: Date(),
            status: .sent
        )
        
        // Add user message to conversation
        conversation.addMessage(userMessage)
        
        // Clear input field
        messageText = ""
        
        // Show typing indicator
        isProcessing = true
        
        // Generate AI response
        Task {
            do {
                let response = try await llmService.generateResponse(
                    for: userMessage.content,
                    conversation: conversation,
                    model: selectedModel,
                    systemPrompt: systemPrompt
                )
                
                let aiMessage = Message(
                    id: UUID(),
                    content: response,
                    isFromUser: false,
                    timestamp: Date(),
                    status: .sent
                )
                
                // Add AI response to conversation
                await MainActor.run {
                    conversation.addMessage(aiMessage)
                    isProcessing = false
                }
            } catch {
                print("Error generating response: \(error)")
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    }
    
    // MARK: - Settings Sheet
    
    private func showSettingsSheet() -> some View {
        NavigationView {
            Form {
                Section(header: Text("System Prompt")) {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("AI Model")) {
                    Picker("Model", selection: $selectedModelId) {
                        ForEach(availableModels) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSettings = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        conversation.systemPrompt = systemPrompt
                        conversation.modelId = selectedModelId
                        showSettings = false
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(conversation.messages) { message in
                    MessageView(message: message)
                        .id(message.id)
                }
            }
            .listStyle(.plain)
            .onChange(of: conversation.messages) { _ in
                if let lastMessage = conversation.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var bottomBar: some View {
        HStack {
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.textBackgroundColor)
                .cornerRadius(8)
                .onSubmit(processMessage)
                .disabled(isProcessing)
            
            Button(action: processMessage) {
                Image(systemName: "paperplane.fill")
                    .padding(8)
            }
            .buttonStyle(.borderless)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.windowBackgroundColor)
    }
    
    private func processMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        
        // Create user message
        let userMessage = Message(
            id: UUID(),
            content: messageText,
            timestamp: Date(),
            isFromUser: true,
            status: .sent
        )
        
        // Add user message to conversation
        conversation.addMessage(userMessage)
        messageText = ""
        
        // Create assistant message
        let assistantMessage = Message(
            id: UUID(),
            content: "",
            timestamp: Date(),
            isFromUser: false,
            status: .sending
        )
        
        // Add assistant message to conversation
        conversation.addMessage(assistantMessage)
        
        // Get the selected model or use the first available one
        guard let model = availableModels.first(where: { $0.id == selectedModelId }) ?? availableModels.first else {
            updateMessage(assistantMessage.id, with: "Error: No available models", status: .failed)
            isProcessing = false
            return
        }
        
        // Send message to LLM service
        Task {
            do {
                let response = try await llmService.sendMessage(
                    userMessage.content,
                    conversation: conversation,
                    systemPrompt: systemPrompt,
                    model: model
                )
                
                // Update the assistant message with the response
                await MainActor.run {
                    updateMessage(assistantMessage.id, with: response, status: .sent)
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    updateMessage(assistantMessage.id, with: "Error: \(error.localizedDescription)", status: .failed)
                    isProcessing = false
                }
            }
        }
    }
    
    private func updateMessage(_ id: UUID, with content: String, status: MessageStatus) {
        if let index = conversation.messages.firstIndex(where: { $0.id == id }) {
            conversation.messages[index].content = content
            conversation.messages[index].status = status
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let conversation = Conversation()
        conversation.addMessage(Message(
            id: UUID(),
            content: "Hello!",
            timestamp: Date(),
            isFromUser: true,
            status: .sent
        ))
        
        conversation.addMessage(Message(
            id: UUID(),
            content: "Hi there! How can I help you today?",
            timestamp: Date(),
            isFromUser: false,
            status: .sent
        ))
        
        return ChatView(conversation: conversation)
            .environmentObject(AppState.shared)
            .frame(width: 400, height: 600)
    }
}
#endif
