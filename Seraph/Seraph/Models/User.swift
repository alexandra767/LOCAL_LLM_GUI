//
//  User.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI

/// Represents a user of the application
struct User: Identifiable, Codable {
    var id: UUID
    var name: String
    var email: String?
    var profileImageUrl: URL?
    var preferences: UserPreferences
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, email: String? = nil, profileImageUrl: URL? = nil, preferences: UserPreferences = UserPreferences(), createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.preferences = preferences
        self.createdAt = createdAt
    }
    
    /// Get the user's initials for displays without profile image
    var initials: String {
        let nameComponents = name.components(separatedBy: " ")
        if nameComponents.count > 1,
           let firstInitial = nameComponents.first?.first,
           let lastInitial = nameComponents.last?.first {
            return String(firstInitial) + String(lastInitial)
        } else if let firstInitial = name.first {
            return String(firstInitial)
        }
        return ""
    }
}

/// Represents user preferences for the application
struct UserPreferences: Codable {
    var isDarkMode: Bool = true
    var accentColor: String = "#FF643D"
    var fontSize: FontSize = .medium
    var defaultModel: String = "ollama-Mistral 7B"
    var customSystemPrompts: [SystemPrompt] = []
    var defaultSystemPrompt: String = "You are a helpful AI assistant."
    var defaultTemperature: Double = 0.7
    var defaultMaxTokens: Int = 2048
    
    /// Get the accent color as a SwiftUI Color
    var accentColorValue: Color {
        Color(hex: accentColor)
    }
}

/// Represents a system prompt template
struct SystemPrompt: Identifiable, Codable {
    var id: UUID
    var name: String
    var content: String
    var isDefault: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, content: String, isDefault: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.content = content
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}

/// Font size options for the application
enum FontSize: String, CaseIterable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var textSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 18
        }
    }
    
    var uiScaleFactor: CGFloat {
        switch self {
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.1
        }
    }
    
    // Font sizes for different text styles
    var bodySize: CGFloat {
        return textSize
    }
    
    var titleSize: CGFloat {
        return textSize + 2
    }
    
    var headerSize: CGFloat {
        return textSize + 6
    }
    
    var captionSize: CGFloat {
        return textSize - 2
    }
}