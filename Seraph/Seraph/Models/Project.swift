//
//  Project.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI

/// Represents a project that can contain multiple chats and documents
struct Project: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var createdAt: Date
    var updatedAt: Date
    var documents: [DocumentAttachment]
    var isPinned: Bool
    var color: String
    
    init(id: UUID = UUID(), name: String, description: String = "", createdAt: Date = Date(), updatedAt: Date = Date(), documents: [DocumentAttachment] = [], isPinned: Bool = false, color: String = "#FF643D") {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.documents = documents
        self.isPinned = isPinned
        self.color = color
    }
    
    /// Get all chats associated with this project (would be implemented with CoreData)
    func getChats() -> [Chat] {
        // In a real implementation, this would fetch chats from CoreData
        // For now, returning an empty array
        return []
    }
    
    /// Get the project color as a SwiftUI Color
    var projectColor: Color {
        Color(hex: color)
    }
    
    /// Computed property to get chats directly
    var chats: [Chat] {
        return getChats()
    }
    
    /// Predefined project colors
    static let colors: [String] = [
        "#FF643D", // Coral (default)
        "#FF453A", // Red
        "#FF9F0A", // Orange
        "#FFD60A", // Yellow
        "#30D158", // Green
        "#0A84FF", // Blue
        "#5E5CE6", // Indigo
        "#BF5AF2", // Purple
        "#FF375F", // Pink
        "#8E8E93"  // Gray
    ]
}

/// Represents the type of export format for chats and projects
enum ExportFormat: String, CaseIterable {
    case markdown = "Markdown"
    case json = "JSON"
    case pdf = "PDF"
    case txt = "Plain Text"
    
    var fileExtension: String {
        switch self {
        case .markdown:
            return "md"
        case .json:
            return "json"
        case .pdf:
            return "pdf"
        case .txt:
            return "txt"
        }
    }
    
    var icon: String {
        switch self {
        case .markdown:
            return "doc.text"
        case .json:
            return "curlybraces"
        case .pdf:
            return "doc.fill"
        case .txt:
            return "doc.plaintext"
        }
    }
}