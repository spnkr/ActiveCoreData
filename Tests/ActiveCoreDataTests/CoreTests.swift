import XCTest
@testable import ActiveCoreData
import CoreData

final class CoreTests: BaseTestCase {
    
    func testManagedObjectFindable() throws {
        
        let b = backgroundContext
        let c = viewContext
        
        
        b.clearAll()
        c.clearAll()
        
        let book = Book.find(column: "title", value: "My Book 1", context: c)
        book.id = "2"
        XCTAssertEqual(book.title, "My Book 1")
        
        let bookAgain = Book.find(column: "title", value: "My Book 1", context: c)
        XCTAssertEqual(bookAgain.title, "My Book 1")
        
        let book2 = Book.find(id: "3", context: c)
        XCTAssertEqual(book2.id, "3")
        
        let noExist = Book.load(id: "100", context: c)
        XCTAssertNil(noExist)
        
        let book100 = Book.find(id: "100", context: c)
        book100.title = "A title"
        
        let book100bNil = Book.load(id: "100", context: b)
        XCTAssertNil(book100bNil)
        
        try c.save()
        
        let book100b = Book.find(id: "100", context: b)
        XCTAssertEqual(book100b.title, "A title")
        
        let doesExist = Book.load(id: "100", context: c)
        XCTAssertNotNil(doesExist)
        
        let noExist2 = Book.load(column: "title", value: "A new book", context: c)
        XCTAssertNil(noExist2)
        
        let book200 = Book.find(column: "title", value: "A new book", context: c)
        book200.id = "5"
        
        let doesExist2 = Book.load(column: "title", value: "A new book", context: c)
        XCTAssertNotNil(doesExist2)
        XCTAssertEqual(doesExist2?.id, "5")
        
    }
    
    func testManagedObjectFindableUsing() throws {
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        
        
        
        let book = Book.find(column: "title", value: "My Book 1", context: c)
        book.id = "2"
        XCTAssertEqual(book.title, "My Book 1")
        
        let bookAgain = Book.find(column: "title", value: "My Book 1", context: c)
        XCTAssertEqual(bookAgain.title, "My Book 1")
        
        let book2 = Book.find(id: "3", context: c)
        XCTAssertEqual(book2.id, "3")
        
        let noExist = Book.load(id: "100", context: c)
        XCTAssertNil(noExist)
        
        let book100 = Book.find(id: "100", context: c)
        book100.title = "A title"
        
		let book100bNil = Book.load(id: "100", context: b)
        XCTAssertNil(book100bNil)
        
        try c.save()
        
        let book100b = Book.find(id: "100", context: b)
        XCTAssertEqual(book100b.title, "A title")
        
        let doesExist = Book.load(id: "100", context: c)
        XCTAssertNotNil(doesExist)
        
        let noExist2 = Book.load(column: "title", value: "A new book", context: c)
        XCTAssertNil(noExist2)
        
        let book200 = Book.find(column: "title", value: "A new book", context: c)
        book200.id = "5"
        
        let doesExist2 = Book.load(column: "title", value: "A new book", context: c)
        XCTAssertNotNil(doesExist2)
        XCTAssertEqual(doesExist2?.id, "5")
        
        let bookB = Book.find(column: "title", value: "My Book 1", context: b)
        XCTAssertEqual(bookB.managedObjectContext, b)
        
        let bookF = Book.find(column: "title", value: "My Book 1", context: c)
        XCTAssertEqual(bookF.managedObjectContext, c)
        
        let bookC = Book.find(column: "title", value: "My Book 1", context: c)
        XCTAssertEqual(bookC.managedObjectContext, c)
        
        XCTAssertEqual(bookF.managedObjectContext, bookC.managedObjectContext)
    }
    
    func testManagedObjectFindableUsing2() throws {
        let e = XCTestExpectation()
        
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
       
        
        Task {
            let book1 = await c.perform({
                return Book.find(id: "2")
            })
            XCTAssertEqual(book1.id, "2")
            
            let count = await c.perform {
              // configure a request with NSCountResultTyoe
                return Book.countFor(.empty(), context: b)
            }
            dump(count)
            
			await DB.background.enqueue {
				let book = Book.find(id: "1", context: $0)
				XCTAssertEqual(book.id, "1")
            }
            
            
			await DB.background.enqueue {
				let book = Book.find(id: "10", context: $0)
				XCTAssertEqual(book.id, "10")
			}
			
            
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
        
        // ActiveCoreData.config = nil
        // try! ActiveCoreData.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
        //     
        // })
        
        let usa = Country.find(id: "1")
        let japan = Country.find(id: "2")
        let mexico = Country.find(id: "3")
        
        let nyc = City.find(id: "nyc-1", context: c)
        let tokyo = City.find(id: "japan-1", context: c)
        
        let enUS = Language.find(column: "langCode", value: "en-us", context: c)
        let jp1 = Language.find(column: "langCode", value: "jp", context: c)
        let es = Language.find(column: "langCode", value: "es", context: c)
        
        nyc.country = usa
        tokyo.country = japan
        
        usa.addToLanguages(enUS)
        usa.addToLanguages(es)
        japan.addToLanguages(jp1)
        mexico.addToLanguages(es)
        
        let withSpanishLanguage = NSPredicate("languages contains %@", es)
		XCTAssertEqual(Country.countFor(withSpanishLanguage, context: b), 2)
        
        Country.destroyAll(matching: withSpanishLanguage, context: b)
        
        XCTAssertEqual(Country.countFor(withSpanishLanguage, context: b), 0)
        
    }
    
    
    func testManagedObjectSearchable() throws {
        let b = backgroundContext
        let c = viewContext
        
        b.clearAll()
        c.clearAll()
        
        // ActiveCoreData.config = nil
        // try! ActiveCoreData.setup(viewContext: c, backgroundContext: b, logHandler: { _ in
        //     
        // })
        
        let book = Book.find(id: "1")
        book.title = "Book 1"
        
        let book2 = Book.find(id: "2")
        book2.title = "Book 2"
        
        let results = Book.matching(NSPredicate("title contains %@", "Book"), context: c)
        XCTAssertEqual(results.count, 2)
        
        let results2 = Book.matching(NSPredicate("title contains %@", "Book"), limit: 1, context: c)
        XCTAssertEqual(results2.count, 1)
        
        let results3 = Book.matching(NSPredicate("title contains %@", "Book"), sortBy: [SortDescriptor("title")], context: c)
        XCTAssertEqual(results3.count, 2)
        XCTAssertEqual(results3.first!.title, "Book 1")
        
        let results4 = Book.matching(NSPredicate("title contains %@", "Book"), sortBy: [NSSortDescriptor(key: "title", ascending: false)], context: c)
        XCTAssertEqual(results4.count, 2)
        XCTAssertEqual(results4.first!.title, "Book 2")
        
    }
    
}

