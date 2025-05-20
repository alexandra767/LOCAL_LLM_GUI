import Foundation
import SwiftUI
import Combine

/// A project in the Seraph application
@MainActor
public final class Project: ProjectProtocol, Identifiable, ObservableObject, Hashable, Sendable, Codable {
    
    // MARK: - CodingKeys
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, lastUpdated, isPinned
    }
    // MARK: - Properties
    
    /// A unique identifier for the project
    public let id: UUID
    
    /// The name of the project
    @Published public var name: String {
        didSet { lastUpdated = Date() }
    }
    
    /// A description of the project
    @Published public var description: String {
        didSet { lastUpdated = Date() }
    }
    
    /// The last time the project was updated
    @Published public var lastUpdated: Date
    
    /// Whether the project is pinned for quick access
    @Published public var isPinned: Bool {
        didSet { lastUpdated = Date() }
    }
    
    // MARK: - Initialization
    
    /// Creates a new project with the specified parameters.
    /// - Parameters:
    ///   - id: A unique identifier for the project (defaults to a new UUID).
    ///   - name: The name of the project.
    ///   - description: A description of the project (defaults to an empty string).
    ///   - lastUpdated: The last time the project was updated (defaults to the current date).
    ///   - isPinned: Whether the project is pinned for quick access (defaults to false).
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        lastUpdated: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.lastUpdated = lastUpdated
        self.isPinned = isPinned
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, lastUpdated, isPinned
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        self.isPinned = try container.decode(Bool.self, forKey: .isPinned)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(isPinned, forKey: .isPinned)
    }
    
    // MARK: - Hashable & Equatable
    
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Sample Data
    
    /// Sample projects for preview and testing
    public static var sampleProjects: [Project] {
        [
            Project(
                name: "Seraph App",
                description: "A modern chat application with AI capabilities.",
                lastUpdated: Date(),
                isPinned: true
            ),
            Project(
                name: "Documentation",
                description: "Project documentation and guides.",
                lastUpdated: Date().addingTimeInterval(-86400),
                isPinned: false
            )
        ]
    }
}
