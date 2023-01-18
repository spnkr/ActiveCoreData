//
//  Example_AppApp.swift
//  Example App
//
//  Created by Will Jessop on 10/26/22.
//

import SwiftUI

@main
struct Example_AppApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) private var phase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background:
                try! persistenceController.container.viewContext.save()
            default:
                break
            }
        }
    }
    
}
