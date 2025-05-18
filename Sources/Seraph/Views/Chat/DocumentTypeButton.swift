import SwiftUI
import AppKit

struct DocumentTypeButton: View {
    let type: DocumentType
    
    var body: some View {
        Button(action: {
            // Filter by type
        }) {
            VStack {
                Image(systemName: type.iconName)
                    .font(.title2)
                Text(type.rawValue)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    DocumentTypeButton(type: .pdf)
}
