//
//  TerminalService.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import Combine

/// Service for executing terminal commands
class TerminalService {
    // MARK: - Published Properties
    @Published var isExecuting: Bool = false
    @Published var lastOutput: String = ""
    @Published var lastError: String = ""
    
    // MARK: - Public Methods
    
    /// Execute a terminal command asynchronously
    func executeCommand(_ command: String) -> AnyPublisher<String, Error> {
        let subject = PassthroughSubject<String, Error>()
        
        isExecuting = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                subject.send(completion: .failure(NSError(domain: "TerminalService", code: -1, userInfo: nil)))
                return
            }
            
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                
                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if let output = String(data: outputData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.lastOutput = output
                        subject.send(output)
                    }
                }
                
                if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
                    DispatchQueue.main.async {
                        self.lastError = errorOutput
                        // We don't treat stderr as an error, just log it
                    }
                }
                
                process.waitUntilExit()
                
                DispatchQueue.main.async {
                    self.isExecuting = false
                    
                    // Check exit status
                    if process.terminationStatus != 0 {
                        let error = NSError(
                            domain: "TerminalService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "Command failed with status: \(process.terminationStatus)"]
                        )
                        subject.send(completion: .failure(error))
                    } else {
                        subject.send(completion: .finished)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExecuting = false
                    self.lastError = error.localizedDescription
                    subject.send(completion: .failure(error))
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    /// Execute a command and stream the output line by line
    func executeCommandWithStream(_ command: String) -> AnyPublisher<String, Error> {
        let subject = PassthroughSubject<String, Error>()
        
        isExecuting = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                subject.send(completion: .failure(NSError(domain: "TerminalService", code: -1, userInfo: nil)))
                return
            }
            
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            // Set up a file handle to read output as it becomes available
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.lastOutput += output
                        subject.send(output)
                    }
                }
            }
            
            // Set up a file handle for error output
            let errorHandle = errorPipe.fileHandleForReading
            errorHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let errorOutput = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.lastError += errorOutput
                        // We don't treat stderr as an error, just log it
                    }
                }
            }
            
            // Handle termination
            process.terminationHandler = { process in
                fileHandle.readabilityHandler = nil
                errorHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    self.isExecuting = false
                    
                    if process.terminationStatus != 0 {
                        let error = NSError(
                            domain: "TerminalService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "Command failed with status: \(process.terminationStatus)"]
                        )
                        subject.send(completion: .failure(error))
                    } else {
                        subject.send(completion: .finished)
                    }
                }
            }
            
            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    self.isExecuting = false
                    self.lastError = error.localizedDescription
                    subject.send(completion: .failure(error))
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    /// Check if a command is available
    func isCommandAvailable(_ command: String) -> AnyPublisher<Bool, Never> {
        return executeCommand("which \(command)")
            .map { _ in true }
            .catch { _ -> AnyPublisher<Bool, Never> in
                Just(false).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}