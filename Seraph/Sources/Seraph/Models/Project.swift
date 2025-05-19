import Foundation
import SwiftUI

public final class Project: Identifiable, Codable, Hashable, ObservableObject {
    public var id = UUID()
    public var name: String {
        didSet { lastModified = Date() }
    }
    public var lastModified: Date
    public var unreadCount: Int = 0
    public var isPinned: Bool = false
    
    public init(name: String, lastModified: Date = Date(), unreadCount: Int = 0, isPinned: Bool = false) {
        self.name = name
        self.lastModified = lastModified
        self.unreadCount = unreadCount
        self.isPinned = isPinned
    }
    
    // MARK: - Hashable & Equatable
    
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Methods
    
    public func updateLastModified() {
        lastModified = Date()
    }
    
    public func togglePinned() {
        isPinned.toggle()
        updateLastModified()
    }
}
