import SwiftUI

struct SystemPromptView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SystemPromptViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("System Prompts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: {
                        viewModel.showNewPromptSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Prompt List
                List {
                    ForEach(viewModel.prompts) { prompt in
                        NavigationLink {
                            EditPromptView(prompt: prompt, viewModel: viewModel)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(prompt.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(prompt.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deletePrompts(at: indexSet)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewPromptSheet) {
                NewPromptView(viewModel: viewModel)
            }
        }
    }
}

struct PromptRowView: View {
    let prompt: SystemPrompt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(prompt.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                if prompt.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(prompt.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}

#Preview {
    SystemPromptView()
        .environmentObject(AppState())
}
