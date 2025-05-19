//
//  CoreDataExtensions.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - CDUser Extensions

extension CDUser {
    
    /// Convert Core Data user to app model
    func toModel() -> User {
        let prefs = preferences?.toModel() ?? UserPreferences()
        
        return User(
            id: id ?? UUID(),
            name: name ?? "Unknown User",
            email: email,
            profileImageUrl: profileImageUrlString != nil ? URL(string: profileImageUrlString!) : nil,
            preferences: prefs,
            createdAt: createdAt ?? Date()
        )
    }
    
    /// Update entity from model
    func update(from model: User, context: NSManagedObjectContext) {
        id = model.id
        name = model.name
        email = model.email
        profileImageUrlString = model.profileImageUrl?.absoluteString
        createdAt = model.createdAt
        
        // Update preferences
        if let preferences = preferences {
            preferences.update(from: model.preferences, context: context)
        } else {
            let newPreferences = CDUserPreferences(context: context)
            newPreferences.id = UUID()
            newPreferences.update(from: model.preferences, context: context)
            preferences = newPreferences
        }
    }
    
    /// Create a new entity from model
    static func create(from model: User, context: NSManagedObjectContext) -> CDUser {
        let entity = CDUser(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.email = model.email
        entity.profileImageUrlString = model.profileImageUrl?.absoluteString
        entity.createdAt = model.createdAt
        
        // Create preferences
        let preferencesEntity = CDUserPreferences(context: context)
        preferencesEntity.id = UUID()
        preferencesEntity.update(from: model.preferences, context: context)
        entity.preferences = preferencesEntity
        
        return entity
    }
}

// MARK: - CDUserPreferences Extensions

extension CDUserPreferences {
    
    /// Convert Core Data preferences to app model
    func toModel() -> UserPreferences {
        return UserPreferences(
            isDarkMode: isDarkMode,
            accentColor: accentColor ?? "#FF643D",
            fontSize: FontSize(rawValue: fontSize ?? "medium") ?? .medium,
            defaultModel: defaultModel ?? "ollama-Mistral 7B",
            customSystemPrompts: [], // This would be loaded separately
            defaultSystemPrompt: defaultSystemPrompt ?? "You are a helpful AI assistant.",
            defaultTemperature: defaultTemperature,
            defaultMaxTokens: Int(defaultMaxTokens)
        )
    }
    
    /// Update entity from model
    func update(from model: UserPreferences, context: NSManagedObjectContext) {
        accentColor = model.accentColor
        isDarkMode = model.isDarkMode
        fontSize = model.fontSize.rawValue
        defaultModel = model.defaultModel
        defaultSystemPrompt = model.defaultSystemPrompt
        defaultTemperature = model.defaultTemperature
        defaultMaxTokens = Int64(model.defaultMaxTokens)
    }
}

// MARK: - CDSystemPrompt Extensions

extension CDSystemPrompt {
    
    /// Convert Core Data system prompt to app model
    func toModel() -> SystemPrompt {
        return SystemPrompt(
            id: id ?? UUID(),
            name: name ?? "Untitled Prompt",
            content: content ?? "",
            isDefault: isDefault,
            createdAt: createdAt ?? Date()
        )
    }
    
    /// Update entity from model
    func update(from model: SystemPrompt, context: NSManagedObjectContext) {
        id = model.id
        name = model.name
        content = model.content
        isDefault = model.isDefault
        createdAt = model.createdAt
    }
    
    /// Create a new entity from model
    static func create(from model: SystemPrompt, context: NSManagedObjectContext) -> CDSystemPrompt {
        let entity = CDSystemPrompt(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.content = model.content
        entity.isDefault = model.isDefault
        entity.createdAt = model.createdAt
        return entity
    }
}

// MARK: - CDProject Extensions

extension CDProject {
    
    /// Convert Core Data project to app model
    func toModel() -> Project {
        let documents = self.documents?.compactMap { ($0 as? CDDocumentAttachment)?.toModel() } ?? []
        
        return Project(
            id: id ?? UUID(),
            name: name ?? "Untitled Project",
            description: projectDescription ?? "",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            documents: documents,
            isPinned: isPinned,
            color: color ?? "#FF643D"
        )
    }
    
    /// Update entity from model
    func update(from model: Project, context: NSManagedObjectContext) {
        id = model.id
        name = model.name
        projectDescription = model.description
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        isPinned = model.isPinned
        color = model.color
        
        // Updating documents would be handled separately
    }
    
    /// Create a new entity from model
    static func create(from model: Project, context: NSManagedObjectContext) -> CDProject {
        let entity = CDProject(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.projectDescription = model.description
        entity.createdAt = model.createdAt
        entity.updatedAt = model.updatedAt
        entity.isPinned = model.isPinned
        entity.color = model.color
        
        // Creating documents would be handled separately
        
        return entity
    }
    
    // Note: Relationship management methods are auto-generated by CoreData
}

// MARK: - CDChat Extensions

extension CDChat {
    
    /// Convert Core Data chat to app model
    func toModel() -> Chat {
        let chatMessages = self.messages?.compactMap { ($0 as? CDMessage)?.toModel() } ?? []
        
        return Chat(
            id: id ?? UUID(),
            title: title ?? "Untitled Chat",
            messages: chatMessages.sorted { $0.timestamp < $1.timestamp },
            projectId: project?.id,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            model: model ?? "ollama-Mistral 7B",
            systemPrompt: systemPrompt ?? "You are a helpful AI assistant.",
            isPinned: isPinned
        )
    }
    
    /// Update entity from model
    func update(from model: Chat, context: NSManagedObjectContext) {
        id = model.id
        title = model.title
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        self.model = model.model
        systemPrompt = model.systemPrompt
        isPinned = model.isPinned
        
        // Update project relationship if needed
        if let projectId = model.projectId, project?.id != projectId {
            let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
            if let projects = try? context.fetch(fetchRequest), let project = projects.first {
                self.project = project
            }
        }
        
        // Updating messages would be handled separately
    }
    
    /// Create a new entity from model
    static func create(from model: Chat, context: NSManagedObjectContext) -> CDChat {
        let entity = CDChat(context: context)
        entity.id = model.id
        entity.title = model.title
        entity.createdAt = model.createdAt
        entity.updatedAt = model.updatedAt
        entity.model = model.model
        entity.systemPrompt = model.systemPrompt
        entity.isPinned = model.isPinned
        
        // Set project relationship if applicable
        if let projectId = model.projectId {
            let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
            if let projects = try? context.fetch(fetchRequest), let project = projects.first {
                entity.project = project
            }
        }
        
        // Creating messages would be handled separately
        
        return entity
    }
    
    // Note: Relationship management methods are auto-generated by CoreData
}

// MARK: - CDMessage Extensions

extension CDMessage {
    
    /// Convert Core Data message to app model
    func toModel() -> Message {
        let messageAttachments = self.attachments?.compactMap { ($0 as? CDDocumentAttachment)?.toModel() } ?? []
        
        return Message(
            id: id ?? UUID(),
            content: content ?? "",
            role: MessageRole(rawValue: role ?? "user") ?? .user,
            timestamp: timestamp ?? Date(),
            isComplete: isComplete,
            attachments: messageAttachments,
            tokenCount: tokenCount > 0 ? Int(tokenCount) : nil
        )
    }
    
    /// Update entity from model
    func update(from model: Message, context: NSManagedObjectContext) {
        id = model.id
        content = model.content
        role = model.role.rawValue
        timestamp = model.timestamp
        isComplete = model.isComplete
        tokenCount = model.tokenCount != nil ? Int64(model.tokenCount!) : 0
        
        // Updating attachments would be handled separately
    }
    
    /// Create a new entity from model
    static func create(from model: Message, in chat: CDChat, context: NSManagedObjectContext) -> CDMessage {
        let entity = CDMessage(context: context)
        entity.id = model.id
        entity.content = model.content
        entity.role = model.role.rawValue
        entity.timestamp = model.timestamp
        entity.isComplete = model.isComplete
        entity.tokenCount = model.tokenCount != nil ? Int64(model.tokenCount!) : 0
        entity.chat = chat
        
        // Creating attachments would be handled separately
        
        return entity
    }
    
    // Note: Relationship management methods are auto-generated by CoreData
}

// MARK: - CDDocumentAttachment Extensions

extension CDDocumentAttachment {
    
    /// Convert Core Data document attachment to app model
    func toModel() -> DocumentAttachment {
        let url = URL(string: urlString ?? "") ?? URL(fileURLWithPath: "/")
        
        return DocumentAttachment(
            id: id ?? UUID(),
            name: name ?? "Untitled Document",
            type: DocumentType(rawValue: type ?? "other") ?? .other,
            url: url,
            content: nil, // CoreData doesn't store the content directly
            fileSize: fileSize,
            createdAt: createdAt ?? Date(),
            preview: preview,
            tokenCount: tokenCount > 0 ? Int(tokenCount) : nil,
            fileExtension: fileExtension
        )
    }
    
    /// Update entity from model
    func update(from model: DocumentAttachment, context: NSManagedObjectContext) {
        id = model.id
        name = model.name
        type = model.type.rawValue
        urlString = model.url?.absoluteString
        createdAt = model.createdAt
        fileSize = model.fileSize ?? 0
        preview = model.preview
        tokenCount = model.tokenCount != nil ? Int64(model.tokenCount!) : 0
        fileExtension = model.fileExtension
    }
    
    /// Create a new entity from model
    static func create(from model: DocumentAttachment, context: NSManagedObjectContext) -> CDDocumentAttachment {
        let entity = CDDocumentAttachment(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.type = model.type.rawValue
        entity.urlString = model.url?.absoluteString ?? ""
        entity.createdAt = model.createdAt
        entity.fileSize = model.fileSize ?? 0
        entity.preview = model.preview
        entity.tokenCount = model.tokenCount != nil ? Int64(model.tokenCount!) : 0
        entity.fileExtension = model.fileExtension
        return entity
    }
}