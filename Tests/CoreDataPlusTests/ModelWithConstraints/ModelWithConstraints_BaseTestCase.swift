import XCTest
@testable import CoreDataPlus
import CoreData

extension NSManagedObjectContext {
    struct HasConstraintsHolder {
        static var _hasConstraints:Bool = false
    }
    
    /// Does this data model have uniqueness constraints?
    ///
    /// Warning:
    /// Intended for CoreDataPlus tests only.
    var hasConstraints:Bool {
        get {
            return HasConstraintsHolder._hasConstraints
        }
        set(newValue) {
            HasConstraintsHolder._hasConstraints = newValue
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
    
    /// Deletes all objects from the `c` and `b` contexts
    func clearSharedContexts() {
        City.destroyAll(context: viewContextWithConstraints)
        Country.destroyAll(context: viewContextWithConstraints)
        Language.destroyAll(context: viewContextWithConstraints)
        
        Book.destroyAll(context: b)
        Author.destroyAll(context: b)
        Language.destroyAll(context: b)
        
        try! b.save()
        try! c.save()
    }
    
    override class func setUp() {
        
    }
    
    override class func tearDown() {
        
    }
}
