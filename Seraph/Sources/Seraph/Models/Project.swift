import Foundation
import SwiftUI
import Combine

/// Represents a project in the app
@preconcurrency
public final class Project: Identifiable, ObservableObject, Codable, @unchecked Sendable {
    public let objectWillChange = ObservableObjectPublisher()
    
    private let accessQueue = DispatchQueue(label: "com.seraph.project", attributes: .concurrent)
    public let id: UUID
    public var name: String {
        get { accessQueue.sync { _name } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._name = newValue
            self?.updateLastModified()
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }}
    }
    public var description: String {
        get { accessQueue.sync { _description } }
        set { accessQueue.async(flags: .barrier) { [weak self] in
            self?._description = newValue
            self?.updateLastModified()
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }}
    }
    public private(set) var lastUpdated: Date
    public let createdAt: Date
    
    // Private backing storage
    private var _name: String
    private var _description: String
    
    private func updateLastModified() {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.lastUpdated = Date()
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        lastUpdated: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self._name = name
        self._description = description
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, lastUpdated, createdAt, updatedAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        _name = try container.decode(String.self, forKey: .name)
        _description = try container.decode(String.self, forKey: .description)
        
        // For backward compatibility, check both lastUpdated and updatedAt
        if let updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt) {
            lastUpdated = updatedAt
        } else {
            lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        }
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? lastUpdated
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(createdAt, forKey: .createdAt)
        // For backward compatibility, also encode as updatedAt
        try container.encode(lastUpdated, forKey: .updatedAt)
    }
    
    // MARK: - Public Methods
    
    /// Updates the project details
    /// - Parameters:
    ///   - name: The new name for the project
    ///   - description: The new description for the project
    public func update(name: String? = nil, description: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let description = description {
            self.description = description
        }
        self.lastUpdated = Date()
    }
}

// MARK: - Equatable

extension Project: Equatable {
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Project: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Data

#if DEBUG
extension Project {
    static let sample = Project(
        name: "Sample Project",
        description: "This is a sample project with some conversations",
        lastUpdated: Date(),
        createdAt: Date().addingTimeInterval(-86400)
    )
    
    static let sampleProjects: [Project] = [
        Project(
            name: "Work",
            description: "Work-related conversations",
            lastUpdated: Date().addingTimeInterval(-86400),
            createdAt: Date().addingTimeInterval(-2592000)
        ),
        Project(
            name: "Personal",
            description: "Personal notes and chats",
            lastUpdated: Date().addingTimeInterval(-172800),
            createdAt: Date().addingTimeInterval(-3456000)
        ),
        Project(
            name: "Ideas",
            description: "Random ideas and thoughts",
            lastUpdated: Date().addingTimeInterval(-259200),
            createdAt: Date().addingTimeInterval(-5184000)
        )
    ]
}
#endif
