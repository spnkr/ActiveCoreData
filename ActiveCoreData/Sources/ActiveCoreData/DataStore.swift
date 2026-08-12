import CoreData
import Foundation

open class DataStore: Container {
	@MainActor public static let shared = DataStore()
	
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
		newbackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		return newbackgroundContext
	}()
	
	lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: Self.persistentContainerName)
		
		container.loadPersistentStores(completionHandler: { (_, error) in
			
		})
		
		return container
	}()
	
	public static let persistentContainerName: String = {
		if let infoDict = Bundle.main.infoDictionary,
		   let activeCoreDataDict = infoDict["ActiveCoreData"] as? [String: Any],
		   let containerName = activeCoreDataDict["persistentContainerName"] as? String {
			return containerName
		}
		
		// Fallback option when the Info.plist key is missing
		return guessModelName()
	}()
	
	private static func guessModelName() -> String {
		let momdUrls = Bundle.main.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? []
		
		return momdUrls.first!.lastPathComponent.replacingOccurrences(of: ".momd", with: "")
	}
}
