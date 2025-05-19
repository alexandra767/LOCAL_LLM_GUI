//
//  CommonComponents.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

// MARK: - Card Components

/// A basic card view with consistent styling
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .cardStyle()
    }
}

// MARK: - Empty State Components

/// Empty state view for when no content is available
struct EmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.tertiaryText)
                .padding(.bottom, AppTheme.Spacing.small)
            
            Text(title)
                .titleTextStyle()
            
            Text(message)
                .captionTextStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.small)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, AppTheme.Spacing.small)
            }
        }
        .padding(AppTheme.Spacing.large)
    }
}

// MARK: - Loading Components

/// Loading spinner with optional text
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                .padding(.bottom, AppTheme.Spacing.small)
            
            Text(message)
                .captionTextStyle()
        }
        .padding(AppTheme.Spacing.large)
    }
}

// MARK: - Input Components

/// Custom text field with app styling
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var onCommit: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.tertiaryText)
                    .padding(.leading, AppTheme.Spacing.small)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text, onCommit: onCommit ?? {})
                    .foregroundColor(AppTheme.primaryText)
                    .padding(icon == nil ? .leading : [], AppTheme.Spacing.small)
            } else {
                TextField(placeholder, text: $text, onCommit: onCommit ?? {})
                    .foregroundColor(AppTheme.primaryText)
                    .padding(icon == nil ? .leading : [], AppTheme.Spacing.small)
            }
        }
        .appTextFieldStyle()
    }
}

/// Custom text editor with app styling
struct AppTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppTheme.tertiaryText)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .foregroundColor(AppTheme.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
        .appTextFieldStyle()
    }
}

// MARK: - List Components

/// Section header for lists
struct ListSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppTheme.tertiaryText)
            .padding(.top, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.small)
    }
}

// AppDivider is defined in AppDivider.swift

// MARK: - Button Components

/// Icon button with consistent styling
struct IconButton: View {
    let iconName: String
    let action: () -> Void
    var color: Color = AppTheme.primaryText
    var size: CGFloat = 18
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: size))
                .foregroundColor(color)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Toggle with app styling
struct AppToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .bodyTextStyle()
        }
        .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentColor))
    }
}

// MARK: - Badge Components

/// Status badge
struct StatusBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(10)
    }
}

// MARK: - Popup Components

/// Message overlay for feedback
struct MessageOverlay: View {
    let message: String
    let type: MessageType
    let onDismiss: () -> Void
    
    enum MessageType {
        case success, error, info
        
        var color: Color {
            switch self {
            case .success:
                return Color.green
            case .error:
                return Color.red
            case .info:
                return AppTheme.accentColor
            }
        }
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle"
            case .error:
                return "exclamationmark.circle"
            case .info:
                return "info.circle"
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: type.icon)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(type.color)
            .cornerRadius(AppTheme.CornerRadius.small)
            .padding(.horizontal, AppTheme.Spacing.medium)
            
            Spacer()
        }
        .padding(.top, AppTheme.Spacing.medium)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}