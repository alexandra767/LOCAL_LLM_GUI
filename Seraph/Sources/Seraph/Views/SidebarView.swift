import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedConversation: ChatConversation.ID?
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text("Seraph")
                    .font(.title3.bold())
                Spacer()
            }
            .padding()
            
            // New Chat Button
            Button {
                let newChat = appState.createNewChat()
                selectedConversation = newChat.id
            } label: {
                HStack {
                    Image(systemName: "plus.message")
                    Text("New Chat")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.bottom)
            
            // Chats List
            List(selection: $selectedConversation) {
                Section("RECENT CHATS") {
                    ForEach(appState.recentChats) { chat in
                        HStack {
                            Image(systemName: "bubble.left")
                                .foregroundColor(selectedConversation == chat.id ? .accentColor : .secondary)
                            Text(chat.title)
                                .lineLimit(1)
                        }
                        .tag(chat.id)
                    }
                }
                
                Section("PROJECTS") {
                    ForEach(appState.projects) { project in
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.secondary)
                            Text(project.name)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            
            Spacer()
            
            // User Profile
            HStack {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    if let user = appState.currentUser {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not Signed In")
                            .font(.headline)
                        Text("Sign in to sync your data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
        .frame(minWidth: 200)
    }
}

#Preview {
    SidebarView(selectedConversation: .constant(nil))
        .environmentObject(AppState())
}
