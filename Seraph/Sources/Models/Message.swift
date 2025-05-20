import Foundation
import SwiftUI
import Combine

/// Represents a single message in a conversation
public struct Message: MessageProtocol, Identifiable, Hashable, Codable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case id, content, isFromUser, timestamp
    }
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    
    public init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
