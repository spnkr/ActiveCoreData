import XCTest
@testable import CoreDataPlus
import CoreData

final class ContextSynchronizationTests_NC: Model_BaseTestCase {
    
    func test1() async throws {
        
        let backgroundContext = DataStore.model.inMemoryPersistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = false
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let b = backgroundContext
        
        clearSharedContexts()
        
        b.performAndWait {
            let book = City.findOrCreate(id: "hello", context: b)
            let book2 = City.findOrCreate(id: "hello2", context: b)
        }
        
        await b.perform(schedule: .enqueued, { [b] in
            let book3 = City.findOrCreate(id: "hello3", context: b)
            let book4 = City.findOrCreate(id: "hello4", context: b)
        })
        
        XCTAssertEqual(try c.count(for: City.fetchRequest()), 0)
        XCTAssertEqual(try b.count(for: City.fetchRequest()), 4)
        
        try b.save()
        
        XCTAssertEqual(try c.count(for: City.fetchRequest()), 4)
        
    }
}
