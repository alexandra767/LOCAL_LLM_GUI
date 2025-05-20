import Foundation
import SwiftUI

/// Represents a project that can contain multiple chat conversations and files
struct Project: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Properties
    
    /// Unique identifier for the project
    let id: String
    
    /// Display name of the project
    var name: String
    
    /// Optional description of the project
    var description: String?
    
    /// Date when the project was last modified
    var lastUpdated: Date
    
    /// Date when the project was created
    let createdAt: Date
    
    /// Whether the project is pinned for quick access
    var isPinned: Bool = false
    
    /// Whether the project is archived
    var isArchived: Bool = false
    
    /// Tags for categorizing the project
    var tags: [String] = []
    
    /// Optional color for the project (for UI theming)
    var color: ProjectColor?
    
    /// Optional cover image URL
    var coverImageURL: URL?
    
    /// Member IDs with access to this project
    var memberIds: [String] = []
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        lastUpdated: Date = Date(),
        createdAt: Date = Date(),
        isPinned: Bool = false,
        isArchived: Bool = false,
        tags: [String] = [],
        color: ProjectColor? = nil,
        coverImageURL: URL? = nil,
        memberIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.tags = tags
        self.color = color
        self.coverImageURL = coverImageURL
        self.memberIds = memberIds
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Methods
    
    /// Updates the last updated timestamp to the current date
    mutating func updateLastUpdated() {
        lastUpdated = Date()
    }
    
    /// Toggles the pinned state of the project
    mutating func togglePinned() {
        isPinned.toggle()
        updateLastUpdated()
    }
    
    /// Archives the project
    mutating func archive() {
        isArchived = true
        updateLastUpdated()
    }
    
    /// Unarchives the project
    mutating func unarchive() {
        isArchived = false
        updateLastUpdated()
    }
}

// MARK: - Project Color

/// Represents a color theme for a project
struct ProjectColor: Codable, Equatable, Hashable {
    /// Base color in hex format (e.g., "#FF5733")
    let hex: String
    
    /// Color brightness (0.0 - 1.0)
    let brightness: Double
    
    /// Whether this is a light color (for text contrast)
    var isLight: Bool {
        brightness > 0.6
    }
    
    /// Text color to use for contrast
    var textColor: String {
        isLight ? "#000000" : "#FFFFFF"
    }
    
    init(hex: String, brightness: Double? = nil) {
        self.hex = hex.uppercased()
        
        // Calculate brightness if not provided
        if let brightness = brightness {
            self.brightness = min(max(brightness, 0.0), 1.0)
        } else {
            // Default brightness calculation based on hex
            self.brightness = 0.5 // Placeholder - actual calculation would parse the hex
        }
    }
    
    // Predefined project colors
    static let defaultColors: [ProjectColor] = [
        ProjectColor(hex: "#FF6B6B", brightness: 0.7),  // Red
        ProjectColor(hex: "#4ECDC4", brightness: 0.7),  // Teal
        ProjectColor(hex: "#45B7D1", brightness: 0.7),  // Blue
        ProjectColor(hex: "#96CEB4", brightness: 0.7),  // Green
        ProjectColor(hex: "#FFEEAD", brightness: 0.8),  // Yellow
        ProjectColor(hex: "#D4A5A5", brightness: 0.7),  // Pink
        ProjectColor(hex: "9B59B6", brightness: 0.6),   // Purple
        ProjectColor(hex: "E67E22", brightness: 0.6),   // Orange
    ]
    
    static func random() -> ProjectColor {
        defaultColors.randomElement() ?? ProjectColor(hex: "#4ECDC4")
    }
}

// MARK: - Project Member

/// Represents a member of a project with their role
struct ProjectMember: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let userId: String
    let projectId: String
    let role: ProjectRole
    let joinedAt: Date
    
    static func == (lhs: ProjectMember, rhs: ProjectMember) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Available roles for project members
enum ProjectRole: String, Codable, CaseIterable {
    case owner
    case admin
    case editor
    case viewer
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .editor: return "Editor"
        case .viewer: return "Viewer"
        }
    }
    
    var canEdit: Bool {
        switch self {
        case .owner, .admin, .editor: return true
        case .viewer: return false
        }
    }
    
    var canInvite: Bool {
        switch self {
        case .owner, .admin: return true
        case .editor, .viewer: return false
        }
    }
}
