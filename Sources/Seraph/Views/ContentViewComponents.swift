import SwiftUI
import AppKit

struct SidebarHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seraph")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("LLM Assistant")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct SidebarNavigation: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // New Chat Button
                Button(action: {
                    appState.selectedChat = nil
                    appState.showProjectsView = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                        Text("New chat")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Chat History
                VStack(spacing: 0) {
                    ForEach(appState.chats) { chat in
                        Button(action: {
                            appState.selectedChat = chat
                            appState.showProjectsView = false
                        }) {
                            HStack {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.white)
                                Text(chat.title)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(chat.updatedAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Settings
                Button(action: {
                    appState.showSettings = true
                    appState.showProjectsView = false
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                        Text("Settings")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Files
                Button(action: {
                    appState.showFilePicker = true
                    appState.showProjectsView = false
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.white)
                        Text("Files")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Projects
                Button(action: {
                    appState.showProjectsView = true
                    appState.selectedChat = nil
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.white)
                        Text("Projects")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(appState.showProjectsView ? Color(NSColor.selectedControlColor) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.vertical, 6)
                
                // Starred Section - Empty by default until chats are created
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starred")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 2)
                    
                    // Will be populated when chats are created and starred
                }
                
                // Recents Section - Empty by default until chats are created
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recents")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .padding(.top, 6)
                    
                    // Will be populated when chats are created
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)))
    }
}

struct ChatMessage: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color(NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)))
                    .cornerRadius(12)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color(NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)))
                    .cornerRadius(12)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct ChatStatus: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            Text("Connected to LLM")
                .font(.caption)
                .foregroundColor(.green)
            Spacer()
            Text("\(appState.chats.count) messages")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)))
    }
}

struct SidebarFooter: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // Profile view in bottom left
            ProfilePictureView()
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    SidebarHeader()
}