import Foundation
import UIKit
import CoreDataPlus
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // if you're not using SwiftUI, this is how to set it up in the AppDelegate
        // the SwiftUI equivalent is here: Example_AppApp.swift
        //
        // let viewContext = PersistenceController.shared.container.viewContext
        //
        // let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        // backgroundContext.automaticallyMergesChangesFromParent = true
        // backgroundContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        //
        // try! CoreDataPlus.setup( viewContext: viewContext,
        //                     backgroundContext: backgroundContext,
        //                     logHandler: { message in print("🌎🌧 log: \(message)") }
        // )
        
        return true
    }
}
