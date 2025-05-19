//
//  ContentView.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .chat
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left")
                }
                .tag(Tab.chat)
            
            Text("Projects")
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
                .tag(Tab.projects)
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.black)
        .foregroundColor(.white)
        .preferredColorScheme(.dark)
        .onAppear {
            // Initialize appState when the app launches
            selectedTab = appState.selectedTab
        }
        .onChange(of: selectedTab) { _, newValue in
            // Keep appState in sync with selected tab
            appState.selectedTab = newValue
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
