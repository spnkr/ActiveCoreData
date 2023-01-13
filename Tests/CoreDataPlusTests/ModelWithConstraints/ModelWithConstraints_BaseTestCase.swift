import XCTest
@testable import CoreDataPlus
import CoreData

class ModelWithConstraints_BaseTestCase: XCTestCase {
    /// Shortcut for a single shared view context
    lazy var c: NSManagedObjectContext = {
        DataStore.modelWithConstraints.inMemoryPersistentContainer.viewContext
    }()
    
    /// Shortcut for a single shared background context. Uses `automaticallyMergesChangesFromParent` = `true` and `NSMergeByPropertyObjectTrumpMergePolicy`.
    lazy var b: NSManagedObjectContext = {
        let b = DataStore.modelWithConstraints.inMemoryPersistentContainer.newBackgroundContext()
        b.automaticallyMergesChangesFromParent = true
        b.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
        return b
    }()
    
    /// Deletes all objects from the `c` and `b` contexts
    func clearSharedContexts() {
        City.destroyAll(context: c)
        Country.destroyAll(context: c)
        Language.destroyAll(context: c)
        
        City.destroyAll(context: b)
        Country.destroyAll(context: b)
        Language.destroyAll(context: b)
        
        try! b.save()
        try! c.save()
    }
    
    override class func setUp() {
        
    }
    
    override class func tearDown() {
        
    }
}
