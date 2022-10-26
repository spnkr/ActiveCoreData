//
//  Persistence.swift
//  Example App
//
//  Created by Will Jessop on 10/26/22.
//

import CoreData
import CoreDataPlus

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // create some authors
        // using the name field as the unique identifier
        // TODO: HANDLE ID/IDENTIFIABLE
        let murakami = Author.findOrCreate(column: "name", value: "Haruki Murakami", context: viewContext)
        let jk = Author.findOrCreate(column: "name", value: "J. K. Rowling", context: viewContext)
        
        // using id as the unique identifier
        let lydia = Author.findOrCreate(id: "1234", context: viewContext)
        lydia.name = "Lydia Millet"
        
        var authors = [murakami, jk, lydia]
        
        for _ in 0..<10 {
            let newItem = Book.findOrCreate(id: UUID().uuidString, context: viewContext)
            newItem.title = "Harry Potter Vol. \(Int.random(in: 1...1000))"
            
            newItem.addToAuthors(authors.randomElement()!)
            
            // add a 2nd author to some books
            if Int.random(in: 1...100) > 50 {
                newItem.addToAuthors(authors.randomElement()!)
            }
        }
        
        try! viewContext.save()
        
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Example_App")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
