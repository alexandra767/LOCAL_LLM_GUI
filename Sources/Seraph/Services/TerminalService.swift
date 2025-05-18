import Foundation
import AVFoundation
import Speech

enum TerminalError: Error {
    case processFailed
    case outputError
    case permissionDenied
}

@MainActor
class TerminalService: ObservableObject {
    @Published var output: String = ""
    @Published var isRunning: Bool = false
    @Published var error: Error?
    
    private var process: Process?
    private var pipe: Pipe?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    func execute(_ command: String, arguments: [String] = []) async throws {
        isRunning = true
        defer { isRunning = false }
        
        do {
            // Create process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            
            // Set up pipe for output
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            
            // Read output
            let data = try pipe.fileHandleForReading.readToEnd()
            guard let output = String(data: data ?? Data(), encoding: .utf8) else {
                throw TerminalError.outputError
            }
            
            // Since the class is now MainActor, we can safely update on the main thread
            let outputToPublish = output
            await MainActor.run {
                self.output = outputToPublish
            }
            
            // Speak output
            speak(output)
            
            // No need for try here as waitUntilExit() doesn't throw
            process.waitUntilExit()
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
    
    func recognizeSpeech() async throws -> String {
        // Note: AVAudioSession is not available on macOS, only iOS
        // This is a simplified implementation for macOS
        
        #if os(macOS)
        // On macOS, we'll use a simplified approach
        // In a real app, you would use NSSpeechRecognizer or another macOS-compatible solution
        return "Speech recognition not implemented on macOS"
        #else
        // iOS implementation would go here
        let audioEngine = AVAudioEngine()
        // Implementation would continue for iOS
        return output
        #endif
    }
}
