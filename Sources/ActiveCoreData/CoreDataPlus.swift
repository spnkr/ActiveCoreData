
import Foundation
import CoreData

public class ActiveCoreData {
    public static let shared = ActiveCoreData()
    internal static var config: Config?
    
    internal struct Config {
        var viewContext: NSManagedObjectContext
        var backgroundContext: NSManagedObjectContext? = nil
    }
    
    public var viewContext: NSManagedObjectContext {
        get {
            guard let config = ActiveCoreData.config else {
                raiseError(.noForeground)
                return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            }
            
            return config.viewContext
        }
    }
    
    public var backgroundContext: NSManagedObjectContext? {
        get {
            ActiveCoreData.config?.backgroundContext
        }
    }
    
    /// Description
    /// - Parameters:
    ///   - viewContext: <#viewContext description#>
    ///   - backgroundContext: <#backgroundContext description#>
    ///   - logHandler: <#logHandler description#>
    ///
    /// Example
    /// ```swift
    ///    let viewContext = PersistenceController.shared.container.viewContext
    ///
    ///            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
    ///            backgroundContext.automaticallyMergesChangesFromParent = true
    ///            backgroundContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    ///
    ///            ActiveCoreData.setup( viewContext: viewContext,
    ///                                backgroundContext: backgroundContext,
    ///                                    logHandler: { message in print("🌎🌧 log: \(message)") }
    ///            )
    ///    let viewContext = PersistenceController.shared.container.viewContext
    /// ```
    ///
    ///
    ///
    ///
    
    // for comment:
    // should these setup methods be added?
    // public class func setup(persistentContainer)
    // public class func setup()
    public class func setup(viewContext: NSManagedObjectContext,
                            backgroundContext: NSManagedObjectContext? = nil,
                            logHandler: @escaping (String) -> Void) throws {
        
        if ActiveCoreData.config != nil {
            throw InternalError.setupAlreadyCalled
        }
        
        ActiveCoreDataLogger.configure(logHandler: logHandler)
        ActiveCoreData.config = Config(viewContext: viewContext, backgroundContext: backgroundContext)
        
    }
    
    /// One line config. Sets up core data.
    public class func setup(store: ActiveCoreDataStore) throws {
        if ActiveCoreData.config != nil {
            throw InternalError.setupAlreadyCalled
        }
        
        ActiveCoreData.config = Config(viewContext: store.viewContext, backgroundContext: store.backgroundContext)
    }
    
    private init() {
        ActiveCoreDataLogger.shared.log("Initializing ActiveCoreData.shared")
    }
}

