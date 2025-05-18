import Foundation
import SwiftUI

@MainActor
class TerminalViewModel: ObservableObject {
    @Published var command: String = ""
    @Published var output: String = ""
    @Published var error: Error?
    @Published var isProcessing: Bool = false
    
    private let terminalService: TerminalService
    
    init() {
        self.terminalService = TerminalService()
    }
    
    func executeCommand() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await terminalService.execute(command)
            output = terminalService.output
        } catch {
            self.error = error
        }
    }
    
    func recognizeSpeech() async throws -> String {
        return try await terminalService.recognizeSpeech()
    }
    
    func speakOutput() {
        terminalService.speak(output)
    }
    
    func clearOutput() {
        output = ""
    }
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
    
    func saveOutput() async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "terminal_output_\(Date().formatted()).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try output.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
