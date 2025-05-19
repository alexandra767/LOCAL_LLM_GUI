import SwiftUI
import AppKit

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var conversation: ChatConversation
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var isProcessing = false
    
    private var currentMessages: [ChatMessage] {
        conversation.messages
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: text, isUser: true)
        conversation.messages.append(userMessage)
        conversation.lastModified = Date()
        
        // Clear input
        messageText = ""
        
        // Simulate response (replace with actual API call)
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let responseMessage = ChatMessage(
                content: "This is a simulated response to: \"\(text)\"",
                isUser: false
            )
            conversation.messages.append(responseMessage)
            conversation.lastModified = Date()
            isProcessing = false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(currentMessages) { message in
                            MessageRow(message: message)
                                .id(message.id)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical)
                    .onAppear {
                        scrollViewProxy = proxy
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                    .onChange(of: currentMessages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // Message input
            HStack(alignment: .bottom, spacing: 12) {
                TextEditor(text: $messageText)
                    .font(.body)
                    .frame(minHeight: 40, maxHeight: 120)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isInputFocused ? Color.accentColor : Color.gray, lineWidth: 1)
                    )
                    .focused($isInputFocused)
                    .onSubmit(sendMessage)
                
                // Send button
                Button(action: sendMessage) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.5)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard !currentMessages.isEmpty else { return }
        let lastMessage = currentMessages.last!
        if animated {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contextMenu {
                        Button(action: { copyToClipboard(message.content) }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
            } else {
                Text(message.content)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .foregroundColor(Color(NSColor.labelColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contextMenu {
                        Button(action: { copyToClipboard(message.content) }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                Spacer()
            }
        }
        .transition(.opacity)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    let conversation = ChatConversation(
        title: "Sample Chat",
        messages: [
            ChatMessage(content: "Hello, how can I help you today?", isUser: false),
            ChatMessage(content: "I need help with my project", isUser: true)
        ]
    )
    
    return ChatView(conversation: conversation)
        .environmentObject({
            let state = AppState()
            state.recentChats = [conversation]
            return state
        }())
}
