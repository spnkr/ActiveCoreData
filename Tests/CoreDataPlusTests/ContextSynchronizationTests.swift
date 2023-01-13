import XCTest
@testable import CoreDataPlus
import CoreData

final class ContextSynchronizationTests: BaseTestCase {
    
    func test1() async throws {
        
        _test1(container: DataStore.model.inMemoryPersistentContainer)
        _test1(container: DataStore.modelWithConstraints.inMemoryPersistentContainer)
        
        
    }
    
    func _test1(container: NSPersistentContainer) async throws {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = false
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let b = backgroundContext
        
        let c = container.viewContext
        c.hasConstraints = true
        
        clearSharedContexts()
        
        b.performAndWait {
            let book = Book.findOrCreate(id: "hello", context: b)
            let book2 = Book.findOrCreate(id: "hello2", context: b)
        }
        
        await b.perform(schedule: .enqueued, { [b] in
            let book3 = Book.findOrCreate(id: "hello3", context: b)
            let book4 = Book.findOrCreate(id: "hello4", context: b)
        })
        
        XCTAssertEqual(try c.count(for: Book.fetchRequest()), 0)
        XCTAssertEqual(try b.count(for: Book.fetchRequest()), 4)
        
        try b.save()
        
        XCTAssertEqual(try c.count(for: Book.fetchRequest()), 4)
    }
}
