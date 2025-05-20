import SwiftUI

/// A view that displays a single conversation row in a list
public struct ConversationRow: View {
    let conversation: Conversation
    
    public init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Conversation icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            // Conversation details
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if !conversation.lastMessage.isEmpty {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Timestamp and unread count
            VStack(alignment: .trailing, spacing: 4) {
                Text(conversation.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

struct ConversationRow_Previews: PreviewProvider {
    static var previews: some View {
        let conversation = Conversation(
            title: "Project Discussion",
            lastMessage: "Let's discuss the project requirements",
            timestamp: Date(),
            unreadCount: 2,
            projectId: UUID(),
            systemPrompt: "",
            messages: []
        )
        
        return List {
            ConversationRow(conversation: conversation)
            ConversationRow(conversation: Conversation(
                title: "Another Chat",
                lastMessage: "This is a longer message that should be truncated in the UI to prevent it from taking up too much space",
                timestamp: Date().addingTimeInterval(-3600),
                unreadCount: 0,
                projectId: UUID(),
                systemPrompt: "",
                messages: []
            ))
        }
        .listStyle(.plain)
    }
}
