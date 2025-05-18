import Foundation
import SwiftUI
import AppKit

enum CodeLanguage: String, CaseIterable, Identifiable {
    case swift = "swift"
    case python = "python"
    case javascript = "javascript"
    case html = "html"
    case css = "css"
    case java = "java"
    case csharp = "csharp"
    case go = "go"
    case rust = "rust"
    case kotlin = "kotlin"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .html: return "HTML"
        case .css: return "CSS"
        case .java: return "Java"
        case .csharp: return "C#"
        case .go: return "Go"
        case .rust: return "Rust"
        case .kotlin: return "Kotlin"
        }
    }
}

struct CodeBlock: Identifiable {
    let id: UUID
    let language: CodeLanguage
    let content: String
    let lineNumber: Int
    
    init(id: UUID = UUID(), language: CodeLanguage, content: String, lineNumber: Int = 1) {
        self.id = id
        self.language = language
        self.content = content
        self.lineNumber = lineNumber
    }
}

class CodeFormatter: ObservableObject {
    @Published var syntaxHighlightingEnabled: Bool = true
    @Published var lineNumbersEnabled: Bool = true
    @Published var selectedLanguage: CodeLanguage = .swift
    
    func format(code: String, language: CodeLanguage) -> AttributedString {
        var attributedString = AttributedString(code)
        
        // Apply syntax highlighting
        if syntaxHighlightingEnabled {
            attributedString = applySyntaxHighlighting(attributedString, language: language)
        }
        
        // Add line numbers
        if lineNumbersEnabled {
            attributedString = addLineNumbers(attributedString)
        }
        
        return attributedString
    }
    
    private func applySyntaxHighlighting(_ string: AttributedString, language: CodeLanguage) -> AttributedString {
        // This is a simplified example - in a real implementation you would use a proper
        // syntax highlighting library
        let result = string
        
        // Example keyword highlighting for Swift
        if language == .swift {
            // Commented out unused variable to fix warning
            // let keywords = ["func", "class", "struct", "let", "var", "if", "else", "for", "while"]
            
            // In a real app, use a proper text processing approach
            // This is just a placeholder since AttributedString manipulation is complex
            // Instead of manipulating AttributedString directly, we'd typically use NSAttributedString
            // or a dedicated syntax highlighting library
        }
        
        return result
    }
    
    private func addLineNumbers(_ string: AttributedString) -> AttributedString {
        // Simple implementation that doesn't rely on complex AttributedString APIs
        let lines = string.description.split(separator: "\n")
        var numberedCode = ""
        
        for (index, line) in lines.enumerated() {
            numberedCode += "\(index + 1): \(line)\n"
        }
        
        return AttributedString(numberedCode)
    }
    
    func copyToClipboard(_ code: String) {
        // Copy code to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }
}
