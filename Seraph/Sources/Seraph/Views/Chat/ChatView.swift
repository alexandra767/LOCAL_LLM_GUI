import SwiftUI
import Combine
import struct Seraph.Conversation
import class Seraph.AppState
import struct Seraph.AIModel

#if canImport(UIKit)
import UIKit
#endif

/// A view that displays a chat conversation with the AI.
/// This view handles sending and receiving messages in a conversation.
public struct ChatView: View {
    // MARK: - Properties
    
    @ObservedObject public var conversation: Conversation
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    
    @State private var newMessage: String = ""
    @State private var isSending: Bool = false
    @State private var showModelSelector: Bool = false
    @State private var selectedModel: AIModel = .defaultModel
    @State private var scrollToBottom: Bool = false
    
    // MARK: - Initialization
    
    public init(conversation: Conversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                                .transition(.opacity)
                        }
                        
                        if isSending {
                            TypingIndicatorView()
                                .id("typing")
                                .transition(.opacity)
                        }
                        
                        // Invisible view at the bottom to auto-scroll to
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: conversation.messages) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Model selector button
                Button(action: { showModelSelector = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                        Text(selectedModel.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showModelSelector) {
                    ModelSelectorView(selectedModel: $selectedModel)
                        .frame(width: 200, height: 300)
                }
                
                // Message input field
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .onSubmit(sendMessage)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage || isSending)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                    .ignoresSafeArea()
            )
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: copyConversation) {
                        Label("Copy Conversation", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive, action: deleteConversation) {
                        Label("Delete Conversation", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard canSendMessage, !isSending else { return }
        
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessage = ""
        isSending = true
        
        // Create user message
        let userMessage = Message(
            id: UUID(),
            content: messageText,
            isFromUser: true,
            timestamp: Date(),
            status: .delivered
        )
        
        // Add user message to conversation
        conversation.addMessage(userMessage)
        
        // Generate AI response
        viewModel.generateResponse(
            for: messageText,
            model: selectedModel,
            systemPrompt: conversation.systemPrompt
        ) { result in
            isSending = false
            
            switch result {
            case .success(let response):
                // Create AI message
                let aiMessage = Message(
                    id: UUID(),
                    content: response,
                    isFromUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                
                // Add AI message to conversation
                conversation.addMessage(aiMessage)
                
            case .failure(let error):
                print("Error generating response: \(error.localizedDescription)")
                
                // Show error message
                let errorMessage = Message(
                    id: UUID(),
                    content: "Sorry, I encountered an error: \(error.localizedDescription)",
                    isFromUser: false,
                    timestamp: Date(),
                    status: .error
                )
                
                conversation.addMessage(errorMessage)
            }
        }
    }
    
    private func copyConversation() {
        let conversationText = conversation.messages
            .map { "\($0.isFromUser ? "You" : "AI"): \($0.content)" }
            .joined(separator: "\n\n")
        
        #if os(iOS)
        UIPasteboard.general.string = conversationText
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(conversationText, forType: .string)
        #endif
    }
    
    private func deleteConversation() {
        appState.deleteConversation(withId: conversation.id)
    }
}

// MARK: - Message View

private struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                messageBubble
            } else {
                messageBubble
                Spacer()
            }
        }
        .transition(.opacity)
    }
    
    private var messageBubble: some View {
        Text(message.content)
            .padding(12)
            .background(message.isFromUser ? Color.blue : Color(.systemGray5))
            .foregroundColor(message.isFromUser ? .white : .primary)
            .cornerRadius(16)
            .contextMenu {
                Button(action: copyMessage) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                
                if !message.isFromUser {
                    Button(action: regenerateResponse) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                }
            }
    }
    
    private func copyMessage() {
        #if os(iOS)
        UIPasteboard.general.string = message.content
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        #endif
    }
    
    private func regenerateResponse() {
        // Implement regeneration logic
    }
}

// MARK: - Typing Indicator View

private struct TypingIndicatorView: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .opacity(0.3 + Double(index) * 0.3)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(0.2 * Double(index)), 
                              value: UUID())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Model Selector View

private struct ModelSelectorView: View {
    @Binding var selectedModel: AIModel
    
    var body: some View {
        List(AIModel.allCases, id: \.self) { model in
            Button(action: { selectedModel = model }) {
                HStack {
                    Text(model.displayName)
                    Spacer()
                    if model == selectedModel {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Visual Effect View

private struct VisualEffectView: NSViewRepresentable {
    let effect: NSVisualEffect
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .hudWindow
    }
}

// MARK: - Preview

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let message = Message(
            id: UUID(),
            content: "Hello, how can I help you today?",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        
        let conversation = Conversation(
            id: UUID(),
            title: "Preview Chat",
            lastMessage: "Hello, how can I help you today?",
            unreadCount: 0,
            systemPrompt: "You are a helpful AI assistant.",
            messages: [message]
        )
        
        return NavigationView {
            ChatView(conversation: conversation)
                .environmentObject(AppState.preview)
        }
    }
}
#endif

// Dummy LLMService for previews
#if DEBUG
private class PreviewLLMService: LLMService {
    static let shared = PreviewLLMService()
    
    override func sendMessage(_ message: String, 
                             model: String = "llama3", 
                             systemPrompt: String = "You are a helpful AI assistant.", 
                             temperature: Double = 0.7) -> AnyPublisher<String, Error> {
        return Just("This is a sample response from the AI.")
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
#endif

/// A view that displays a chat conversation with messages and an input field.
public struct ChatView: View {
    @ObservedObject public var conversation: Conversation
    @EnvironmentObject private var appState: AppState
    
    // Dependencies
    private let llmService: any LLMServiceProtocol
    
    @State private var newMessage: String = ""
    @State private var isSending: Bool = false
    @State private var isStreaming: Bool = false
    @State private var streamingMessage: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    // Default model for the chat
    private let defaultModel = "llama3"
    
    private let scrollToId = "bottom"
    
    public init(conversation: any ConversationProtocol, llmService: any LLMServiceProtocol = LLMService.shared) {
        self.conversation = conversation
        self.llmService = llmService
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(conversation.messages, id: \.id) { message in
                            MessageView(message: message)
                                .id(message.id == conversation.messages.last?.id ? scrollToId : message.id)
                                .transition(.opacity)
                        }
                        
                        if isStreaming {
                            TypingIndicatorView()
                                .id(scrollToId)
                        }
                        
                        // Invisible view at the bottom to ensure we can scroll to it
                        Color.clear
                            .frame(height: 1)
                            .id(scrollToId)
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy, animated: false)
                }
                .onChange(of: conversation.messages) { _ in
                    withAnimation {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            
            // Input area
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Text editor for message input
                    TextEditor(text: $newMessage)
                        .frame(minHeight: 40, maxHeight: 120)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                        .onSubmit(sendMessage)
                    
                    // Send button
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                            .opacity(canSendMessage ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSendMessage || isSending)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            }
        }
        .navigationTitle(conversation.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: copyConversation) {
                        Label("Copy Conversation", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive, action: deleteConversation) {
                        Label("Delete Conversation", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private var canSendMessage: Bool {
        !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
    
    // MARK: - Message Sending
    
    private func sendMessage() {
        guard canSendMessage, !isSending else { return }
        
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessage = ""
        
        // Create and add the user message
        let userMessage = Message(content: messageText, isFromUser: true, timestamp: Date())
        conversation.addMessage(userMessage)
        
        // Show typing indicator
        isSending = true
        isStreaming = true
        streamingMessage = ""
        
        // Generate a response from the AI
        let systemPrompt = "You are a helpful AI assistant." // Default system prompt
        
        // Use the preview service in debug mode, otherwise use the real service
        #if DEBUG
        let service = PreviewLLMService.shared
        #else
        let service = LLMService.shared
        #endif
        
        service.sendMessage(
            messageText,
            model: defaultModel,
            systemPrompt: systemPrompt,
            temperature: 0.7
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    // When finished, add the complete message if we were streaming
                    if self.isStreaming, !self.streamingMessage.isEmpty {
                        let responseMessage = Message(
                            content: self.streamingMessage,
                            isFromUser: false,
                            timestamp: Date()
                        )
                        self.conversation.addMessage(responseMessage)
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    // Add an error message to the conversation
                    let errorMessage = Message(
                        content: "Sorry, I encountered an error: \(error.localizedDescription)",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    self.conversation.addMessage(errorMessage)
                }
                
                self.isSending = false
                self.isStreaming = false
                self.streamingMessage = ""
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Update the streaming message
                self.streamingMessage = response
                
                // If this is the first chunk, add the message to the conversation
                if !self.isStreaming {
                    self.isStreaming = true
                }
            }
        )
        .store(in: &cancellables)
    }
    
    private func copyConversation() {
        let conversationText = conversation.messages
            .map { "\($0.isFromUser ? "You" : "AI"): \($0.content)" }
            .joined(separator: "\n\n")
        
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(conversationText, forType: .string)
        #else
        UIPasteboard.general.string = conversationText
        #endif
    }
    
    private func shareConversation() {
        let conversationText = conversation.messages
            .map { "\($0.isFromUser ? "You" : "AI"): \($0.content)" }
            .joined(separator: "\n\n")
        
        #if os(macOS)
        // Show share sheet on macOS
        let picker = NSSharingServicePicker(items: [conversationText])
        if let view = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        #else
        // Show share sheet on iOS
        let activityVC = UIActivityViewController(activityItems: [conversationText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
    
    private func deleteConversation() {
        // In a real app, you would ask for confirmation first
        appState.deleteConversation(conversation.id)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation {
                proxy.scrollTo(scrollToId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(scrollToId, anchor: .bottom)
        }
    }
}

// MARK: - Message View

private struct MessageView: View {
    let message: Message
    @EnvironmentObject private var appState: AppState
    
    @State private var isHovering: Bool = false
    @State private var isShowingCopyConfirmation: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromUser {
                Spacer()
            } else {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 4)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(12)
                    .contextMenu {
                        Button {
                            #if os(macOS)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.content, forType: .string)
                            #else
                            UIPasteboard.general.string = message.content
                            #endif
                            isShowingCopyConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isShowingCopyConfirmation = false
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                
                if isShowingCopyConfirmation {
                    Text("Copied!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
                
                Text(message.timestamp.formatted())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut, value: isHovering)
    }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
                title: "New Conversation",
                lastMessage: "",
                timestamp: Date()
            )
            recentChats.append(conversation)
            return conversation
        }
        
        func deleteConversation(_ id: UUID) {
            recentChats.removeAll { $0.id == id }
        }
        
        func createNewProject() -> Project {
            let project = Project(
                name: "New Project",
                description: "",
                lastUpdated: Date()
            )
    static var previews: some View {
        let conversation = Conversation(
            title: "Preview Conversation",
            lastMessage: "Hello, how can I help you today?",
            timestamp: Date(),
            unreadCount: 0,
            projectId: nil,
            messages: [
                Message(content: "Hello, how can I help you today?", isFromUser: false, timestamp: Date())
            ]
        )
        
        return ChatView(conversation: conversation)
            .environmentObject(AppState.preview)
    }
}

// Helper for previews
#if DEBUG
private class PreviewLLMService: LLMService {
    static let shared = PreviewLLMService()
    
    override func sendMessage(
        _ message: String,
        model: String = "llama3",
        systemPrompt: String = "You are a helpful AI assistant.",
        temperature: Double = 0.7
    ) -> AnyPublisher<String, Error> {
        return Just("This is a sample response from the AI. You asked: \(message)")
            .delay(for: .seconds(1), scheduler: RunLoop.main) // Simulate network delay
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
#endif
