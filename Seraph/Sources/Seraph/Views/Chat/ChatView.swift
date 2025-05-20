import SwiftUI
import Combine

/// A view that displays a conversation between the user and AI,
/// allowing the user to send messages and view responses.
public struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var conversation: Conversation
    private let llmService: LLMServiceProtocol
    
    @State private var messageText = ""
    @State private var isProcessing = false
    @State private var scrollTarget: UUID?
    @State private var systemPrompt = ""
    @State private var showSettings = false
    @State private var selectedModel: AIModel = .llama3
    
    // MARK: - Initialization
    
    public init(conversation: Conversation, llmService: LLMServiceProtocol = LLMService.shared) {
        self.conversation = conversation
        self.llmService = llmService
        self._systemPrompt = State(initialValue: conversation.systemPrompt)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            messagesView
            bottomBar
        }
        .navigationTitle(conversation.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit System Prompt") {
                        showSettings = true
                    }
                    Divider()
                    Button(role: .destructive) {
                        // Delete conversation
                        appState.deleteConversation(withId: conversation.id)
                    } label: {
                        Label("Delete Conversation", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            // Simple settings sheet
            Form {
                Section(header: Text("System Prompt")) {
                    TextEditor(text: $systemPrompt)
                        .frame(height: 100)
                }
                
                Section(header: Text("Model")) {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(AIModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                }
            }
            .padding()
            .frame(width: 400, height: 300)
        }
    }
    
    // MARK: - Views
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Date header
                Text(conversation.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                // Messages
                ForEach(conversation.messages) { message in
                    messageView(for: message)
                        .id(message.id)
                }
            }
            .padding()
        }
    }
    
    private var bottomBar: some View {
        HStack {
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .disabled(isProcessing)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
        .padding()
    }
    
    private func messageView(for message: Message) -> some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.isFromUser ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(message.isFromUser ? .white : .primary)
                .cornerRadius(12)
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Create and add the user message
        let text = messageText
        let userMessage = Message(
            content: text,
            timestamp: Date(),
            isFromUser: true
        )
        conversation.addMessage(userMessage)
        messageText = ""
        
        // Process with AI
        isProcessing = true
        
        var localCancellables = Set<AnyCancellable>()
        
        // Create local references to avoid captures
        let localConversation = conversation
        let localScrollTargetBinding = $scrollTarget
        
        // Send to LLM service
        llmService.generateResponse(
            message: text,
            model: selectedModel,
            systemPrompt: systemPrompt,
            history: localConversation.messages
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                // Update on the main thread
                DispatchQueue.main.async {
                    isProcessing = false
                    
                    if case let .failure(error) = completion {
                        // Add error message
                        let errorMessage = Message(
                            content: "Sorry, an error occurred: \(error.localizedDescription)",
                            timestamp: Date(),
                            isFromUser: false
                        )
                        localConversation.addMessage(errorMessage)
                    }
                }
            },
            receiveValue: { response in
                // Process on the main thread
                DispatchQueue.main.async {
                    // Add AI response message
                    let responseMessage = Message(
                        content: response,
                        timestamp: Date(),
                        isFromUser: false
                    )
                    localConversation.addMessage(responseMessage)
                    
                    // Update scroll position
                    localScrollTargetBinding.wrappedValue = responseMessage.id
                }
            }
        )
        .store(in: &localCancellables)
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Previews
#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let conversation = Conversation(
            title: "Preview Conversation",
            lastMessage: "Hello, how can I help you today?",
            timestamp: Date(),
            unreadCount: 0,
            projectId: nil,
            systemPrompt: "You are a helpful AI assistant.",
            messages: [
                Message(content: "Hello, how can I help you today?", timestamp: Date(), isFromUser: false)
            ]
        )
        
        return ChatView(conversation: conversation)
            .environmentObject(AppState.preview)
    }
}
#endif