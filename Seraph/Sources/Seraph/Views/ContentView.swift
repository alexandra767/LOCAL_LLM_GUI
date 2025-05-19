import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedConversation: ChatConversation.ID?
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedConversation: $selectedConversation)
                .frame(minWidth: 200)
        } detail: {
            if let selectedId = selectedConversation,
               let conversation = appState.recentChats.first(where: { $0.id == selectedId }) {
                ChatView(conversation: conversation)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Text("No chat selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Button("Start a new chat") {
                        let newChat = appState.createNewChat()
                        selectedConversation = newChat.id
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if appState.recentChats.isEmpty {
                let newChat = appState.createNewChat()
                selectedConversation = newChat.id
            } else if selectedConversation == nil {
                selectedConversation = appState.recentChats.first?.id
            }
        }
        .onChange(of: appState.recentChats) { _ in
            if selectedConversation == nil || !appState.recentChats.contains(where: { $0.id == selectedConversation }) {
                selectedConversation = appState.recentChats.first?.id
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject({
            let state = AppState()
            state.loadSampleData()
            return state
        }())
}
