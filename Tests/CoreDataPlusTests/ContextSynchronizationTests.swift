import XCTest
@testable import CoreDataPlus
import CoreData

final class ContextSynchronizationTests: BaseTestCase {
    
    func test1() async throws {
        
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
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
    
    func test2() async throws {
        
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        b.performAndWait {
            let nyc = City.findOrCreate(id: "nyc-1", context: b)
            let enUS = Language.findOrCreate(column: "langCode", value: "en-us", context: b)
        }
        
        await b.perform(schedule: .enqueued, { [b] in
            let ldn = City.findOrCreate(id: "ldn-1", context: b)
            let jp = Language.findOrCreate(column: "langCode", value: "jp", context: b)
        })
        
        XCTAssertEqual(try c.count(for: Language.fetchRequest()), 0)
        XCTAssertEqual(try c.count(for: City.fetchRequest()), 0)
        
        XCTAssertEqual(try b.count(for: Language.fetchRequest()), 2)
        XCTAssertEqual(try b.count(for: City.fetchRequest()), 2)
        
        
        try b.save()
        
        XCTAssertEqual(try c.count(for: Language.fetchRequest()), 2)
        XCTAssertEqual(try c.count(for: City.fetchRequest()), 2)
    }
    
    func test3() async throws {
        
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        b.performAndWait {
            let nyc = City.findOrCreate(id: "nyc-1", context: b)
            let enUS = Language.findOrCreate(column: "langCode", value: "en-us", context: b)
            let jp1 = Language.findOrCreate(column: "langCode", value: "jp", context: b)
            jp1.name = "Japanese 1"
        }
        
        await b.perform(schedule: .enqueued, { [b] in
            let nyc2 = City.findOrCreate(id: "nyc-1", context: b)
            let jp = Language.findOrCreate(column: "langCode", value: "jp", context: b)
            jp.name = "Japanese 2"
        })
        
        XCTAssertEqual(try c.count(for: Language.fetchRequest()), 0)
        XCTAssertEqual(try c.count(for: City.fetchRequest()), 0)
        
        XCTAssertEqual(try b.count(for: Language.fetchRequest()), 2)
        XCTAssertEqual(try b.count(for: City.fetchRequest()), 1)
        
        
        try b.save()
        
        XCTAssertEqual(try c.count(for: Language.fetchRequest()), 2)
        XCTAssertEqual(try c.count(for: City.fetchRequest()), 1)
        
        XCTAssertEqual(Language.findButDoNotCreate(column: "langCode", value: "jp", context: c)!.name, "Japanese 2")
        XCTAssertEqual(Language.findButDoNotCreate(column: "langCode", value: "jp", context: b)!.name, "Japanese 2")
    }
    
    
}
