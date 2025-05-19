//
//  ModelSelectorView.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

struct ModelSelectorView: View {
    @Binding var selectedModel: LLMModel
    @EnvironmentObject var appState: AppState
    
    // Group models by category
    var modelGroups: [(String, [OllamaModel])] {
        let models = OllamaModel.allCases
        
        // DeepSeek models
        let deepseekModels = models.filter { 
            $0 == .deepseek || $0 == .deepseek_coder || 
            $0 == .deepseek_r1_14b_m4 || $0 == .deepseek_r1_8b_m4 
        }
        
        // Llama models
        let llamaModels = models.filter { 
            $0 == .llama3_8b || $0 == .llama3_70b || 
            $0 == .llama3_8b_instruct || $0 == .llama3_70b_instruct
        }
        
        // CodeLlama models
        let codeLlamaModels = models.filter { 
            $0 == .codellama_7b || $0 == .codellama_13b || $0 == .codellama_34b
        }
        
        // Phi models
        let phiModels = models.filter { 
            $0 == .phi3_mini || $0 == .phi3_small || $0 == .phi3_medium
        }
        
        // Mixtral models
        let mixtralModels = models.filter { 
            $0 == .mixtral || $0 == .mixtral_8x7b
        }
        
        // Other models
        let otherModels = models.filter { 
            $0 == .mistral7b || $0 == .gemma_2b || $0 == .gemma_7b ||
            $0 == .vicuna_7b || $0 == .vicuna_13b
        }
        
        return [
            ("DeepSeek", deepseekModels),
            ("Llama", llamaModels),
            ("CodeLlama", codeLlamaModels),
            ("Phi", phiModels),
            ("Mixtral", mixtralModels),
            ("Other", otherModels)
        ]
    }
    
    // Search text
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Local Model")
                    .font(.headline)
                
                Spacer()
                
                // Connection indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(appState.connectionStatus.color)
                        .frame(width: 6, height: 6)
                    
                    Text(appState.connectionStatus.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search models", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Divider()
            
            // Connection status info
            if appState.connectionStatus != .connected {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Ollama not connected - using simulation mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                        
                    Text("The models below are available but require Ollama to be running.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            List {
                ForEach(modelGroups.filter { group in
                    if searchText.isEmpty {
                        return true
                    }
                    return group.1.contains { model in
                        model.rawValue.lowercased().contains(searchText.lowercased())
                    }
                }, id: \.0) { groupName, models in
                    Section(header: Text(groupName)) {
                        ForEach(models.filter {
                            searchText.isEmpty ? true : $0.rawValue.lowercased().contains(searchText.lowercased())
                        }, id: \.self) { model in
                            ModelRowView(
                                isSelected: selectedModel == .ollama(model),
                                modelName: model.rawValue,
                                isAvailable: appState.connectionStatus == .connected,
                                action: { selectedModel = .ollama(model) }
                            )
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
        .frame(width: 300, height: 400)
        .background(Color.black)
    }
}

struct ModelRowView: View {
    let isSelected: Bool
    let modelName: String
    let isAvailable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "cube.transparent")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.caption)
                
                Text(modelName)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
                
                if !isAvailable {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ModelSelectorView(selectedModel: .constant(LLMModel.ollama(.mistral7b)))
        .environmentObject(AppState.shared)
}