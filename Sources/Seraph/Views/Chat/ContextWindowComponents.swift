import SwiftUI
import AppKit

struct ContextWindowHeader: View {
    @Binding var showTokenDetails: Bool
    
    var body: some View {
        HStack {
            Text("Context Window")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            
            Button(action: {
                showTokenDetails = true
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ContextDetails: View {
    @ObservedObject var viewModel: ContextWindowViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TokenUsage(viewModel: viewModel)
                MessageHistory(viewModel: viewModel)
            }
            .padding(.horizontal)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct TokenUsage: View {
    @ObservedObject var viewModel: ContextWindowViewModel
    
    var body: some View {
        HStack {
            Text("Tokens Used")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Text("\(viewModel.tokenCount) / \(viewModel.maxTokens)")
                .font(.headline)
                .foregroundColor(viewModel.isTokenLimitExceeded ? .red : .green)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
        .cornerRadius(8)
    }
}

struct MessageHistory: View {
    @ObservedObject var viewModel: ContextWindowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message History")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(viewModel.messages) { message in
                HStack {
                    Text(message.role.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(message.content)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    ContextWindowHeader(showTokenDetails: .constant(false))
}
