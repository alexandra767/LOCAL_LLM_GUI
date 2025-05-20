import SwiftUI
import UniformTypeIdentifiers
import Combine

/// A view that displays the app settings and preferences
public struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedModel: AIModel
    @State private var temperature: Double
    @State private var maxTokens: Int
    @State private var showingFileImporter = false
    @State private var localModels: [AIModel] = []
    @State private var newModelName: String = ""
    @State private var newModelDescription: String = ""
    @State private var selectedModelFile: URL?
    
    private var availableModels: [AIModel] {
        return AIModel.allModels
    }
    
    public init() {
        // Initialize with default values that will be overridden in onAppear
        _selectedModel = State(initialValue: AIModel.llama3)
        _temperature = State(initialValue: 0.7)
        _maxTokens = State(initialValue: 2048)
    }
    
    public var body: some View {
        Form {
            Section(header: Text("Model")) {
                Picker("Model", selection: $selectedModel) {
                    ForEach(AIModel.allModels) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .onChange(of: selectedModel) { newModel in
                    appState.setCurrentModel(newModel)
                }
                
                // Model description
                if !selectedModel.description.isEmpty {
                    Text(selectedModel.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Model path if it's a local model
                if let path = selectedModel.modelPath {
                    Text("Path: \(path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    UserDefaults.standard.set(newValue, forKey: "maxTokens")
                }
            }
            
            // Local Models Management
            Section(header: Text("Local Models")) {
                Button(action: {
                    showingFileImporter = true
                }) {
                    Label("Add Local Model", systemImage: "plus.circle")
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.data],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            selectedModelFile = url
                            // Show model details dialog
                            newModelName = url.deletingPathExtension().lastPathComponent
                            newModelDescription = "Local model at \(url.lastPathComponent)"
                        }
                    case .failure(let error):
                        print("Error selecting file: \(error.localizedDescription)")
                    }
                }
                
                if !localModels.isEmpty {
                    ForEach(localModels) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                    .font(.headline)
                                if !model.description.isEmpty {
                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button(action: { removeLocalModel(model) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    Text("No local models added")
                        .foregroundColor(.secondary)
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
        .frame(minWidth: 450, minHeight: 500)
        .onAppear {
            loadSettings()
            loadLocalModels()
        }
        .alert("Add Local Model", isPresented: Binding(
            get: { selectedModelFile != nil },
            set: { if !$0 { selectedModelFile = nil }}
        ), actions: {
            TextField("Model Name", text: $newModelName)
            TextField("Description", text: $newModelDescription)
            Button("Cancel") {
                selectedModelFile = nil
            }
            Button("Add") {
                addLocalModel()
            }
            .disabled(newModelName.isEmpty || selectedModelFile == nil)
        }, message: {
            Text("Enter details for the local model")
        })
    }
    
    private func loadSettings() {
        // Load saved settings
        if let model = AIModel.allModels.first(where: { $0.id == appState.currentModel }) {
            selectedModel = model
        }
        
        // Load temperature and max tokens from UserDefaults
        temperature = UserDefaults.standard.double(forKey: "temperature") != 0.0 ? 
            UserDefaults.standard.double(forKey: "temperature") : 0.7
        maxTokens = UserDefaults.standard.integer(forKey: "maxTokens") != 0 ? 
            UserDefaults.standard.integer(forKey: "maxTokens") : 2048
        
        // Load local models
        loadLocalModels()
    }
    
    private func loadLocalModels() {
        // Load local models from UserDefaults
        if let savedModels = UserDefaults.standard.array(forKey: "customLocalModels") as? [[String: String]] {
            localModels = savedModels.compactMap { modelData in
                guard let name = modelData["name"],
                      let path = modelData["path"],
                      let displayName = modelData["displayName"],
                      let description = modelData["description"] else {
                    return nil
                }
                return AIModel.localModel(
                    name: name,
                    path: path,
                    displayName: displayName,
                    description: description
                )
            }
        } else {
            localModels = []
        }
    }
    
    private func addLocalModel() {
        guard !newModelName.isEmpty, let fileURL = selectedModelFile else { return }
        
        let newModel = AIModel.localModel(
            name: newModelName,
            path: fileURL.path,
            displayName: newModelName,
            description: newModelDescription
        )
        
        // Add to local models
        localModels.append(newModel)
        
        // Save to UserDefaults
        var savedModels = UserDefaults.standard.array(forKey: "customLocalModels") as? [[String: String]] ?? []
        savedModels.append([
            "name": newModelName,
            "path": fileURL.path,
            "displayName": newModelName,
            "description": newModelDescription
        ])
        UserDefaults.standard.set(savedModels, forKey: "customLocalModels")
        
        // Update UI
        loadLocalModels()
        
        // Reset form
        selectedModelFile = nil
        newModelName = ""
        newModelDescription = ""
    }
    
    private func removeLocalModel(_ model: AIModel) {
        // Remove the local model
        if let savedModels = UserDefaults.standard.array(forKey: "customLocalModels") as? [[String: String]] {
            let updatedModels = savedModels.filter { modelData in
                guard let path = modelData["path"] else { return true }
                return model.modelPath != path
            }
            UserDefaults.standard.set(updatedModels, forKey: "customLocalModels")
            
            // Update UI
            loadLocalModels()
            
            // If the removed model was selected, switch to default
            if selectedModel.id == model.id {
                selectedModel = AIModel.defaultModel
                appState.setCurrentModel(selectedModel)
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
