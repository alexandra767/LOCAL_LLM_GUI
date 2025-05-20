import Foundation

public enum NavigationItem: Identifiable, Hashable {
    case chat(id: UUID)
    case project(id: UUID)
    case settings
    
    public var id: String {
        switch self {
        case .chat(let id):
            return "chat-\(id.uuidString)"
        case .project(let id):
            return "project-\(id.uuidString)"
        case .settings:
            return "settings"
        }
    }
    
    public static var allCases: [NavigationItem] {
        [.chat(id: UUID()), .project(id: UUID()), .settings]
    }
    
    public static var chats: NavigationItem { .chat(id: UUID()) }
    public static var projects: NavigationItem { .project(id: UUID()) }
    
    public static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
