import Foundation
import Seraph

extension AppState {
    /// A preview instance of AppState with sample data for SwiftUI previews.
    static var preview: AppState {
        let state = AppState()
        
        // Add sample conversations
        let conversation1 = Conversation(
            title: "Sample Chat 1",
            lastMessage: "I need help with my SwiftUI app",
            timestamp: Date(),
            unreadCount: 0,
            projectId: nil,
            messages: [
                Message(content: "Hello, how can I help you today?", isFromUser: false, timestamp: Date()),
                Message(content: "I need help with my SwiftUI app", isFromUser: true, timestamp: Date())
            ]
        )
        
        let conversation2 = Conversation(
            title: "Sample Chat 2",
            lastMessage: "Thanks! I'm excited to chat.",
            timestamp: Date(),
            unreadCount: 0,
            projectId: nil,
            messages: [
                Message(content: "Welcome to our conversation!", isFromUser: false, timestamp: Date()),
                Message(content: "Thanks! I'm excited to chat.", isFromUser: true, timestamp: Date())
            ]
        )
        
        state.conversations = [conversation1, conversation2]
        
        // Add sample projects
        let project1 = Project(
            name: "My SwiftUI App",
            description: "A new app I'm working on",
            lastUpdated: Date(),
            createdAt: Date()
        )
        
        let project2 = Project(
            name: "Learning Combine",
            description: "Project for learning Combine framework",
            lastUpdated: Date(),
            createdAt: Date()
        )
        
        state.projects = [project1, project2]
        
        return state
    }
}
