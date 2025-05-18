import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct DocumentPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDocument: DocumentAttachment?
    @State private var showPreview = false
    @ObservedObject var viewModel: ChatViewModel
    
    private let supportedTypes: [UTType] = [
        .pdf,
        .text,
        .jpeg,
        .png,
        .gif
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search files...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                // Document Types
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DocumentType.allCases) { type in
                            DocumentTypeButton(type: type)
                        }
                    }
                    .padding()
                }
                
                // Document List
                List {
                    ForEach(viewModel.attachments.indices, id: \.self) { index in
                        AttachmentRowView(attachment: viewModel.attachments[index])
                            .onTapGesture {
                                // Handle tap
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.removeAttachment(viewModel.attachments[index])
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.removeAttachment(viewModel.attachments[index])
                        }
                    }
                }
            }
            .navigationTitle("Attachments")
            .toolbar {
                ToolbarItem {
                    Button("Add") {
                        // Open file picker
                        showFilePicker()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = supportedTypes
        
        panel.begin { result in
            if result == .OK, let urls = panel.urls.first {
                Task {
                    await viewModel.addAttachment(from: urls)
                }
            }
        }
    }
}

struct AttachmentRowView: View {
    let attachment: DocumentAttachment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: attachment.type.iconName)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(attachment.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let sizeString = attachment.metadata["size"],
                   let size = Int64(sizeString) {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension DocumentType {
    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .pdf: return "doc"
        case .image: return "photo"
        case .markdown: return "doc.text.fill"
        }
    }
}

#Preview {
    DocumentPickerView(viewModel: ChatViewModel())
}
