import SwiftUI
import Combine

/// A view that displays the app settings and preferences
public struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedModel: AIModel
    @State private var temperature: Double
    @State private var maxTokens: Int
    
    private let availableModels = AIModel.allCases

    
    public init() {
        // Initialize with default values that will be overridden in onAppear
        _selectedModel = State(initialValue: .llama3)
        _temperature = State(initialValue: 0.7)
        _maxTokens = State(initialValue: 2048)
    }
    
    public var body: some View {
        Form {
            Section(header: Text("Model")) {
                Picker("Model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .onChange(of: selectedModel) { newValue in
                    appState.currentModel = newValue.rawValue
                }
                
                VStack(alignment: .leading) {
                    Text("Temperature: \(temperature, specifier: "%.1f")")
                    Slider(value: $temperature, in: 0...2, step: 0.1) {
                        Text("Temperature")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("2")
                    }
                }
                .onChange(of: temperature) { newValue in
                    // Save temperature setting
                    UserDefaults.standard.set(newValue, forKey: "temperature")
                }
                
                VStack(alignment: .leading) {
                    Text("Max Tokens: \(maxTokens)")
                    Slider(value: Binding(
                        get: { Double(maxTokens) },
                        set: { maxTokens = Int($0) }
                    ), in: 1...4096, step: 1) {
                        Text("Max Tokens")
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("4096")
                    }
                }
                .onChange(of: maxTokens) { newValue in
                    // Save max tokens setting
                    UserDefaults.standard.set(newValue, forKey: "maxTokens")
                }
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: .constant(false))
                Toggle("Reduce Motion", isOn: .constant(false))
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            // Load saved settings
            if let model = AIModel(rawValue: appState.currentModel) {
                selectedModel = model
            }
            temperature = UserDefaults.standard.double(forKey: "temperature")
            if temperature == 0 {
                temperature = 0.7 // Default value
            }
            
            maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
            if maxTokens == 0 {
                maxTokens = 2048 // Default value
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState.preview)
    }
}
#endif
