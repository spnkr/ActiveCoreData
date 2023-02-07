
import Foundation
import CoreData
import NotificationCenter



public class CoreDataPlus {
    public static let shared = CoreDataPlus()
    internal static var config: Config?
    
    internal struct Config {
        var viewContext: NSManagedObjectContext
        var backgroundContext: NSManagedObjectContext? = nil
    }
    
    public var viewContext: NSManagedObjectContext {
        get {
            guard let config = CoreDataPlus.config else {
                raiseError(.noForeground)
                return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            }
            
            return config.viewContext
        }
    }
    
    public var backgroundContext: NSManagedObjectContext? {
        get {
            CoreDataPlus.config?.backgroundContext
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
    ///            CoreDataPlus.setup( viewContext: viewContext,
    ///                                backgroundContext: backgroundContext,
    ///                                    logHandler: { message in print("🌎🌧 log: \(message)") }
    ///            )
    ///    let viewContext = PersistenceController.shared.container.viewContext
    /// ```
    ///
    ///
    ///
    ///
    
    // public class func setup(persistentContainer)
    //
    // public class func setup(nil)
    public class func setup(viewContext: NSManagedObjectContext,
                            backgroundContext: NSManagedObjectContext? = nil,
                            logHandler: @escaping (String) -> Void) throws {
        
        if CoreDataPlus.config != nil {
            throw InternalError.setupAlreadyCalled
        }
        
        CoreDataPlusLogger.configure(logHandler: logHandler)
        CoreDataPlus.config = Config(viewContext: viewContext, backgroundContext: backgroundContext)
        
    }
    
    /// One line config. Sets up core data.
    public class func setup(store: CoreDataPlusStore) throws {
        if CoreDataPlus.config != nil {
            throw InternalError.setupAlreadyCalled
        }
        
        // let persist = Persist.shared // using guess model name
        // then pass the viewContext and backgroundContext to this
        
        // CoreDataPlusLogger.configure(logHandler: logHandler)
        CoreDataPlus.config = Config(viewContext: store.viewContext, backgroundContext: store.backgroundContext)
    }
    
    private init() {
        CoreDataPlusLogger.shared.log("Initializing CoreDataPlus.shared")
    }
}

