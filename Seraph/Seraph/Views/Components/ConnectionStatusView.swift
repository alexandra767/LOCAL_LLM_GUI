//
//  ConnectionStatusView.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

struct ConnectionStatusView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showTooltip: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: appState.connectionStatus.icon)
                .font(.system(size: 10))
                .foregroundColor(appState.connectionStatus.color)
            
            Text(appState.connectionStatus.description)
                .font(.system(size: 12))
                .foregroundColor(Color.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .onHover { isHovering in
            showTooltip = isHovering
        }
        .popover(isPresented: $showTooltip) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LLM Connection Status")
                    .font(.headline)
                
                Divider()
                
                HStack {
                    Text("Active Model:")
                    Spacer()
                    Text(appState.selectedModel.displayName)
                        .bold()
                }
                
                HStack {
                    Text("Provider:")
                    Spacer()
                    Text(appState.selectedModel.provider.rawValue)
                }
                
                Button("Change Model") {
                    // Navigate to model selection
                    appState.selectedTab = .settings
                    // In a full implementation, this would also navigate to the Models tab in Settings
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(width: 250)
        }
    }
}

#Preview {
    ConnectionStatusView()
        .environmentObject(AppState.shared)
        .padding()
        .background(Color.black)
}