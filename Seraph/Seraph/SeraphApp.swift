//
//  SeraphApp.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI
import Combine

@main
struct SeraphApp: App {
    // Add persistence controller to support CoreData
    let persistenceController = PersistenceController.shared
    
    // Initialize app state
    @StateObject private var appState = AppState.shared
    
    // LLM services
    private let ollamaService = OllamaService.shared
    
    // Store subscriptions
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .onAppear {
                    // Initialize app when launching
                    initializeApp()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
    
    private func initializeApp() {
        print("Initializing Seraph app...")
        
        // Set default model if needed
        if appState.selectedModel.id.isEmpty {
            appState.selectedModel = .ollama(.mistral7b)
        }
        
        // Check Ollama availability
        appState.connectionStatus = .connecting
        
        ollamaService.checkAvailability()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to check Ollama availability: \(error.localizedDescription)")
                        appState.connectionStatus = .disconnected
                    }
                },
                receiveValue: { isAvailable in
                    appState.connectionStatus = isAvailable ? .connected : .disconnected
                    print("Ollama availability check: \(isAvailable ? "Available" : "Unavailable")")
                }
            )
            .store(in: &cancellables)
    }
}