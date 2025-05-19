import SwiftUI

struct FilesView: View {
    var body: some View {
        VStack {
            Text("Files")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your files will appear here")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FilesView()
}
