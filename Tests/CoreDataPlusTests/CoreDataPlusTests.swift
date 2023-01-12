import XCTest
@testable import CoreDataPlus
import CoreData

final class CoreDataPlusTests: XCTestCase {
    // TODO: Fix and expand
    func testSaving() throws {
        let e = XCTestExpectation()
        let e2 = XCTestExpectation()
        let e3 = XCTestExpectation()
        
        let c = DataStore.model.inMemoryPersistentContainer.viewContext
        
        let b = DataStore.model.inMemoryPersistentContainer.newBackgroundContext()
        b.automaticallyMergesChangesFromParent = true
        b.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        XCTAssertEqual(0, Author.countFor(pred("id = %@", "huxley"), context: c))
        
        let huxley = Author.findOrCreate(id: "huxley", context: c)
        huxley.name = "A. Huxley"
        
        let huxley2 = Author.findOrCreate(id: "huxley", context: c)
        huxley2.name = "Ald. Huxley"
        
        b.perform {
            let huxley3 = Author.findOrCreate(id: "huxley", context: c)
            huxley3.name = "Ald. Huxley"
        }
        
        // try! c.save()
        
        XCTAssertEqual(0, Author.countFor(pred("name = %@", "A. Huxley"), context: c))
        XCTAssertEqual(1, Author.countFor(pred("id = %@", "huxley"), context: c))
        
        b.perform {
            c.performAndWait {
                XCTAssertEqual(0, Author.countFor(pred("name = %@", "A. Huxley"), context: c))
                XCTAssertEqual(1, Author.countFor(pred("id = %@", "huxley"), context: c))
            }
            
            XCTAssertEqual(0, Author.countFor(pred("name = %@", "A. Huxley"), context: b))
            XCTAssertEqual(1, Author.countFor(pred("id = %@", "huxley"), context: b))
            
            try! b.save()
            
            c.performAndWait {
                XCTAssertEqual(0, Author.countFor(pred("name = %@", "A. Huxley"), context: c))
                XCTAssertEqual(1, Author.countFor(pred("id = %@", "huxley"), context: c))
            }
            
            XCTAssertEqual(0, Author.countFor(pred("name = %@", "A. Huxley"), context: b))
            XCTAssertEqual(1, Author.countFor(pred("id = %@", "huxley"), context: b))
            
            
            // MARK: - Foreground/background saving 1
            let huxley4 = Author.findOrCreate(id: "huxley", context: b)
            
            var foregroundName: String?
            c.performAndWait {
                huxley2.name = "aldous huxley"
                foregroundName = huxley2.name
            }
            
            XCTAssertNotEqual(foregroundName, huxley4.name)
            
            
            // MARK: - Foreground/background saving 2
            let huxleyB = Author.findOrCreate(id: "huxley", context: b)
            XCTAssertEqual("", huxleyB.name)
            // try? c.save()
            //
            let huxleyC = Author.findOrCreate(id: "huxley", context: b)
            XCTAssertEqual("", huxleyC.name)
            
            
            // MARK: - Foreground/background saving 3
            let huxleyZ = Author.findOrCreate(id: "huxley", context: b)
            huxleyZ.name = huxley2.name
            XCTAssertEqual(huxley2.name, huxleyZ.name)
            
            huxleyZ.name = "Aldous Leonard Huxley"
            
            var foregroundNameLong: String?
            c.performAndWait {
                let huxLong = Author.findOrCreate(id: "huxley", context: c)
                foregroundNameLong = huxLong.name
            }
            XCTAssertEqual("aldous huxley", foregroundNameLong)
            
            try! b.save()
            
            // var foregroundNameLong2: String?
            // c.performAndWait {
            //     let huxLong = Author.findOrCreate(id: "huxley", context: c)
            //     foregroundNameLong2 = huxLong.name
            //
            //     XCTAssertEqual("Aldous Leonard Huxley", foregroundNameLong2)
            //     XCTAssertEqual("aldous huxley", foregroundNameLong2)
            //
            //     e2.fulfill()
            // }
            //
            // let huxleyC2 = Author.findOrCreate(id: "huxley", context: b)
            // XCTAssertEqual("aldous huxley", huxleyC2.name)
            
            
            // MARK: - Foreground/background saving 4
            
            // var foregroundNameB: String?
            // c.perform {
            //     huxley2.name = "aldous huxley"
            //     foregroundNameB = huxley2.name
            //
            //     Task {
            //         XCTAssertThrowsError(try c.save()) { error in
            //             XCTAssertEqual((error as! NSError).code, 133020)
            //             XCTAssertEqual((error as! NSError).localizedDescription, "Could not merge changes.")
            //         }
            //
            //         e3.fulfill()
            //     }
            //
            // }
            
            XCTAssertEqual("Aldous Leonard Huxley", huxleyB.name)
            
            e.fulfill()
        }
        
        wait(for: [e], timeout: 5.0)
    }
}
