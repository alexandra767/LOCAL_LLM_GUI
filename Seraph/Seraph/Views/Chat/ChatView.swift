//
//  ChatView.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI
import Combine
import AppKit

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @State private var showModelSelector = false
    @State private var keyboardMonitor: Any? = nil
    
    init() {
        // Create a ChatViewModel with the shared OllamaService
        _viewModel = StateObject(wrappedValue: ChatViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with model selector and connection status
            ChatHeaderView(
                connectionStatus: appState.connectionStatus,
                modelName: appState.selectedModel.displayName,
                showModelSelector: $showModelSelector
            )
            
            // Chat messages
            ChatMessagesView(viewModel: viewModel)
            
            // Input area
            MessageInputView(
                inputMessage: $viewModel.inputMessage,
                isProcessing: viewModel.isProcessing,
                onSend: viewModel.sendMessage
            )
        }
        .background(Color.black)
        .onAppear {
            // Check Ollama connection
            viewModel.checkConnection()
            
            // Setup keyboard shortcut for ESC key
            setupKeyboardShortcut()
        }
        .onDisappear {
            // Clean up keyboard monitor when view disappears
            if let monitor = keyboardMonitor as? NSObjectProtocol {
                NSEvent.removeMonitor(monitor)
                keyboardMonitor = nil
            }
        }
        .toolbar {
            Button(action: {
                viewModel.checkConnection() 
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        }
        .popover(isPresented: $showModelSelector) {
            ModelSelectorView(selectedModel: $appState.selectedModel)
        }
    }
}

// MARK: - Header View
struct ChatHeaderView: View {
    let connectionStatus: ConnectionStatus
    let modelName: String
    @Binding var showModelSelector: Bool
    
    var body: some View {
        HStack {
            Text("Chat")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Connection status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(connectionStatus.color)
                    .frame(width: 8, height: 8)
                
                Text(connectionStatus.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            
            Button(action: {
                showModelSelector.toggle()
            }) {
                HStack {
                    Text(modelName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Messages View
struct ChatMessagesView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.currentChat?.messages.isEmpty ?? true {
                        EmptyChatView()
                    } else {
                        // Show actual messages
                        ForEach(viewModel.currentChat?.messages ?? []) { message in
                            MessageView(message: message)
                                .id(message.id) // For scrolling
                        }
                        
                        // Show typing indicator with token stats when processing
                        if viewModel.isProcessing {
                            TypingIndicatorView()
                            TokenStatsView(
                                tokenCount: viewModel.currentTokenCount,
                                processingTime: viewModel.currentProcessingTime,
                                tokenRate: viewModel.currentTokenRate
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(hex: "#1E1E1E"))
            .onChange(of: viewModel.currentChat?.messages.count) { _, _ in
                scrollToBottom(proxy: scrollProxy)
            }
            .onChange(of: viewModel.isProcessing) { _, isProcessing in
                if isProcessing {
                    scrollToTypingIndicator(proxy: scrollProxy)
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.currentChat?.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func scrollToTypingIndicator(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo("typingIndicator", anchor: .bottom)
        }
    }
}

// MARK: - Empty Chat View
struct EmptyChatView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Seraph - Local LLM Interface")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Connect to local Ollama models on your system.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text("Selected model: \(appState.selectedModel.displayName)")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            if appState.connectionStatus == .connected {
                Text("Ready to chat with your local models")
                    .font(.callout)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    Text("⚠️ Ollama server not running")
                        .font(.callout)
                        .foregroundColor(.orange)
                    
                    Text("To fix this, open Terminal and run:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("ollama serve")
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.black)
                        .foregroundColor(.green)
                        .cornerRadius(4)
                        
                    Text("Then restart this app")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Token Stats View
struct TokenStatsView: View {
    let tokenCount: Int
    let processingTime: TimeInterval
    let tokenRate: Double
    
    var body: some View {
        HStack {
            // Format token count with k suffix for thousands
            let formattedTokenCount = tokenCount >= 1000 
                ? String(format: "%.1fk", Double(tokenCount) / 1000.0)
                : "\(tokenCount)"
            
            Text("(\(String(format: "%.1fs", processingTime)) ↑ \(formattedTokenCount) tokens · \(String(format: "%.1f", tokenRate)) t/s · esc to interrupt)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.2))
                .cornerRadius(4)
            
            Spacer()
        }
        .padding(.leading, 40)
    }
}

// MARK: - Input View
struct MessageInputView: View {
    @Binding var inputMessage: String
    let isProcessing: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $inputMessage)
                .padding(12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .foregroundColor(.white)
                .disabled(isProcessing)
                .onSubmit {
                    if !inputMessage.isEmpty && !isProcessing {
                        onSend()
                    }
                }
            
            Button(action: onSend) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(inputMessage.isEmpty ? .gray : .blue)
                }
            }
            .disabled(isProcessing || inputMessage.isEmpty)
            .frame(width: 30, height: 30)
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Message View
struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top) {
            // Avatar
            ZStack {
                Circle()
                    .fill(message.role.color)
                    .frame(width: 32, height: 32)
                
                Image(systemName: message.role.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                MessageHeaderView(message: message)
                
                // Display message content
                MessageContentView(content: message.content)
                
                // Attachments, if any
                if !message.attachments.isEmpty {
                    ForEach(message.attachments) { attachment in
                        AttachmentView(attachment: attachment)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Message Header View
struct MessageHeaderView: View {
    let message: Message
    
    var body: some View {
        HStack {
            Text(message.role.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack(spacing: 4) {
                // Token count for assistant messages
                if message.role == .assistant, let tokenCount = message.tokenCount {
                    // Format token count with k suffix for thousands
                    let formattedTokenCount = tokenCount >= 1000 
                        ? String(format: "%.1fk", Double(tokenCount) / 1000.0)
                        : "\(tokenCount)"
                    
                    Text("[\(formattedTokenCount) tokens]")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Text(formattedDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Message Content View
struct MessageContentView: View {
    let content: String
    
    var body: some View {
        Group {
            if content.contains("💭 THINKING:") || content.contains("💭 FUNCTION CALL:") {
                SpecialContentView(content: content)
            } else {
                FormatMessageText(content: content)
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Special Content View (Thinking/Function Calls)
struct SpecialContentView: View {
    let content: String
    
    var body: some View {
        let normalContent = content
            .replacingOccurrences(of: "💭 THINKING:", with: "THINKING_SECTION_MARKER")
            .replacingOccurrences(of: "💭 FUNCTION CALL:", with: "FUNCTION_CALL_MARKER")
        
        let normalParts = normalContent.components(separatedBy: "THINKING_SECTION_MARKER")
        
        VStack(alignment: .leading, spacing: 8) {
            // Regular content
            if !normalParts[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                FormatMessageText(content: normalParts[0])
            }
            
            // Process thinking and function call sections
            ForEach(1..<normalParts.count, id: \.self) { index in
                let part = normalParts[index]
                let functionParts = part.components(separatedBy: "FUNCTION_CALL_MARKER")
                
                VStack(alignment: .leading, spacing: 4) {
                    // Thinking header
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("THINKING:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    // Thinking content
                    Text(functionParts[0])
                        .lineLimit(nil)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.yellow.opacity(0.9))
                    
                    // If there are function calls within this thinking section
                    ForEach(1..<functionParts.count, id: \.self) { funcIndex in
                        FunctionCallView(content: functionParts[funcIndex])
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            }
            
            // Process standalone function calls
            if content.contains("💭 FUNCTION CALL:") {
                let functionStandaloneParts = content.components(separatedBy: "💭 FUNCTION CALL:")
                
                ForEach(1..<functionStandaloneParts.count, id: \.self) { index in
                    let part = functionStandaloneParts[index]
                    
                    // Skip if this is already inside a thinking section
                    if !part.contains("💭 THINKING:") && !normalParts.dropFirst().contains(where: { $0.contains(part) }) {
                        FunctionCallView(content: part)
                    }
                }
            }
        }
    }
}

// MARK: - Function Call View
struct FunctionCallView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "function")
                    .foregroundColor(.cyan)
                
                Text("FUNCTION CALL:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }
            
            Text(content)
                .lineLimit(nil)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.9))
        }
        .padding(8)
        .background(Color.black.opacity(0.4))
        .cornerRadius(6)
    }
}

// MARK: - Typing Indicator View
struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .top) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            // Typing indicator
            VStack(alignment: .leading, spacing: 4) {
                Text("Assistant")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .offset(y: index == 1 ? -4 : 0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animationOffset
                            )
                    }
                }
                .padding(10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .id("typingIndicator") // For scrolling
        .onAppear {
            animationOffset = 4 // Trigger animation
        }
    }
}

// MARK: - Attachment View
struct AttachmentView: View {
    let attachment: DocumentAttachment
    
    var body: some View {
        HStack {
            Image(systemName: attachment.type.icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(attachment.name)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(attachment.formattedSize)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "arrow.down.circle")
                .foregroundColor(.blue)
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - Model Selector View
// This view is now moved to ModelSelectorView.swift, so we use the implementation from there

// MARK: - Message Role Extensions
extension MessageRole {
    var color: Color {
        switch self {
        case .user:
            return .blue
        case .assistant:
            return .green
        case .system:
            return .orange
        case .function:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .user:
            return "person.fill"
        case .assistant:
            return "brain"
        case .system:
            return "gear"
        case .function:
            return "function"
        }
    }
}

// MARK: - Previews
#Preview {
    ChatView()
        .environmentObject(AppState.shared)
}

// MARK: - Message Text Formatter
struct FormatMessageText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // First check if the content has any code blocks
            if content.contains("```") {
                // If so, process as mixed content with code blocks
                let components = extractCodeBlocks(from: content)
                ForEach(0..<components.count, id: \.self) { index in
                    let component = components[index]
                    if component.isCodeBlock {
                        codeBlockView(for: component)
                    } else {
                        Text(component.text)
                            .lineLimit(nil)
                            .foregroundColor(.white)
                    }
                }
            } else {
                // Otherwise just show as plain text
                Text(content)
                    .lineLimit(nil)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func codeBlockView(for component: TextComponent) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Language indicator (only show if we have a language)
            if let language = component.language, !language.isEmpty {
                HStack {
                    Text(language)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    
                    Spacer()
                }
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedCorner(radius: 6, corners: [.topLeft, .topRight]))
            }
            
            // Code content with syntax highlighting
            ScrollView(.horizontal, showsIndicators: false) {
                if let language = component.language, 
                   !language.isEmpty, 
                   (language.lowercased() == "python" || language.lowercased() == "swift") {
                    // Use enhanced syntax highlighting for Python or Swift
                    SyntaxHighlightedText(code: component.text, language: language.lowercased())
                        .padding(8)
                } else {
                    // For other languages or no language specified, use basic monospaced text
                    Text(component.text)
                        .fontWeight(.medium)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green.opacity(0.9))
                        .padding(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(hex: "#1E1E1E"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Function to extract code blocks from text
    private func extractCodeBlocks(from text: String) -> [TextComponent] {
        var components: [TextComponent] = []
        var currentText = ""
        var insideCodeBlock = false
        var currentLanguage = ""
        
        // Create a state machine to parse the text accurately
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            // Check for code block markers
            if line.hasPrefix("```") {
                if insideCodeBlock {
                    // End of code block - don't include the closing marker in the code
                    components.append(TextComponent(text: currentText, isCodeBlock: true, language: currentLanguage))
                    currentText = ""
                    currentLanguage = ""
                    insideCodeBlock = false
                } else {
                    // Start of code block - don't include the opening marker in the code
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, isCodeBlock: false))
                        currentText = ""
                    }
                    insideCodeBlock = true
                    
                    // Extract language if specified
                    let languageSpecifier = line.dropFirst(3)
                    if !languageSpecifier.isEmpty {
                        currentLanguage = String(languageSpecifier).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } else {
                // Normal content
                currentText += line + "\n"
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            components.append(TextComponent(text: currentText, isCodeBlock: insideCodeBlock, language: currentLanguage))
        }
        
        // Safety check - if no components were created, just return the text as-is
        if components.isEmpty {
            components = [TextComponent(text: text, isCodeBlock: false)]
        }
        
        return components
    }
}

struct TextComponent {
    let text: String
    let isCodeBlock: Bool
    let language: String?
    
    init(text: String, isCodeBlock: Bool, language: String? = nil) {
        self.text = text
        self.isCodeBlock = isCodeBlock
        self.language = language
    }
}

/// Custom view for syntax highlighting code
struct SyntaxHighlightedText: View {
    let code: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Process code by lines
            ForEach(Array(code.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                if !line.isEmpty {
                    syntaxHighlightedLine(line)
                } else {
                    // Empty line
                    Text(" ")
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
    
    private func syntaxHighlightedLine(_ line: String) -> some View {
        HStack(spacing: 0) {
            // Tokenize and colorize the line
            ForEach(tokenize(line), id: \.offset) { token in
                Text(token.text)
                    .foregroundColor(colorForToken(token))
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
    
    private func tokenize(_ line: String) -> [(text: String, type: TokenType, offset: Int)] {
        // Basic tokenizer for common programming elements
        var tokens: [(text: String, type: TokenType, offset: Int)] = []
        var currentIndex = 0
        
        // Helper to add a token
        func addToken(_ text: String, type: TokenType) {
            tokens.append((text: text, type: type, offset: currentIndex))
            currentIndex += 1
        }
        
        // This is a simplified approach - a real tokenizer would be more complex
        // For now, just add the entire line with basic coloring based on the language
        if isPythonLike(language) {
            // Python-specific coloring (simplified for demo)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                addToken(line, type: .comment)
            } else if line.contains("def ") || line.contains("class ") {
                addToken(line, type: .definition)
            } else if line.contains("import ") || line.contains("from ") {
                addToken(line, type: .keyword)
            } else {
                // Apply basic python syntax highlighting
                if let regex = try? NSRegularExpression(pattern: "(\\b(def|if|else|elif|for|while|try|except|finally|with|as|import|from|class|return|True|False|None|and|or|not|in|is)\\b)", options: []) {
                    let nsString = line as NSString
                    let range = NSRange(location: 0, length: nsString.length)
                    let matches = regex.matches(in: line, options: [], range: range)
                    
                    if !matches.isEmpty {
                        var lastIndex = 0
                        
                        for match in matches {
                            // Add text before keyword
                            if match.range.location > lastIndex {
                                let preText = nsString.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                                addToken(preText, type: .plainText)
                            }
                            
                            // Add keyword
                            let keywordText = nsString.substring(with: match.range)
                            addToken(keywordText, type: .keyword)
                            
                            lastIndex = match.range.location + match.range.length
                        }
                        
                        // Add remaining text
                        if lastIndex < nsString.length {
                            let remainingText = nsString.substring(with: NSRange(location: lastIndex, length: nsString.length - lastIndex))
                            addToken(remainingText, type: .plainText)
                        }
                    } else {
                        addToken(line, type: .plainText)
                    }
                } else {
                    addToken(line, type: .plainText)
                }
            }
        } else {
            // Default highlighting for other languages
            addToken(line, type: .plainText)
        }
        
        return tokens
    }
    
    private func colorForToken(_ token: (text: String, type: TokenType, offset: Int)) -> Color {
        switch token.type {
        case .keyword:
            return Color.purple.opacity(0.9)
        case .string:
            return Color.red.opacity(0.9)
        case .number:
            return Color.blue.opacity(0.9)
        case .comment:
            return Color.green.opacity(0.7)
        case .functionCall:
            return Color.cyan.opacity(0.9)
        case .definition:
            return Color.yellow.opacity(0.9)
        case .type:
            return Color.orange.opacity(0.9)
        case .property:
            return Color.blue.opacity(0.7)
        case .plainText:
            return Color.white.opacity(0.9)
        }
    }
    
    private func isPythonLike(_ language: String) -> Bool {
        return language.lowercased() == "python" || language.lowercased() == "py"
    }
}

enum TokenType {
    case keyword
    case string
    case number
    case comment
    case functionCall
    case definition
    case type
    case property
    case plainText
}

/// Custom rounded corner shape that works in SwiftUI for macOS
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: [Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft)
        let topRight = corners.contains(.topRight)
        let bottomLeft = corners.contains(.bottomLeft)
        let bottomRight = corners.contains(.bottomRight)
        
        // Start drawing from the top-left corner if rounded
        if topLeft {
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        
        // Draw top edge and top-right corner
        if topRight {
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: Angle(degrees: -90),
                        endAngle: Angle(degrees: 0),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        
        // Draw right edge and bottom-right corner
        if bottomRight {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                        radius: radius,
                        startAngle: Angle(degrees: 0),
                        endAngle: Angle(degrees: 90),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        // Draw bottom edge and bottom-left corner
        if bottomLeft {
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                        radius: radius,
                        startAngle: Angle(degrees: 90),
                        endAngle: Angle(degrees: 180),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        
        // Draw left edge and top-left corner
        if topLeft {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: Angle(degrees: 180),
                        endAngle: Angle(degrees: 270),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Keyboard Shortcut Extension
extension ChatView {
    func setupKeyboardShortcut() {
        // Remove any existing monitor first
        if let monitor = keyboardMonitor as? NSObjectProtocol {
            NSEvent.removeMonitor(monitor)
        }
        
        // Create a new monitor for the ESC key
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak viewModel] event in
            if event.keyCode == 53 && viewModel?.isProcessing == true { // 53 is ESC key
                viewModel?.cancelGeneration()
                return nil // Event handled
            }
            return event // Pass the event through
        }
    }
}