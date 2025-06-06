import SwiftUI
import Seraph

@main
@available(macOS 13.0, *)
@MainActor
struct SeraphApp: App {
    @StateObject private var appState: AppState
    
    init() {
        // Initialize AppState on the main thread
        _appState = StateObject(wrappedValue: AppState.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if #available(macOS 14.0, *) {
                    MainView()
                        .environmentObject(appState)
                } else {
                    Text("Seraph requires macOS 14.0 or newer")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Chat") {
                    Task { 
                        appState.createNewConversation()
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Project") {
                    // TODO: Implement new project creation
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandGroup(replacing: .appInfo) {
                Button("About Seraph") {
                    // TODO: Show about window
                }
            }
            
            SidebarCommands()
            ToolbarCommands()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
