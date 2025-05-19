//
//  ThemeModifiers.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

/// Custom styling for the app's dark mode theme
struct AppTheme {
    // Colors
    static let primaryBackground = Color("#3A3A3C") // Medium-dark gray background (lighter than original)
    static let secondaryBackground = Color("#48484A") // Slightly lighter medium-dark gray
    static let accentColor = Color("#7C4DFF") // Vibrant purple
    static let primaryText = Color("#FFFFFF") // White (keeping original)
    static let secondaryText = Color("#E0E0E0") // Off-white (keeping original)
    static let tertiaryText = Color("#BDBDBD") // Light gray for better visibility (keeping original)
    static let subtleBorder = Color("#5A5A5C") // Medium gray border
    static let highlightBackground = Color("#48484A") // Slightly lighter background for highlights
    
    // Icon colors
    static let iconPrimary = Color("#7C4DFF") // Accent color for icons
    static let iconSecondary = Color("#E0E0E0") // Light gray for secondary icons (keeping original)
    
    // Typography
    struct FontSize {
        static let header: CGFloat = 24
        static let title: CGFloat = 18
        static let body: CGFloat = 16
        static let caption: CGFloat = 14
    }
    
    // Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // Rounded corners
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 16
    }
    
    // Icon sizes
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 22
        static let large: CGFloat = 28
    }
    
    // Sidebar width
    static let sidebarWidth: CGFloat = 240
}

// MARK: - View Modifiers

/// Text style for headers
struct HeaderTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.FontSize.header, weight: .semibold))
            .foregroundColor(AppTheme.primaryText)
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}

/// Text style for section titles
struct TitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.FontSize.title, weight: .semibold))
            .foregroundColor(AppTheme.primaryText)
    }
}

/// Text style for body text
struct BodyTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.FontSize.body, weight: .regular))
            .foregroundColor(AppTheme.primaryText)
            .lineSpacing(4)
    }
}

/// Text style for secondary information
struct CaptionTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: AppTheme.FontSize.caption, weight: .medium))
            .foregroundColor(AppTheme.tertiaryText)
    }
}

/// Card style for content containers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
    }
}

/// Style for primary buttons
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(AppTheme.CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Style for secondary buttons
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(AppTheme.accentColor, lineWidth: 1)
                    )
            )
            .foregroundColor(AppTheme.accentColor)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Style for input fields
struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.small)
            .background(AppTheme.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .foregroundColor(AppTheme.primaryText)
    }
}

/// Icon style for improved visibility
struct IconStyle: ViewModifier {
    var color: Color
    var size: CGFloat
    
    init(color: Color = AppTheme.iconPrimary, size: CGFloat = AppTheme.IconSize.medium) {
        self.color = color
        self.size = size
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
            .foregroundColor(color)
    }
}

/// Button with enhanced styling for sidebar and navigation
struct EnhancedNavigationButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? AppTheme.highlightBackground : Color.clear)
            .cornerRadius(AppTheme.CornerRadius.small)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - View Extensions

extension View {
    func headerTextStyle() -> some View {
        self.modifier(HeaderTextStyle())
    }
    
    func titleTextStyle() -> some View {
        self.modifier(TitleTextStyle())
    }
    
    func bodyTextStyle() -> some View {
        self.modifier(BodyTextStyle())
    }
    
    func captionTextStyle() -> some View {
        self.modifier(CaptionTextStyle())
    }
    
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
    
    func appTextFieldStyle() -> some View {
        self.modifier(AppTextFieldStyle())
    }
    
    func iconStyle(color: Color = AppTheme.iconPrimary, size: CGFloat = AppTheme.IconSize.medium) -> some View {
        self.modifier(IconStyle(color: color, size: size))
    }
    
    func enhancedShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}