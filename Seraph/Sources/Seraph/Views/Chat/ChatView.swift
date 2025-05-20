import SwiftUI
import Combine
import Foundation
import AppKit

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

// The TypingIndicatorView is now used from Views/Common/TypingIndicatorView.swift

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
    @State private var showSettings: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    private let llmService: LLMServiceProtocol
    
    // MARK: - Initialization
    
    /// Initialize a new ChatView
    /// - Parameters:
    ///   - conversation: The conversation to display and manage
    ///   - llmService: The LLM service to use for generating responses
    public init(conversation: Conversation, llmService: LLMServiceProtocol) {
        self.conversation = conversation
        self.llmService = llmService
        
        // Initialize selected model if available
        if let firstModel = AIModel.allModels.first {
            _selectedModelId = State(initialValue: firstModel.rawValue)
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
        .sheet(isPresented: $showSettings) {
            showSettingsSheet()
        }
    }
    
    // MARK: - View Components
    
    private var modelSelector: some View {
        Picker("Model", selection: $selectedModelId) {
            ForEach(availableModels) { model in
                Text(model.displayName).tag(model.rawValue)
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
                    HStack {
                        Text("AI is typing...")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        TypingIndicatorView()
                    }
                    .padding()
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
        Task { @MainActor in
            // Initialize available models
            availableModels = AIModel.allModels
            
            // Select first model by default if none selected
            if selectedModelId.isEmpty && !availableModels.isEmpty {
                selectedModelId = availableModels[0].rawValue
            }
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
              let selectedModel = availableModels.first(where: { $0.rawValue == selectedModelId }) else {
            return
        }
        
        let userMessage = Message(
            content: messageText,
            timestamp: Date(),
            isFromUser: true,
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
                let response = try await llmService.sendMessage(
                    messageText,
                    conversation: conversation,
                    systemPrompt: systemPrompt,
                    model: selectedModel
                )
                
                let aiMessage = Message(
                    content: response,
                    timestamp: Date(),
                    isFromUser: false,
                    status: .sent
                )
                
                // Add AI response to conversation
                await MainActor.run {
                    conversation.addMessage(aiMessage)
                    isProcessing = false
                }
            } catch {
                print("Error generating response: \(error)")
                isProcessing = false
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
                            Text(model.displayName).tag(model.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSettings = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        conversation.systemPrompt = systemPrompt
                        showSettings = false
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
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
            content: "Hello!",
            timestamp: Date(),
            isFromUser: true,
            status: .sent
        ))
        
        conversation.addMessage(Message(
            content: "Hi there! How can I help you today?",
            timestamp: Date(),
            isFromUser: false,
            status: .sent
        ))
        
        return ChatView(conversation: conversation, llmService: LLMService.shared)
            .environmentObject(AppState.shared)
            .frame(width: 400, height: 600)
    }
}
#endif
