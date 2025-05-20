import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Background Colors
        static let background = Color(hex: "#1E1E1E")
        static let secondaryBackground = Color(hex: "#252525")
        static let tertiaryBackground = Color(hex: "#2D2D2D")
        
        // Text Colors
        static let primaryText = Color.white
        static let secondaryText = Color(hex: "#AAAAAA")
        static let tertiaryText = Color(hex: "#888888")
        
        // Accent Colors
        static let accent = Color(hex: "#FF643D")
        static let accentLight = Color(hex: "#FF8C6B")
        
        // UI Elements
        static let border = Color(hex: "#333333")
        static let divider = Color(hex: "#2A2A2A")
        static let selection = Color(hex: "#3A3A3A")
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 24, weight: .light)
        static let title = Font.system(size: 20, weight: .medium)
        static let headline = Font.system(size: 16, weight: .semibold)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let button = Font.system(size: 14, weight: .medium)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
    }
}

// MARK: - View Modifiers
struct ThemedBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.background)
            .foregroundColor(Theme.Colors.primaryText)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - Extension for Color
// This extension allows us to use hex color codes directly
// Example: Color(hex: "#FF643D")
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
