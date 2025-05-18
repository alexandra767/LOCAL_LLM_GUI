import SwiftUI
import AppKit

struct ContextWindowView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ContextWindowViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            ContextWindowHeader(showTokenDetails: $viewModel.showTokenDetails)
            ContextDetails(viewModel: viewModel)
        }
        .background(Color(NSColor(red: 0.1176, green: 0.1176, blue: 0.1176, alpha: 1.0)))
        .sheet(isPresented: $viewModel.showTokenDetails) {
            TokenDetailsView(viewModel: viewModel)
        }
    }
}

struct TokenDetailsView: View {
    let viewModel: ContextWindowViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Token Details")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            List {
                Section {
                    Text("Total Tokens: \(viewModel.tokenCount)")
                    Text("Max Tokens: \(viewModel.maxTokens)")
                    Text("Model: \(viewModel.currentModel ?? "N/A")")
                }
                
                Section {
                    Text("Token Distribution")
                    Text("User Messages: \(viewModel.userTokenCount)")
                    Text("Assistant Messages: \(viewModel.assistantTokenCount)")
                    Text("System Messages: \(viewModel.systemTokenCount)")
                }
            }
        }
    }
}

#Preview {
    ContextWindowView()
        .environmentObject(AppState())
}
