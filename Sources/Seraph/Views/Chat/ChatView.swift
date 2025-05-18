import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ChatViewModel()
    @State private var showAttachmentPicker = false
    
    var chat: Chat?
    
    init(chat: Chat? = nil) {
        self.chat = chat
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack {
                Text(appState.selectedChat?.title ?? "New Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: {
                    appState.selectedChat?.isStarred.toggle()
                }) {
                    Image(systemName: appState.selectedChat?.isStarred == true ? "star.fill" : "star")
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    showAttachmentPicker = true
                }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    // Share chat
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Token Counter
            HStack {
                Text(TokenCounter.getTokenUsageString(in: viewModel.messages))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Attachments
            if !viewModel.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.attachments) { attachment in
                            DocumentAttachmentView(attachment: attachment)
                                .frame(width: 100, height: 100)
                                .onTapGesture {
                                    // Show attachment details
                                }
                                .onLongPressGesture {
                                    // Remove attachment
                                    viewModel.removeAttachment(attachment)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
            
            // Chat Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageView(message: message)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Input Area
            HStack {
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane")
                        .foregroundColor(.white)
                }
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(Color(NSColor(red: 0.1176, green: 0.1176, blue: 0.1176, alpha: 1.0)))
        .sheet(isPresented: $showAttachmentPicker) {
            DocumentPickerView(viewModel: viewModel)
        }
    }
}

struct ChatMessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .leading : .trailing) {
                Text(MarkdownParser.parse(message.content))
                    .foregroundColor(message.role == .user ? .white : .gray)
                    .padding()
                    .background(
                        message.role == .user ?
                        Color(NSColor.controlBackgroundColor).opacity(0.2) :
                        Color(NSColor.controlBackgroundColor).opacity(0.1)
                    )
                    .cornerRadius(12)
                    .overlay(
                        Group {
                            if message.isStreaming {
                                ProgressView()
                            }
                        }
                    )
            }
            
            if message.role == .user {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(AppState())
}
