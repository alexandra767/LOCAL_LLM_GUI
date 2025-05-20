import Foundation
import Combine

public enum NavigationDestination: Hashable, Identifiable {
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
    
    public static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
