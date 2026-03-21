//
//  SVLBH_PanelApp.swift
//  SVLBH Panel
//
//  Created by Patrick Bays on 21.03.26.
//

import SwiftUI

@main
struct SVLBH_PanelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
