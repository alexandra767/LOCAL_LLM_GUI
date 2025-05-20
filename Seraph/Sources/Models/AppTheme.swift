import SwiftUI

/// Represents the app's theme options.
public enum Theme: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case light
    case dark
    
    public var id: String { rawValue }
    
    /// The color scheme that should be applied for this theme.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// The display name of the theme.
    public var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    /// The default theme for the app.
    public static let `default`: Theme = .system
}

// MARK: - View Modifier for Theme

/// A view modifier that applies the selected theme to a view.
public struct ThemeModifier: ViewModifier {
    @AppStorage("selectedTheme") private var theme: String = Theme.default.rawValue
    
    private var selectedTheme: Theme {
        Theme(rawValue: theme) ?? .system
    }
    
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(selectedTheme.colorScheme)
    }
}

// MARK: - View Extension

public extension View {
    /// Applies the current theme to the view.
    /// - Returns: A view with the theme applied.
    func withTheme() -> some View {
        self.modifier(ThemeModifier())
    }
}
