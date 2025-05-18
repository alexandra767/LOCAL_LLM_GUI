import SwiftUI
import AppKit

struct ModelConfigurationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ModelConfigurationViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Model Selection
                Section(header: Text("Model")) {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.id) { model in
                            Text(model.name)
                                .tag(model.id)
                        }
                    }
                    
                    Text(viewModel.selectedModel?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Parameters
                Section(header: Text("Parameters")) {
                    // Temperature
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text("\(viewModel.temperature, specifier: "%.1f")")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                    
                    // Top P
                    HStack {
                        Text("Top P")
                        Spacer()
                        Text("\(viewModel.topP, specifier: "%.1f")")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $viewModel.topP, in: 0...1, step: 0.1)
                    
                    // Presence Penalty
                    HStack {
                        Text("Presence Penalty")
                        Spacer()
                        Text("\(viewModel.presencePenalty, specifier: "%.1f")")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $viewModel.presencePenalty, in: -2...2, step: 0.1)
                    
                    // Frequency Penalty
                    HStack {
                        Text("Frequency Penalty")
                        Spacer()
                        Text("\(viewModel.frequencyPenalty, specifier: "%.1f")")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $viewModel.frequencyPenalty, in: -2...2, step: 0.1)
                    
                    // Max Tokens
                    HStack {
                        Text("Max Tokens")
                        Spacer()
                        Text("\(viewModel.maxTokens)")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: .constant(viewModel.maxTokensDouble), in: 1...4096, step: 1)
                    .onChange(of: viewModel.maxTokensDouble) { oldValue, newValue in
                        viewModel.updateMaxTokens(newValue)
                    }
                }
                
                // Advanced Settings
                Section(header: Text("Advanced")) {
                    Toggle("Streaming", isOn: $viewModel.isStreaming)
                    Toggle("Best of", isOn: $viewModel.isBestOfEnabled)
                        .disabled(!viewModel.isBestOfEnabled)
                    
                    if viewModel.isBestOfEnabled {
                        Stepper("Best of: \(viewModel.bestOf)", value: $viewModel.bestOf, in: 1...5)
                    }
                    
                    Toggle("Echo", isOn: $viewModel.isEcho)
                    Toggle("Logprobs", isOn: $viewModel.isLogprobs)
                }
            }
            .navigationTitle("Model Configuration")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

#Preview {
    ModelConfigurationView()
        .environmentObject(AppState())
}
