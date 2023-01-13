import XCTest
@testable import CoreDataPlus
import CoreData

class DataStore {
    
    static let model = DataStore(modelName: "Model")
    
    private var modelName: String
    private init(modelName: String) {
        self.modelName = modelName
    }
    
    lazy public var inMemoryPersistentContainer: NSPersistentContainer = {
        
        guard let modelURL = Bundle.module.url(forResource: modelName, withExtension: "momd", subdirectory: "Data Models") else {
            fatalError()
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError()
        }
        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    lazy public var persistentContainer: NSPersistentContainer? = {
        guard let modelURL = Bundle.module.url(forResource:"Model", withExtension: "momd", subdirectory: "Data Models") else { return  nil }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else { return nil }
        
        let container = NSPersistentContainer(name:"Model", managedObjectModel:model)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    public lazy var backgroundContext: NSManagedObjectContext = {
      let newbackgroundContext = inMemoryPersistentContainer.newBackgroundContext()
      newbackgroundContext.automaticallyMergesChangesFromParent = true
      newbackgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
      return newbackgroundContext
    }()
    
    public lazy var mainContext: NSManagedObjectContext = {
      return self.inMemoryPersistentContainer.viewContext
    }()

}
