//
//  Example_AppApp.swift
//  Example App
//
//  Created by Will Jessop on 10/26/22.
//

import SwiftUI
import CoreDataPlus

@main
struct Example_AppApp: App {
    let yourDataStore = CoreDataPlusStore.shared
    
    @Environment(\.scenePhase) private var phase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        do {
            try CoreDataPlus.setup(store: CoreDataPlusStore.shared)
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, yourDataStore.viewContext)
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background:
                try! yourDataStore.viewContext.save()
            default:
                break
            }
        }
    }
    
}
