import SwiftUI

/// A view that displays a typing indicator with animated dots.
public struct TypingIndicatorView: View {
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .opacity(isAnimating ? 0.3 : 1.0)
                    .scaleEffect(isAnimating ? 0.6 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.leading)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Previews

#if DEBUG
struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TypingIndicatorView()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
