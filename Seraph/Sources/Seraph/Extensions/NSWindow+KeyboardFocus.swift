import AppKit
import Foundation

extension NSWindow {
    /**
     A SwiftUI workaround that ensures text fields in the window can reliably receive keyboard focus.
     This is particularly helpful for SwiftUI apps where focus management can be problematic.
     */
    func forceActivateFirstTextField() {
        // Clear the current first responder 
        self.makeFirstResponder(nil)
        
        // Bring this window to front
        self.makeKeyAndOrderFront(nil)
        
        // Look for text fields in the content view hierarchy
        if let contentView = self.contentView {
            findAndActivateTextField(in: contentView)
        }
    }
    
    /**
     Recursively searches the view hierarchy for a text field that can be activated.
     */
    private func findAndActivateTextField(in view: NSView) {
        // Check if this view is a text field that can be edited
        if let textField = view as? NSTextField, textField.isEditable {
            self.makeFirstResponder(textField)
            return
        }
        
        // Recursively search all subviews
        for subview in view.subviews {
            findAndActivateTextField(in: subview)
        }
    }
}

// MARK: - Application Extension

extension NSApplication {
    /**
     Ensures keyboard focus for text input in the main window.
     Call this method when you need to force keyboard focus to a text field.
     */
    func forceKeyboardFocus() {
        DispatchQueue.main.async {
            if let mainWindow = self.mainWindow {
                mainWindow.forceActivateFirstTextField()
            }
        }
    }
}