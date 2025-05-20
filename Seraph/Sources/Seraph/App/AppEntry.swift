import SwiftUI

/// The main entry point for the Seraph application.
@main
struct SeraphApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Chat") {
                    Task { @MainActor in
                        await appState.createNewConversation()
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
