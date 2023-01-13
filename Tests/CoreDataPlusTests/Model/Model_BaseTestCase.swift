import XCTest
@testable import CoreDataPlus
import CoreData

class Model_BaseTestCase: XCTestCase {
    /// Shortcut for a single shared view context
    lazy var c: NSManagedObjectContext = {
        DataStore.model.inMemoryPersistentContainer.viewContext
    }()
    
    /// Shortcut for a single shared background context. Uses `automaticallyMergesChangesFromParent` = `true` and `NSMergeByPropertyObjectTrumpMergePolicy`.
    lazy var b: NSManagedObjectContext = {
        let b = DataStore.model.inMemoryPersistentContainer.newBackgroundContext()
        b.automaticallyMergesChangesFromParent = true
        b.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
        return b
    }()
    
    /// Deletes all objects from the `c` and `b` contexts
    func clearSharedContexts() {
        Book.destroyAll(context: c)
        Author.destroyAll(context: c)
        
        Book.destroyAll(context: b)
        Author.destroyAll(context: b)
        
        try! b.save()
        try! c.save()
    }
    
    override class func setUp() {
        
    }
    
    override class func tearDown() {
        
    }
}
