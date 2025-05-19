//
//  MarkdownParser.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI

/// Utility for parsing and rendering Markdown content
class MarkdownParser {
    
    // MARK: - Parsing Methods
    
    /// Parse markdown text into attributed string with basic styling
    func parse(_ markdown: String) -> AttributedString {
        do {
            // Use basic parsing option to avoid complex styling
            return try AttributedString(markdown: markdown)
        } catch {
            print("Error parsing markdown: \(error)")
            return AttributedString(markdown)
        }
    }
    
    /// Extract code blocks from markdown
    func extractCodeBlocks(_ markdown: String) -> [String] {
        var codeBlocks: [String] = []
        
        // Find code blocks using regex
        let codeBlockPattern = #"```(.+?)```"#
        let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators])
        
        if let regex = regex {
            let nsRange = NSRange(markdown.startIndex..., in: markdown)
            let matches = regex.matches(in: markdown, options: [], range: nsRange)
            
            for match in matches {
                if let range = Range(match.range, in: markdown) {
                    let codeBlock = String(markdown[range])
                    // Remove the backticks and language identifier
                    let cleanedBlock = codeBlock
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Extract language if specified
                    let lines = cleanedBlock.components(separatedBy: .newlines)
                    if lines.count > 0 {
                        let restOfBlock = lines.dropFirst().joined(separator: "\n")
                        codeBlocks.append(restOfBlock)
                    } else {
                        codeBlocks.append(cleanedBlock)
                    }
                }
            }
        }
        
        return codeBlocks
    }
    
    /// Extract language from code block
    func extractLanguage(fromCodeBlock codeBlock: String) -> String? {
        let lines = codeBlock.components(separatedBy: .newlines)
        if lines.count > 0 {
            let firstLine = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if the first line is a language identifier
            if !firstLine.contains(" ") && !firstLine.isEmpty {
                return firstLine
            }
        }
        
        return nil
    }
    
    // MARK: - Rendering Methods
    
    /// Create a view for rendered markdown
    func createMarkdownView(for markdown: String) -> some View {
        let attributedString = parse(markdown)
        
        return ScrollView {
            Text(attributedString)
                .padding()
                .textSelection(.enabled)
        }
    }
}

// MARK: - Markdown Text View

/// Custom view for rendering markdown
struct MarkdownTextView: View {
    let markdown: String
    private let parser = MarkdownParser()
    
    var body: some View {
        parser.createMarkdownView(for: markdown)
    }
}

// MARK: - Code Block View

/// Custom view for displaying code blocks
struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var isCopied: Bool = false
    
    // Using system colors instead of custom colors
    private let cornerRadius: CGFloat = 6
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language header
            if let language = language {
                HStack {
                    Text(language)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        copyToClipboard()
                    }) {
                        Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.2))
            }
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .padding(12)
                    .textSelection(.enabled)
            }
            .background(Color.secondary.opacity(0.1))
        }
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func copyToClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        #else
        UIPasteboard.general.string = code
        #endif
        
        withAnimation {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MarkdownViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MarkdownTextView(markdown: """
            # Hello World
            
            This is **bold** and this is *italic*.
            
            ```swift
            func helloWorld() {
                print("Hello, World!")
            }
            ```
            """)
            
            CodeBlockView(
                code: """
                func helloWorld() {
                    print("Hello, World!")
                }
                """,
                language: "swift"
            )
            .frame(width: 400)
        }
        .padding()
        .background(Color.black.opacity(0.9)) // Dark background
    }
}
#endif