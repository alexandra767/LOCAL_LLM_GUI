import SwiftUI

// This is a SwiftUI app, not a command-line tool
// But we need a main.swift for the executable target
print("Launching Seraph...")

import AppKit

// Create a strong reference to the delegate to prevent deallocation
let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate
NSApplication.shared.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let appState = AppState()
    let userManager = UserManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
            .environmentObject(appState)
            .environmentObject(userManager)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save data if needed
    }
}