import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Recent Chats")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: {
                    viewModel.createNewChat()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            // Chat list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.chats) { chat in
                        ChatItemView(chat: chat, viewModel: viewModel)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(red: 0.1176, green: 0.1176, blue: 0.1176))
    }
}

struct ChatItemView: View {
    let chat: Chat
    @ObservedObject var viewModel: ChatViewModel
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationLink(destination: ChatView(chat: chat)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chat.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if chat.isStarred {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(lastMessagePreview(from: chat))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(formattedDate(chat.updatedAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                .alert("Delete Chat", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        viewModel.deleteChat(chat)
                    }
                } message: {
                    Text("Are you sure you want to delete this chat? This action cannot be undone.")
                }
            }
            .padding()
            .background(Color(NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func lastMessagePreview(from chat: Chat) -> String {
        if let lastMessage = chat.messages.last {
            return "\(lastMessage.role.rawValue): \(lastMessage.content)"
        } else {
            return "No messages yet"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatListView()
        .environmentObject(AppState())
}