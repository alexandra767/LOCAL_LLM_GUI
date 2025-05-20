import SwiftUI

struct SidebarHeaderView: View {
    let title: String
    let action: (() -> Void)?
    
    init(title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
                .tracking(1)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(Theme.Typography.caption.weight(.medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.top, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        SidebarHeaderView(title: "Recent Chats")
        SidebarHeaderView(title: "Projects", action: {})
    }
    .frame(width: 220)
    .background(Theme.Colors.background)
}
