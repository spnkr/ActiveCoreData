import XCTest
@testable import ActiveCoreData
import CoreData

final class CoreTests: BaseTestCase {
    
    func testManagedObjectFindable() throws {
        
        let b = backgroundContext
        let c = viewContext
        ActiveCoreData.config = ActiveCoreData.Config(viewContext: c)
        
        b.clearAll()
        c.clearAll()
        
        let book = Book.findOrCreate(column: "title", value: "My Book 1", context: c)
        book.id = "2"
        XCTAssertEqual(book.title, "My Book 1")
        
        let bookAgain = Book.findOrCreate(column: "title", value: "My Book 1", context: c)
        XCTAssertEqual(bookAgain.title, "My Book 1")
        
        let book2 = Book.findOrCreate(id: "3", context: c)
        XCTAssertEqual(book2.id, "3")
        
        let noExist = Book.find(id: "100", context: c)
        XCTAssertNil(noExist)
        
        let book100 = Book.findOrCreate(id: "100", context: c)
        book100.title = "A title"
        
        let book100bNil = Book.find(id: "100", context: b)
        XCTAssertNil(book100bNil)
        
        try c.save()
        
        let book100b = Book.findOrCreate(id: "100", context: b)
        XCTAssertEqual(book100b.title, "A title")
        
        let doesExist = Book.find(id: "100", context: c)
        XCTAssertNotNil(doesExist)
        
        let noExist2 = Book.find(column: "title", value: "A new book", context: c)
        XCTAssertNil(noExist2)
        
        let book200 = Book.findOrCreate(column: "title", value: "A new book", context: c)
        book200.id = "5"
        
        let doesExist2 = Book.find(column: "title", value: "A new book", context: c)
        XCTAssertNotNil(doesExist2)
        XCTAssertEqual(doesExist2?.id, "5")
        
    }
    
    func testManagedObjectFindableUsing() throws {
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        ActiveCoreData.config = nil
        try! ActiveCoreData.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
            
        })
        
        
        let book = Book.findOrCreate(column: "title", value: "My Book 1")
        book.id = "2"
        XCTAssertEqual(book.title, "My Book 1")
        
        let bookAgain = Book.findOrCreate(column: "title", value: "My Book 1")
        XCTAssertEqual(bookAgain.title, "My Book 1")
        
        let book2 = Book.findOrCreate(id: "3")
        XCTAssertEqual(book2.id, "3")
        
        let noExist = Book.find(id: "100")
        XCTAssertNil(noExist)
        
        let book100 = Book.findOrCreate(id: "100")
        book100.title = "A title"
        
        let book100bNil = Book.find(id: "100", using: .background)
        XCTAssertNil(book100bNil)
        
        try c.save()
        
        let book100b = Book.findOrCreate(id: "100", using: .background)
        XCTAssertEqual(book100b.title, "A title")
        
        let doesExist = Book.find(id: "100")
        XCTAssertNotNil(doesExist)
        
        let noExist2 = Book.find(column: "title", value: "A new book")
        XCTAssertNil(noExist2)
        
        let book200 = Book.findOrCreate(column: "title", value: "A new book")
        book200.id = "5"
        
        let doesExist2 = Book.find(column: "title", value: "A new book")
        XCTAssertNotNil(doesExist2)
        XCTAssertEqual(doesExist2?.id, "5")
        
        let bookB = Book.findOrCreate(column: "title", value: "My Book 1", using: .background)
        XCTAssertEqual(bookB.managedObjectContext, b)
        
        let bookF = Book.findOrCreate(column: "title", value: "My Book 1", using: .foreground)
        XCTAssertEqual(bookF.managedObjectContext, c)
        
        let bookC = Book.findOrCreate(column: "title", value: "My Book 1", using: .custom(nsManagedObjectContext: c))
        XCTAssertEqual(bookC.managedObjectContext, c)
        
        XCTAssertEqual(bookF.managedObjectContext, bookC.managedObjectContext)
    }
    
    func testManagedObjectFindableUsing2() throws {
        let e = XCTestExpectation()
        
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        ActiveCoreData.config = nil
        try! ActiveCoreData.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
            
        })
        
        Task {
            let book1 = await c.perform({
                return Book.findOrCreate(id: "2")
            })
            XCTAssertEqual(book1.id, "2")
            
            let count = await c.perform {
              // configure a request with NSCountResultTyoe
                return Book.countFor(.empty())
            }
            dump(count)
            
            let book = await ActiveCoreData.shared.viewContext.perform({
                return Book.findOrCreate(id: "1")
            })
            XCTAssertEqual(book.id, "1")
            
            let book2 = await ActiveCoreData.shared.backgroundContext!.perform({
                return Book.findOrCreate(id: "10", using: .background)
            })
            XCTAssertEqual(book2.id, "10")
            
            e.fulfill()
        }
        
        wait(for: [e], timeout: 3.0)
    }
    
    func testSortDescriptors() throws {
        let sort1 = NSSortDescriptor(\Book.id)
        let sort2 = NSSortDescriptor(keyPath: \Book.id, ascending: true)
        
        XCTAssertEqual(sort1, sort2)
        
        let sort3 = NSSortDescriptor("title")
        let sort4 = NSSortDescriptor(key: "title", ascending: true)
        
        XCTAssertEqual(sort3, sort4)
    }
    
    
    
    
    
    func testManagedObjectDeletableAndCountFor() throws {
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        ActiveCoreData.config = nil
        try! ActiveCoreData.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
            
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
        
        let withSpanishLanguage = NSPredicate("languages contains %@", es)
        XCTAssertEqual(Country.countFor(withSpanishLanguage), 2)
        
        Country.destroyAll(matching: withSpanishLanguage)
        
        XCTAssertEqual(Country.countFor(withSpanishLanguage), 0)
        
    }
    
    
    func testManagedObjectSearchable() throws {
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        ActiveCoreData.config = nil
        try! ActiveCoreData.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
            
        })
        
        let book = Book.findOrCreate(id: "1")
        book.title = "Book 1"
        
        let book2 = Book.findOrCreate(id: "2")
        book2.title = "Book 2"
        
        let results = Book.searchFor(NSPredicate("title contains %@", "Book"), context: c)
        XCTAssertEqual(results.count, 2)
        
        let results2 = Book.searchFor(NSPredicate("title contains %@", "Book"), limit: 1, using: .foreground)
        XCTAssertEqual(results2.count, 1)
        
        let results3 = Book.searchFor(NSPredicate("title contains %@", "Book"), sortBy: [SortDescriptor("title")], using: .foreground)
        XCTAssertEqual(results3.count, 2)
        XCTAssertEqual(results3.first!.title, "Book 1")
        
        let results4 = Book.searchFor(NSPredicate("title contains %@", "Book"), sortBy: [NSSortDescriptor(key: "title", ascending: false)], using: .foreground)
        XCTAssertEqual(results4.count, 2)
        XCTAssertEqual(results4.first!.title, "Book 2")
        
    }
    
}

