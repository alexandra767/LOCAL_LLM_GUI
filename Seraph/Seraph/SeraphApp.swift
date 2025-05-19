//
//  SeraphApp.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/19/25.
//

import SwiftUI

@main
struct SeraphApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
