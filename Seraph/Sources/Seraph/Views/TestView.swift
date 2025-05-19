import SwiftUI

struct TestView: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test Text Field")
                .font(.title)
                .padding()
            
            TextField("Type something...", text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.blue : Color.gray, lineWidth: 1)
                )
                .focused($isFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
            
            Text("You typed: \(text)")
                .foregroundColor(.secondary)
            
            Button("Click here if text field doesn't have focus") {
                isFocused = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 500, height: 400)
        .onAppear {
            // Make sure the window is key when the view appears
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

#Preview {
    TestView()
}
