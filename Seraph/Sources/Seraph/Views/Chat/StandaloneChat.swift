import SwiftUI
import Combine
import Foundation
import AppKit
import LLMService

// A completely standalone chat window that doesn't share the main navigation/view hierarchy
class ChatWindowController: NSWindowController {
    private var conversation: Conversation
    private var appState: AppState
    
    init(conversation: Conversation, appState: AppState) {
        self.conversation = conversation
        self.appState = appState
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = conversation.title
        window.center()
        window.setFrameAutosaveName("ChatWindow")
        
        // Create standalone chat view without navigation dependencies
        let chatView = StandaloneChatView(conversation: conversation)
            .environmentObject(appState)
        
        // Use NSHostingView to embed SwiftUI view in NSWindow
        window.contentView = NSHostingView(rootView: chatView)
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
    }
}

// Standalone chat view without navigation dependencies
struct StandaloneChatView: View {
    @ObservedObject var conversation: Conversation
    @State private var messageText: String = ""
    @State private var isProcessing: Bool = false
    @State private var systemPrompt: String = "You are a helpful AI assistant."
    @State private var selectedModel: AIModel = AIModel.defaultModel
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false
    @EnvironmentObject private var appState: AppState
    
    init(conversation: Conversation) {
        self.conversation = conversation
        _systemPrompt = State(initialValue: conversation.systemPrompt)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Create and add user message
        let userMessage = Message(
            content: text,
            timestamp: Date(),
            isFromUser: true
        )
        
        conversation.addMessage(userMessage)
        messageText = ""
        
        // Process AI response
        processAIResponse()
    }
    
    private func processAIResponse() {
        guard let lastUserMessage = conversation.messages.last(where: { $0.isFromUser }) else {
            print("No user message found to process")
            return
        }
        
        isProcessing = true
        
        // Create a placeholder for the AI response
        let responseMessage = Message(
            content: "",
            timestamp: Date(),
            isFromUser: false
        )
        
        // Add the response message to the conversation
        conversation.addMessage(responseMessage)
        
        // Get the response from the LLM service
        let cancellable = appState.llmService.generateResponse(
            message: lastUserMessage.content,
            model: selectedModel,
            systemPrompt: systemPrompt,
            history: conversation.messages
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                self.isProcessing = false
                
                if case .failure(let error) = completion {
                    // Display the error message to the user
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    
                    // Update the last message to indicate an error
                    if let lastIndex = self.conversation.messages.lastIndex(where: { $0.id == responseMessage.id }) {
                        self.conversation.messages[lastIndex].content = "Failed to generate response. Please try again."
                        self.conversation.messages[lastIndex].status = .failed
                    }
                    
                    print("Error generating response: \(error.localizedDescription)")
                }
            },
            receiveValue: { response in
                // Update the message with the AI's response
                if let lastIndex = self.conversation.messages.lastIndex(where: { $0.id == responseMessage.id }) {
                    self.conversation.messages[lastIndex].content = response
                    self.conversation.messages[lastIndex].status = .delivered
                }
            }
        )
        
        cancellables.insert(cancellable)
    }
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .onChange(of: conversation.messages) { _ in
                if let lastMessage = conversation.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // Simple native input field
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, onCommit: sendMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isProcessing)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    private var modelPicker: some View {
        HStack {
            Picker("Model", selection: $selectedModel) {
                ForEach(AIModel.allModels) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 200)
            
            Spacer()
            
            Button(action: {
                Task {
                    await appState.llmService.scanForLocalModels()
                    if let defaultModel = AIModel.allModels.first {
                        selectedModel = defaultModel
                    }
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                modelPicker
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main chat area
            chatMessagesView
            
            // Input area 
            inputArea
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Make sure there's at least one message in the conversation
            if conversation.messages.isEmpty {
                let welcomeMessage = Message(
                    content: "Welcome! How can I help you today?",
                    timestamp: Date(),
                    isFromUser: false,
                    status: .delivered
                )
                conversation.addMessage(welcomeMessage)
            }
            
            // Load system prompt if available
            if !conversation.systemPrompt.isEmpty {
                systemPrompt = conversation.systemPrompt
            }
        }
    }
}

// Message bubble view component
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isFromUser {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))
                    .padding(.top, 2)
            }
            
            if message.isFromUser {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .contextMenu {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.content, forType: .string)
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .foregroundColor(Color(NSColor.textColor))
                        .cornerRadius(12)
                        .contextMenu {
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(message.content, forType: .string)
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                    
                    if message.status == .sending {
                        ProgressView()
                            .scaleEffect(0.5)
                            .padding(.leading, 8)
                    } else if message.status == .failed {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Failed to send")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.leading, 8)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .transition(.opacity)
        .animation(.easeInOut, value: message.id)
    }
}

// Helper to open a standalone chat window
extension Conversation {
    func openInStandaloneWindow(with appState: AppState) {
        let windowController = ChatWindowController(conversation: self, appState: appState)
        windowController.showWindow()
    }
}