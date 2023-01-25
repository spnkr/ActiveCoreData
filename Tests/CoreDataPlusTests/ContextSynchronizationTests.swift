import XCTest
@testable import CoreDataPlus
import CoreData

final class ContextSynchronizationTests: BaseTestCase {
    
    func syncTestBasic() async throws {
        
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
    
    func syncTestExtended() async throws {
        
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
    
    func syncTestEnhanced() async throws {
        
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
    
    func testManagedObjectDeletableAndCountForSynchronization() throws {
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        CoreDataPlus.config = nil
        CoreDataPlus.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
            
        })
        
        let usa = Country.findOrCreate(id: "1")
        let japan = Country.findOrCreate(id: "2")
        let mexico = Country.findOrCreate(id: "3")
        
        let nyc = City.findOrCreate(id: "nyc-1", context: c)
        let tokyo = City.findOrCreate(id: "japan-1", context: c)
        
        let enUS = Language.findOrCreate(column: "langCode", value: "en-us", context: c)
        let jp1 = Language.findOrCreate(column: "langCode", value: "jp", context: c)
        let es = Language.findOrCreate(column: "langCode", value: "es", context: c)
        
        nyc.country = usa
        tokyo.country = japan
        
        usa.addToLanguages(enUS)
        usa.addToLanguages(es)
        japan.addToLanguages(jp1)
        mexico.addToLanguages(es)
        
        let withSpanishLanguage = Predicate("languages contains %@", es)
        XCTAssertEqual(Country.countFor(withSpanishLanguage), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .background), 0)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .foreground), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .custom(nsManagedObjectContext: c)), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .custom(nsManagedObjectContext: b)), 0)
        
        try! c.save()
        
        XCTAssertEqual(Country.countFor(withSpanishLanguage), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .background), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .foreground), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .custom(nsManagedObjectContext: c)), 2)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .custom(nsManagedObjectContext: b)), 2)
        
        Country.destroyAll(matching: withSpanishLanguage)
        
        XCTAssertEqual(Country.countFor(withSpanishLanguage), 0)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .background), 2)
        
        try! c.save()
        
        XCTAssertEqual(Country.countFor(withSpanishLanguage), 0)
        XCTAssertEqual(Country.countFor(withSpanishLanguage, using: .background), 0)
    }
}
