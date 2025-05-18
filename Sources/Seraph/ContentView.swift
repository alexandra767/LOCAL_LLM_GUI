import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Claude")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color(NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)))
                
                // Navigation
                SidebarNavigation()
                
                Spacer()
                
                // Footer
                SidebarFooter()
            }
            .frame(width: 220)
            .background(Color(NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)))
            
            // Main Content
            VStack {
                if appState.showProjectsView {
                    // Projects view
                    ProjectView()
                } else if appState.selectedChat != nil {
                    // Chat view
                    VStack(alignment: .leading, spacing: 16) {
                        // Model selection
                        HStack {
                            Text("Model:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Picker("Select Model", selection: $appState.selectedModel) {
                                ForEach(appState.availableModels, id: \.self) { model in
                                    Text(model)
                                        .tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: appState.selectedModel) { oldValue, newValue in
                                Task {
                                    if let model = newValue {
                                        do {
                                            try await appState.llmService.connect(model: model)
                                        } catch {
                                            print("Error connecting to model: \(error)")
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                Task {
                                    do {
                                        try await appState.llmService.ejectCurrentModel()
                                    } catch {
                                        print("Error ejecting model: \(error)")
                                    }
                                }
                            }) {
                                Image(systemName: "eject.fill")
                                    .foregroundColor(.white)
                            }
                            .disabled(!appState.llmService.isConnected)
                        }
                        .padding(.horizontal)
                        
                        Text("Back at it, Alexandra")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        Spacer()
                        
                        // Message input area
                        VStack {
                            Text("How can I help you today?")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)))
                                .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: 800)
                    }
                    .padding()
                } else {
                    // Welcome view
                    VStack(alignment: .center) {
                        Spacer()
                        
                        Text("Back at it, Alexandra")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Message input area
                        VStack {
                            Text("How can I help you today?")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)))
                                .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: 800)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)))
        }
    }
}

struct SidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                configuration.isPressed ?
                Color(NSColor.controlBackgroundColor) :
                Color.clear
            )
            .foregroundColor(.white)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
