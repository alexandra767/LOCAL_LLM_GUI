import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // LLM Settings
                Section(header: Text("LLM Configuration")) {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    
                    Toggle("Streaming", isOn: $viewModel.isStreamingEnabled)
                    
                    Picker("Temperature", selection: $viewModel.temperature) {
                        ForEach([0.1, 0.3, 0.5, 0.7, 1.0], id: \.self) { temp in
                            Text("\(temp)").tag(temp)
                        }
                    }
                }
                
                // Appearance
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                    
                    Picker("Font Size", selection: $viewModel.fontSize) {
                        ForEach([12, 14, 16, 18, 20], id: \.self) { size in
                            Text("\(size)pt").tag(size)
                        }
                    }
                }
                
                // Advanced
                Section(header: Text("Advanced")) {
                    Toggle("Debug Logging", isOn: $viewModel.isDebugLogging)
                    
                    Button(action: {
                        viewModel.clearCache()
                    }) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
