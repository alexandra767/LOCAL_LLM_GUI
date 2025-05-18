import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedModel: String = "mistral"
    @Published var availableModels: [String] = ["mistral", "deepseek", "llama2"]
    @Published var isStreamingEnabled: Bool = true
    @Published var temperature: Double = 0.7
    @Published var isDarkMode: Bool = true
    @Published var fontSize: Int = 16
    @Published var isDebugLogging: Bool = false
    
    private let defaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        selectedModel = defaults.string(forKey: "selectedModel") ?? "mistral"
        isStreamingEnabled = defaults.bool(forKey: "isStreamingEnabled")
        temperature = defaults.double(forKey: "temperature")
        isDarkMode = defaults.bool(forKey: "isDarkMode")
        fontSize = defaults.integer(forKey: "fontSize")
        isDebugLogging = defaults.bool(forKey: "isDebugLogging")
    }
    
    func saveSettings() {
        defaults.set(selectedModel, forKey: "selectedModel")
        defaults.set(isStreamingEnabled, forKey: "isStreamingEnabled")
        defaults.set(temperature, forKey: "temperature")
        defaults.set(isDarkMode, forKey: "isDarkMode")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(isDebugLogging, forKey: "isDebugLogging")
    }
    
    func clearCache() {
        // TODO: Implement cache clearing logic
        // This would typically involve clearing any stored conversation history,
        // model responses, or other cached data
        print("Cache cleared")
    }
    
    func applySettings() {
        saveSettings()
        // TODO: Apply settings to the app
        // This would typically involve updating the LLM service configuration,
        // UI appearance, etc.
    }
}
