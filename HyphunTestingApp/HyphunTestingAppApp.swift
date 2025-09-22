//
//  HyphunTestingAppApp.swift
//  HyphunTestingApp
//
//  Created by Krithik Roshan on 21/09/25.
//

import SwiftUI

@main
struct HyphunTestingAppApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
