
import Foundation
import CoreData
import NotificationCenter

public class CoreDataPlusStore: CoreDataContainer {
    public static let shared = CoreDataPlusStore()
    private init() {
        modelName = guessModelName()
    }
    
    private var didConfigure = false
    public var assignedModelName: String? {
        modelName
    }
    internal var modelName: String!
    // internal var overriddenPersistentContainer: NSPersistentContainer?
    // internal var overriddenPersistentCloudKitContainer: NSPersistentCloudKitContainer?
    
    /// Use this
    public func configure() {
        let persist = CoreDataPlusStore.shared
        
        guard persist.didConfigure == false else {
            NSLog("Already configured. Ignorning.")
            return
        }
        
        persist.modelName = guessModelName()
        
        CoreDataPlusLogger.shared.log("Enabled persistence for data model '\(String(describing: persist.modelName))' (auto-detected)")
        
        persist.didConfigure = true
    }
    
    /// If you have a model name mistmatch:
    public func configure(modelName overrideName: String?) {
        let persist = CoreDataPlusStore.shared
        
        guard persist.didConfigure == false else {
            NSLog("Already configured. Ignorning.")
            return
        }
        
        persist.modelName = overrideName
        
        CoreDataPlusLogger.shared.log("Enabled persistence for data model '\(String(describing: persist.modelName))'")
        
        persist.didConfigure = true
    }
    
    // /// To use your own NSPersistentContainer with our automatic context management:
    // /// For example, to set various properties like change tracking.
    // public func configure(container: NSPersistentContainer) {
    //     let persist = CoreDataPlusStore.shared
    //
    //     guard persist.didConfigure == false else { return }
    //
    //     persist.overriddenPersistentContainer = container
    //
    //     CoreDataPlusLogger.shared.log("Enabled persistence using manual NSPersistentContainer")
    //
    //     persist.didConfigure = true
    // }
    // /// To use your own NSPersistentCloudKitContainer with our automatic context management:
    // /// For example, to set various properties like version history
    // public func configure(cloudKitContainer: NSPersistentCloudKitContainer?) {
    //
    // }
    
    /// To use your own NSManagedObjectContext management, don't use CoreDataPlusStore. Instead pass your contexts to each call.
    public func configure(viewContext: NSManagedObjectContext, backgroundContext: NSManagedObjectContext?) { }
    
    /// Read-only context for use on main thread.
    public lazy var viewContext: NSManagedObjectContext = {
        let c = persistentContainer.viewContext
        c.automaticallyMergesChangesFromParent = true
        return c
    }()
    
    /// Single background context for all writes, and background data loading.
    public lazy var backgroundContext: NSManagedObjectContext = {
        let newbackgroundContext = persistentContainer.newBackgroundContext()
        newbackgroundContext.automaticallyMergesChangesFromParent = true
        newbackgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return newbackgroundContext
    }()
    
    private func guessModelName() -> String? {
        let momdUrls = Bundle.main.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? []
        
        guard momdUrls.count == 1 else { return nil }
        
        return momdUrls.first?.lastPathComponent.replacingOccurrences(of: ".momd", with: "")
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
}

