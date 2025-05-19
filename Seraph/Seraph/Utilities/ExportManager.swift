//
//  ExportManager.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI

/// Utility for exporting chats and projects to different formats
class ExportManager {
    
    // MARK: - Constants
    
    /// Default export directory
    private static let defaultExportDirectory = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/Seraph Exports")
    
    // MARK: - Export Methods
    
    /// Export a chat to a given format
    static func exportChat(_ chat: Chat, to format: ExportFormat) -> URL? {
        // Create export directory if it doesn't exist
        try? FileManager.default.createDirectory(at: defaultExportDirectory, withIntermediateDirectories: true)
        
        // Generate filename based on chat title
        let sanitizedTitle = chat.title.replacingOccurrences(of: " ", with: "_")
                                       .replacingOccurrences(of: "/", with: "-")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "Chat_\(sanitizedTitle)_\(timestamp).\(format.fileExtension)"
        
        // Create export file URL
        let fileURL = defaultExportDirectory.appendingPathComponent(filename)
        
        // Generate content based on format
        let content: String
        switch format {
        case .markdown:
            content = generateMarkdownForChat(chat)
        case .json:
            content = generateJSONForChat(chat)
        case .txt:
            content = generatePlainTextForChat(chat)
        case .pdf:
            // PDF export would be implemented differently
            return exportChatToPDF(chat, fileURL: fileURL)
        }
        
        // Write content to file
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting chat: \(error)")
            return nil
        }
    }
    
    /// Export a project to a given format
    static func exportProject(_ project: Project, chats: [Chat], to format: ExportFormat) -> URL? {
        // Create export directory if it doesn't exist
        try? FileManager.default.createDirectory(at: defaultExportDirectory, withIntermediateDirectories: true)
        
        // Generate filename based on project name
        let sanitizedName = project.name.replacingOccurrences(of: " ", with: "_")
                                        .replacingOccurrences(of: "/", with: "-")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "Project_\(sanitizedName)_\(timestamp).\(format.fileExtension)"
        
        // Create export file URL
        let fileURL = defaultExportDirectory.appendingPathComponent(filename)
        
        // Generate content based on format
        let content: String
        switch format {
        case .markdown:
            content = generateMarkdownForProject(project, chats: chats)
        case .json:
            content = generateJSONForProject(project, chats: chats)
        case .txt:
            content = generatePlainTextForProject(project, chats: chats)
        case .pdf:
            // PDF export would be implemented differently
            return exportProjectToPDF(project, chats: chats, fileURL: fileURL)
        }
        
        // Write content to file
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting project: \(error)")
            return nil
        }
    }
    
    // MARK: - Content Generation
    
    /// Generate markdown representation of a chat
    private static func generateMarkdownForChat(_ chat: Chat) -> String {
        var markdown = "# \(chat.title)\n\n"
        
        // Add metadata
        markdown += "- **Model**: \(chat.model)\n"
        markdown += "- **Created**: \(formattedDate(chat.createdAt))\n"
        markdown += "- **Updated**: \(formattedDate(chat.updatedAt))\n\n"
        
        // Add system prompt
        markdown += "## System Prompt\n\n"
        markdown += "\(chat.systemPrompt)\n\n"
        
        // Add messages
        markdown += "## Conversation\n\n"
        
        for message in chat.messages {
            markdown += "### \(message.role.rawValue) (\(formattedTime(message.timestamp)))\n\n"
            markdown += "\(message.content)\n\n"
        }
        
        return markdown
    }
    
    /// Generate JSON representation of a chat
    private static func generateJSONForChat(_ chat: Chat) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(chat)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("Error encoding chat to JSON: \(error)")
            return "{}"
        }
    }
    
    /// Generate plain text representation of a chat
    private static func generatePlainTextForChat(_ chat: Chat) -> String {
        var text = "Chat: \(chat.title)\n\n"
        
        // Add metadata
        text += "Model: \(chat.model)\n"
        text += "Created: \(formattedDate(chat.createdAt))\n"
        text += "Updated: \(formattedDate(chat.updatedAt))\n\n"
        
        // Add system prompt
        text += "System Prompt:\n\(chat.systemPrompt)\n\n"
        
        // Add messages
        text += "Conversation:\n\n"
        
        for message in chat.messages {
            text += "[\(message.role.rawValue) - \(formattedTime(message.timestamp))]\n"
            text += "\(message.content)\n\n"
        }
        
        return text
    }
    
    /// Export chat to PDF format
    private static func exportChatToPDF(_ chat: Chat, fileURL: URL) -> URL? {
        // In a real implementation, this would render the chat to a PDF
        // For now, this is a placeholder that creates a simple text file
        let content = "PDF export is not implemented in this version.\n\n" + generatePlainTextForChat(chat)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting chat to PDF: \(error)")
            return nil
        }
    }
    
    /// Generate markdown representation of a project
    private static func generateMarkdownForProject(_ project: Project, chats: [Chat]) -> String {
        var markdown = "# Project: \(project.name)\n\n"
        
        // Add metadata
        markdown += "- **Created**: \(formattedDate(project.createdAt))\n"
        markdown += "- **Updated**: \(formattedDate(project.updatedAt))\n\n"
        
        // Add description
        if !project.description.isEmpty {
            markdown += "## Description\n\n"
            markdown += "\(project.description)\n\n"
        }
        
        // Add documents
        if !project.documents.isEmpty {
            markdown += "## Documents\n\n"
            
            for document in project.documents {
                markdown += "- \(document.name) (\(document.type.rawValue))\n"
            }
            
            markdown += "\n"
        }
        
        // Add chats
        if !chats.isEmpty {
            markdown += "## Chats\n\n"
            
            for chat in chats {
                markdown += "### \(chat.title)\n\n"
                
                // Add metadata
                markdown += "- **Model**: \(chat.model)\n"
                markdown += "- **Created**: \(formattedDate(chat.createdAt))\n\n"
                
                // Add messages
                markdown += "#### Conversation\n\n"
                
                for message in chat.messages {
                    markdown += "**\(message.role.rawValue)** (\(formattedTime(message.timestamp)))\n\n"
                    markdown += "\(message.content)\n\n"
                }
                
                markdown += "---\n\n"
            }
        }
        
        return markdown
    }
    
    /// Generate JSON representation of a project
    private static func generateJSONForProject(_ project: Project, chats: [Chat]) -> String {
        // Create a dictionary to represent the project and chats
        let projectData: [String: Any] = [
            "project": [
                "id": project.id.uuidString,
                "name": project.name,
                "description": project.description,
                "createdAt": ISO8601DateFormatter().string(from: project.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: project.updatedAt),
                "isPinned": project.isPinned,
                "color": project.color,
                "documents": project.documents.map { [
                    "id": $0.id.uuidString,
                    "name": $0.name,
                    "type": $0.type.rawValue,
                    "url": $0.url?.absoluteString ?? "",
                    "createdAt": ISO8601DateFormatter().string(from: $0.createdAt)
                ]}
            ],
            "chats": chats.map { chat -> [String: Any] in
                let chatDict: [String: Any] = [
                    "id": chat.id.uuidString,
                    "title": chat.title,
                    "model": chat.model,
                    "systemPrompt": chat.systemPrompt,
                    "createdAt": ISO8601DateFormatter().string(from: chat.createdAt),
                    "updatedAt": ISO8601DateFormatter().string(from: chat.updatedAt),
                    "isPinned": chat.isPinned,
                    "messages": chat.messages.map { [
                        "id": $0.id.uuidString,
                        "content": $0.content,
                        "role": $0.role.rawValue,
                        "timestamp": ISO8601DateFormatter().string(from: $0.timestamp),
                        "isComplete": $0.isComplete
                    ]}
                ]
                return chatDict
            }
        ]
        
        // Convert to JSON
        do {
            let data = try JSONSerialization.data(withJSONObject: projectData, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("Error encoding project to JSON: \(error)")
            return "{}"
        }
    }
    
    /// Generate plain text representation of a project
    private static func generatePlainTextForProject(_ project: Project, chats: [Chat]) -> String {
        var text = "Project: \(project.name)\n\n"
        
        // Add metadata
        text += "Created: \(formattedDate(project.createdAt))\n"
        text += "Updated: \(formattedDate(project.updatedAt))\n\n"
        
        // Add description
        if !project.description.isEmpty {
            text += "Description:\n\(project.description)\n\n"
        }
        
        // Add documents
        if !project.documents.isEmpty {
            text += "Documents:\n\n"
            
            for document in project.documents {
                text += "- \(document.name) (\(document.type.rawValue))\n"
            }
            
            text += "\n"
        }
        
        // Add chats
        if !chats.isEmpty {
            text += "Chats:\n\n"
            
            for chat in chats {
                text += "=== \(chat.title) ===\n\n"
                
                // Add metadata
                text += "Model: \(chat.model)\n"
                text += "Created: \(formattedDate(chat.createdAt))\n\n"
                
                // Add messages
                text += "Conversation:\n\n"
                
                for message in chat.messages {
                    text += "[\(message.role.rawValue) - \(formattedTime(message.timestamp))]\n"
                    text += "\(message.content)\n\n"
                }
                
                text += "--------------------\n\n"
            }
        }
        
        return text
    }
    
    /// Export project to PDF format
    private static func exportProjectToPDF(_ project: Project, chats: [Chat], fileURL: URL) -> URL? {
        // In a real implementation, this would render the project to a PDF
        // For now, this is a placeholder that creates a simple text file
        let content = "PDF export is not implemented in this version.\n\n" + generatePlainTextForProject(project, chats: chats)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting project to PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format a date for display
    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Format a time for display
    private static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}