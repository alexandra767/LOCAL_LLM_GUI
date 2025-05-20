import SwiftUI

struct SidebarItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let hasUnread: Bool
    let action: () -> Void
    
    init(icon: String, title: String, isSelected: Bool = false, hasUnread: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.hasUnread = hasUnread
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: icon)
                    .frame(width: 16, height: 16)
                    .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.secondaryText)
                
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(isSelected ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
                    .lineLimit(1)
                
                Spacer()
                
                if hasUnread {
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .background(isSelected ? Theme.Colors.selection : Color.clear)
            .cornerRadius(Theme.CornerRadius.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
        SidebarItemView(icon: "bubble.left.and.bubble.right", 
                       title: "General Chat", 
                       isSelected: true,
                       hasUnread: true) {}
        
        SidebarItemView(icon: "bubble.left.and.bubble.right", 
                       title: "Project Discussion",
                       hasUnread: false) {}
    }
    .padding()
    .frame(width: 220)
    .background(Theme.Colors.background)
}
