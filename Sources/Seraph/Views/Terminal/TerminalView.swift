import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TerminalViewModel()
    @State private var isRecording = false
    @State private var isSpeaking = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Terminal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: {
                        isRecording.toggle()
                        if isRecording {
                            Task {
                                try? await viewModel.recognizeSpeech()
                            }
                        }
                    }) {
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .foregroundColor(isRecording ? .red : .white)
                    }
                    
                    Button(action: {
                        viewModel.speakOutput()
                    }) {
                        Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.3")
                            .foregroundColor(isSpeaking ? .blue : .white)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Output
                ScrollView {
                    Text(viewModel.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                }
                .background(Color(NSColor.controlBackgroundColor))
                
                // Command Input
                HStack {
                    TextField("Enter command...", text: $viewModel.command)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            // executeCommand() doesn't throw so no need for try
                            await viewModel.executeCommand()
                        }
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white)
                    }
                    .disabled(viewModel.command.isEmpty)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .background(Color(NSColor(red: 0.1176, green: 0.1176, blue: 0.1176, alpha: 1.0)))
            
            // Error Alert
            if let error = viewModel.error {
                AlertView(isPresented: .constant(true), title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct AlertView: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
            
            Text(message)
                .padding()
            
            Button("OK") {
                isPresented = false
            }
            .padding()
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

#Preview {
    TerminalView()
        .environmentObject(AppState())
}
