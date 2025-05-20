import SwiftUI

// MARK: - Sidebar Item

/// Represents an item in the sidebar navigation
enum SidebarItem: Hashable, Identifiable {
    // Main sections
    case chats
    case files
    case search
    case settings
    
    // Dynamic items
    case project(id: String)
    case chat(id: String)
    case file(id: String)
    
    // Settings subsections
    case settingsGeneral
    case settingsAppearance
    case settingsModels
    case settingsAccount
    case settingsBilling
    case settingsTeam
    case settingsAdvanced
    
    // MARK: - Computed Properties
    
    /// Unique identifier for the item
    var id: String {
        switch self {
        case .chats: return "chats"
        case .files: return "files"
        case .search: return "search"
        case .settings: return "settings"
        case .project(let id): return "project_\(id)"
        case .chat(let id): return "chat_\(id)"
        case .file(let id): return "file_\(id)"
        case .settingsGeneral: return "settings_general"
        case .settingsAppearance: return "settings_appearance"
        case .settingsModels: return "settings_models"
        case .settingsAccount: return "settings_account"
        case .settingsBilling: return "settings_billing"
        case .settingsTeam: return "settings_team"
        case .settingsAdvanced: return "settings_advanced"
        }
    }
    
    /// Display title for the item
    var title: String {
        switch self {
        case .chats: return "Chats"
        case .files: return "Files"
        case .search: return "Search"
        case .settings: return "Settings"
        case .project: return "Project" // Actual title will come from the project model
        case .chat: return "Chat" // Actual title will come from the chat model
        case .file: return "File" // Actual title will come from the file model
        case .settingsGeneral: return "General"
        case .settingsAppearance: return "Appearance"
        case .settingsModels: return "AI Models"
        case .settingsAccount: return "Account"
        case .settingsBilling: return "Billing"
        case .settingsTeam: return "Team"
        case .settingsAdvanced: return "Advanced"
        }
    }
    
    /// System icon name for the item
    var icon: String {
        switch self {
        case .chats: return "bubble.left.and.bubble.right"
        case .files: return "doc.text"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        case .project: return "folder"
        case .chat: return "bubble.left"
        case .file: return "doc.text"
        case .settingsGeneral: return "gear"
        case .settingsAppearance: return "paintpalette"
        case .settingsModels: return "cpu"
        case .settingsAccount: return "person.crop.circle"
        case .settingsBilling: return "creditcard"
        case .settingsTeam: return "person.2"
        case .settingsAdvanced: return "wrench.and.screwdriver"
        }
    }
    
    /// Whether this item is selectable in the sidebar
    var isSelectable: Bool {
        switch self {
        case .settings: return false // This is a section header
        default: return true
        }
    }
    
    /// The section this item belongs to
    var section: SidebarSection? {
        switch self {
        case .chats, .chat: return .chats
        case .files, .file: return .files
        case .search: return .search
        case .settings, .settingsGeneral, .settingsAppearance, .settingsModels,
             .settingsAccount, .settingsBilling, .settingsTeam, .settingsAdvanced:
            return .settings
        case .project: return nil // Projects are in their own section
        }
    }
    
    // MARK: - Static Properties
    
    /// Default item to select when the app launches
    static var defaultItem: SidebarItem {
        return .chats
    }
    
    /// All main navigation items
    static var mainItems: [SidebarItem] {
        [.chats, .files, .search, .settings]
    }
    
    /// All settings items
    static var settingsItems: [SidebarItem] {
        [
            .settingsGeneral,
            .settingsAppearance,
            .settingsModels,
            .settingsAccount,
            .settingsBilling,
            .settingsTeam,
            .settingsAdvanced
        ]
    }
}

// MARK: - Sidebar Section

/// Represents a section in the sidebar
enum SidebarSection: String, CaseIterable, Identifiable {
    case chats
    case projects
    case files
    case search
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .chats: return "CHATS"
        case .projects: return "PROJECTS"
        case .files: return "FILES"
        case .search: return "SEARCH"
        case .settings: return "SETTINGS"
        }
    }
    
    var icon: String? {
        switch self {
        case .chats: return "bubble.left.and.bubble.right"
        case .projects: return "folder"
        case .files: return "doc.text"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        }
    }
    
    var isCollapsible: Bool {
        switch self {
        case .chats, .projects, .files, .search: return true
        case .settings: return false
        }
    }
}
