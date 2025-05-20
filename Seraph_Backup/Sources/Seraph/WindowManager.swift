import AppKit
import SwiftUI

@MainActor
class WindowManager: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = WindowManager()
    
    private var mainWindow: NSWindow?
    private(set) var appState: AppState?
    private var isCreatingWindow = false
    private var windowCreationTask: Task<Void, Never>?
    
    private override init() {
        super.init()
    }
    
    deinit {
        windowCreationTask?.cancel()
    }
    
    func ensureWindowIsVisible() {
        // Cancel any pending window creation
        windowCreationTask?.cancel()
        
        windowCreationTask = Task { @MainActor in
            guard !isCreatingWindow else { return }
            
            // If we have a visible window, bring it to front
            if let window = mainWindow, window.isVisible {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            
            // Otherwise create a new window
            await createMainWindow()
        }
    }
    
    private func createMainWindow() async {
        // Prevent multiple window creation attempts
        guard !isCreatingWindow else { return }
        isCreatingWindow = true
        
        defer { isCreatingWindow = false }
        
        // If we already have a window, just bring it to front
        if let existingWindow = mainWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        print("Creating main window...")
        
        // Create a new AppState instance for this window if we don't have one
        if appState == nil {
            appState = AppState()
        }
        
        guard let appState = appState else {
            print("Failed to create AppState")
            return
        }
        
        // Create the window on the main thread
        await MainActor.run {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            window.center()
            window.setFrameAutosaveName("Main Window")
            
            window.contentView = NSHostingView(
                rootView: ContentView()
                    .environmentObject(appState)
            )
            
            // Store reference to the window and set delegate
            self.mainWindow = window
            window.delegate = self
            
            // Configure window behavior
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.managed, .fullScreenPrimary]
            
            // Show and activate the window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            print("Window created and shown")
        }
    }
    
    // MARK: - NSWindowDelegate
    
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            // Clean up when window is closed
            if let window = notification.object as? NSWindow, window === self.mainWindow {
                print("Window will close")
                window.delegate = nil
                self.mainWindow = nil
                // Don't nil out appState here to preserve state if window is recreated
            }
        }
    }
}
