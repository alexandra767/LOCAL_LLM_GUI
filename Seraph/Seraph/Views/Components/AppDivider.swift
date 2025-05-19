//
//  AppDivider.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import SwiftUI

/// Custom divider with app styling
struct AppDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 1)
            .padding(.vertical, 4)
    }
}

#Preview {
    AppDivider()
        .padding()
}