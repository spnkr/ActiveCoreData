
import Foundation
import CoreData

public class ActiveCoreDataStore: CoreDataContainer {
	private let modelName: String = "YOUR_MODEL_NAME"
	public static let shared = ActiveCoreDataStore()
	
	/// Read-only context for use on main thread.
	public lazy var viewContext: NSManagedObjectContext = {
		let c = persistentContainer.viewContext
		c.automaticallyMergesChangesFromParent = true
		return c
	}()
	
	/// Single background context for all writes, and background data loading.
	public lazy var backgroundContext: NSManagedObjectContext = {
		let newbackgroundContext = persistentContainer.newBackgroundContext()
		newbackgroundContext.automaticallyMergesChangesFromParent = true
		newbackgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		
		return newbackgroundContext
	}()
	
	lazy var persistentContainer: NSPersistentContainer = {
		assert(modelName != "YOUR_MODEL_NAME", "Put the name of your core data model file in ActiveCoreDataStore")
		
		let container = NSPersistentContainer(name: modelName)
		
		container.loadPersistentStores(completionHandler: { (_, error) in
			if let error = error as NSError? {
				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
			}
		})
		
		return container
	}()
}
