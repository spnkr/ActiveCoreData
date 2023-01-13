import XCTest
@testable import CoreDataPlus
import CoreData

extension NSManagedObjectContext {
    struct CoreDataPlusHolder {
        static var _hasConstraints:Bool = false
        static var _isAuthors:Bool = false
        
    }
    
    /// Does this data model have uniqueness constraints?
    ///
    /// Warning:
    /// Intended for CoreDataPlus tests only.
    var hasConstraints:Bool {
        get {
            return CoreDataPlusHolder._hasConstraints
        }
        set(newValue) {
            CoreDataPlusHolder._hasConstraints = newValue
        }
    }
    
    func clearAll() {
        if self.hasConstraints {
            Language.destroyAll(context: self,         saveAfter: false    ,  wrapInContextPerformBlock: false)
            City.destroyAll(context: self,        saveAfter: false     ,  wrapInContextPerformBlock: false)
            Country.destroyAll(context: self,      saveAfter: false    ,  wrapInContextPerformBlock: false)
        } else {
            Author.destroyAll(context: self,      saveAfter: false     ,  wrapInContextPerformBlock: false)
            Book.destroyAll(context: self,        saveAfter: false     ,  wrapInContextPerformBlock: false)
        }
    }
    
}

class BaseTestCase: XCTestCase {
    /// Shortcut for a single shared view context.
    ///
    /// Contains `Author` and `Book` objects. This has no uniqueness constraints.
    lazy var viewContext: NSManagedObjectContext = {
        let context = DataStore.model.inMemoryPersistentContainer.viewContext
        context.hasConstraints = false
        
        return context
    }()
    
    /// Shortcut for a single shared background context. Uses `automaticallyMergesChangesFromParent` = `true` and `NSMergeByPropertyObjectTrumpMergePolicy`.
    ///
    /// Contains `Author` and `Book` objects. This has no uniqueness constraints.
    lazy var backgroundContext: NSManagedObjectContext = {
        let b = DataStore.model.inMemoryPersistentContainer.newBackgroundContext()
        b.automaticallyMergesChangesFromParent = true
        b.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        b.hasConstraints = false
        
        return b
    }()
    
    /// Shortcut for a single shared view context.
    ///
    /// Contains `City`, `Country`, and `Language` objects.
    ///
    /// This has uniqueness constraints on `id` for `City` and `Country`, and a uniqueness constraint on `langCode` for `Language`.
    lazy var viewContextWithConstraints: NSManagedObjectContext = {
        let context = DataStore.modelWithConstraints.inMemoryPersistentContainer.viewContext
        context.hasConstraints = true
        
        return context
    }()
    
    /// Shortcut for a single shared background context. Uses `automaticallyMergesChangesFromParent` = `true` and `NSMergeByPropertyObjectTrumpMergePolicy`.
    ///
    /// Contains `City`, `Country`, and `Language` objects.
    ///
    /// This has uniqueness constraints on `id` for `City` and `Country`, and a uniqueness constraint on `langCode` for `Language`.
    lazy var backgroundContextWithConstraints: NSManagedObjectContext = {
        let b = DataStore.modelWithConstraints.inMemoryPersistentContainer.newBackgroundContext()
        b.automaticallyMergesChangesFromParent = true
        b.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        b.hasConstraints = true
        
        return b
    }()
    
    /// Deletes all objects from the built-in contexts
    func clearSharedContexts() {
        backgroundContextWithConstraints.clearAll()
        viewContextWithConstraints.clearAll()
        
        backgroundContext.clearAll()
        viewContext.clearAll()
    }
    
    override class func setUp() {
        
    }
    
    override class func tearDown() {
        
    }
}
