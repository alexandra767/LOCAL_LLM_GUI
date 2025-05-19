//
//  ChatRepository.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import CoreData
import Combine

/// Repository for managing chats and messages
class ChatRepository {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Chat Operations
    
    /// Get all chats
    func getAllChats() -> [Chat] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        
        // Sort by updated date, most recent first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            return cdChats.map { $0.toModel() }
        } catch {
            print("Error fetching chats: \(error)")
            return []
        }
    }
    
    /// Get pinned chats
    func getPinnedChats() -> [Chat] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "isPinned == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            return cdChats.map { $0.toModel() }
        } catch {
            print("Error fetching pinned chats: \(error)")
            return []
        }
    }
    
    /// Get recent chats
    func getRecentChats(limit: Int = 5) -> [Chat] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            return cdChats.map { $0.toModel() }
        } catch {
            print("Error fetching recent chats: \(error)")
            return []
        }
    }
    
    /// Get chat by ID
    func getChat(id: UUID) -> Chat? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            return cdChats.first?.toModel()
        } catch {
            print("Error fetching chat with ID \(id): \(error)")
            return nil
        }
    }
    
    /// Get chats for a project
    func getChatsForProject(projectId: UUID) -> [Chat] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "project.id == %@", projectId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            return cdChats.map { $0.toModel() }
        } catch {
            print("Error fetching chats for project \(projectId): \(error)")
            return []
        }
    }
    
    /// Save a chat
    func saveChat(_ chat: Chat) -> Chat {
        let context = persistenceController.container.viewContext
        
        // Check if chat already exists
        if let existingChat = findCDChat(id: chat.id, context: context) {
            existingChat.update(from: chat, context: context)
            saveContext(context)
            return existingChat.toModel()
        } else {
            // Create new chat
            let newChat = CDChat.create(from: chat, context: context)
            
            // Create messages
            for message in chat.messages {
                let _ = CDMessage.create(from: message, in: newChat, context: context)
            }
            
            saveContext(context)
            return newChat.toModel()
        }
    }
    
    /// Delete a chat
    func deleteChat(id: UUID) {
        let context = persistenceController.container.viewContext
        
        if let chatToDelete = findCDChat(id: id, context: context) {
            context.delete(chatToDelete)
            saveContext(context)
        }
    }
    
    /// Add a message to a chat
    func addMessage(_ message: Message, toChatWithId chatId: UUID) -> Message? {
        let context = persistenceController.container.viewContext
        
        guard let chat = findCDChat(id: chatId, context: context) else {
            print("Chat with ID \(chatId) not found")
            return nil
        }
        
        let newMessage = CDMessage.create(from: message, in: chat, context: context)
        
        // Handle attachments if present
        if !message.attachments.isEmpty {
            for attachment in message.attachments {
                let cdAttachment = CDDocumentAttachment.create(from: attachment, context: context)
                newMessage.addToAttachments(cdAttachment)
            }
        }
        
        // Update chat's updatedAt timestamp
        chat.updatedAt = Date()
        
        saveContext(context)
        return newMessage.toModel()
    }
    
    /// Update a message in a chat
    func updateMessage(_ message: Message, inChatWithId chatId: UUID) -> Message? {
        let context = persistenceController.container.viewContext
        
        guard let chat = findCDChat(id: chatId, context: context),
              let cdMessage = findCDMessage(id: message.id, inChat: chat, context: context) else {
            print("Chat with ID \(chatId) or message with ID \(message.id) not found")
            return nil
        }
        
        cdMessage.update(from: message, context: context)
        
        // Update chat's updatedAt timestamp
        chat.updatedAt = Date()
        
        saveContext(context)
        return cdMessage.toModel()
    }
    
    /// Toggle whether a chat is pinned
    func togglePinChat(id: UUID) -> Chat? {
        let context = persistenceController.container.viewContext
        
        guard let chat = findCDChat(id: id, context: context) else {
            print("Chat with ID \(id) not found")
            return nil
        }
        
        chat.isPinned = !chat.isPinned
        chat.updatedAt = Date()
        
        saveContext(context)
        return chat.toModel()
    }
    
    /// Search for chats matching a query
    func searchChats(query: String) -> [Chat] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        
        // Search in title or message content
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let messagePredicate = NSPredicate(format: "ANY messages.content CONTAINS[cd] %@", query)
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, messagePredicate])
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            return cdChats.map { $0.toModel() }
        } catch {
            print("Error searching chats: \(error)")
            return []
        }
    }
    
    // MARK: - Private Helpers
    
    /// Find a CDChat entity by ID
    private func findCDChat(id: UUID, context: NSManagedObjectContext) -> CDChat? {
        let fetchRequest: NSFetchRequest<CDChat> = CDChat.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding chat: \(error)")
            return nil
        }
    }
    
    /// Find a CDMessage entity by ID within a chat
    private func findCDMessage(id: UUID, inChat chat: CDChat, context: NSManagedObjectContext) -> CDMessage? {
        let fetchRequest: NSFetchRequest<CDMessage> = CDMessage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND chat == %@", id as CVarArg, chat)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding message: \(error)")
            return nil
        }
    }
    
    /// Save the managed object context
    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}