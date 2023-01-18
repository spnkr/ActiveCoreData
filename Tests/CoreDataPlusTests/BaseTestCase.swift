import XCTest
@testable import CoreDataPlus
import CoreData

extension NSManagedObjectContext {
    func clearAll() {
        Language.destroyAll(context: self)
        City.destroyAll(context: self)
        Country.destroyAll(context: self)
        Author.destroyAll(context: self)
        Book.destroyAll(context: self)
    }
    
}

class BaseTestCase: XCTestCase {
    /// Shortcut for a single shared view context.
    ///
    /// Contains `Author` and `Book` objects. These have no uniqueness constraints.
    ///
    /// Also Contains `City`, `Country`, and `Language` objects. These have uniqueness constraints on `id` for `City` and `Country`, and a uniqueness constraint on `langCode` for `Language`.
    lazy var viewContext: NSManagedObjectContext = {
        let context = DataStore.model.inMemoryPersistentContainer.viewContext
        
        return context
    }()
    
    /// Shortcut for a single shared background context. Uses `automaticallyMergesChangesFromParent` = `true` and `NSMergeByPropertyObjectTrumpMergePolicy`.
    ///
    /// Contains `Author` and `Book` objects. These have no uniqueness constraints.
    ///
    /// Also Contains `City`, `Country`, and `Language` objects. These have uniqueness constraints on `id` for `City` and `Country`, and a uniqueness constraint on `langCode` for `Language`.
    lazy var backgroundContext: NSManagedObjectContext = {
        let b = DataStore.model.inMemoryPersistentContainer.newBackgroundContext()
        b.automaticallyMergesChangesFromParent = true
        b.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return b
    }()
    
    /// Deletes all objects from the built-in contexts
    func clearSharedContexts() {
        backgroundContext.clearAll()
        viewContext.clearAll()
    }
    
    override class func setUp() {
        
    }
    
    override class func tearDown() {
        
    }
}
