import Foundation
import SwiftUI

struct MarkdownParser {
    static func parse(_ text: String) -> AttributedString {
        // Simplified implementation that doesn't manipulate AttributedString directly
        // For the purposes of this demo, we'll just return plain text
        // In a real implementation, you'd use a proper markdown parser like Down or Ink
        return AttributedString(text)
    }
}
