import Foundation
import SwiftUI

struct Model: Identifiable, Codable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Model, rhs: Model) -> Bool {
        lhs.id == rhs.id
    }
    let id: String
    let name: String
    let description: String
    let maxTokens: Int
    let temperatureRange: ClosedRange<Double>
    let topPRange: ClosedRange<Double>
    
    init(id: String, name: String, description: String, maxTokens: Int, temperatureRange: ClosedRange<Double>, topPRange: ClosedRange<Double>) {
        self.id = id
        self.name = name
        self.description = description
        self.maxTokens = maxTokens
        self.temperatureRange = temperatureRange
        self.topPRange = topPRange
    }
}

@MainActor
class ModelConfigurationViewModel: ObservableObject {
    @Published var selectedModel: Model?
    @Published var availableModels: [Model] = []
    @Published var temperature: Double = 0.7
    @Published var topP: Double = 1.0
    @Published var presencePenalty: Double = 0.0
    @Published var frequencyPenalty: Double = 0.0
    @Published var maxTokens: Int = 2048
    @Published var maxTokensDouble: Double = 2048.0
    @Published var isStreaming: Bool = true
    @Published var isBestOfEnabled: Bool = false
    @Published var bestOf: Int = 1
    @Published var isEcho: Bool = false
    @Published var isLogprobs: Bool = false
    
    init() {
        maxTokensDouble = Double(maxTokens)
        loadModels()
        loadSettings()
    }
    
    func updateMaxTokens(_ value: Double) {
        maxTokens = Int(value)
        maxTokensDouble = value
    }
    
    private func loadModels() {
        availableModels = [
            Model(
                id: "mistral-7b-instruct",
                name: "Mistral 7B",
                description: "Fast and efficient 7B parameter model",
                maxTokens: 4096,
                temperatureRange: 0...1,
                topPRange: 0...1
            ),
            Model(
                id: "deepseek-r1-7b",
                name: "DeepSeek R1",
                description: "Research-oriented 7B parameter model",
                maxTokens: 8192,
                temperatureRange: 0...1,
                topPRange: 0...1
            ),
            Model(
                id: "llama-2-7b",
                name: "LLaMA 2",
                description: "Meta's open-source 7B parameter model",
                maxTokens: 4096,
                temperatureRange: 0...1,
                topPRange: 0...1
            )
        ]
        
        selectedModel = availableModels.first
    }
    
    private func loadSettings() {
        // Load from UserDefaults or other persistence
        temperature = UserDefaults.standard.double(forKey: "temperature")
        topP = UserDefaults.standard.double(forKey: "topP")
        presencePenalty = UserDefaults.standard.double(forKey: "presencePenalty")
        frequencyPenalty = UserDefaults.standard.double(forKey: "frequencyPenalty")
        maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        isStreaming = UserDefaults.standard.bool(forKey: "isStreaming")
        isBestOfEnabled = UserDefaults.standard.bool(forKey: "isBestOfEnabled")
        bestOf = UserDefaults.standard.integer(forKey: "bestOf")
        isEcho = UserDefaults.standard.bool(forKey: "isEcho")
        isLogprobs = UserDefaults.standard.bool(forKey: "isLogprobs")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.set(topP, forKey: "topP")
        UserDefaults.standard.set(presencePenalty, forKey: "presencePenalty")
        UserDefaults.standard.set(frequencyPenalty, forKey: "frequencyPenalty")
        UserDefaults.standard.set(maxTokens, forKey: "maxTokens")
        UserDefaults.standard.set(isStreaming, forKey: "isStreaming")
        UserDefaults.standard.set(isBestOfEnabled, forKey: "isBestOfEnabled")
        UserDefaults.standard.set(bestOf, forKey: "bestOf")
        UserDefaults.standard.set(isEcho, forKey: "isEcho")
        UserDefaults.standard.set(isLogprobs, forKey: "isLogprobs")
    }
    
    func applySettings() {
        saveSettings()
        // TODO: Apply settings to LLM service
    }
    
    func resetToDefaults() {
        temperature = 0.7
        topP = 1.0
        presencePenalty = 0.0
        frequencyPenalty = 0.0
        maxTokens = 2048
        isStreaming = true
        isBestOfEnabled = false
        bestOf = 1
        isEcho = false
        isLogprobs = false
        saveSettings()
    }
}
