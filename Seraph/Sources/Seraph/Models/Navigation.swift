import Foundation
import SwiftUI

/// Represents the different navigation destinations in the app
public enum NavigationDestination: Hashable, Sendable, Identifiable {
    case chats
    case chat(id: UUID)
    case projects
    case project(id: UUID)
    case settings
    
    public var id: String {
        switch self {
        case .chats:
            return "chats"
        case .chat(let id):
            return "chat-\(id.uuidString)"
        case .projects:
            return "projects"
        case .project(let id):
            return "project-\(id.uuidString)"
        case .settings:
            return "settings"
        }
    }
    
    public var title: String {
        switch self {
        case .chats:
            return "Chats"
        case .chat:
            return "Chat"
        case .projects:
            return "Projects"
        case .project:
            return "Project"
        case .settings:
            return "Settings"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .chats, .chat:
            return "bubble.left.and.bubble.right"
        case .projects, .project:
            return "folder"
        case .settings:
            return "gear"
        }
    }
    
    public static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("Navigation Destinations:")
            .font(.headline)
        
        ForEach([
            NavigationDestination.chats,
            .chat(id: UUID()),
            .projects,
            .project(id: UUID()),
            .settings
        ]) { destination in
            HStack {
                Image(systemName: destination.systemImage)
                Text(destination.title)
                Spacer()
                Text(destination.id.prefix(10))
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    .padding()
    .frame(width: 300)
}
