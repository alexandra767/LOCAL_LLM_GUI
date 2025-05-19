import SwiftUI
import AppKit

@main
@MainActor
struct SeraphApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // This is a workaround to prevent the default WindowGroup behavior
    @State private var window: NSWindow?
    
    var body: some Scene {
        // Empty scene - we'll manage the window manually
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Seraph") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "A modern AI assistant application",
                                attributes: [
                                    NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
                                ]
                            ),
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025 Seraph"
                        ]
                    )
                }
            }
            
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(after: .newItem) {
                Button("New Chat") {
                    let appState = WindowManager.shared.appState ?? AppState()
                    let newChat = appState.createNewChat()
                    NotificationCenter.default.post(
                        name: .newChatCreated,
                        object: nil,
                        userInfo: ["chat": newChat]
                    )
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Show Main Window") {
                    WindowManager.shared.ensureWindowIsVisible()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var activationTask: Task<Void, Never>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App did finish launching")
        
        // Set activation policy first
        NSApp.setActivationPolicy(.regular)
        
        // Hide the default window if it exists
        NSApp.windows.forEach { $0.close() }
        
        // Create and show our main window
        WindowManager.shared.ensureWindowIsVisible()
        
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            WindowManager.shared.ensureWindowIsVisible()
        } else {
            NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
        }
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
    
    deinit {
        activationTask?.cancel()
    }
}

extension Notification.Name {
    static let newChatCreated = Notification.Name("newChatCreated")
}
