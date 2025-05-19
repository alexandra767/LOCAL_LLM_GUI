//
//  UserRepository.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import CoreData
import Combine

/// Repository for managing user data and preferences
class UserRepository {
    // MARK: - Properties
    private let persistenceController: PersistenceController
    private let defaults = UserDefaults.standard
    private let userDefaultsKey = "appUser"
    
    // MARK: - Initialization
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - User Operations
    
    /// Get current user
    func getCurrentUser() -> User? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        
        // Get the first user (in a real app, this would be more sophisticated)
        fetchRequest.fetchLimit = 1
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first?.toModel()
        } catch {
            print("Error fetching current user: \(error)")
            return nil
        }
    }
    
    /// Create or update user
    func saveUser(_ user: User) -> User {
        let context = persistenceController.container.viewContext
        
        // Check if user exists
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingUser = results.first {
                // Update existing user
                existingUser.update(from: user, context: context)
                saveContext(context)
                return existingUser.toModel()
            } else {
                // Create new user
                let newUser = CDUser.create(from: user, context: context)
                saveContext(context)
                return newUser.toModel()
            }
        } catch {
            print("Error saving user: \(error)")
            
            // Create new user as fallback
            let newUser = CDUser.create(from: user, context: context)
            saveContext(context)
            return newUser.toModel()
        }
    }
    
    /// Get or create default user
    func getOrCreateDefaultUser() -> User {
        if let existingUser = getCurrentUser() {
            return existingUser
        } else {
            // Create default user
            let defaultUser = User(
                name: "Default User",
                preferences: UserPreferences()
            )
            return saveUser(defaultUser)
        }
    }
    
    // MARK: - UserDefaults Methods (for backward compatibility)
    
    /// Get the current user from UserDefaults
    func getUserFromDefaults() -> User? {
        if let userData = defaults.data(forKey: userDefaultsKey) {
            do {
                let user = try JSONDecoder().decode(User.self, from: userData)
                return user
            } catch {
                print("Error decoding user data from UserDefaults: \(error)")
            }
        }
        return nil
    }
    
    /// Save the user data to UserDefaults
    @discardableResult
    func saveUserToDefaults(_ user: User) -> User {
        do {
            let userData = try JSONEncoder().encode(user)
            defaults.set(userData, forKey: userDefaultsKey)
            return user
        } catch {
            print("Error encoding user data for UserDefaults: \(error)")
            return user
        }
    }
    
    /// Delete the current user from UserDefaults
    func deleteUserFromDefaults() {
        defaults.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - System Prompt Operations
    
    /// Get all system prompts
    func getAllSystemPrompts() -> [SystemPrompt] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDSystemPrompt> = CDSystemPrompt.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "isDefault", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        do {
            let cdPrompts = try context.fetch(fetchRequest)
            return cdPrompts.map { $0.toModel() }
        } catch {
            print("Error fetching system prompts: \(error)")
            return []
        }
    }
    
    /// Get default system prompt
    func getDefaultSystemPrompt() -> SystemPrompt? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDSystemPrompt> = CDSystemPrompt.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
        fetchRequest.fetchLimit = 1
        
        do {
            let cdPrompts = try context.fetch(fetchRequest)
            return cdPrompts.first?.toModel()
        } catch {
            print("Error fetching default system prompt: \(error)")
            return nil
        }
    }
    
    /// Save system prompt
    func saveSystemPrompt(_ prompt: SystemPrompt) -> SystemPrompt {
        let context = persistenceController.container.viewContext
        
        // Check if prompt exists
        if let existingPrompt = findCDSystemPrompt(id: prompt.id, context: context) {
            // If this prompt is being set as default, clear other defaults
            if prompt.isDefault && !existingPrompt.isDefault {
                clearDefaultSystemPrompts(context: context)
            }
            
            existingPrompt.update(from: prompt, context: context)
            saveContext(context)
            return existingPrompt.toModel()
        } else {
            // If this prompt is being set as default, clear other defaults
            if prompt.isDefault {
                clearDefaultSystemPrompts(context: context)
            }
            
            // Create new prompt
            let newPrompt = CDSystemPrompt.create(from: prompt, context: context)
            saveContext(context)
            return newPrompt.toModel()
        }
    }
    
    /// Delete system prompt
    func deleteSystemPrompt(id: UUID) {
        let context = persistenceController.container.viewContext
        
        if let promptToDelete = findCDSystemPrompt(id: id, context: context) {
            // Don't delete if it's the default prompt
            if !promptToDelete.isDefault {
                context.delete(promptToDelete)
                saveContext(context)
            }
        }
    }
    
    /// Set default system prompt
    func setDefaultSystemPrompt(id: UUID) -> SystemPrompt? {
        let context = persistenceController.container.viewContext
        
        guard let prompt = findCDSystemPrompt(id: id, context: context) else {
            print("System prompt with ID \(id) not found")
            return nil
        }
        
        // Clear other defaults
        clearDefaultSystemPrompts(context: context)
        
        // Set this one as default
        prompt.isDefault = true
        
        saveContext(context)
        return prompt.toModel()
    }
    
    // MARK: - Private Helpers
    
    /// Find a CDSystemPrompt entity by ID
    private func findCDSystemPrompt(id: UUID, context: NSManagedObjectContext) -> CDSystemPrompt? {
        let fetchRequest: NSFetchRequest<CDSystemPrompt> = CDSystemPrompt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding system prompt: \(error)")
            return nil
        }
    }
    
    /// Clear all default system prompts
    private func clearDefaultSystemPrompts(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CDSystemPrompt> = CDSystemPrompt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let defaultPrompts = try context.fetch(fetchRequest)
            for prompt in defaultPrompts {
                prompt.isDefault = false
            }
        } catch {
            print("Error clearing default system prompts: \(error)")
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
    
    // MARK: - System Prompt Templates
    
    /// Create default system prompts if none exist
    func createDefaultSystemPromptsIfNeeded() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDSystemPrompt> = CDSystemPrompt.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            
            if count == 0 {
                // Create default system prompts
                let defaultPrompts = getDefaultSystemPromptTemplates()
                
                for prompt in defaultPrompts {
                    let _ = CDSystemPrompt.create(from: prompt, context: context)
                }
                
                saveContext(context)
            }
        } catch {
            print("Error checking/creating default system prompts: \(error)")
        }
    }
    
    /// Get default system prompt templates
    private func getDefaultSystemPromptTemplates() -> [SystemPrompt] {
        return [
            SystemPrompt(
                name: "Default Assistant",
                content: "You are a helpful AI assistant.",
                isDefault: true
            ),
            SystemPrompt(
                name: "Code Assistant",
                content: "You are a helpful programming assistant. Provide code examples and explanations that help developers understand concepts and solve problems."
            ),
            SystemPrompt(
                name: "Creative Writer",
                content: "You are a creative writing assistant skilled in generating stories, narratives, and creative content."
            ),
            SystemPrompt(
                name: "Data Analyst",
                content: "You are a data analysis assistant. Help analyze data, provide insights, and explain statistical concepts in clear terms."
            )
        ]
    }
}